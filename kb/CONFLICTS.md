# Open conflicts

Disagreements between sources, or between a source and the code. Each one has a way to
settle it. When it is settled, move it to **Resolved** with the answer and the change made.

| # | Topic | Says A | Says B | Impact | How to settle |
|---|---|---|---|---|---|
| 1 | Grove Cure | HELP: Druid and Sylvan Grove Cure, "hindered by nothing" | No trigger | An unblockable cure that V3 never sees | Capture its fire line, then add a trigger |
| 2 | **Server priorities are January's** | Code `ataxia_defaultCuringPrios()` | Live `normal` set (2026-10-10): broken arms 1 (ours 10), broken legs 2 (7), weariness 7 (6), horror 10 (9), crescendo 6 (9), healthleech 9 (8), scytherus 2 (3) | Every priority change since v4.7.276 (2026-08-19) has never reached SSC. The table is only sent by the `reset prios` alias; `ataxia_resetOnLogin` has no caller. | **You:** type `reset prios` in the normal set, then capture `CURING PRIORITY LIST` again and run `python tools/kb_prio_diff.py`. **Code (later):** decide whether the table should be re-sent automatically when it changes. |
| 3 | Priority names the server rejects | Our table writes `rebounding` 18 and `unweavingspirit3/4/5` 2 | Live list has no `rebounding` (it is a defence) and no per-stack spirit rows (body and mind have them); live base `unweavingspirit` is 4, not our 25 | Silent no-op writes. Spirit is cured at 4, not held back as intended. | Decide what unweaving spirit should be without stack levels. Drop the rejected keys from the table. |
| 4 | PvE bash curing set name | `ataxia/008` installs and switches a set named **`bash`** | Live CURINGSET LIST has **`bashing`** (21/22 used) and no `bash` | The PvE curing profile is probably not installed, so bashing uses PvP priorities | **You:** `aconfig bashcuring status` (it reports what the game says). |
| 5 | Defence server names | `ataxiaTables.defences` values `blade tune`, `acrobatics on`, `dance harrying`, `avoid ` (trailing space), `boosting`, and 4 names SSC does not keep | Live defence list: `tune`, `acrobatics`, `avoid`, `boostedregeneration`; no harrying/parrying/compoundmask/simultaneity/clarity | Unknown until traced: the defup batch is built from profile names, not these values | Trace `systemDefup`/`supportedDefence`; see `kb/defences/README.md` |
| 6 | Trigger-wrap lint blind to folded patterns | `tools/check_wrap.py` reads only one-line plain or quoted `- pattern:` values | 131 trigger files in our package carry a pattern wider than 118 columns written as a FOLDED plain scalar (e.g. the old Slough line). Each may never match on a wrapped server. | Patterns that silently never fire | Separate project: teach the lint folded scalars, allowlist, then shorten each pattern to an early fragment |

## Resolved

| Date | Topic | Answer | Change |
|---|---|---|---|
| 2026-10-10 | DIAGNOSE cost | AB 1380 (Survival): **1.00 second of equilibrium**. CLAUDE.md and the explorer doc (v4.7.390) called it free. | Docs corrected. The swarm recovery sends DIAGNOSE every 8s while afflicted; it is not attacking then, so the cost is harmless, but it is not zero. |
| 2026-10-10 | Disfigurement vs disloyalty | Live WHATCURES: they are TWO afflictions, both "Smoke Valerian / Smoke Realgar". The Serpent offense records disfigurement for monkshood, but the V3 smoke table only knew disloyalty. | v4.7.396: `disfigurement` appended to `smokeCureTableV3`. Still open: which one monkshood really gives (CLAUDE.md's venom table says disloyalty, the Serpent offense says disfigurement). Settle with `HELP MONKSHOOD` or `AB VENOM`. |
| 2026-10-10 | Hypochondria cure (HELP 13.7.2 said kelp/aurum) | Live `WHATCURES`: **Eat Lobelia / Eat Argentum** (`kb/raw/live/whatcures.txt`). The code was right; HELP 13.7.2 is stale. | No code change. The catalog now reads live WHATCURES and flags stale HELP rows. |
| 2026-10-10 | Magi Harmony passive never tracked | The line is Magi's (HELP + guide) | v4.7.395: new trigger `passive_active/029_Harmony_(Magi).lua`, pattern removed from 025, `passive_harmony` cooldown |
| 2026-10-10 | Paladin Healing passive never tracked | Paladins have the Rite of Healing (HELP + guide) | v4.7.395: 024 accepts Paladin for the "gentle glow" line only |
| 2026-10-10 | Dragonheal blocker | Blocked by weariness AND recklessness together; 1 cure when prone | v4.7.395: 005 removes nothing outright; 3 random cures, 1 if prone |
| 2026-10-10 | Fire Lord Slough | Blocked by prone (HELP). The ~160-column pattern could not survive the wrap | v4.7.395: 016 proves not-prone, and matches an early fragment |
| 2026-10-10 | Sleeplock defence names (guide said "Gypsum/Kola") | HELP 13.7.1: gypsum = insomnia, kola/quartz = instant wake | Corrected in `kb/afflictions/locks.md` |
| 2026-10-10 | Cures in CLAUDE.md venom table | HELP 13.7.2: anorexia = apply epidermal; slickness = bloodroot / smoke valerian; blindness = apply epidermal | Fixed rows for slike, gecko, oleander, colocasia, monkshood in CLAUDE.md |
| 2026-10-10 | "Calcium" as the ash mineral | HELP 13.7.1: prickly ash = **stannum** (calcite is the pear mineral) | Fixed `.claude/databases/afflictions.yaml` and `venoms.yaml` |
| 2026-10-10 | Disfigurement listed under ash | HELP 13.7.2: smoke valerian/realgar | Fixed both YAML databases (see #2 for the naming question) |
