--[[mudlet
type: trigger
name: Proned
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Third Person
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
- pattern: ^A guardian angel extends a hand in the direction of (\w+), and \w+ is suddenly sent sprawling to the ground by
    an invisible force.$
  type: 1
- pattern: ^The shadow of (\w+) springs into action, violently lashing out at its corporial twin and driving \w+ to \w+ knees.$
  type: 1
- pattern: ^(\w+) closes \w+ eyes, curls up into a ball and falls asleep.$
  type: 1
- pattern: ^\w+ raises \w+ trunk into the air and trumpets mightily, knocking (\w+) to the ground.$
  type: 1
- pattern: ^\w+ tramples over (\w+) with \w+ enormous body.$
  type: 1
- pattern: ^With a synchronous, guttural rasp, \w+'s many serpentine heads breathe forth wisps of rapidly condensing smoke
    that entangle (\w+) in a tangible web.$
  type: 1
- pattern: ^A mighty, bestial roar from \w+ leaves (\w+) looking dazed.$
  type: 1
- pattern: ^The staff sweeps the legs out from under (\w+), sending \w+ sprawling.$
  type: 1
- pattern: ^(\w+) slips on a thin layer of fluid, \w+ feet flying out from under \w+.$
  type: 1
- pattern: ^Water thunders down upon (\w+), driving \w+ relentlessly to \w+ knees.$
  type: 1
- pattern: ^Drawing an enormous breath, you exhale, expelling a gale of wind with such force that (\w+) is knocked over.$
  type: 1
- pattern: ^The shadow of (\w+) springs into action, violently lashing out at its corporeal twin and driving \w+ to \w+ knees.
  type: 1
- pattern: ^A gust of wind strikes (\w+), throwing (\w+) to the ground.$
  type: 1
- pattern: ^(\w+) is flung violently from \w+ feet.$
  type: 1
- pattern: ^You lunge downward, slamming the edge of .+ into the shins of (\w+).$
  type: 1
- pattern: ^The power of your blow sweeps the legs out from under (\w+).$
  type: 1
- pattern: ^Sweeping out with a blade hand, you strike at the back of (\w+)'s knee.$
  type: 1
- pattern: ^You knock the legs out from under (\w+) and send \w+ sprawling.$
  type: 1
- pattern: ^\w+ delivers a series of lashes to (\w+) with a translucent lash.$
  type: 1
- pattern: ^(\w+)'s eyes close suddenly as \w+ falls asleep.$
  type: 1
- pattern: ^As your blow cuts deeply into the leg of (\w+), you drive savagely forward, taking \w+ clean off\w+ feet\.$
  type: 1
]]--

if isTargeted(matches[2]) then
	tAffs.prone = true
	tAffs.shield = false
	selectString(line,1)
	setBold(true)
	fg("violet")
	resetFormat()
  tarAffed("prone")
  confirmAffV2("prone")
  applyAffV3("prone")
end

