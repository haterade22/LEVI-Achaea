--[[mudlet
type: trigger
name: Sip Gained
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
- pattern: You may drink another health or mana elixir.
  type: 3
]]--

if type(target) == "number" and ataxiaBasher.enabled then
  if zgui then
    cecho("bashDisplay", "\n<violet>SIP| <purple>Gained sip balance!")
  else
    ataxiagui.bashConsole:cecho("\n<violet>SIP| <purple>Gained sip balance!")		
  end
	if not ataxiaBasher.manual then
		deleteFull()
	end
end
ataxia.vitals.sipbal = true

if ataxia.afflictions.kkractlebrand or ataxia.afflictions.latched then
send("sip health")
end