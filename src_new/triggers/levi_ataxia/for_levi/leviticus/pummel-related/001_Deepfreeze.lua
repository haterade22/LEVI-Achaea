--[[mudlet
type: trigger
name: Deepfreeze
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes K-S
- Magi
- Pummel-related
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'no'
  isPerlSlashGOption: 'no'
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
- pattern: You drain the heat from the air around your enemies, causing them to experience the cold of the abyss itself.
  type: 3
]]--

-- PvP affliction tracking: numeric target = a denizen (see 014_Deepfreeze). Since the
-- Winter's Heart boon the basher casts this at denizen crowds, and tarAffed() must never
-- be fed a denizen id.
if targetIshere and type(target) ~= "number" then
  if haveAff("nocaloric") then
    tarAffed("shivering", "frozen")
  else
    tarAffed("nocaloric", "shivering")
  end
end

-- The full-width box is a PvP flourish. While bashing, deepfreeze fires roughly every
-- round against a crowd, and a banner per round buries the combat text -- so colour the
-- cast line instead and keep the box for PvP.
if ataxiaBasher and ataxiaBasher.enabled then
  selectString(line, 1)
  setBold(true)
  fg("cyan")
  deselect()
  resetFormat()
else
  ataxia_boxEcho("~ baby it's cold outside ~", "black:a_blue")
end