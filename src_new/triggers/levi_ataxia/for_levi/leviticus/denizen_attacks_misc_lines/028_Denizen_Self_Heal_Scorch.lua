--[[mudlet
type: trigger
name: Denizen Self Heal Scorch
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Denizen Attacks Misc Lines
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
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
packageName: ''
patterns:
- pattern: ^Swallowing the morsel, (.+) crouches low, seeming invigorated\.$
  type: 1
]]--

-- A DENIZEN HEALING ITSELF (captured live 2026-08-12, a monstrous hellhound):
--
--     A monstrous hellhound lunges at Gavai and clamps down on his arm, shredding flesh...
--     Swallowing the morsel, a monstrous hellhound crouches low, seeming invigorated.
--
-- The SECOND line is the one worth acting on -- it is the heal itself, and SCORCH applies INHIBIT,
-- which is precisely "slows the healing process" (AB 2299). The lunge is the mob eating a party
-- member; the swallow is it getting the benefit, and the benefit is what we can take away.
--
-- Reacting to the heal rather than pre-empting the bite is deliberate. The bite names a PLAYER and
-- its wording will vary per victim, while this line names the DENIZEN and is stable -- and a mob
-- that has just healed is proven to be worth 18 rage, where one that merely bit someone is not.
-- The cost is that the first heal always lands; with a 25s cooldown that is the right trade.
--
-- Note the healer is usually NOT our current target -- in the capture it lunged at Gavai -- which
-- is exactly why this cannot ride the attack round and why ataxiaBasher_dragonScorch resolves the
-- name rather than assuming `target`.
--
-- The handler owns every gate (class, rage, the 25s cooldown, the global battlerage cooldown,
-- and "does it already have inhibit"), so this stays a one-line adapter and the logic stays
-- unit-testable. `bash scorch off` disables it.
--
-- The wording is hellhound-specific as captured, but the pattern is written around the DENIZEN
-- capture rather than the mob name, so any other denizen printing this line is covered. Other
-- self-heal wordings ("...ceases tending to his wounds") belong here too when captured.
if ataxiaBasher_dragonScorch then ataxiaBasher_dragonScorch(matches[2]) end

-- indian_red: the "this is costing us" colour, as used for lava and the danger alarms. A denizen
-- undoing our damage belongs there. NOT the orange family, which is reserved for the user.
selectString(line, 1)
fg("indian_red")
deselect()
resetFormat()
