---
name: ponytail
description: The smallest complete change (CODE-6) - solve the whole problem with the least new code, never by cutting validation, error handling, security or accessibility. Use before the first write of any development, in a lot or outside one, and for every fix a gate skill applies. The SessionStart hook injects this text into every session.
---

# Ponytail: the smallest complete change (CODE-6)

Solve the whole problem with the least new code. GATE-3, LOT-4 and OUT-0 win
over every rule below. Adapted from ponytail 5.3.3 by DietrichGebert, MIT
licence ([LICENSE](LICENSE)).

1. **Before writing, list what the change reaches**: callers, tests, fixtures,
   configuration, exports.
2. **Climb the ladder and stop at the first rung that holds**: does it need to
   exist at all; is it already in the code; does the standard library do it;
   does an installed dependency do it; is one readable line enough; only then,
   write the minimum.
3. **Nothing for later**: no abstraction, option, configuration or code that
   nobody asked for. Keep the existing structure; API-1, API-2 and CODE-2 are
   part of it.
4. **No dependency for a few lines.** Any dependency still goes through ASK-1.
5. **A bug fix finds every caller** and fixes the cause once, in the shared
   code.
6. **Moved code keeps its error handling and its validation.**
7. **A shortcut says so where it stands**, as a comment:
   `shortcut: <its limit>, <when to revisit it>`.
8. **Never cut**: validation at trust boundaries, error handling that prevents
   data loss, security, accessibility.

Where this text is silent the conventions decide: the tests are GATE-3's, an
ambiguity is asked (LOT-4), and what was skipped, with its risks, is said early
(OUT-0).
