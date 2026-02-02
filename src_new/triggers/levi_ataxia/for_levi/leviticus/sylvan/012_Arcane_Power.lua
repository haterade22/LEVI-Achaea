--[[mudlet
type: trigger
name: Arcane Power
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Affs Post Queue - Gated
- Classes K-S
- Sylvan
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
- pattern: ^You have (\d+) units of arcane energy built up.$
  type: 1
- pattern: ^You have (\d+) units of arcane energy stored.$
  type: 1
]]--

tAffs.disturb = true
if applyAffV3 then applyAffV3("disturb") end
sylArcanePower = tonumber(matches[2])
tAffs.feedback = true
if applyAffV3 then applyAffV3("feedback") end
ataxiaEcho("Arcane power is at: <white>"..sylArcanePower..".")