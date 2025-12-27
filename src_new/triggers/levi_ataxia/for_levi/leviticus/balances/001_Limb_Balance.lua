--[[mudlet
type: trigger
name: Limb Balance
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
- pattern: ^You have recovered balance on your (.+).$
  type: 1
]]--

if type(target) == "number" and ataxiaBasher.enabled then
	if not bashBalSub then
    if zgui then
      cecho("bashDisplay", "\n<yellow>BAL| <goldenrod>Got limb balance!")
    else
		  ataxiagui.bashConsole:cecho("\n<yellow>BAL| <goldenrod>Got limb balance!")		
    end
		bashBalSub = tempTimer(1, [[ bashBalSub = nil ]])
	end
	if not ataxiaBasher.manual and not autoHarvesting then
		deleteFull()
	end
end

if matches[2] == "legs" then
endBalTimer()
balanceHighlight()
tarc.write()
end