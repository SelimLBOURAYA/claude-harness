#!/usr/bin/env python3
"""Autopilot: runs one lot of the current repository from lot-start to merge (lot 27).

Every step is a fresh headless session (`claude -p`) with the model chosen for
that step, passed per process: `~/.claude/settings.json` is never rewritten and
`claude-profile` is never called. Each session answers through a JSON schema
(`status`, `lot`, `questions`, `reason`), and the script checks every step
itself, deterministically, before the next one: the model's word is never
enough. At the first `blocked`, `failed`, failed check or timeout, the state is
written to `.claude/autopilot-state.json`, `notify-send` is called, and the
script stops. One lot per launch: it stops after the merge.

Usage, from the root of a harnessed repository:

    autopilot.py                         start the next lot
    autopilot.py N                       start lot N, named to lot-start
    autopilot.py --resume                resume a stopped run at its recorded step
    autopilot.py --resume --answer TEXT  answer the questions of a blocked start or dev
    autopilot.py --dry-run               print the step commands without running them

Exit status: 0 merged (or dry run), 1 stopped, 2 refused to start.

Standard library only (V6).
"""

import argparse
import datetime
import json
import os
import re
import signal
import subprocess
import sys

HERE = os.path.dirname(os.path.realpath(__file__))
# The import below must leave no __pycache__ in the marketplace clone.
sys.dont_write_bytecode = True
sys.path.insert(0, os.path.join(HERE, "..", "hooks"))
import lotfile  # noqa: E402

SYNC_STATUS = os.path.join(HERE, "..", "skills", "lot-start", "sync-status.py")
STATE_PATH = os.path.join(".claude", "autopilot-state.json")

# A ceiling against a session that never ends (a loop on a red test, a stuck
# CI), not a target. The environment override exists for the tests only.
STEP_TIMEOUT = int(os.environ.get("AUTOPILOT_STEP_TIMEOUT", "1800"))

OPUS = ("--model", "claude-opus-5-5", "--effort", "medium")
PROFILES = {"claude": "settings.claude.json", "deepseek": "settings.deepseek.json"}

# step -> (label, model options, profile)
MODELS = {
    "start": ("DeepSeek", (), "deepseek"),
    "dev": ("DeepSeek", (), "deepseek"),
    "test": ("DeepSeek", (), "deepseek"),
    "fix": ("DeepSeek", (), "deepseek"),
    "review": ("Opus", OPUS, "claude"),
    "audit": ("Opus", OPUS, "claude"),
    "ship": ("DeepSeek", (), "deepseek"),
}
SEQUENCE = ("start", "dev", "test", "review", "audit", "ship")
# The lot IDs lot-confirm.sh accepts. The lot comes from the model's answer and
# names log files, reports and the confirmation prompt: nothing else passes.
LOT_ID = re.compile(r"[0-9]+[a-z]?(\.[0-9]+)?")

# The two forms lot-confirm.sh accepts as the whole prompt (lot 28): --answer
# must never carry one, the confirmation only comes after the checks.
CONFIRMATION = re.compile(r"(?:/claude-harness:)?lot-start confirm (?:%s)" % LOT_ID.pattern)
ANSWER_PREFIX = "Owner answers to your questions:"

FIX_PROMPT = (
    "A test that lot-test left uncommitted in the working tree reveals a bug of "
    "lot {lot}. Fix the production code, never the test (GATE-2), run the "
    "Validation command of CLAUDE.md green, then commit the fix with the test: "
    "`fix({lot}): fix the bug lot-test revealed`."
)
PROMPTS = {
    "start": "/claude-harness:lot-start",
    "dev": "lot-start confirm {lot}",
    "test": "/claude-harness:lot-test",
    "fix": FIX_PROMPT,
    "review": "/claude-harness:lot-review",
    "audit": "/claude-harness:lot-audit",
    "ship": "/claude-harness:lot-ship",
}


