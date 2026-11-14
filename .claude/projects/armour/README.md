# Armour and paragon management: the reference that was in CLAUDE.md

> Moved verbatim from `CLAUDE.md` on 2026-11-13 (`docs/adrs/002-knowledge-delivery-tiers.md`). Until then every session loaded this text. It is not yet reconciled with the other documents of this subject: where they disagree, check the code or the game source, then correct the wrong one.

### Armour & Paragon Management (`ataxia.armour`)
Configurable profile system for armour paragon slots, traits, and morphing. Auto-swaps on basher enable/disable.

**Key Files:**
| File | Purpose |
|------|---------|
| `src_new/scripts/.../gear_system/002_Armour_Paragons.lua` | Main system (`ataxia.armour` namespace) |
| `src_new/aliases/.../gear_system/002_Armour_Paragons.lua` | `armour` alias dispatcher |
| `src_new/triggers/.../gear_system/001_Paragon_Inventory.lua` | Auto-detect paragons from `ii paragon` |
| `src_new/triggers/.../gear_system/002_Armour_Probe.lua` | Embrasure lines of `probe armour` (incl. `N: Empty.`) -> `onProbeLine` |
| `src_new/triggers/.../gear_system/003_Armour_Probe_Header.lua` | `This armour has N embrasures.` -> `onProbeHeader` (opens the snapshot, v4.7.323) |

**Profile Structure:**
```lua
ataxia.armour.config.profiles["bash"] = {
  slots = {"icosagon", "serendipitous", "crucious"},  -- TYPE names (v4.7.323); ids still accepted
  traits = {"quick-witted", "fully fit", "marksman", ...},
  armourType = nil,  -- nil/string/"auto"
}
```

**Auto-swap:** `armour auto on` + `armour bash <profile>` + `armour pvp <profile>` — hooks into `"basher enabled"` / `"basher disabled"` events.

**Morph:** Sends `MORPHARMOUR armour INTO <type>`. Tracks cooldown (10min). `armourType = "auto"` resolves via `gmcp.Char.Status.class` → `classArmourType` lookup. Auto-detects current armour type from class on init if unknown.

**Paragons are NAME-addressable -- but only by a ONE-WORD name (game change 2026-08-03, v4.7.205; the limit found live in v4.7.326).** `INSERT CRUCIOUS INTO FULLPLATE` works without knowing the ID ("a crucious paragon"), but `insert icosagon` / `insert metalliferous` are refused -- "That is not a valid paragon." -- for "an auspicious icosagon paragon" / "a resonate metalliferous paragon". So the SWAP resolves a type word to an id before inserting (below); a profile still NAMES types. It works without knowing the ID, so a profile slot may hold either a registered id (`paragon514466`) or a bare type keyword (`crucious`). `ataxia.armour.paragonName` resolves in that order -- registered id (proven to exist on this character) -> known type keyword -> raw string -- and `isBorrowedRedundant` inherits it, so name-slotted profiles behave exactly like id-slotted ones. **`armour scan` is now a convenience, not a prerequisite:** Borrowed Power used to be entirely inert on a character that had never scanned, because it could not name a replacement paragon; it now falls back to the type keyword. Not explored: the announcement's example targets the armour ITEM (`INTO FULLPLATE`) with no embrasure number, while the package still sends `insert <ref> into armour embrasure <n>` -- proven to work, and the announcement concerns the identifier rather than the target syntax.

**Paragon Lookup:** `PARAGON_TYPES` table maps 24 paragon type keywords to clean display names with effects. `registerParagon()` resolves raw game names (e.g., "an aeneaous paragon") to display names (e.g., "aeneaous (absorption)"). Stale names re-resolved on load.

**THE SWAP ASKS BEFORE IT ACTS (v4.7.323, user-directed).** Every `armour <profile>` sends `ii paragon` + `probe armour` (`ataxia.armour.refresh`), and plans from the answers with the pure `ataxia.armour.planSwap(slots, cur, known, inventory, capacity)`. The probe is a SNAPSHOT: the header opens it, embrasure lines fill it, it commits `PROBE_SETTLE` later, so an unlisted or `N: Empty.` embrasure reads EMPTY -- and only probes the module sent are read (`state.probing`), so probing another armour cannot corrupt the worn one's state. Plan rules: a slot already holding the right TYPE (`paragonKey`) is kept; a want we cannot supply (not in the inventory, not released by another embrasure this swap -- resolved to a fixed point) is reported `NEED` and its embrasure is NOT TOUCHED, never emptied; a profile is a list of TYPES, but **the insert names an ID** -- the one `ii paragon` showed for the paragon of that type we hold (v4.7.326: v4.7.323 sent the type word, and `insert icosagon` / `insert metalliferous` were refused, "That is not a valid paragon.", with both in the inventory -- the type word is the item's keyword only for one-word names like "a crucious paragon"; the pry had gone out, so embrasures were left EMPTY); with no inventory answer, the profile's own id, else `idForType`, else the bare word; all pries before all inserts (the old loop interleaved them, so a paragon could not move between embrasures); slots past the armour's capacity are skipped. `planReport` prints one line per embrasure, and `verifySwap` probes again `VERIFY_DELAY` (1.5s) later -- pry/insert answer instantly (v4.7.211 log) -- and reports `Verified` or the embrasure that did not take. **An unanswered refresh means NO swap (v4.7.326 review):** no pries, no inserts, traits only, and an echo -- a swap planned from an old picture pries blind, and a pry whose insert is refused is how v4.7.323 emptied embrasures (this replaced v4.7.323's "plan from the earlier picture" rule). `idForType(k, busy)` passes over ids still in an embrasure the swap KEEPS and picks the lowest by NUMBER. `armour probe [profile]` is the dry run; `armour scan` uses the same refresh, so it registers paragons IN the armour, which `ii paragon` never lists. Probed paragons keep the game's effect text (`config.paragonEffects`). Tests load the real script (`test_armour_swap_diff.lua`); the old test copied the planning logic, and a copy cannot catch a regression.

**Persistence:** Self-contained `table.save/load` to `getMudletHomeDir()/armourconfig` with `_ataxia_backup` fallback.

**Commands:** `armour`, `armour <name>`, `armour add/remove/set/show/auto/bash/pvp/morph/scan/probe/paragons/types/help`
