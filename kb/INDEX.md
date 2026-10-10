# KB Index

One line per page. Kept up to date by `/kb-ingest`.

## Afflictions (core)
- [afflictions/README.md](afflictions/README.md): how afflictions and cures work from both sides; start here
- [afflictions/database.md](afflictions/database.md): the game's own record of all 125 afflictions (AFFLICTION SHOW): cures, durations, the lines you see when hit and cured, flags such as NoRandomCure (GENERATED; `afflictions.json` is the machine copy)
- [afflictions/catalog.md](afflictions/catalog.md): every affliction's cure, joined to our tracker and SSC priorities (GENERATED)
- [afflictions/cure-channels.md](afflictions/cure-channels.md): cure balances, what blocks each one, shared balances
- [afflictions/class-cures.md](afflictions/class-cures.md): each class's active and passive cures, blockers, fire lines, our triggers
- [afflictions/locks.md](afflictions/locks.md): lock definitions and how each is escaped
- [afflictions/limb-damage.md](afflictions/limb-damage.md): body part states, damage vs break, parrying

## Curing
- [curing/curatives.md](curing/curatives.md): every herb/mineral pair, elixir and salve
- [curing/server-side-curing.md](curing/server-side-curing.md): SSC commands, how our code drives them, and your live curing state

## Defences
- [defences/README.md](defences/README.md): the game's 279 defence names, and our names that do not match

## Mechanics
- [mechanics/balance-and-queueing.md](mechanics/balance-and-queueing.md): balance vs equilibrium, server queue commands, types and the 10-command limit

## Meta
- [README.md](README.md): how the KB works and how to add material
- [CONFLICTS.md](CONFLICTS.md): open disagreements to settle in-game or in code
- [_template.md](_template.md): shape of a new entry

## Raw sources
| File | What | Ingested |
|---|---|---|
| raw/help/13.7.2_afflictions-and-what-cures-them.txt | HELP 13.7.2 affliction -> cure table | 2026-10-10 |
| raw/help/13.7.1_curatives-and-what-they-cure.txt | HELP 13.7.1 curatives | 2026-10-10 |
| raw/help/13.7.8_server-side-curing.txt | HELP 13.7.8 SSC commands | 2026-10-10 |
| raw/help/conditional-afflictions-for-the-achaean-forms.txt | HELP: class active/passive cures and blockers (old skill names) | 2026-10-10 |
| raw/live/whatcures.txt | Live WHATCURES output, one line per affliction (read by `tools/kb_catalog.py`) | 2026-10-10 (hypochondria) |
| raw/live/affliction_show/ (133), raw/live/captures/ | First `kbcapture afflictions` run: 267 answers | 2026-10-10 |
| raw/live/affliction_list.txt | AFFLICTION LIST, **first page only (29%)**: re-capture with MORE paging | 2026-10-10 |
| raw/live/curing-priority-list_normal_2026-10-10.txt (+ defence list, curingset list, curing status) | Your live SSC state | 2026-10-10 |
| raw/live/def_all-defences_2026-10-10.txt | The game's defence names | 2026-10-10 |
| raw/help/13.7_healing-and-curing.txt, 13.9_body-part-damage.txt | HELP 13.7, 13.9 | 2026-10-10 |
| raw/help/4.6_equilibrium-and-balance.txt, 4.6.1_queueing.txt | HELP 4.6, 4.6.1 | 2026-10-10 |
| raw/ab/survival_diagnose_1380.txt | AB Diagnose | 2026-10-10 |
| raw/guides/lock-types.txt | Community guide: lock types | 2026-10-10 |
| raw/guides/active-and-passive-cures-with-fire-lines.txt | Community guide: what each class cure looks like | 2026-10-10 |

## Related references outside kb/
- `.claude/classes/<class>.md`: per-class dossiers (kill routes, abilities)
- `.claude/classes/lock_types.md`, `.claude/databases/*.yaml`: lock and affliction data
- `docs/kill-paths.md`: cross-class kill-path index
- `memory/affliction-tracking.md`: the V3 target tracker
