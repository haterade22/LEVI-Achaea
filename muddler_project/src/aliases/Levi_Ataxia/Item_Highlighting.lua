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