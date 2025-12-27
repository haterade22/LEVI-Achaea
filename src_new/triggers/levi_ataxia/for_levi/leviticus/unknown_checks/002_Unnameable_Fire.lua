--[[mudlet
type: trigger
name: Unnameable Fire
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Curing Stuff
- Unknown Checks
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
- pattern: ^You realise with horror that the eldritch utterence has caused (\d+) \w+ to descend upon you.$
  type: 1
]]--

local unn = {
	"stupidity",
	"confusion",
	"dementia",
}
for i=1, tonumber(matches[2]) do
	send("curing predict "..unn[i],false)
	cecho("\n<red> + + <yellow>"..unn[i]:upper().."<red> + +")
	ataxia.afflictions[unn[i]] = true
end