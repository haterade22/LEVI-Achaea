--[[mudlet
type: trigger
name: Battlerage Large
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
- pattern: ^You leap and spin in the air, striking .+ repeatedly with an outstretched foot.
  type: 1
- pattern: ^You cup your hands together and fling them outwards, sending a spiral of shimmering portals into (.+)'s body.$
  type: 1
- pattern: You barrel into (.+) and knock \w+ to the ground before stomping over \w+ prone form.
  type: 1
- pattern: ^You use your powerful voice to distract (.+) with a ululating howl before stepping in with a vicious slash.$
  type: 1
- pattern: ^You summon whips of shadow to viciously lash the form of .+.$
  type: 1
- pattern: ^At your command, (.+) stomps over to (.+) and wraps \w+ in a tight embrace, squeezing the life from \w+.$
  type: 1
- pattern: ^You unleash a ferocious onslaught on (.*), relentlessly pounding (\w+) with (.*).$
  type: 1
- pattern: ^You point an imperious finger at (.+). Blood spurts out of (.+)'s eyes, ears, nose, and mouth.$
  type: 1
- pattern: ^You call down a rain of needle-sharp spears of ice, sending them plunging into the body of (.+).$
  type: 1
- pattern: ^You leap upon (.+) and sink your fangs into (her|his) throat before leaping away, blood gushing from the horrific
    wound.$
  type: 1
- pattern: ^You sketch out the symbol for magnesium and direct the energy to sear .+'s flesh.$
  type: 1
- pattern: ^You open your cavernous maw and summon a blast of lightning to pulverize (.+).$
  type: 1
- pattern: 'You twist in a tight circle, slashing '
  type: 2
- pattern: ^You burst into motion, blades materialising in your hands as you deliver a relentless flurry of blows against
    (.+).$
  type: 1
- pattern: 'You send a crushing wave of pressurised air '
  type: 2
- pattern: ^You summon a great vine to wrap itself around (.+), then channel the element of earth into it, causing it to become
    rock hard and shatter as it constricts around \w+.$
  type: 1
- pattern: 'You discreetly secret a lit firecracker to '
  type: 2
- pattern: Praying to the Gods, you lay a desolating rite on
  type: 2
- pattern: ^You perform a holy rite and bind it to .+ soul, creating a conduit for holy lightning to strike down upon \w+\.$
  type: 1
- pattern: You call forth a raging firestorm to destroy
  type: 2
- pattern: ^You breathe a long torrent of flame at (.+)\, igniting \w+ skin.$
  type: 1
- pattern: ^You level your draconic gaze at (.+)\, assaulting \w+ with psychic waves of force.$
  type: 1
- pattern: ^You croon to the myriad minds that surround you, and send them to feast upon (.+) in a wave of chittering hunger.$
  type: 1
- pattern: ^Imbuing your form with the might of earth, you launch a terrible assault upon (.+)\, raining blow after blow down
    upon him with your empowered fists.$
  type: 1
- pattern: You leap high into the air,
  type: 2
- pattern: ^You lash out with power and will, your only task to crush the light from the wretched (.+)\.$
  type: 1
- pattern: ^You raise a clenched fist and in obedience the earth rises in turn, a great hand of stone unfurling to clamp about
    (.+) in a vice-like squeeze\.$
  type: 1
- pattern: ^You point at (.+) and your daegger flies towards \w+, burrowing into \w+ body and emerging out the other side\.$
  type: 1
- pattern: ^You leap upon .+, forming putrid spikes on your armour that tear into \w+ flesh\.$
  type: 1
]]--

ataxiaBasher.shielded = false
ataxiaTemp.ignoreCrits = false
bashStats.attacks = bashStats.attacks + 1

battleRage_Timers.large = tempTimer(24, [[battleRage_Timers.large = nil]])

if type(target) == "number" and ataxiaBasher.enabled then
	bashConsoleEcho("battlerage", "Used hard-hitting battlerage")
	if not ataxiaBasher.manual then
		deleteFull()
	end
end

