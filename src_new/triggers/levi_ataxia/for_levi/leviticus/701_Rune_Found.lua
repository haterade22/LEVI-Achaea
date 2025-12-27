--[[mudlet
type: trigger
name: Rune Found
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Misc Triggers
- Item Highlighting
- Runes on person/ground
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'no'
  isPerlSlashGOption: 'yes'
  isColorizerTrigger: 'no'
  isFilterTrigger: 'no'
  isSoundTrigger: 'no'
  isColorTrigger: 'no'
  isColorTriggerFg: 'no'
  isColorTriggerBg: 'no'
triggerType: 0
conditonLineDelta: 0
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: A rune (.+?) has been sketched onto \w+.
  type: 1
- pattern: A rune (.+?) has been sketched into the ground here.
  type: 1
]]--


if ataxia.settings.highlighting and ataxia.settings.highlighting.runes then
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
    ["like an upward-pointing arrow"] = {name = "tiwaz", effect = "def strip"},
    ["shaped like a mighty oak"] = {name = "jera", effect = "+1 CON/STR"},
    ["resembling an elk"] = {name = "algiz", effect = "10% all resist"},
    ["like a lion"] = {name = "berkana", effect = "L1 HP regen"},
    ["resembling a horse"] = {name = "raido", effect = "escape"},
    ["like a flurry of lightning bolts"] = {name = "isaz", effect = "periodic offbal"},
    ["like a rising sun"] = {name = "dagaz", effect = "cures affs"},
    ["shaped like a yew"] = {name = "eihwaz", effect = "destroy vibes"},
    ["resembling a volcano"] = {name = "thurisaz", effect = "LoS damage"},
  }
  
  for i = 1, #matches, 2 do
    local rune = matches[i+1]
    local line = matches[i]
  
    local pos = selectString(line, 1)
    moveCursor("main", pos+#line-1, getLineNumber())
  
    if runeEffects[rune] then
      cinsertText(string.format(" <green>(<NavajoWhite>%s: <orange>%s<green>)",
        runeEffects[rune].name, runeEffects[rune].effect))
    else
      cinsertText(" <a_blue>(<a_brown>unknown!<a_blue>)")
    end
  end
  
  deselect()
  resetFormat()
  moveCursorEnd()
end