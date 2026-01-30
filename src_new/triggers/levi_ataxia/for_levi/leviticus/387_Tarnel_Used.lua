--[[mudlet
type: trigger
name: Tarnel Used
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Spiritlore System
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
- pattern: ^Abruptly severing your bond with the spirit of Tarnel, The Walker, you use the released spiritual energy to bind
    (\w+).$
  type: 1
- pattern: '1'
  type: 5
- pattern: (.*)
  type: 1
]]--

if not multimatches[3][2]:find("weakens") then
	ataxiaTemp.tarnelCooldown = true
end