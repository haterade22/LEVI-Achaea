--[[mudlet
type: alias
name: KB Capture
hierarchy:
- Levi_Ataxia
- Ataxia
- Basher
- Configs
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^kbcapture(?: (.+))?$
command: ''
packageName: ''
]]--

-- `kbcapture`              -- status
-- `kbcapture afflictions`  -- AFFLICTION LIST, then AFFLICTION SHOW + WHATCURES for every name we know
-- `kbcapture stop`         -- stop after the current answer
-- `kbcapture <cmd | cmd>` -- capture any game command(s), e.g. `kbcapture help cures | help heal`.
--                           Separated by "|", NOT ";": Mudlet splits input on ";" before this alias
--                           sees it, so the second command went to the game uncaptured.
-- Answers are appended to <profile>/kb_capture.txt; in the repo, `python tools/kb_capture_import.py`
-- files them into kb/raw/live/. Script: misc_scripts/025_KB_Capture.lua.
local arg = matches[2]
if not arg or arg == "" then
  ataxiaKB.status()
elseif arg == "stop" then
  ataxiaKB.stop()
elseif arg == "afflictions" then
  -- extendFromList: once AFFLICTION LIST answers, ask about every affliction the GAME lists too.
  ataxiaKB.start(ataxiaKB.afflictionCommands(), { extendFromList = true })
else
  local cmds = {}
  for c in arg:gmatch("[^|]+") do
    c = c:gsub("^%s+", ""):gsub("%s+$", "")
    if c ~= "" then cmds[#cmds + 1] = c end
  end
  ataxiaKB.start(cmds)
end
