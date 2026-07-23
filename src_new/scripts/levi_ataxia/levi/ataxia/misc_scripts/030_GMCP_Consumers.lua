--[[mudlet
type: script
name: GMCP Consumers
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- Misc Scripts
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

-- Passive GMCP consumers (2026-07-23, from the GMCP capability audit). Each stashes server-pushed
-- data into ataxia.* so other systems can read it later; none change combat behaviour. Handlers
-- register at FILE LOAD with kill-before-register so a SYSUPDATE reload doesn't stack duplicates.
ataxia = ataxia or {}
ataxia.skills = ataxia.skills or {}          -- { [skillsetName] = "Rank (NN%)" }  <- Char.Skills.Groups
ataxia.statusVars = ataxia.statusVars or {}  -- { [internalName] = "Caption" }      <- Char.StatusVars
ataxia.time = ataxia.time or {}              -- merged IRE.Time.List/Update payload
ataxia.channels = ataxia.channels or {}      -- { [internalName] = "Caption" } from Comm.Channel.List
ataxiaGmcpConsumers = ataxiaGmcpConsumers or {} -- handler-id registry (reload-safe)

-- Core.Goodbye: the server's parting reason string, sent right before it drops the connection.
-- For an unattended basher/explorer this is the only record of WHY a session ended (idle-kick vs
-- death vs boot), so log it loudly and stash the last one.
function ataxiaGmcpConsumers_onGoodbye()
  local reason = gmcp and gmcp.Core and gmcp.Core.Goodbye
  ataxia.lastGoodbye = (type(reason) == "string" and reason) or "(no reason given)"
  if ataxiaEcho then ataxiaEcho("Server disconnect: " .. ataxia.lastGoodbye) end
end

-- IRE.Time: time of day / moonphase / daynight. Update carries only changed fields, so MERGE
-- into the stored table rather than replacing it.
function ataxiaGmcpConsumers_onTime()
  local t = gmcp and gmcp.IRE and gmcp.IRE.Time and (gmcp.IRE.Time.List or gmcp.IRE.Time.Update)
  if type(t) ~= "table" then return end
  for k, v in pairs(t) do ataxia.time[k] = v end
end

-- Char.StatusVars: name->caption map for every Char.Status variable the server advertises. Knowing
-- the authoritative variable set future-proofs the status line; it also documents that later
-- Char.Status messages carry ONLY changed keys (handlers must not assume every field is present).
function ataxiaGmcpConsumers_onStatusVars()
  local sv = gmcp and gmcp.Char and gmcp.Char.StatusVars
  if type(sv) ~= "table" then return end
  ataxia.statusVars = {}
  for name, caption in pairs(sv) do ataxia.statusVars[name] = caption end
end

-- Char.Skills.Groups: array of { name, rank } for every skillset. Cache { name = rank } so future
-- gating can check the character actually has an ability at the needed rank instead of assuming
-- class implies it (an under-trained/reincarnated char otherwise fails commands and wastes balance).
-- Requested once at login via `Char.Skills.Get {}` (see levilogin). Data-layer only -- nothing
-- consumes it yet, so it cannot regress dispatch.
function ataxiaGmcpConsumers_onSkillGroups()
  local groups = gmcp and gmcp.Char and gmcp.Char.Skills and gmcp.Char.Skills.Groups
  if type(groups) ~= "table" then return end
  ataxia.skills = {}
  for _, g in ipairs(groups) do
    if type(g) == "table" and g.name then ataxia.skills[g.name] = g.rank end
  end
end

-- Comm.Channel.List: [{ name, caption, command }] for every channel THIS character actually has
-- (sent on login and when channels change). Cache { name = caption } so any channel->window/label
-- routing can consult the authoritative set instead of a hardcoded literal that drops unknown
-- house/order/clan channels into "Misc". Data-layer only for now; the active chat display
-- (update_windows/001_showChat) still uses its own map and is untouched.
function ataxiaGmcpConsumers_onChannelList()
  local list = gmcp and gmcp.Comm and gmcp.Comm.Channel and gmcp.Comm.Channel.List
  if type(list) ~= "table" then return end
  ataxia.channels = {}
  for _, c in ipairs(list) do
    if type(c) == "table" and c.name then ataxia.channels[c.name] = c.caption or c.name end
  end
end

local function _reg(event, fnName)
  if ataxiaGmcpConsumers[event] then pcall(killAnonymousEventHandler, ataxiaGmcpConsumers[event]) end
  ataxiaGmcpConsumers[event] = registerAnonymousEventHandler(event, fnName)
end
_reg("gmcp.Core.Goodbye", "ataxiaGmcpConsumers_onGoodbye")
_reg("gmcp.IRE.Time.List", "ataxiaGmcpConsumers_onTime")
_reg("gmcp.IRE.Time.Update", "ataxiaGmcpConsumers_onTime")
_reg("gmcp.Char.StatusVars", "ataxiaGmcpConsumers_onStatusVars")
_reg("gmcp.Char.Skills.Groups", "ataxiaGmcpConsumers_onSkillGroups")
_reg("gmcp.Comm.Channel.List", "ataxiaGmcpConsumers_onChannelList")
