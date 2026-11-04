---
topic: strike-feet-removed-2026-11-04
confidence: mixed (tagged per claim)
sources:
  - kb/raw/players/strike-feet-2026-11-04.txt
  - kb/raw/wiki/Striking.wiki
code:
  - src_new/scripts/levi_ataxia/levi/levi_scripts/blademaster/001_Logic.lua
  - src_new/scripts/levi_ataxia/levi/levi_scripts/blademaster/005_CC_BM_Ice.lua
  - src_new/triggers/levi_ataxia/for_levi/leviticus/264_Not_Mounted.lua
  - src_new/triggers/levi_ataxia/for_levi/leviticus/265_Mounted.lua
last_verified: 2026-11-04
---

# STRIKE FEET removed

Blademaster no longer has STRIKE FEET. STRIKE KNEES now does both jobs: it prones a target on foot
and pulls a mounted target from the mount. In a fight, one strike covers both states, but a mounted
target does not go prone on that strike, so it still takes a second KNEES to put them down.

## Facts

### Knees (Striking)
- **Syntax:** `STRIKE <target> KNEES`. `STRIKE <target> FEET` no longer exists.
- **Cost:** 3.25 seconds of balance  ·  **Works on:** adventurers (READ, the wiki)
- **Effect:** a target on foot falls. A target "sitting upon a steed or similar" is yanked from the mount instead (READ, `kb/raw/wiki/Striking.wiki`:91).
- **Line seen:** none captured. See Conflicts.
- **Confidence:** the removal is the user's report (`kb/raw/players/strike-feet-2026-11-04.txt`), with no AB capture or game post on file.
- **Code:**
  - `blademaster/005_CC_BM_Ice.lua` (live): sends `knees` for the dismount (:881, :1442) and does not send `feet`. It needed no change.
  - `blademaster/001_Logic.lua` (switched off): the three `tstrike = "feet"` sites became `knees`. Its readers `002_Attack` and `003_BrokenStar` are also switched off, so nothing changes in play.
- **Notes:**
  - The game change may be older than the report. The wiki capture of 2026-10-10 already has this Knees text and lists no Feet.
  - The legacy code picked `feet` only with `tmounted == true`, so the dismount as Feet's job is INFERRED from that code.
  - `.claude/classes/blademaster.md` listed `feet: prone` in two tables. Both rows are gone.

## Conflicts

Open: [CONFLICTS #59](../CONFLICTS.md). No log holds the lines that set and clear `tmounted`, so we do
not know what KNEES prints on a mounted target today.
