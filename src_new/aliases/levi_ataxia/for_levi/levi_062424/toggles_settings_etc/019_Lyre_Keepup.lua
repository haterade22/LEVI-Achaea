--[[mudlet
type: alias
name: Lyre Keepup
hierarchy:
- Levi_Ataxia
- Ataxia
- Config
- Toggles
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^lyre$
command: ''
packageName: ''
]]--

if ataxiaTemp.lyreMode then
  ataxiaTemp.lyreMode = nil
  send("curing on",false)
else
  ataxiaTemp.lyreMode = true
  local sp = ataxia.settings.separator
  send("queue addclear free stand"..sp.."curing off"..sp.."strum lyre",false)
end
ataxiaEcho("Lyre mode has been "..(ataxiaTemp.lyreMode and "<green>enabled." or "<red>disabled."))