def start_prompt(lot):
    """The lot-start prompt, naming the lot when one was given (lot 28)."""
    return PROMPTS["start"] + (" " + lot if lot else "")


def answer_prompt(text):
    """The owner's answers, sent to the stopped session that asked (lot 28)."""
    return ANSWER_PREFIX + "\n" + text


SYSTEM_PROMPT = (
    "Autopilot run (HARNESS_AUTOPILOT=1): no human is present in this session. "
    "Any question a skill would ask the user ends the turn instead: answer with "
    "status `blocked` and the questions in `questions`, without deciding them "
    "yourself: one entry per question, in French, each option of a question on "
    "its own line. Answer `failed` with the reason when the step cannot complete "
    "(for lot-test: when an added test reveals a bug), and `ok` only when the "
    "step's skill reached its end. The `lot-start confirm N` hand-off that ends "
    "lot-start's Part A is that normal end: answer `ok`, never put it in "
    "`questions`, the autopilot sends the confirmation itself. `lot` is the lot "
    "ID. Never tell the user to open a new session or to switch profile: the "
    "autopilot does it."
)
SCHEMA = {
    "type": "object",
    "properties": {
        "status": {"enum": ["ok", "blocked", "failed"]},
        "lot": {"type": "string"},
        "questions": {"type": "array", "items": {"type": "string"}},
        "reason": {"type": "string"},
    },
    "required": ["status", "lot", "questions", "reason"],
}

# What lot-test may commit, by Stack (lot-test section 0.1).
TEST_FILES = {
    "backend": lambda path: path.startswith("src/test/"),
    "frontend": lambda path: path.endswith(".spec.ts"),
    "harness": lambda path: path.startswith("tests/"),
}


class Stop(Exception):
    """A stop: the reason, the step a --resume starts from, and the answer.

    `status` and `questions` are the model's own answer when a blocked session
    stopped the run; any other stop leaves them empty (lot 28).
    """

    def __init__(self, reason, resume, status=None, questions=None):
        super().__init__(reason)
        self.reason = reason
        self.resume = resume
        self.status = status
        self.questions = questions or []


# --------------------------------------------------------------------------
# repository


git = lotfile.run_git


def validation_command(params):
    """The Validation command of the Gate parameters, None when it does not apply."""
    validation = params.get("Validation command", "")
    return validation if validation and validation.lower() != "n/a" else None


def changed_files(root, base, head="HEAD"):
    """Files touched by the commits base..head."""
    out = git(root, "log", "--format=", "--name-only", "%s..%s" % (base, head)) or ""
    return sorted({line for line in out.splitlines() if line})


def committed(root, path):
    return git(root, "cat-file", "-e", "HEAD:" + path) is not None


def exclude_state(root):
    """The state file stays out of git without editing the project's .gitignore."""
    if subprocess.run(["git", "-C", root, "check-ignore", "-q", STATE_PATH]).returncode == 0:
        return
    exclude = git(root, "rev-parse", "--git-path", "info/exclude")
    if exclude is None:
        return
    exclude = os.path.join(root, exclude)
    os.makedirs(os.path.dirname(exclude), exist_ok=True)
    with open(exclude, "a", encoding="utf-8") as handle:
        handle.write("\n%s\n" % STATE_PATH)


def read_state(root):
    try:
        with open(os.path.join(root, STATE_PATH), encoding="utf-8") as handle:
            return json.load(handle)
    except (OSError, ValueError):
        return None


def write_state(root, state):
    exclude_state(root)
    os.makedirs(os.path.join(root, ".claude"), exist_ok=True)
    with open(os.path.join(root, STATE_PATH), "w", encoding="utf-8") as handle:
        json.dump(state, handle, indent=2)
        handle.write("\n")


# --------------------------------------------------------------------------
# sessions


