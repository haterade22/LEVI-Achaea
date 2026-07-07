--[[mudlet
type: trigger
name: Mnemosyne Survey
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Basher
- Bashing
- Basher Lines
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
- pattern: ^You are in .*Mnemosyne
  type: 1
]]--

-- Mnemosyne is an unmapped tower-climb instance (gmcp.Room.Info.area is ""), so we
-- flag it from its SURVEY line. Cleared on entering a real mapped room in
-- ataxia_Room_Update(). ataxiaBasher_isNoFleeArea() reads this flag.
if not ataxiaBasher.inMnemosyne then
  ataxiaBasher.inMnemosyne = true
  ataxiaEcho("Mnemosyne detected — no-flee mode ON (shield instead of flee).")
end
