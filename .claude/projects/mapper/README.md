# Mudlet Mapper (mmp): the reference that was in CLAUDE.md

> Moved verbatim from `CLAUDE.md` on 2026-11-13 (`docs/adrs/002-knowledge-delivery-tiers.md`). Until then every session loaded this text. It is not yet reconciled with the other documents of this subject: where they disagree, check the code or the game source, then correct the wrong one.

### Mudlet Mapper (mmp)
- `mmp.gotoRoom(roomID)` - Navigate to a specific room
- `mmp.gotoArea(areaName)` - Navigate to area entrance
- `mmp.gotoFeature(featureName)` - Navigate to map features
- `mmp.getPath(from, to)` - Calculate and cache paths
- `mmp.fixPath()` - Optimize paths for sprint/dash/gallop
- Fast travel integration (wings, tarot, harness, pebble)
- Balance-aware movement with GMCP integration
- Multi-game support (Achaea, Aetolia, Lusternia, Imperian)

**The mapper is a SEPARATE, self-updating package** (IRE mudlet-mapper, its own "Check for updates"
prompt). `src_new/scripts/mudlet-mapper/` is a stale reference snapshot that the build never ships
(`INCLUDE_ROOTS = {"Levi_Ataxia"}`), so its code is not what runs. **Never ship copies of mapper items
inside Levi_Ataxia** -- v4.7.374 removed four copies of its hourly update timer that had been doubling
its polling, and that Muddler had merged into one timer (same name, same group) at an unstable
interval. Before relying on an `mmp.*` name, check it against upstream `mudlet-mapper.xml`, not the
snapshot.

**Map source (upstream, 2026-10):** `mconfig crowdmap on|off` became `mconfig mapsource
game|published|service` (`crowdmap` survives as a deprecated alias; `mmp.settings.crowdmap` is gone,
read `mmp.settings.mapsource`). `service` is an experimental live Crowdmap; `crowdmapservicesend`
(default off) reports local map changes to it. Two consequences for this package:
- **Upstream wraps Mudlet's global map-write API** (`setRoomName`, `addRoom`, `deleteRoom`,
  `setRoomUserData`, `addSpecialExit`, `setRoomEnv`, `setDoor`, `createMapLabel`, ...). With sending on,
  ANY call from ANY package is reported to the shared service. Our only map write today is `lockRoom`
  (`genrunning/003`), which is not wrapped. Think twice before adding a map write, and never write
  Mnemosyne/dementia-derived data into the Mudlet map.
- **`gmcpmapupdates` + Mnemosyne dementia:** with it on, `mmp.syncSafeRoomInfo` writes every
  `gmcp.Room.Info`'s name, environment, indoor/outdoor flag and area onto the mapped room of that
  number, unchecked. Dementia (Creville's Legacy) sends a real room number with hallucinated details on
  that channel (see the v4.7.249 dead-reckoning note), so it must be OFF in the tower.
  **The package enforces that (v4.7.377, `mnemosyne/016_Mapper_GMCP_Guard.lua`):**
  - "mnemosyne entered" switches it off (silent `setOption`, read back), but only if it was on.
  - "mnemosyne left" switches it back on, but only if WE switched it off.
  - A `gmcp.Char.Vitals` check covers the three paths that raise no event: a reload mid-climb (the
    restored `inMnemosyne` makes `mnemHere`'s transition guard silent), the user re-enabling it
    mid-climb, and a restore owed from an earlier session.
  - The debt marker `ataxiaBasher.mapperGmcpOwed` is DELIBERATELY saved. The mapper writes its options
    only on sysExitEvent and we save on disconnect, so a clean exit stores both "off" and "owed",
    while a crash stores neither.
  - `ataxia_loadSettings` does not restore: on a fresh start it can run before the mapper's own
    option load, which would overwrite the restore after the marker was already cleared.
