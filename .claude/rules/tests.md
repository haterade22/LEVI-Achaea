---
paths:
  - "src_new/tests/**"
  - "tools/test_*.py"
---

# Tests (path rule)

CANARY: `tests-rule-loaded-2026-11-13`. This file is the first path-scoped rule in this repository.
If you can read this line without having opened `.claude/rules/tests.md` yourself, the rule loaded
when you touched a test file: say so, with the marker, when the user asks whether path rules load.
The result belongs in `docs/reference/harness-facts.md`, section 2.

The test conventions with their incidents are in `CONTRIBUTING.md` ("Tests"). The rules below add to
them; they are stated nowhere else.

- **The two-edit test.** Judge each test by two edits. Break the behaviour: the test must fail.
  Change only the internals, with the behaviour the same: the test must stay green. A test that
  fails on the second edit pins the code's text, not what the code does.
- **An expected value is a literal.** Write the number or the string that must come out. Never
  compute it with the code under test, or with a copy of its formula: such a test agrees with any
  defect.
- **A game line in a test is real.** Copy it verbatim from `kb/raw/` or from a filed fight log and
  give the path in a comment. If you change it to make a variant, label it "modelled on <path>".
  An invented line proves only that the pattern matches what its author imagined.
- **Three results.** A run has a pass, a failure or NOT RUN (exit 2). No `lupa`, zero test files
  or an empty walk is NOT RUN. Never write a skip that lets the suite say OK.

Run:

```bash
/c/Python314/python tools/run_lua_tests.py                         # the Lua suite (lupa, Lua 5.1)
/c/Python314/python tools/run_lua_tests.py src_new/tests/test_x.lua
/c/Python314/python -B tools/test_x.py                             # one Python test file
/c/Python314/python -B tools/ci_local.py                           # every CI validate step
```
