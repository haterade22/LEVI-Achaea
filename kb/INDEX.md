# KB Index

One line per page. Kept up to date by `/kb-ingest`.

## Afflictions (core)
- [afflictions/README.md](afflictions/README.md): how afflictions and cures work from both sides; start here
- [afflictions/database.md](afflictions/database.md): the game's own record of all 125 afflictions (AFFLICTION SHOW): cures, durations, the lines you see when hit and cured, flags such as NoRandomCure (GENERATED; `afflictions.json` is the machine copy)
- [afflictions/catalog.md](afflictions/catalog.md): every affliction's cure, joined to our tracker and SSC priorities (GENERATED)
- [afflictions/cure-channels.md](afflictions/cure-channels.md): cure balances, what blocks each one, shared balances
- [afflictions/class-cures.md](afflictions/class-cures.md): each class's active and passive cures, blockers, fire lines, our triggers
- [afflictions/expiry-lines.md](afflictions/expiry-lines.md): timed afflictions leaving the TARGET: the lines we catch, the clock backstop, lines still wanted
- [afflictions/locks.md](afflictions/locks.md): lock definitions and how each is escaped
- [afflictions/limb-damage.md](afflictions/limb-damage.md): body part states, damage vs break, parrying

## Classes
- [classes/](classes/): one page per class (21) with every ability of its skills -- syntax, cost, cooldown, target, the afflictions it names (GENERATED from the wiki by `tools/kb_wiki_skills.py`; WIKI confidence). `abilities.json` is the machine copy (60 skills, 1,929 abilities)

## Curing
- [curing/curatives.md](curing/curatives.md): every herb/mineral pair, elixir and salve
- [curing/server-side-curing.md](curing/server-side-curing.md): SSC commands, how our code drives them, and your live curing state

## Defences
- [defences/README.md](defences/README.md): the game's 279 defence names, and our names that do not match

## Mechanics
- [mechanics/balance-and-queueing.md](mechanics/balance-and-queueing.md): balance vs equilibrium, server queue commands, types and the 10-command limit
- [mechanics/elementals-and-glance.md](mechanics/elementals-and-glance.md): elemental denizen names and attacks, the "There are N <plural> here." room prose, GLANCE, a denizen shield going up

## Changes (game announcements)
- [changes/2026-10-23_classleads.md](changes/2026-10-23_classleads.md): the 2026-10-23 class-lead post, one block per change with its fight impact and code join: Crystalism DESTABILISE + OVERLOAD, Elementalism PEBBLE, Psionics PULSE, Woodlore GRAPPLE (AB for all four), Serpent SUGGEST/SEAL off balance, Striking on a broken head, ANGEL PANIC, HERESY, tempered melancholic, HALOPHILIC, HYPERSIGHT, Telepathy locks, DWB EXPEND, RETALIATE, third-party cure lines, artefact cooldowns; part 2: CLOTTING by amount, the Serpent snake's progressive sileris strip, DWB inline invests, EMBRACE without vines, wreathe/incinerate/flame, Groves, ACCUSATION