def command(step, home, session=None):
    label, model, profile = MODELS[step]
    cmd = ["claude", "-p", *model, "--settings", os.path.join(home, ".claude", PROFILES[profile])]
    if session:
        cmd += ["--resume", session]
    cmd += [
        "--permission-mode", "acceptEdits",
        "--output-format", "stream-json", "--verbose",
        "--json-schema", json.dumps(SCHEMA),
        "--append-system-prompt", SYSTEM_PROMPT,
    ]
    return cmd


def allowed_tools(params, home):
    """Per-process allowlist, on top of the profile's: nothing committed in the project.

    python3 is limited to the plugin's own scripts: `python3 -c` would run any
    git command out of the git guard's sight. The two printenv are the profile
    guard and the Autopilot section of lot-review and lot-audit: a headless
    session denies what it cannot ask.
    """
    plugin = os.path.join(home, ".claude", "plugins", "cache", "claude-harness")
    tools = ["Bash(printenv ANTHROPIC_BASE_URL)", "Bash(printenv HARNESS_AUTOPILOT)",
             "Bash(gh pr *)", "Bash(gh run *)", "Bash(python3 %s/*)" % plugin, "Bash(jq *)"]
    validation = validation_command(params)
    if validation:
        tools[:0] = ["Bash(%s)" % validation, "Bash(%s *)" % validation]
    return ["--allowedTools", ",".join(tools)]


def parse_output(path, offset=0):
    """(structured answer or None, session id) from a stream-json log, read from offset.

    The log is appended to: a rerun of a step the same day must never read the
    answer of an earlier session, so only what follows offset counts.
    """
    answer, session = None, None
    try:
        with open(path, "rb") as handle:
            handle.seek(offset)
            lines = handle.read().decode("utf-8", "replace").splitlines()
    except OSError:
        return None, None
    for line in lines:
        try:
            event = json.loads(line)
        except ValueError:
            continue
        if not isinstance(event, dict):
            continue
        session = event.get("session_id") or session
        if event.get("type") == "result":
            answer = event.get("structured_output")
            if not isinstance(answer, dict):
                try:
                    answer = json.loads(event.get("result") or "")
                except ValueError:
                    answer = None
    return answer, session


