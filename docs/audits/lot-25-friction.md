# Lot 25 — Skill friction

## lot-review
- `lot-review / 2` — the forked `code-review` agent fed guard probes as one-line
  `$'…'` strings with escaped quotes; `shlex` cannot lex ANSI-C quoting, so the
  git guard asked the owner to confirm a command that only piped text into the
  guard. Cost: one owner prompt, approved after an explanation. Writing the
  probes to a script in the scratchpad avoids it.
- `lot-review / 2` — the agent classed the pipe-continued heredoc (finding #1)
  as already on `develop` and left it unfixed; replaying both guards showed it
  was a regression of the lot. Cost: one comparison run of the two guards.
