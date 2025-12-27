--[[mudlet
type: trigger
name: Sip Used
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
- pattern: ^You take a drink from .+ vial.$
  type: 1
- pattern: The elixir heals and soothes you.
  type: 3
- pattern: Your mind feels stronger and more alert.
  type: 3
]]--

if type(target) == "number" and ataxiaBasher.enabled then
	if not bashElixirSub then
   if zgui then
      cecho("bashDisplay", "\n<purple>SIP| <violet>Used sip balance!")	
    else   
		  ataxiagui.bashConsole:cecho("\n<purple>SIP| <violet>Used sip balance!")		
    end
		bashElixirSub = tempTimer(1, [[ bashElixirSub = nil ]])
	end
	if not ataxiaBasher.manual then
		deleteFull()
	end
end

ataxia.vitals.sipbal = false