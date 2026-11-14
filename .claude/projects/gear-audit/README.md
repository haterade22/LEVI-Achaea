# Gear Audit & BiS Analysis

> Moved verbatim from `CLAUDE.md` on 2026-11-13 (`docs/adrs/002-knowledge-delivery-tiers.md`). Until then every session loaded this text. It is not yet reconciled with the other documents of this subject: where they disagree, check the code or the game source, then correct the wrong one.

### Gear Audit & BiS Analysis (`gearAudit`)
Automated gear inventory and PvE Best-in-Slot scoring system. Collects all gear via GEAR LIST ALL + GEAR PROBE, then scores items for PvE damage output.

**Key File:** `src_new/scripts/.../gear_system/001_Gear_Audit.lua`
**Alias:** `src_new/aliases/.../gear_system/001_Gear_Audit.lua` (`gearaudit`)

**Commands:**
| Command | Purpose |
|---------|---------|
| `gearaudit` | Start new gear audit (GEAR LIST ALL + GEAR PROBE all items) |
| `gearaudit show` | Display all collected gear |
| `gearaudit detail <id>` | Full details for a gear ID |
| `gearaudit set/slot/effect <filter>` | Filter by set, slot, or effect keyword |
| `gearaudit bis` | PvE Best-in-Slot analysis (all slots, per-set + overall) |
| `gearaudit bis <slot>` | BiS analysis for a specific slot |
| `gearaudit score <id>` | Detailed score breakdown with weights |
| `gearaudit scrap` | Scrap recommendations -- **AUTO-SENDS** `GEAR SCRAP <id> CONFIRM`, one per balance, unprompted |
| `gearaudit scrap <set>` | Scrap recommendations for a specific set |
| `gearaudit save/load` | Manual save/load |

**BiS Scoring Weights** (configurable via `gearAudit.config.bisWeights`):
| Stat | Weight | Priority |
|------|--------|----------|
| Additional Damage % / Bonus Damage % | 10.0 | Highest |
| Celerity | 8.0 | Very High |
| Burst Damage (normalized) | 7.0 | High |
| Ignore Denizen Resistance | 6.0 | High |
| Crit Chance | 5.0 | High |
| Crit Damage | 4.0 | Moderate |
| HP Increase / Battlerage Damage | 3.0 | Moderate |
| HP Regen | 2.5 | Moderate |
| Damage Reduction / Rage Gen / BR Rage Gen / Bleed Damage | 2.0 | Low |
| Resistance | 1.5 | Low |
| WP Regen / Blackout Reduction | 1.0 | Lowest |

Conditional gear (location-locked) discounted 50%; battlerage-conditional 30%.
Burst damage normalized to per-attack value: `effectivePct = burstPct / (cooldown / 3)`.
Scrap threshold: items scoring below 50% of set BiS (`gearAudit.config.scrapThreshold`).

**Display never truncates (v4.7.208).** `display()` auto-sizes ID/Set/Slot to their widest
actual value and gives the remainder of the console to Effects, wrapping long text onto
indented continuation rows -- via `gearAudit.consoleWidth()` (pcall-guarded `getColumnCount`),
`wrapText`, `tableRule`, `tableRow`, configured by `gearAudit.config.display`
(`width` pins it, `maxWidth`/`fallback`/`minEffects`). `displayBis` reuses the same helpers.
**The old 40-char Effects cut was not the real problem** -- `summarizeEffect`'s *fallback*
(`effects[1]:sub(1,30)`) was, because roughly half a real 147-item inventory had **no matching
pattern at all** and was printing raw sentence fragments. `scoreEffect` missed the same
families, so `bis`/`score`/`scrap` valued crit damage, crit chance, rage generation and bonus
denizen damage at zero. Both now cover them; the fallback returns the **full** raw text, which
is what a new pattern gets written from. Every added pattern is **safe-fail** -- a wrong guess
about a sentence's tail simply doesn't match and falls through to that raw text. Order matters
in one place: `generate (%d+)%% less` must be tested before `attacks will generate (%d+)%%`, or
a rage penalty is scored as a bonus.

**`gearaudit scrap` is destructive and unprompted** -- `displayScrap` queues
`GEAR SCRAP <id> CONFIRM` for every recommendation and auto-sends it, one per balance. Any
change to `scoreEffect`/`bisWeights` changes what gets destroyed.

**Persistence:** `gearaudit` file via `table.save/load` with `_ataxia_backup` fallback.
