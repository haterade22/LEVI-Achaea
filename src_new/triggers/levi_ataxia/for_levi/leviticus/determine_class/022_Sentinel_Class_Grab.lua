--[[mudlet
type: trigger
name: Sentinel Class Grab
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Curing Stuff
- Priority Management
- Determine Class
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
- pattern: ^(\w+) hurls .+ axe at you
  type: 1
- pattern: ^(\w+) commands \w+ (?:spider|wolf|hawk|bear) to attack you
  type: 1
- pattern: ^(\w+) strikes you with a quick skirmishing blow
  type: 1
- pattern: ^(\w+) cocks back \w+ arm and throws .+ at your
  type: 1
- pattern: ^(\w+) lays open your flesh with an expert lateral slice
  type: 1
- pattern: ^Turning with the motion of \w+ strike, (\w+) comes back around to slam
  type: 1
- pattern: ^(\w+) swiftly sweeps your feet out from beneath you with
  type: 1
- pattern: ^(\w+) savagely gouges into you with
  type: 1
- pattern: ^(\w+) viciously lacerates you with
  type: 1
- pattern: ^Agony radiates out from the point of impact as (\w+) brings the haft of
  type: 1
- pattern: ^(\w+) thrusts \w+ blade angrily towards you, but you dodge
  type: 1
]]--

-- v4.7.275 -- the 2026-08-19 Grulk log: this signature recognised 4 of his 51 attacks (8%).
--
-- The throw pattern was `throws .+ axe at your`, which needs the literal " axe at your". His
-- line reads "...throws a claw-etched handaxe of steel and ash AT YOUR left leg" -- the material
-- suffix comes after the noun, so it never matched. 44 throws, zero detections. Anchored on the
-- distinctive "cocks back <his> arm and throws" phrasing instead, with "at your" keeping it off
-- the denizen-directed variant ("...throws ... at a massive jade spider").
--
-- The five Stormspear/Skirmishing lines below were absent entirely -- including the haft crush
-- that KILLED us. They are anchored on the ability phrasing, not the weapon name, so a plain
-- spear reads the same as an artefact one.
--
-- Consequence of the miss: classDetect.combatTimeoutSeconds kept expiring mid-fight, so the
-- `sentinel` curingset was switched in and reset to `normal` three times in 123 seconds, each
-- reset also wiping every defence priority while we were locked. And it self-reinforced --
-- "combat ended" partly because we had stopped attacking.
classDetect.setAttackerClass(matches[2], "Sentinel")