class Pilot:
    def __init__(self, root, params, home, state, expected_lot=None,
                 answer_step=None, answer_text=None):
        self.root = root
        self.params = params
        self.home = home
        self.state = state
        self.expected_lot = expected_lot
        self.answer_step = answer_step
        self.answer_text = answer_text
        self.logs = os.path.join(home, ".claude", "autopilot", os.path.basename(root))

    @property
    def lot(self):
        return self.state.get("lot")

    def log_path(self, step):
        date = datetime.date.today().isoformat()
        return os.path.join(self.logs, "%s-lot-%s-%s.jsonl" % (date, self.lot or "new", step))

    def answered_session(self, step, text):
        """Resume the stopped session with the owner's answers (lot 28).

        A stop before the session answers (timeout, Ctrl-C, no structured
        answer) stays blocked, so the same answers can be sent again.
        """
        try:
            return self.session(step, resume=self.state.get("session_id"),
                                prompt=answer_prompt(text))
        except Stop as stop:
            raise Stop(stop.reason, step, status="blocked", questions=self.state.get("questions"))

    def take_answer(self, step):
        """The owner's answers when they answer this very step, once (lot 28)."""
        if self.answer_step != step:
            return None
        self.answer_step = None
        return self.answer_text

    def session(self, step, resume=None, prompt=None):
        """Run one step's session; returns its structured answer, or stops."""
        cmd = command(step, self.home, resume) + allowed_tools(self.params, self.home)
        if prompt is None:
            prompt = PROMPTS[step].format(lot=self.lot)
        env = dict(os.environ, HARNESS_AUTOPILOT="1")
        path = self.log_path(step)
        os.makedirs(self.logs, exist_ok=True)
        print("autopilot: %s (%s), log %s" % (step, MODELS[step][0], path), flush=True)
        offset = os.path.getsize(path) if os.path.exists(path) else 0
        with open(path, "a", encoding="utf-8") as out:
            proc = subprocess.Popen(
                cmd, cwd=self.root, env=env, stdin=subprocess.PIPE, stdout=out,
                stderr=subprocess.STDOUT, text=True, start_new_session=True,
            )
            try:
                proc.communicate(prompt, timeout=STEP_TIMEOUT)
            except subprocess.TimeoutExpired:
                os.killpg(proc.pid, signal.SIGKILL)
                proc.wait()
                raise Stop("%s: timeout after %ss, session killed" % (step, STEP_TIMEOUT), step)
            except KeyboardInterrupt:
                # The session has its own process group: Ctrl-C does not reach it.
                os.killpg(proc.pid, signal.SIGKILL)
                proc.wait()
                raise Stop("%s: interrupted, session killed" % step, step)
        answer, session = parse_output(path, offset)
        if session:
            self.state["session_id"] = session
        if answer is None:
            raise Stop("%s: no structured answer (exit %s)" % (step, proc.returncode), step)
        return answer

    def expect_ok(self, step, answer, blocked_resume=None):
        status = answer.get("status")
        questions = answer.get("questions") or []
        if status == "ok" and not questions:
            return
        if status == "ok":
            # Questions are a block whatever the status says: --answer must reach them.
            status = "blocked"
        reason = "%s: %s - %s" % (step, status, answer.get("reason", ""))
        raise Stop(reason, blocked_resume if status == "blocked" and blocked_resume else step,
                   status=status, questions=questions)

    def validation_green(self, step):
        validation = validation_command(self.params)
        if not validation:
            return
        with open(self.log_path(step), "a", encoding="utf-8") as out:
            try:
                code = subprocess.run(
                    validation, shell=True, cwd=self.root, stdout=out,
                    stderr=subprocess.STDOUT, timeout=STEP_TIMEOUT,
                ).returncode
            except subprocess.TimeoutExpired:
                code = "timeout"
        if code != 0:
            raise Stop("%s: Validation command `%s` red (%s)" % (step, validation, code), step)

    # --- the steps -------------------------------------------------------

    @staticmethod
    def drop_confirmations(answer):
        """The `lot-start confirm N` hand-off is Part A's end, not a question (lot 29).

        A blocked answer whose every question was that hand-off is the normal
        end of lot-start's Part A: it counts as `ok`, and the autopilot sends the
        confirmation itself. Any other question stays, and the run stops before
        the confirmation as before.
        """
        questions = answer.get("questions") or []
        kept = [question for question in questions if not CONFIRMATION.search(question)]
        if len(kept) == len(questions):
            return
        answer["questions"] = kept
        if answer.get("status") == "blocked" and not kept:
            answer["status"] = "ok"

    def check_start(self, answer):
        """The checks of lot-start, whether it ran whole or answered (lot 28)."""
        self.drop_confirmations(answer)
        self.expect_ok("start", answer)
        sync = subprocess.run(
            [sys.executable, SYNC_STATUS, self.root], capture_output=True, text=True
        )
        if sync.returncode != 0:
            raise Stop("start: sync-status.py exited %s" % sync.returncode, "start")
        branch = lotfile.current_branch(self.root) or ""
        match = lotfile.LOT_BRANCH.match(branch)
        lot = str(answer.get("lot", ""))
        if not LOT_ID.fullmatch(lot):
            raise Stop("start: `%s` is not a lot ID" % lot, "start")
        if self.expected_lot and lot != self.expected_lot:
            raise Stop("start: lot-start answered lot %s, not the required %s"
                       % (lot, self.expected_lot), "start")
        if not match or match.group(1) != lotfile.lot_base(lot):
            raise Stop("start: branch `%s` is not feat/lot-%s-*" % (branch, lot), "start")
        self.state.update(lot=lot, branch=branch, start_session=self.state.get("session_id"))

    def check_dev(self, answer):
        """The checks of the development, whether it ran whole or answered (lot 28)."""
        self.expect_ok("dev", answer)
        if git(self.root, "status", "--porcelain"):
            raise Stop("dev: the working tree is not clean", "dev")
        develop = lotfile.develop_ref(self.root) or "origin/develop"
        scoped = git(self.root, "log", "--format=%s", "%s..HEAD" % develop) or ""
        pattern = re.compile(r"^[a-z]+\(%s\)!?:" % re.escape(self.lot))
        if not any(pattern.match(subject) for subject in scoped.splitlines()):
            raise Stop("dev: no commit scoped to lot %s on the branch" % self.lot, "dev")
        self.validation_green("dev")

    def step_start(self):
        answer_text = self.take_answer("start")
        if answer_text is None:
            answer = self.session("start", prompt=start_prompt(self.expected_lot))
        else:
            answer = self.answered_session("start", answer_text)
        self.check_start(answer)

    def step_dev(self):
        answer_text = self.take_answer("dev")
        if answer_text is not None:
            answer = self.answered_session("dev", answer_text)
        else:
            # First pass: the lot-start session itself, which holds Part A. A resume
            # opens a new session, which rewrites the same lock and continues.
            session = self.state.pop("start_session", None)
            answer = self.session("dev", resume=session)
        self.check_dev(answer)

    def check_test_files(self, before):
        """Every lot-test session's own commits, before a fix commit joins the range."""
        allowed = TEST_FILES.get(self.params.get("Stack", ""), lambda path: True)
        friction = "docs/audits/lot-%s-friction.md" % self.lot
        outside = [
            path for path in changed_files(self.root, before)
            if not allowed(path) and path != friction
        ]
        if outside:
            raise Stop("test: lot-test committed non-test files: " + ", ".join(outside), "test")

    def step_test(self):
        while True:
            before = git(self.root, "rev-parse", "HEAD")
            answer = self.session("test")
            self.check_test_files(before)
            if answer.get("status") == "failed" and not self.state.get("fix_used"):
                self.state["fix_used"] = True
                try:
                    self.expect_ok("fix", self.session("fix"))
                except Stop as stop:
                    # "fix" is no step of SEQUENCE: settle the bug, resume lot-test.
                    raise Stop(stop.reason, "test") from None
                continue
            self.expect_ok("test", answer)
            break

    def gate_step(self, step, report, following):
        develop = lotfile.develop_ref(self.root) or "origin/develop"
        before = git(self.root, "rev-parse", "HEAD")
        lot_diff = set((git(self.root, "diff", "--name-only", "%s...%s" % (develop, before)) or "").splitlines())
        answer = self.session(step)
        # Checked whatever the status: a blocked step resumes at the following
        # one, so its commits are never checked again.
        lots = os.path.relpath(lotfile.lots_file(self.root, self.params) or "", self.root)
        allowed = {lots, "docs/memory.md"}
        outside = [
            path for path in changed_files(self.root, before)
            if path not in lot_diff and not path.startswith("docs/audits/") and path not in allowed
        ]
        if outside:
            raise Stop("%s: a commit touches files outside the lot's diff: %s"
                       % (step, ", ".join(outside)), step)
        if answer.get("status") in ("ok", "blocked") and not committed(self.root, report):
            # The step's own questions often say why the report is not committed;
            # questions are a block whatever the status says, as in expect_ok.
            questions = answer.get("questions") or []
            status = "blocked" if questions else answer.get("status")
            raise Stop("%s: %s is not committed" % (step, report), step,
                       status=status, questions=questions)
        # A finding that needs a decision: the owner settles it, then --resume
        # goes on with the following step.
        self.expect_ok(step, answer, blocked_resume=following)

    def step_review(self):
        self.gate_step("review", "docs/audits/lot-%s-review.md" % self.lot, "audit")

    def step_audit(self):
        self.gate_step("audit", "docs/audits/lot-%s.md" % self.lot, "ship")

    def step_ship(self):
        integration = "docs/audits/lot-0-integration.md"
        if self.params.get("Stack") == "frontend" and not os.path.isfile(
            os.path.join(self.root, integration)
        ):
            raise Stop("ship: frontend without %s; run integration-check by hand" % integration, "ship")
        self.expect_ok("ship", self.session("ship"))
        state = subprocess.run(
            ["gh", "pr", "view", self.state["branch"], "--json", "state", "--jq", ".state"],
            cwd=self.root, capture_output=True, text=True,
        ).stdout.strip()
        if state != "MERGED":
            raise Stop("ship: the pull request is `%s`, not MERGED" % (state or "unknown"), "ship")
        if os.path.exists(os.path.join(self.root, lotfile.LOCK_PATH)):
            raise Stop("ship: the lot lock .claude/current-lot is still present", "ship")

    def run(self, first):
        for step in SEQUENCE[SEQUENCE.index(first):]:
            self.state["step"] = step
            getattr(self, "step_" + step)()


