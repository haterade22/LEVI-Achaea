---
topic: expiry-lines
confidence: mixed (tagged per line)
sources:
  - kb/afflictions/afflictions.json      # Default time + YOUR expiry line (AFFLICTION SHOW)
  - src_new/triggers/...                  # third-person lines already in triggers (CONFIRMED-in-code)
last_verified: 2026-10-11
---

# Timed afflictions: when they wear off the TARGET

45 afflictions wear off on their own after a fixed time ([database.md](database.md)). For the
target, we need to know when one goes. There are two ways to know it:

1. **The game's third-person line**, when it shows one ("Xarthus seems able to move more freely all
   of a sudden."). Exact. The trigger calls `ataxia_tarAffFaded(aff)`.
2. **The clock**: `ataxia_tarAffTimed(aff)` (`017_Affliction_Management.lua`) gives the affliction
   and removes it after the game's `Default time`. It is the backstop when the line is missed or
   has not been captured yet.

AFFLICTION SHOW only gives the line **you** see when it leaves **you**. The third-person version
only shows up when it happens to someone in front of you, so those lines come from combat logs.

## Third-person lines we catch (CONFIRMED-in-code)

| Affliction (our key) | Line | Trigger |
|---|---|---|
| hamstring | `^(\w+) seems able to move more freely all of a sudden.$` | striking/001 |
| vinewreathed | `^The vines flailing about (\w+)'s form recede.$` | 696 (it removed `vinewreathe` until v4.7.405) |
| waterbond | `^The tendrils of water that bound (\w+) splash to the ground as the power sustaining them fades\.$` | staffcast/001, other_things_fading/001 (that one removed `bonds` until v4.7.405) |
| lightbind (a flag, not tracked) | `^The golden chains of light which bind (\w+) dissipate.$` | 290 |
| ensorcelled | `^You sense that your ensorcelment of (\w+) has broken.$` (first person, about your own ensorcel) | misc/004 (it was ignored after the first cast until v4.7.405) |

## On the clock only (no third-person line captured yet)

| Our key | Duration | What you see when it leaves YOU (from AFFLICTION SHOW) |
|---|---|---|
| airfist | 15s | "Clarity of form returns as the wind plaguing your mind dies down." |
| voidfist | 15s | "The empty grasp of the void retreats, and you breathe more easily." |
| dazzle | 60s | "The affects of the dazzling wear off." |
| hellsight | 120s | "The hellish visions that haunted you recede into the darkness from whence they came." |
| muddled | 12s | (none given) |
| scalded | 20s | (none given) |

The first-person line is a strong hint at the third-person one, but it is not that line. **Wanted
from combat logs:** the third-person lines for hamstring's siblings above, and for the timed
afflictions we do not track on targets yet: pacified (20s), trueblind (7s), snared (20s), timeflux
(60s), stridulating (15s), lightbind (22s), vitrified (45s), corruption (45s), silver (180s).
