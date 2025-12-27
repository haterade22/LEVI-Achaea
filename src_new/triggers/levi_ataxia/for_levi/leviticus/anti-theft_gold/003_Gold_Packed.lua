--[[mudlet
type: trigger
name: Gold Packed
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Misc Triggers
- Anti-theft/Gold
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
- pattern: ^You put (\d+) gold sovereigns in (.+).$
  type: 1
- pattern: You hold no "gold".
  type: 3
]]--

ataxiaTemp.goldinhand = nil
if type(target) == "number" and ataxiaBasher.enabled then

    if not ataxiaBasher.manual then
			deleteFull()
		end
end

if bashStats then
	bashStats.gainedGold = ( tonumber(gmcp.Char.Status.gold) - bashStats.loginGold )
end
