--[[mudlet
type: trigger
name: Denizen Clean-up
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Basher
- Bashing
- Basher Lines
- Denizen Attacks / Misc Lines
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
- pattern: A burly Mingruk slave whispers, "Coward."
  type: 3
- pattern: A burly Mingruk slave flinches beneath the blows.
  type: 3
- pattern: A painful rattle wheezes through a vicious gnoll soldier's lungs as he drops his battleaxe.
  type: 3
- pattern: A smirking gnoll slaver curls his lip and sneers arrogantly.
  type: 3
- pattern: A smirking gnoll slaver shudders on the ground, his head bows as he whispers, "I submit."
  type: 3
- pattern: The polearm clutched in an apathetic gnoll sentinel's hand suddenly falls before you as the sentinel whirls around.
  type: 3
- pattern: A hard-working Mingruk farmer collapses into a broken heap onto a patch of freshly tilled soil.
  type: 3
- pattern: Narrowing his eyes to thin slits, a troll dweller breathes slowly as his lips part into a sneer of pure malice.
  type: 3
- pattern: Bloodshot eyes glowering, a jester throws his head back, uttering a shrill cackle.
  type: 3
- pattern: Torn scabs around her eyelids leak blood as a blind woman furrows her brow in rage, breathing heavily between bared
    teeth.
  type: 3
- pattern: 'The blow is too much for the weakened form '
  type: 2
- pattern: Closing his eyes and shaking his head, Ulthor looks up gradually as silent, unnerving madness plays upon his features.
  type: 3
- pattern: A wicked, insane screech escapes a crawling Tsol'aa's lips as his neck bends backwards, his body shaking with fury.
  type: 3
- pattern: Stroking guardedly at her wings, a maniacal atavian glowers with rage, spitting upon the ground below her hovering
    feet.
  type: 3
- pattern: A shady dealer quickly removes a small packet, shoving the contents up his nose. Breathing deeply, he opens his
    eye and stares at you, livid with heightened energy and anger.
  type: 3
- pattern: Seething with insanity and anger, a dwarven patient tilts his head back, uttering a deep battle cry.
  type: 3
- pattern: The floor shakes slightly as a troll dweller topples over, landing upon the ground with a resounding thud.
  type: 3
- pattern: Lifeless hands release the hilt of a heavy axe as a dwarven patient drops to the ground, falling beside his clanking
    weapon.
  type: 3
- pattern: The sadistic grin painted upon this jester's face droops slightly as he frowns and falls to his feet, quivering
    in pain.
  type: 3
- pattern: Raising a blow dart to his mouth, a Qurnok warrior exhales a blast of air which quickly sends two darts into your
    chest.
  type: 3
- pattern: ^Unable to maintain cohesion, (.+)'s mutated and warped flesh sloughs off from \w+ bones as \w+ collapses to the
    ground in a twisted heap.$
  type: 1
- pattern: ^(.+) is tormented by horrific visions from the Plane of Chaos.$
  type: 1
- pattern: ^(.+) is no longer tormented by horrific visions from the Plane of Chaos.$
  type: 1
- pattern: ^(.+) grows paler as \w+ shadow grows more opaque.$
  type: 1
- pattern: ^The white-hot flames searing (.+)'s flesh flare one last time, then suddenly disappear.$
  type: 1
- pattern: 'Sharp gusts of wind whip across '
  type: 2
- pattern: ^The lightning arcs about \w+ body, bursting \w+ heart and roasting \w+ own organs inside \w+ body as \w+ quickly
    perishes.$
  type: 1
- pattern: The sharp winds tormenting
  type: 2
- pattern: A striped regasco drops low in the water, seeking a safe haven amidst the rocks.
  type: 3
- pattern: A subtle snatcher goes completely motionless, becoming very difficult to see within the currents.
  type: 3
- pattern: A striped regasco panics, darting back and forth wildly.
  type: 3
- pattern: In an attempt to thwart its attackers, a subtle snatcher swims downward and kicks up a cloud of sand, making it
    impossible to see through the murky waters.
  type: 3
- pattern: ^Blood continues to spurt out of (.+)'s eyes, ears, nose, and mouth.$
  type: 1
- pattern: ^The blood spurting from (.+) slows to a trickle.$
  type: 1
- pattern: A small squirrel continues to pester
  type: 2
- pattern: You connect!
  type: 3
- pattern: A bearded pig snorts and paws angrily at the earth.
  type: 3
- pattern: The long, wiry hairs covering a bearded pig's body bristle and stand upright.
  type: 3
- pattern: Tilting back his thickly armoured head, an armoured boalisk gives an agonising, furious roar.
  type: 3
- pattern: The body of an armoured boalisk shudders and strains in the final throes of death.
  type: 3
- pattern: The deadly arachnid releases an annoyed, unearthly screech as the ocelli mounted atop its head shiver bristly in
    agitation.
  type: 3
- pattern: A ghost bat screeches angrily at you, forcing you to clamp your hands over your ears in agony.
  type: 3
- pattern: ^.+ clutches \w+ sides and howls in pain.$
  type: 1
- pattern: With a final screech, a ghost bat ceases flapping its wings and plummets to the ground.
  type: 3
- pattern: ^(.+) continues to bleed from \w+ open wounds.$
  type: 1
- pattern: ^(.+) clutches \w+ sides and howls in pain.$
  type: 3
- pattern: ^(.+) arches \w+ back in agony as a desolating rite constricts \w+ body.$
  type: 1
- pattern: Lifting its head and letting loose one final howl, a plated fernbeast's feet collapse beneath it as it falls to
    the ground in a motionless heap.
  type: 3
- pattern: ^The white-hot flames searing .+'s flesh flare in intensity.$
  type: 1
- pattern: 'As the icy flames claw at '
  type: 2
]]--

	if not ataxiaBasher.manual then
		deleteFull()
	end
