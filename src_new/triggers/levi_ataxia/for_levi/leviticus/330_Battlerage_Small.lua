--[[mudlet
type: trigger
name: Battlerage Small
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Basher
- Bashing
- Basher Lines
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
- pattern: ^You spin and strike .+ with the back of your fist.$
  type: 1
- pattern: ^Raising your hands in the air, you summon horrific visions to torment (.+).$
  type: 1
- pattern: ^You form small chunks of ice in your enormous maw, then spit them at (.+) in a barrage.$
  type: 1
- pattern: ^You twist your wrist swiftly, slicing (.+) with a long slash of your sweeping blade.$
  type: 1
- pattern: ^You command the shadow of .+ to begin siphoning away the life of its host.$
  type: 1
- pattern: You draw upon the power of air to summon sharp gusts of wind
  type: 2
- pattern: ^You charge at (.*), slamming into (\w+) and throwing (\w+) back.$
  type: 1
- pattern: ^You point an imperious finger at .+. \w+ flesh blackens and sloughs off.$
  type: 1
- pattern: ^You manifest icicles from the vapour surrounding you, casting them in a deadly volley at (.+).$
  type: 1
- pattern: ^You crack (.+) over your head before repeatedly lashing (.+) with it.$
  type: 1
- pattern: ^You spit a stream of acidic venom at (.+) who writhes in agony as the spittle seeps into \w+ skin.$
  type: 1
- pattern: ^You quickly mix together several chemical by-products and fling the toxic mixture into .+'s face, causing \w+
    to cough and choke.$
  type: 1
- pattern: ^You charge quickly at .+, throwing your mighty form into \w+ and sending \w+ staggering back.$
  type: 1
- pattern: You give out a chittering call and
  type: 2
- pattern: A Shin-enhanced leap flings you high into the air.
  type: 2
- pattern: ^You weave a jagged blade into being and viciously hack at (.+), opening bleeding wounds.$
  type: 1
- pattern: You call down a lightning bolt to destroy
  type: 2
- pattern: ^(.+)t coughs and splutters as you channel a gout of water at \w+ face.$
  type: 1
- pattern: ^You wrap (.+) in a tight headlock and repeatedly rub your knuckles painfully across \w+ scalp.$
  type: 1
- pattern: Your angel flares its wings and flaps them powerfully
  type: 2
- pattern: ^You stare at .+, giving \w+ the evileye. \w+ limbs begin to convulse.$
  type: 1
- pattern: ^Holy fire lends strength to your arm as you bring a .+ crashing down on .+\.$
  type: 1
- pattern: Summoning forth the primal fires, you engulf
  type: 2
- pattern: ^You reach out and claw at the air, heating the body of (.+) from within.$
  type: 1
- pattern: ^You bring one of your stone fists down upon (.+) in a smashing blow.$
  type: 1
- pattern: ^Your many mouths shriek at (.+) a wrath-filled cry given ancient power.$
  type: 1
- pattern: ^Opening your dragon's mouth to its fullest, you blast (.+) with your toxic wrath, damaging his very essence\.$
  type: 1
- pattern: ^A black tendril of mist coalesces from your hand and enters (.+)'s brain, causing \w+ to flinch in pain.
  type: 1
]]--

ataxiaBasher.shielded = false
ataxiaTemp.ignoreCrits = false
bashStats.attacks = bashStats.attacks + 1

battleRage_Timers.small = tempTimer(17, [[battleRage_Timers.small = nil]])

if type(target) == "number" and ataxiaBasher.enabled then
  bashConsoleEcho("battlerage", "Used Small battlerage")
	if not ataxiaBasher.manual then
		deleteFull()
	end
end



