--[[mudlet
type: trigger
name: Get Humour Levels
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes A-J
- Alchemist
attributes:
  isActive: 'no'
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
mStayOpen: 20
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^Looking over \w+, you see that:$
  type: 1
]]--

deleteLine()
cecho("\n<a_blue> --- [ <NavajoWhite>EVALUATE: <a_green>"..target:upper().."<a_blue> ] ---")
tEval = {
	sanguine = 0, choleric = 0, phlegmatic = 0, melancholic = 0,
	hp = 0, mp = 0,
}

tAffs.sanguine = nil
tAffs.melancholic = nil
tAffs.phlegmatic = nil
tAffs.choleric = nil