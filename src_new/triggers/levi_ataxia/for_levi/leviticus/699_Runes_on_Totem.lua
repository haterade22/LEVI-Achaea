--[[mudlet
type: trigger
name: Runes on Totem
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Misc Triggers
- Item Highlighting
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'yes'
  isPerlSlashGOption: 'no'
  isColorizerTrigger: 'no'
  isFilterTrigger: 'no'
  isSoundTrigger: 'no'
  isColorTrigger: 'no'
  isColorTriggerFg: 'no'
  isColorTriggerBg: 'no'
triggerType: 0
conditonLineDelta: 1
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: A rune
  type: 2
- pattern: ^A rune (.+) is sketched in slot \d+\.$
  type: 1
]]--

if ataxia.settings.highlighting and ataxia.settings.highlighting.runes then
  local rune = multimatches[2][2]
  local runeEffects = {
    ["like an open eye"] = {name = "wunjo", effect = "unblind"},
    ["that looks like a stick man"] = {name = "inguz", effect = "paralysis"},
    ["shaped like a butterfly"] = {name = "nairat", effect = "entangle"},
    ["like a closed eye"] = {name = "fehu", effect = "sleep"},
    ["resembling a bell"] = {name = "mannaz", effect = "undeaf"},
    ["that looks like a nail"] = {name = "sowulu", effect = "damage"},
    ["that looks like something out of your nightmares"] = {name = "kena", effect = "fear"},
    ["shaped like a viper"] = {name = "sleizak", effect = "voyria"},
    ["resembling an apple core"] = {name = "loshre", effect = "anorexia"},
    ["resembling a square box"] = {name = "pithakhan", effect = "drain mana"},
    ["like a lightning bolt"] = {name = "uruz", effect = "hp regen"},
    ["resembling a leech"] = {name = "nauthiz", effect = "hunger"},
    ["like an upward-pointing arrow"] = {name = "tiwaz", effect = "def strip"}
  }
  
  echo(string.rep(" ", 60-#multimatches[2][1]))
  
  if runeEffects[rune] then
    cecho(string.format(" <DarkGreen>(<NavajoWhite>%s: <red>%s<DarkGreen>)",
      runeEffects[rune].name, runeEffects[rune].effect))
  else
    cecho(" <a_red>(<a_brown>unknown!<a_red)")
  end
end