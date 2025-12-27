--[[mudlet
type: trigger
name: Potash/Moss Used
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Balances
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
- pattern: You eat a potash crystal.
  type: 3
- pattern: You feel your health and mana replenished.
  type: 3
- pattern: You eat some irid moss.
  type: 3
]]--

if type(target) == "number" and ataxiaBasher.enabled then
	if not bashMossSub then
    if zgui then
      cecho("bashDisplay", "\n<DarkGreen>MOSS| <green>Used moss balance!")	
    else
		  ataxiagui.bashConsole:cecho("\n<DarkGreen>MOSS| <green>Used moss balance!")		
    end
		bashMossSub = tempTimer(1, [[ bashMossSub = nil ]])
	end
	if not ataxiaBasher.manual then
		deleteFull()
	end
end
