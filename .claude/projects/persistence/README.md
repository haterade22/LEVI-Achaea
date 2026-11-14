# Data persistence and the profile backup: the reference that was in CLAUDE.md

> Moved verbatim from `CLAUDE.md` on 2026-11-13 (`docs/adrs/002-knowledge-delivery-tiers.md`). Until then every session loaded this text. It is not yet reconciled with the other documents of this subject: where they disagree, check the code or the game source, then correct the wrong one.

### Data Persistence & Profile Backup

All system state is saved to disk files in `getMudletHomeDir()` via `table.save()`/`table.load()`. A profile backup system provides redundancy by also storing data in the `_ataxia_backup` global (Mudlet saved variable).

**Save flow**: Every save rotates a `.bak`, writes to disk, AND copies into `_ataxia_backup`. `ataxia` is
passed through `sanitizeForSave()` first — it strips **live GUI/runtime objects** (Geyser windows, Mudlet
`db` proxies) so they never hit disk. Detection is `getmetatable`/`rawget` only — **never index
`.hide`/`.show`** (a `db` proxy's `__index` errors "access sheet 'hide'"). This matters because GUI objects
are — as a known TODO — stored under the saved `ataxia` namespace (`ataxia.mnemosyne.map.window`,
`ataxia.data.hunter.window`, vital bars, chat).

**Transient state must NOT ride the saved namespace (v4.7.192/193/194).** Because the save is
wholesale and `deepMerge` ends in an unconditional `dst[k] = v`, any flag that is *set true on
use and cleared only by a `tempTimer`* comes back from disk stuck ON -- the timer that would
clear it does not survive a relog or SYSUPDATE. The feature is then permanently disabled,
silently. Four were built this way and are now reload-safe TIMESTAMPS on `ataxiaTemp`: the
emergency wand of reflection (`wandReflectAt`, **1 hour** -- at that length an interrupted
cooldown is the normal case), the Maran barrier (`maranAt`, 65s), the vulture talon
(`vultureTalonAt`, 180s) and the darkshade auto-prioritise (`darkshadeTimer` /
`darkshadePrioritized`). A missing stamp reads READY, so the failure direction is one early
re-use rather than a lockout. Never serialize a `tempTimer` **id** either -- after a reload it
names whatever timer inherited that integer, and `killTimer` cancels a stranger's. CONFIG
(thresholds, durations, ids) does belong on `ataxia`; only the transient half moves.

**A NAMESPACE UNDER `ataxia` IS PERSISTED WHETHER OR NOT YOU MEANT IT (v4.7.299).**
`ataxia_saveSettings` does `table.save(file, sanitizeForSave(ataxia))` -- WHOLESALE -- and
`sanitizeForSave` strips only FUNCTIONS, METATABLED objects and GUI snapshots. A table of ordinary
scalars goes straight to disk, and `deepMerge` ends in an unconditional `dst[k] = v` for non-tables,
so **the stored value WINS on load**. `ataxia.mnemosyne.run` was built on the belief that it was
"in-memory only" -- its header said so -- and `active`, `ripple`, `publicId`, `lastOffered`, `lives`
and `waveProgress` all came back from the previous session. **The telemetry was the least of it:**
the only thing that clears run state is `_resetRun`, reached through `startRun`/`endRun`, both
BELOW the `_auto()` gate -- so with reporting off (the shipped default) nothing ever cleared it,
while consumers that are NOT gated on reporting read it: `run.boss` makes the Bard pick WAVEDANCE
on an ordinary ripple and the legend deck WITHHOLD Xylthus (a card cannot bind a boss) and the
explorer patrol for a boss that is not there, and `run.ripple` drives the Bard's hawkstep gate and
the swarm's depth-scaled thresholds. `M._clearStaleRun()` fixes it, called from
`ataxia_loadSettings` -- **not** from a second `sysLoadEvent` handler, because ORDERING is the
subtle half: a separate handler's order relative to the loader is undefined, so it could run BEFORE
the merge and be undone by it, whereas inside the loader it is ordered by construction. `active`
and `boss` are cleared there but deliberately NOT folded into `_resetRun` (`startRun` sets `active`
true and then calls `_resetRun`; `boss` is re-learned from each ripple's Objective line), and a
test pins that so a future tidy-up cannot merge them. **Before parking any transient flag under
`ataxia`, decide whether it should be on `ataxiaTemp` instead** -- that is the same v4.7.192-194
rule, and this is the third system caught by it.

**THE FOURTH: THE TRACKER'S OWN HTTP QUEUE (v4.7.336).** `ataxia.mnemosyne._busy` and `_queue` sat
on the same saved namespace, beside the run state v4.7.299 fixed, and nobody looked. One save caught
a POST in flight; the next start restored `_busy = true` with no request on the wire and no watchdog
to clear it, so `_pump` returned early FOREVER and every report after it queued without a sound --
**711 requests, about nine runs**, in the live save, nothing sent, nothing failed, nothing echoed.
Each save wrote the wedge out again, so it survived every restart (and every XML reimport, which
reaches the same loader). Two general rules come out of it: **a busy flag restored without the timer
that clears it is a permanent livelock** -- a flag only a live timer can clear must never be
trusted after a reload -- and **never serialize a timer or event-handler id** (the v4.7.192 rule
again: `_watchdog` came back naming a stranger's timer, and the restored handler ids made the next
reinstall kill the wrong handlers and leave ours registered twice). `M._resumeQueue` (end of 001 AND
`ataxia_loadSettings` after the merge) clears the flag and REPLAYS the queue in order --
at-least-once, the user's choice over dropping it; the ids moved to `ataxiaTemp.mnemHttp`; `_pump`
refuses a busy flag with no send stamp from this session; and `mnem status` shows the queue, because
the only tell for nine runs was `ripple 0` on an active run.

**KNOWN DEFECT, UNFIXED: THE PROFILE-BACKUP RESTORE DESTROYS LIVE NAMESPACES (found 2026-09-09).**
`ataxia_loadSettings`'s backup branch is `for k, v in pairs(_ataxia_backup.ataxia) do ataxia[k] = v
end` -- a RAW WHOLESALE REPLACE that bypasses every protection `mergeLoad` has (the cycle-safe
`deepMerge`, `stripGui`, and the live-runtime-object guard whose ten-line comment sits directly
above it). Since `sanitizeForSave` strips FUNCTIONS, the backup's copy of a namespace is DATA ONLY
-- so assigning it over the live one **deletes that namespace's functions**: `ataxia.mnemosyne`
(the whole run tracker, map, explorer and swarm API), `ataxia.armour`, `ataxia.updater`,
`ataxia.bars`, `ataxia.defense`. It also re-introduces exactly the live-GUI-object corruption that
comment exists to prevent. Found because a test asserting the v4.7.299 reset runs on the backup
path FAILED -- the reset was unreachable, because the function it calls no longer existed by then.
The fix is to give that branch the file branch's merge semantics (hoist `deepMerge`/`stripGui` out
of `mergeLoad`); it changes disaster recovery for EVERY namespace under `ataxia`, so it wants its
own change and its own testing. **Until then a profile-backup restore needs a reload**, and the
`KNOWN DEFECT` comment at the site says so.

**Load flow** (`ataxia_loadSettings`, on `sysLoadEvent` **and** `sysInstallPackage`): fault-isolated — the
main-settings load and each sub-load (basher/paths/extraction/NDB/SLC/itemCatalog/ldm) are `pcall`-wrapped
so one corrupt file can't strand the rest; `ataxia.loaded` is set only at the end (an interrupted load
retries); and `deepMerge` is **cycle-safe** (`seen` set) and **GUI-safe** (`stripGui(loaded)` recursively
drops serialized GUI snapshots before merge, and it never merges into a live runtime object). Each file
falls back primary → `.bak` → `_ataxia_backup`.

**Disk Files** (all relative to `getMudletHomeDir()`):

| File | Variable | Data | Save Source |
|------|----------|------|-------------|
| `ataxia` | `ataxia` | Main settings, vitals, curing priorities | `001_Save_Load_Settings.lua` |
| `basher` | `ataxiaBasher` | Basher state, targets, shield timers | `001_Save_Load_Settings.lua` |
| `basherpaths` | `ataxiaBasherPaths` | Hunting route paths | `001_Save_Load_Settings.lua` |
| `andb` | `ataxiaNDB` | Player database | `001_Save_Load_Settings.lua` |
| `extractLocations` | `ataxiaExtraction` | Extraction zones | `001_Save_Load_Settings.lua` |
| `slcconfig` | `selfLimbDamage.config` | Self-Limb Tracking config | `001_Save_Load_Settings.lua` |
| `shaman_profile.lua` | `shaman` | Shaman offense config | `shaman_system/002_Save_Load_functions.lua` |
| `legenddeck` | `ldm.deck` | Card charges/timers | `legend_deck/004_Legend_Deck_Save_Load.lua` |
| `legenddeck_config` | `ldm.config/favorites/enabled` | Card config | `legend_deck/004_Legend_Deck_Save_Load.lua` |
| `classDetect_config.lua` | `classDetect.config/curingsetMap` | Class detection settings | `class_detect/001_Class_Detect_Engine.lua` |
| `gearaudit` | `gearAudit.data` | Gear inventory | `gear_system/001_Gear_Audit.lua` |
| `armourconfig` | `ataxia.armour.config` | Armour profiles, paragons, morph state | `gear_system/002_Armour_Paragons.lua` |
| `itemcatalog` | `itemCatalog.items/config` | Cataloged items, user notes, config | `item_catalog/004_Item_Catalog_Save_Load.lua` |
| `ataxia_bars_config.lua` | `ataxia.bars.config` | Vital bar toggles | `build_windows/016_buildVitalBars.lua` |
| `mapper.options.lua` | `mmp.locked/settings` | Mapper options | `mudlet-mapper` (no profile backup) |

**Profile Backup Keys** (in `_ataxia_backup`):
`ataxia`, `basher`, `basherpaths`, `ndb`, `extraction`, `slcconfig`, `shaman`, `legenddeck`, `legenddeck_config`, `classDetect`, `gearaudit`, `armourconfig`, `itemcatalog`, `bars_config`

**Other Storage**: SQLite `exp_db` (hunting stats via Mudlet `db` API), SQLite `mob_damage_db` (per-mob non-crit damage tracking via `db` API), `ataxiaNDB/*.json` (temp API downloads).

**Event Hooks**: `sysDisconnectionEvent` → `ataxia_saveSettings()`, `sysLoadEvent` → `ataxia_loadSettings()`, and `sysInstallPackage` → `ataxia_updateApplied()` which calls `ataxia_loadSettings()` when not already loaded (so install/self-update loads settings without needing a reconnect). `ataxia_loadSettings()` is fault-isolated: the main-settings load and each sub-load (basher/paths/extraction/NDB/SLC/itemCatalog/ldm) are `pcall`-wrapped, its `deepMerge` is cycle-safe, and `ataxia.loaded` is set only at the very end.

**Setup**: User must add `_ataxia_backup` as a saved variable in Mudlet's Variables panel (one-time, type: table).

---
