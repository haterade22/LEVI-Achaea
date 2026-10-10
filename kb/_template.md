---
topic: <kebab-case-topic>
confidence: <CONFIRMED (live) | CONFIRMED (HELP) | CONFIRMED-in-code | guide | ASSUMED>   # or "mixed (tagged per claim)"
sources:
  - kb/raw/<folder>/<file>.txt
code:                       # files that depend on these facts (omit if none)
  - src_new/...
last_verified: YYYY-MM-DD
---

# <Title>

One paragraph: what this is and why it matters in a fight.

## Facts

For an ability (AB output), one block each:

### <Ability> (<Skill>, AB <number>)
- **Syntax:** `<COMMAND> <target>`
- **Cost:** <balance/eq seconds, mana, kai, rage...>  ·  **Cooldown:** <...>
- **Works on:** <adventurers / denizens / room>
- **Effect:** <what it does, quoting the source where wording matters>
- **Gives / cures afflictions:** <list, linked to afflictions/catalog.md>
- **Blocked by:** <affliction or state>
- **Line seen:** "<exact game line>" (ours / opponent's)
- **Confidence:** <tag>  ·  **Source:** kb/raw/...
- **Code:** <file:line that uses it, and whether it agrees>
- **Notes:** <the WHY: interactions, pitfalls, what this means for offense/defence>

## Conflicts

Anything that disagrees with another source or with the code. Also add it to kb/CONFLICTS.md.