## Combat (classes as they look in real fights)
- [combat/shikudo.md](combat/shikudo.md): every Shikudo strike, damage and effect line from both sides (first vs later in a combo), light strikes, forms, kata, Telepathy, ASSESS, SHATTER, the Dispatch kill as done, and what our triggers record
- [combat/runewarden-snb.md](combat/runewarden-snb.md): a sword-and-board Runewarden's round (slice, venom, shield strikes), her curing and runes, and the impale-disembowel kill
- [combat/fights/](combat/fights/README.md): one write-up per combat log -- Mystor's six arena fights as a Shikudo against a Depthswalker, an Infernal (three), an Apostate and a Shaman, with the opponents' own typed commands (MIND SAPIENCE), their curing, every distinct game line, and lessons for our package.

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
| raw/live/affliction_show/ (211), raw/live/captures/ | `kbcapture afflictions` runs: all 203 game afflictions, plus old names. Re-run 2026-10-23 (`captures/kb_capture_2026-10-23_204555.txt`): every record and the list unchanged since 2026-10-11, apart from tempered melancholic's mana-regen clause | 2026-10-23 |
| raw/live/affliction_list.txt | AFFLICTION LIST, all 203 afflictions (4 MORE pages) | 2026-10-10 |
| raw/live/defence-batch-test_2026-10-10.txt | Test: one bad defence name in a batch only rejects that name | 2026-10-10 |
| raw/live/curing-priority-defence-list_bash_2026-10-10.txt | Defence priorities, bash set | 2026-10-10 |
| raw/live/curing-priority-list_normal_2026-10-10.txt (+ defence list, curingset list, curing status) | Your live SSC state | 2026-10-10 |
| raw/live/def_all-defences_2026-10-10.txt | The game's defence names | 2026-10-10 |
| raw/help/13.7_healing-and-curing.txt, 13.9_body-part-damage.txt | HELP 13.7, 13.9 | 2026-10-10 |
| raw/help/4.6_equilibrium-and-balance.txt, 4.6.1_queueing.txt | HELP 4.6, 4.6.1 | 2026-10-10 |
| raw/ab/survival_diagnose_1380.txt | AB Diagnose | 2026-10-10 |
| raw/announcements/classleads_2026-10-23.txt | The class-lead change post of 2026-10-23 | 2026-10-23 |
| raw/live/captures/kb_capture_2026-10-23_122952.txt | AFFLICTION SHOW temperedmelancholic, pasted: the new mana-regen clause (filed by `kb_capture_import.py`; one soft wrap joined) | 2026-10-23 |
| raw/ab/crystalism_overload_2026-10-23.txt, elementalism_pebble_2026-10-23.txt, psionics_pulse_2026-10-23.txt, woodlore_grapple_2026-10-23.txt | AB for the four new abilities of that post | 2026-10-23 |
| raw/wiki/<Skill>.wiki (60) | Achaea wiki skill pages, raw wikitext | 2026-10-11 |
| raw/logs/2026-10-11_shikudo-vs-runewarden-snb_attacker.txt | Combat log: a Shikudo kills a Runewarden by Dispatch (the monk's view; shared by the user) | 2026-10-11 |
| raw/logs/2026-10-11_runewarden-snb-vs-shikudo_defender.txt | Combat log: a Runewarden kills a Shikudo by disembowel (her view; channel chat removed) | 2026-10-11 |
| raw/logs/2026-10-11_mystor_*.txt (6) | Mystor's own arena fights as a Shikudo: against a Depthswalker, an Infernal (three times), an Apostate and a Shaman; five with MIND SAPIENCE on the opponent, so his typed commands show | 2026-10-11 |
| raw/players/shikudo-2026-10-11.txt | Players in their own words: the user and Mystor on Shikudo, Telepathy, the mind lock and blackout | 2026-10-11 |
| raw/players/serpent-2026-10-12.txt | Serpent notes relayed by the user: DSTAB, hypochondria's delayed impatience, IMPULSE MASOCHISM MONKSHOOD, fratricide's 2.25 s relapse | 2026-10-12 |
| raw/players/magi-tabethys-2026-10-12.txt | Tabethys on Magi: the core rotation (magma, dehydrate, dehydrate, fulminate), CAST MUDSLIDE, the focus lock and the freeze-to-glaciate finisher | 2026-10-12 |
| raw/players/dizziness-fall-2026-10-15.txt | The dizzy fall line ("The ground seems to tilt and you fall with a thump."): it takes balance and cancels the move; dizziness can be uncurable | 2026-10-15 |
| raw/players/mnemosyne-scaling-boons-2026-10-16.txt | Mana Powered's text (4% per WHOLE 1000 max mana), the stat boons (4% per point, user), and the STAT box row format (two stats per row) | 2026-10-16 |
| raw/players/cures-user-2026-10-23.txt | The user on the five names the game does not list: bleeding = CLOT (amount), drowning = pear, nocaloric = apply caloric (a defence); the four tempered humours = ginger/antimony | 2026-10-23 |
| raw/announcements/classleads_2026-10-23_part2.txt | Part 2 of the 2026-10-23 class-lead post: Groves, Metamorphosis, Oppression, Reclamation, the Serpent snake, DWB inline invests, CLOTTING | 2026-10-23 |
| raw/guides/lock-types.txt | Community guide: lock types | 2026-10-10 |
| raw/guides/active-and-passive-cures-with-fire-lines.txt | Community guide: what each class cure looks like | 2026-10-10 |

## Related references outside kb/
- `.claude/classes/<class>.md`: per-class dossiers (kill routes, abilities)
- `.claude/classes/lock_types.md`, `.claude/databases/*.yaml`: lock and affliction data
- `docs/kill-paths.md`: cross-class kill-path index
- `memory/affliction-tracking.md`: the V3 target tracker
