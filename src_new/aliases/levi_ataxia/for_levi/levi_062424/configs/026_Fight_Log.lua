--[[mudlet
type: alias
name: Fight Log
hierarchy:
- Levi_Ataxia
- Ataxia
- Basher
- Configs
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^fightlog(?: (.+))?$
command: ''
packageName: ''
]]--

-- `fightlog`                 -- status: recording or not, the folder, the last saved log
-- `fightlog on [name]`       -- record now (default name: our target); runs until `fightlog off`
-- `fightlog off`             -- stop and save
-- `fightlog auto on|off`     -- record PvP fights on our own (default on)
-- `fightlog idle <seconds>`  -- an automatic recording stops after this long with nothing naming
--                               the opponent (default 60)
-- Logs go to <profile>/fightlogs/; in the repo, `python tools/fightlog_import.py` files them into
-- kb/raw/logs/ours/. Script: misc_scripts/026_Fight_Log.lua.
ataxiaFight.command(matches[2])
