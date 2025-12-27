--[[mudlet
type: trigger
name: Line Deletion
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Misc Triggers
- Clean-up
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
- pattern: You are not fallen or kneeling.
  type: 3
- pattern: You are already wielding that.
  type: 3
- pattern: ^\w+ (ceases to|begins to) wield (.+) in (his|her) (left|right) hand.$
  type: 1
- pattern: ^\w+ exhales loudly.$
  type: 1
- pattern: ^\w+ inhales and begins holding \w+ breath.$
  type: 1
- pattern: You are already wielding
  type: 2
- pattern: You must regain equilibrium first.
  type: 3
- pattern: You must regain balance first.
  type: 3
- pattern: 'Alias "aSys" will now execute:'
  type: 2
- pattern: ^You have set the \'\w+\' defence to the \d+ priority.$
  type: 1
- pattern: '^\[System\]\: Queued \w+ commands cleared.$'
  type: 1
- pattern: You are not the member of any party.
  type: 3
- pattern: You lightly strike the side of yourself's head with your rapier.
  type: 3
- pattern: ^\w+ closes \w+ eyes and bows \w+ head.$
  type: 1
- pattern: ^\w+ snaps \w+ head up suddenly.$
  type: 1
- pattern: Crawling on your belly like a worm is hardly befitting behaviour. Your target is not mounted!
  type: 3
- pattern: ^You summon a blade of wind to shear at the magical shield of (.+), but find no such barrier.$
  type: 1
- pattern: You may channel the fury of battle once again.
  type: 3
- pattern: ^You glower at \w+, preparing to assault \w+ humours. You make a gesture toward \w+, grabbing at the ether strand
    binding you.$
  type: 1
- pattern: You may study the physiological composition of your subjects once again.
  type: 3
- pattern: ^(.+) charred corpse drops to the ground, blackened skin still smoking.$
  type: 1
]]--

deleteFull()

--^\[System\]\: (Prepended|Added) .+ to your (.+) queue.$