# --------------------------------------------------------------------------
# summary and notification


def findings(root, lot):
    """(fixed, ignored, deferred) rows of the lot's review and audit reports."""
    counts = [0, 0, 0]
    for name in ("lot-%s-review.md" % lot, "lot-%s.md" % lot):
        try:
            with open(os.path.join(root, "docs", "audits", name), encoding="utf-8") as handle:
                rows = [line for line in handle if line.startswith("|")]
        except OSError:
            continue
        for row in rows:
            if "rejected: minor (autopilot)" in row:
                counts[1] += 1
            elif "fixed in" in row:
                counts[0] += 1
            elif re.search(r"deferred|open:", row):
                counts[2] += 1
    return counts


def answerable(status, resume):
    """Only a blocked lot-start or development stop accepts --answer (lot 28):
    anywhere else the owner settles the stop and --resume goes on."""
    return status == "blocked" and resume in ("start", "dev")


def answer_hint(stop):
    """The questions, numbered one per line, and the command that settles them
    (lot 28, laid out for the terminal in lot 29)."""
    answer = answerable(stop.status, stop.resume)
    if not stop.questions and not answer:
        return ""
    lines = ["", "Questions:" if stop.questions else "Questions: none"]
    for number, question in enumerate(stop.questions, 1):
        prefix = "  %d. " % number
        lines.append(prefix + question.strip().replace("\n", "\n" + " " * len(prefix)))
        lines.append("")
    if not stop.questions:
        lines.append("")
    lines.append('Answer with: autopilot.py --resume --answer "<your answers>"' if answer
                 else "Settle them, then: autopilot.py --resume")
    return "\n".join(lines)


