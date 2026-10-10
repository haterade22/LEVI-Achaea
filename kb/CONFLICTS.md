# Open conflicts

Disagreements between sources, or between a source and the code. Each one has a way to
settle it. When it is settled, move it to **Resolved** with the answer and the change made.

| # | Topic | Says A | Says B | Impact | How to settle |
|---|---|---|---|---|---|
| 1 | Hypochondria cure | HELP 13.7.2: **kelp/aurum** | Code `curingTable` (reconciled to live WHATCURES, v4.7.372): **lobelia** | Target tracker. A kelp eat would never clear it, and a lobelia eat would. | `WHATCURES HYPOCHONDRIA` in-game. Paste the output. |
| 2 | Disfigurement vs disloyalty | HELP 13.7.2 lists **Disfigurement** (smoke valerian) | Code tracks **`disloyalty`** in the smoke table, has no `disfigurement` key and no SSC priority for it | Probably a rename (monkshood gives disloyalty now) | `WHATCURES DISLOYALTY` / `AFFLICTION SHOW DISFIGUREMENT` |
| 3 | Grove Cure | HELP: Druid and Sylvan Grove Cure, "hindered by nothing" | No trigger | An unblockable cure that V3 never sees | Capture its fire line, then add a trigger |
| 4 | Trigger-wrap lint blind to folded patterns | `tools/check_wrap.py` reads only one-line plain or quoted `- pattern:` values | 131 trigger files in our package carry a pattern wider than 118 columns written as a FOLDED plain scalar (e.g. the old Slough line). Each may never match on a wrapped server. | Patterns that silently never fire | Separate project: teach the lint folded scalars, allowlist, then shorten each pattern to an early fragment |

## Resolved

| Date | Topic | Answer | Change |
|---|---|---|---|
| 2026-10-10 | Magi Harmony passive never tracked | The line is Magi's (HELP + guide) | v4.7.395: new trigger `passive_active/029_Harmony_(Magi).lua`, pattern removed from 025, `passive_harmony` cooldown |
| 2026-10-10 | Paladin Healing passive never tracked | Paladins have the Rite of Healing (HELP + guide) | v4.7.395: 024 accepts Paladin for the "gentle glow" line only |
| 2026-10-10 | Dragonheal blocker | Blocked by weariness AND recklessness together; 1 cure when prone | v4.7.395: 005 removes nothing outright; 3 random cures, 1 if prone |
| 2026-10-10 | Fire Lord Slough | Blocked by prone (HELP). The ~160-column pattern could not survive the wrap | v4.7.395: 016 proves not-prone, and matches an early fragment |
| 2026-10-10 | Sleeplock defence names (guide said "Gypsum/Kola") | HELP 13.7.1: gypsum = insomnia, kola/quartz = instant wake | Corrected in `kb/afflictions/locks.md` |
| 2026-10-10 | Cures in CLAUDE.md venom table | HELP 13.7.2: anorexia = apply epidermal; slickness = bloodroot / smoke valerian; blindness = apply epidermal | Fixed rows for slike, gecko, oleander, colocasia, monkshood in CLAUDE.md |
| 2026-10-10 | "Calcium" as the ash mineral | HELP 13.7.1: prickly ash = **stannum** (calcite is the pear mineral) | Fixed `.claude/databases/afflictions.yaml` and `venoms.yaml` |
| 2026-10-10 | Disfigurement listed under ash | HELP 13.7.2: smoke valerian/realgar | Fixed both YAML databases (see #2 for the naming question) |
