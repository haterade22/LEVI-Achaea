--[[mudlet
type: alias
name: Item Highlighting
hierarchy:
- Levi_Ataxia
- Ataxia
- Config
- Toggles
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^aconfig highlight (\w+)$
command: ''
packageName: ''
]]--

local hl = {
  "guards", "sigils", "totems", "runes", "bals", "limbs"
}
ataxia.settings.highlighting = ataxia.settings.highlighting or {}

if not table.contains(hl, matches[2]:lower() ) then
  ataxia_Echo("Invalid item to highlight, please choose from: <green>"..table.concat(hl, ", ")..".")
elseif not ataxia.settings.highlighting[matches[2]:lower()] then
  ataxia.settings.highlighting[matches[2]:lower()] = true
  ataxia_Echo("Will now highlight "..matches[2].." where applicable.")
else
  ataxia.settings.highlighting[matches[2]:lower()] = false
  ataxia_Echo("No longer highlighting "..matches[2]..".")
end
ataxia_saveSettings(false)