def notify(message):
    try:
        subprocess.run(["notify-send", "claude-harness autopilot", message], timeout=10)
    except (OSError, subprocess.SubprocessError):
        print("autopilot: notify-send unavailable", file=sys.stderr)


def summary(root, lot, outcome):
    fixed, ignored, deferred = findings(root, lot) if lot else (0, 0, 0)
    return "%s. Findings: %d fixed, %d ignored, %d deferred." % (outcome, fixed, ignored, deferred)


# --------------------------------------------------------------------------


def refuse(message):
    print("autopilot: " + message, file=sys.stderr)
    return 2


def main(argv=None):
    parser = argparse.ArgumentParser(description="Run one lot from lot-start to merge.")
    parser.add_argument("lot", nargs="?", metavar="N", help="the lot lot-start must pick, named in its prompt")
    parser.add_argument("--resume", action="store_true", help="resume at the recorded step")
    parser.add_argument("--answer", metavar="TEXT",
                        help="the answers to a blocked lot-start or development (with --resume)")
    parser.add_argument("--dry-run", action="store_true", help="print the commands only")
    args = parser.parse_args(argv)

    if args.lot is not None and args.resume:
        return refuse("a lot and --resume are exclusive: a resumed run takes its lot from the state")
    if args.lot is not None and not LOT_ID.fullmatch(args.lot):
        return refuse("`%s` is not a lot ID" % args.lot)
    if args.answer is not None and not args.resume:
        return refuse("--answer needs --resume")
    if args.answer is not None and not args.answer.strip():
        return refuse("--answer needs the answers, not an empty text")
    if args.answer is not None and CONFIRMATION.fullmatch(args.answer.strip()):
        return refuse("--answer refuses a lot confirmation: the confirmation is sent after "
                      "the checks, never before them")

    root = lotfile.repo_root(os.getcwd())
    params = lotfile.gate_parameters(root) if root else None
    path = lotfile.lots_file(root, params) if params is not None else None
    if not params or not path or lotfile.status_table(lotfile.read_lines(path)) is None:
        return refuse("not a harnessed repository (no Gate parameters or no status table)")

    home = os.path.expanduser("~")
    try:
        with open(os.path.join(home, ".claude", "settings.json"), encoding="utf-8") as handle:
            base_env = json.load(handle).get("env") or {}
    except (OSError, ValueError):
        base_env = {}
    if base_env.get("ANTHROPIC_BASE_URL") or os.environ.get("ANTHROPIC_BASE_URL"):
        return refuse(
            "ANTHROPIC_BASE_URL is set: --settings cannot remove it, so the Claude steps "
            "would run elsewhere. Run `claude-profile claude` first."
        )

    if args.dry_run:
        long_values = {json.dumps(SCHEMA): "<schema>", SYSTEM_PROMPT: "<system prompt>"}
        print("<schema> = %s\n<system prompt> = %s\n" % (json.dumps(SCHEMA), SYSTEM_PROMPT))
        for step in SEQUENCE[:3] + ("fix",) + SEQUENCE[3:]:
            session = "<lot-start session>" if step == "dev" else None
            cmd = [long_values.get(arg, arg) for arg in command(step, home, session) + allowed_tools(params, home)]
            prompt = start_prompt(args.lot) if step == "start" else PROMPTS[step].format(lot="<N>")
            print("%-6s %-8s %s <<< %s" % (step, MODELS[step][0], " ".join(cmd), prompt))
        return 0

    state = read_state(root)
    if args.resume:
        if not state or not state.get("resume"):
            return refuse("nothing to resume: no stopped run in %s" % STATE_PATH)
        first = state["resume"]
        if args.answer is not None:
            if not answerable(state.get("status"), first):
                return refuse("--answer applies only to a stop blocked at start or dev, "
                              "not to a `%s` stop at %s" % (state.get("status"), first))
            if not state.get("session_id"):
                return refuse("--answer needs the stopped session in %s" % STATE_PATH)
    else:
        if state:
            return refuse("a stopped run exists (%s): use --resume" % STATE_PATH)
        state, first = {}, "start"
        if args.lot is not None:
            state["expected_lot"] = args.lot

    subprocess.run(["git", "-C", root, "fetch", "-q", "origin"])
    pilot = Pilot(root, params, home, state,
                  expected_lot=state.get("expected_lot"),
                  answer_step=first if args.answer is not None else None,
                  answer_text=args.answer)
    try:
        pilot.run(first)
    except Stop as stop:
        state.update(resume=stop.resume, reason=stop.reason, status=stop.status,
                     questions=stop.questions,
                     stopped=datetime.datetime.now().isoformat(timespec="seconds"))
        write_state(root, state)
        message = summary(root, state.get("lot"), "Lot %s stopped: %s" % (state.get("lot") or "?", stop.reason))
        message += answer_hint(stop)
        notify(message)
        print("autopilot: " + message)
        return 1
    try:
        os.remove(os.path.join(root, STATE_PATH))
    except OSError:
        pass
    message = summary(root, state.get("lot"), "Lot %s merged" % state.get("lot"))
    notify(message)
    print("autopilot: " + message)
    return 0


if __name__ == "__main__":
    sys.exit(main())
