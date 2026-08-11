--[[mudlet
type: trigger
name: Cleave Splash
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
- pattern: ^Your vicious attack cleaves to a nearby enemy\.$
  type: 1
]]--

-- The HAMMER AND NAIL splash landing (captured live 2026-08-11). The boon reads "While a
-- sowulu rune is present, your attacks will cause damage to another random denizen in the
-- location", and this is that second denizen being hit -- the proof the rune is actually
-- paying for the round `ataxiaBasher_rwSowulu` spent sketching it.
--
-- Worth seeing precisely because it is the only feedback that the rune is working: sowulu is
-- sketched once per room and then never mentioned again, so without this line a rune that
-- failed to land looks identical to one that is splashing every swing.
--
-- CHARTREUSE BOLD -- the established "damage actually happening" colour in this package
-- (hyena maul and falcon rake landings 367/370, the bisect Thunderclap swing 035, Arc 046).
-- This is our own damage reaching a second target, so it belongs in that family rather than
-- with the affliction-proc colours.
selectString(line, 1)
setBold(true)
fg("chartreuse")
deselect()
resetFormat()
