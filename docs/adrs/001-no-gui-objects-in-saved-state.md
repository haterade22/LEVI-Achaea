# ADR-001: GUI/runtime objects must not live in serialized state

**Status:** Accepted
**Date:** 2026-07-11
**Author:** haterade22

## Context

The ataxia settings loader (`ataxia/001_Save_Load_Settings.lua`) persists the whole `ataxia` global to
disk with `table.save(ataxia)` and reloads it with `table.load` + a recursive `mergeLoad`/`deepMerge`.
Several subsystems store **live Geyser/Adjustable GUI objects** *inside* that saved namespace —
`ataxia.mnemosyne.map.window`/`.container`/`.cells`, `ataxia.data.hunter.window`, the vital bars
(`ataxia.bars`), and chat. Mudlet `db` proxy objects (e.g. `exp_db`) can also end up referenced there.

These objects are runtime-only: they carry methods (behind metatables) and dense **circular references**
(container ↔ windowList ↔ child ↔ parent). Persisting them caused a cascade of failures discovered over
2026-07-09/10 (see CHANGELOG v4.7.50 → v4.7.53):

- The circular refs made the un-guarded `deepMerge` recurse forever → **stack overflow**, aborting the
  loader before it assigned `ataxiaNDB` → `qwp` reported "Name database not currently loaded".
- Once the loader was cycle-guarded and completed, it **merged the stale serialized snapshot back into
  the live Geyser object**, polluting a container's `windowList` with methodless plain-table children →
  `gmcp.Room` → `container:hide()/show()` crashes (`GeyserContainer.lua:139/167`).
- Detecting these objects by probing `t.hide`/`t.show` fired a Mudlet `db` proxy's `__index` →
  `DB.lua:1669: attempt to access sheet 'hide'`, spamming on every save and garbling GMCP.

## Decision

**Runtime/GUI objects are never serialized.** Until they are physically moved out of the saved namespace,
the loader/saver actively strip them:

- **Save** — `sanitizeForSave(ataxia)` produces a data-only copy before `table.save`, dropping any table
  that is a runtime object.
- **Load** — `stripGui(loaded)` recursively removes serialized GUI snapshots from the loaded data before
  the merge, and `deepMerge` refuses to recurse into a live runtime object.
- **Detection uses `getmetatable(t) ~= nil` and `rawget(t, field)` ONLY** — never index arbitrary fields
  (`.hide`/`.show`), because `__index` on `db`/Geyser proxies has side effects.

The **preferred long-term fix** (tracked TODO) is to stop storing GUI objects under `ataxia` at all — keep
them in a non-persisted namespace (e.g. `ataxiagui.*` or a plain runtime table) so no stripping is needed.

## Consequences

### Positive
- The loader can never stack-overflow or corrupt live widgets from a dirty save; a corrupt/locked file
  degrades gracefully (per-sub-load `pcall`).
- Save files shrink and stop accumulating serialized widget graphs.
- A reusable, side-effect-free rule for "is this a runtime object": `getmetatable`/`rawget`.

### Negative
- The strippers are **heuristic** (`getmetatable` + a GUI-field allowlist). A genuine data table that
  carries a metatable would be dropped from the save; a novel GUI object type without the known fields
  could slip through `stripGui`. This is mitigated but not eliminated until GUI objects leave `ataxia`.
- Two extra passes (`stripGui` on load, `sanitizeForSave` on save) — negligible cost (load/save are rare).

## Alternatives Considered

### Store GUI objects in `ataxia` but blocklist specific keys from save/load
- **Pros:** simple, explicit.
- **Cons:** fragile — every new window must remember to add its key; misses nested/wholesale cases.
- **Why rejected:** the wholesale-subtree bug (`ataxia.bars = {hp={window=…}}`) showed key-level guards
  are easy to get wrong; a structural rule (metatable/GUI-field) generalizes.

### Move all GUI objects out of `ataxia` now
- **Pros:** removes the root cause; no stripping needed.
- **Cons:** touches many subsystems (mnemosyne map, hunter window, bars, chat) and their build/rebuild
  paths; risky to do under an active incident.
- **Why deferred:** kept as the tracked long-term fix; the strippers make the system correct in the
  meantime.

## References

- CHANGELOG entries 2026-07-09 → 2026-07-10 (v4.7.50 loader stack overflow → v4.7.53 db-proxy fix)
- `src_new/scripts/levi_ataxia/levi/ataxia/001_Save_Load_Settings.lua` (`mergeLoad`/`deepMerge`/`stripGui`/`sanitizeForSave`)
- `src_new/tests/test_settings.lua` (cyclic-save, live-object, wholesale-subtree, save-sanitize cases)
- Memory: `bug-patterns.md` (Save/Load Ordering; "never index tables you don't own"), `gui-windows.md`, `mnemosyne.md`
