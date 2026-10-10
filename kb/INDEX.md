# KB Index

One line per page. Kept up to date by `/kb-ingest`.

## Afflictions (core)
- [afflictions/README.md](afflictions/README.md): how afflictions and cures work from both sides; start here
- [afflictions/catalog.md](afflictions/catalog.md): every affliction's cure, joined to our tracker and SSC priorities (GENERATED)
- [afflictions/cure-channels.md](afflictions/cure-channels.md): cure balances, what blocks each one, shared balances
- [afflictions/class-cures.md](afflictions/class-cures.md): each class's active and passive cures, blockers, fire lines, our triggers
- [afflictions/locks.md](afflictions/locks.md): lock definitions and how each is escaped

## Curing
- [curing/curatives.md](curing/curatives.md): every herb/mineral pair, elixir and salve
- [curing/server-side-curing.md](curing/server-side-curing.md): SSC commands and how our code drives them

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
| raw/live/affliction_show/, raw/live/affliction_list.txt, raw/live/captures/ | `kbcapture` output filed by `tools/kb_capture_import.py` | as captured |
| raw/guides/lock-types.txt | Community guide: lock types | 2026-10-10 |
| raw/guides/active-and-passive-cures-with-fire-lines.txt | Community guide: what each class cure looks like | 2026-10-10 |

## Related references outside kb/
- `.claude/classes/<class>.md`: per-class dossiers (kill routes, abilities)
- `.claude/classes/lock_types.md`, `.claude/databases/*.yaml`: lock and affliction data
- `docs/kill-paths.md`: cross-class kill-path index
- `memory/affliction-tracking.md`: the V3 target tracker
