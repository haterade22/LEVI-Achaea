# Player database (ataxiaNDB): the reference that was in CLAUDE.md

> Moved verbatim from `CLAUDE.md` on 2026-11-13 (`docs/adrs/002-knowledge-delivery-tiers.md`). Until then every session loaded this text. It is not yet reconciled with the other documents of this subject: where they disagree, check the code or the game source, then correct the wrong one.

### Player Database (ataxiaNDB)
- Fetches from Achaea API (`http://api.achaea.com/characters/`)
- Tracks: name, city, house, class, level, XP rank, player kills, mark, army rank, dauntless
- City-based name highlighting with per-city colours
- Enemy and army rank tracking
- Auto-honours hidden-city players (queued with 2s spacing after API batch)
- `an refresh [city]` — bulk `honours` to update mark/army/dauntless (honours-only data)
- Threat queries: `an marks`, `an army`, `an dauntless`, `an threats` (all support optional city filter)
- Player notes: `an noteadd/noteshow/noteremove`

**Mindnet party calls (v4.7.472, `telepathy/001_Mindnet.lua`).** `ataxia_mindnetTellParty(name, area)` (`013_Raid_Mode_Things`) decides the `pt <name> IN!` line. `raid mindnet` off stops it. Raid on and Annwyn call everyone, and Mhaldor calls its city enemies, as before. Otherwise, in any area and only in a party, it calls a player who is not us, is not on `ataxiaTemp.allies`, and whose `ataxiaNDB_getCitizenship` differs from our city (`Unknown` and `Rogues` differ). The city enemy list is not the filter, because in the fight that prompted this it missed most of the other side. **`ataxia.channels` (GMCP `Comm.Channel.List`) gives both inputs: `party` is listed while in a party, and the caption of `ct` is our city's name.** `ataxia_raidMode` is the wrong reader for this setting, because it returns false with raid off. `raid.mindnet` is seeded true at load, because `ataxia_raidToggle` flips nil to true. Rules and sources: `kb/mechanics/mindnet.md`. Test: `test_mindnet_report.lua`.
