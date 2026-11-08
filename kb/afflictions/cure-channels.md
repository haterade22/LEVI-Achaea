---
topic: cure-channels
confidence: CONFIRMED unless tagged
sources:
  - kb/raw/help/13.7.2_afflictions-and-what-cures-them.txt
  - kb/raw/help/13.7.1_curatives-and-what-they-cure.txt
  - kb/raw/guides/lock-types.txt
last_verified: 2026-10-10
---

# Cure channels

A **channel** is a way of curing that has its own balance. Two cures on the same balance
compete with each other, and an affliction that **blocks** a channel shuts off everything
cured through it. See [README.md](README.md) for the overall model.

| Channel | Command | Curatives | Blocked by | What it cures (HELP 13.7.2) |
|---|---|---|---|---|
| **Eat** | `EAT <herb>` | kelp/aurum, ginseng/ferrum, goldenseal/plumbum, lobelia/argentum, prickly ash/stannum, bellwort/cuprum, bloodroot/magnesium, ginger/antimony. **Pear/calcite is eaten but spends the LUNGS** (below) | **anorexia** | Most afflictions: one per eat, from that herb's group ([catalog](catalog.md)) |
| **Apply** | `APPLY <salve> [to <part>]` | epidermal, mending, restoration, caloric | **slickness** | anorexia, blindness, deafness, stuttering (epidermal); crippled limbs, ablaze (mending); damaged/mangled limbs, concussion, internal trauma (restoration); freezing (caloric) |
| **Smoke** | `SMOKE <pipe>` | elm/cinnabar, valerian/realgar | **asthma** | aeon, deadening (elm); disloyalty (old name disfigurement), hellsight, mana leech, slickness (valerian) |
| **Sip** | `SIP <elixir>` | health, mana, immunity, ... | (none listed) | voyria (immunity) |
| **Focus** | `FOCUS` | (none) | **impatience** | anorexia, or a mental affliction (lock guide) |
| **Tree** | `TOUCH TREE` | tree tattoo | **paralysis** | one random affliction |
| **Writhe** | `WRITHE` | (none) | (none listed) | entangled, transfixed, webbed |
| **Clot** | `CLOT` | (none) | (none listed) | bleeding (SSC: `CURING USECLOT`, `CURING CLOTAT <amount>`) |
| **Compose** | `COMPOSE` | (none) | (none listed) | fear |
| **Scrub** | `SCRUB` | (none) | must be at a water location | stinky |
| **Swim** | (move into deep water) | (none) | needs water | ablaze ("may also be resolved by finding an available source of water to swim in") |

## Shared balances (CONFIRMED in code, not in HELP)

- **Pear and calcite spend the lungs, not the eat balance (CONFIRMED live, 2026-11-01, n=29).** The command is `EAT`, and
  the recovery is the smoke line. In 29 of 29 pear or calcite eats, a `Your lungs have recovered enough...` line
  followed with NO smoke in between, and the lungs recover only after being spent (`s98kPGv6` rows 207-215,
  `3ys7NuHA`). `3ys7NuHA` holds 25 calcite eats and 0 `You may eat another plant or mineral.` lines. So against an Air
  Lord, the pressure cure competes with valerian and elm for the same 1.48 s clock.
- **Anorexia may also block sips (INFERRED).** Its line reads "The idea of eating or drinking is repulsive to you."
  (`2026-11-01_..._LcJC-rJ5`:673). No sip was sent under anorexia in the fights checked. The table above lists no blocker.
- **Moss and potash have their own clock, not the eat's.** Potash, 4 of 4 (MEASURED, 2026-11-07): Saibel ate potash
  0.001 s after a magnesium and 0.961 s after an aurum, and a herb 0.39-0.73 s after a potash, while her herb
  eat-to-eat never fell under 1.506 s (n=47). The rows are in `raw/logs/ours/2026-11-07_164635_Saibel.log`
  (415-418, 638-688, 910-916, 1419-1423), from our seat. Moss to its own recovery line is 5.91-5.94 s
  ([foundations](../mechanics/foundations.md), Clocks). So healing by moss does not take a herb's eat
  ([CONFLICTS](../CONFLICTS.md), Resolved 2026-11-07, was #11). The PvE bash curing profile
  (`ataxia/ataxia/008_Bash_Curing_Profile.lua`) gave the shared eat as one of its reasons; its other reason, the
  salve below, stands.
- **Salves are shared between limb mending/restoration and the traumas** (concussion,
  mildtrauma, serioustrauma). The same profile parks those at 20 so limbs come first while bashing.
- **The four fractures are NOT salve cures** (corrected 2026-10-23, v4.7.449). `crackedribs`,
  `skullfractures`, `wristfractures` and `torntendons` are cured by `APPLY HEALTH TO <spot>`, the
  health elixir (CONFIRMED, `AFFLICTION SHOW`, [skullfractures](../raw/live/affliction_show/skullfractures.txt)).
  - One application removes ONE stack: "You take some elixir from a stone vial and rub it into
    your head." / "The pain in your head lessens somewhat." took `skullfractures (3)` to `(2)`
    (CONFIRMED, user log 2026-10-23).
  - SSC applies health for them only above 70% health ("Will cure fractures above 70%", CURING
    STATUS; `CURING HEALTHAFFSABOVE`). See [server-side-curing](../curing/server-side-curing.md).
  - `skullfractures` lengthens the elixir recovery and gives periodic nausea; `crackedribs` cuts
    elixir healing and gives periodic sensitivity. A big stack therefore cures slowly, and the
    nausea costs a ferrum every few seconds (CONFIRMED, user log 2026-10-23).
  - They most likely share the elixir balance with health sips (UNCONFIRMED).
  - They are STACK afflictions: `ataxia.afflictions` holds a number. With Death's Demise the
    Mnemosyne sweep waits in the cleared room until they are cured (`mnemosyne/008`
    `M._fractureHold`, 20 s stall release).
- **A herb and its mineral are interchangeable** and use the same balance. SSC's
  `CURING FALLBACK ON` uses the other when you run out of one.

## Two cures for one affliction

- **Slickness** can be eaten (bloodroot/magnesium) **or** smoked (valerian/realgar). The smoke
  needs no anorexia-free window, but asthma blocks it. Locking slickness therefore takes
  both anorexia and asthma, which is why softlock has three afflictions and not two.
- **Anorexia** is cured by applying epidermal **or** by FOCUS. Slickness blocks the salve and
  impatience blocks focus. Truelock adds impatience for exactly this reason.

## Where the code models this

| Concept | Code |
|---|---|
| Target herb groups (tracking) | `curingTable` in `curing/002_Wide_Groups.lua` (live), with `curingTableV3` as fallback (`affliction_tracking_core/007`) |
| Target smoke/salve cures | `smokeCureTableV3`, `salveCureTableV3` (`affliction_tracking_core/007`). The application line names the SPOT, not the salve, so `salveCureTableV3` is keyed by spot (body, skin, head, limbs) and lists everything a salve there cures, in our priority order; one application branches to ONE cure (v4.7.404). Triggers 391 (body/skin), 392 (head), 393 (body restoration timing), 395 (limbs), 153 (health elixir on fractures) |
| Our cure order | `ataxia_defaultCuringPrios()` (`ataxia/001`), bash delta in `ataxia/008` |
| Lock checks | `.claude/databases/locks.yaml`, `.claude/classes/lock_types.md` |

## How the target tracker reads a cure line (2026-11-08)

Code, covered by tests and a replay of FL ([foundations](../mechanics/foundations.md) keeps the log keys). None of it has been run in Mudlet.
Files: `ataxia/affliction_tracking_core/007_Branching_State_Tracker.lua`, `008_V3_Integration.lua`.

- **A cure line is a fact.** One candidate went, and the branch weights say which is likely. When the confirm window closes the split stays (`007`:1488). The windows (herb 1.3 s, smoke 2.0, salve 2.5, `007`:1414-1416) used to unfold the cure, as if nothing had been cured. Saibel's shortest eat-to-eat is 1.506 s (n=47), so most branched eats had nothing to close them. A replay of FL unfolded 11 times before and none after.
- **A proof drops the branches it rules out.** A tree proves no paralysis (`008`:338), a focus no impatience (`008`:396), an apply no slickness (triggers 391, 392, 393, 395, 396, `herbs/013`), a smoke no asthma (`onSmokeCureV3`, `007`:499). `proveAffAbsentV3` (`007`:758) must run BEFORE any erase: an erase only strips the affliction from each branch, and a ruled-out branch keeps its weight. While the action's clock runs the tracker calls the line an illusion, and it proves nothing. A focus with impatience certain in every branch is an illusion too (`008`:391).
- **A sileris berry or a quicksilver droplet is not on salve balance.** `herbs/013` proves no slickness and leaves the salve clock alone. A salve line and one of these came 0.143 s and 0.168 s apart: `raw/logs/ours/2026-11-03_081532_Tabethys.log`:1435/1455 and `raw/logs/ours/2026-10-27_112717_Tabethys.log`:1328/1351. MEASURED, n=2.
- **One application is charged once.** 391, 392 and 395 run before 396 and start the salve clock, so 396 skips an application charged under 0.1 s ago (`salveChargedAtV3`, `007`:701, read at `008`:142).
- **Only what was held is reported.** A tree, a passive or a bloodroot eat reports a cure only for an affliction in `tAffs` or at 30% or more before it (`curing/002_Wide_Groups.lua`:222, `008`:497, `herbs/005`:77). A smaller guess leaves the tracker without a report.
- **A line that names the cure replaces the random one.** `ataxia_randomCureV3` (`ataxia/ataxia/001_Miscellaneous_Aff_Tracking_Methods.lua`:384) wraps the random cure in `herbs/002`, `003`, `007`, `008`, 390 and 398. `ataxia_knownCureV3` (:401) puts the branches back, applies what the action proved and takes out the named affliction. It acts only for the same person and kind within 0.5 s (:343), with the branches unchanged since. Callers: `third-person_removes/001-006`, `herbs/004`, 399. A wrap's mercury erase must come before the wrap (`herbs/002`).
- **The random pools.** Tree: 77 (`008`:278). Passive: the same 77, voyria first (`008`:452); it was 53. [CONFLICTS](../CONFLICTS.md) #65 is still open on what the game's pool is.
- **Branches.** The cap is 300 (`007`:78, was 50). When every branch falls under the 1% floor they are kept, and the cap cuts them only past 300 (`pruneStatesV3`, `007`:914). A three-cure passive over ten afflictions used to empty the tracker. Past 300 branches the cut is still arbitrary among equal weights.
- **Certain means every branch.** Ask `isAffCertainV3` (`007`:833). Never compare a probability with `>= 1.0`: the sum can read a few ulps under 1.
