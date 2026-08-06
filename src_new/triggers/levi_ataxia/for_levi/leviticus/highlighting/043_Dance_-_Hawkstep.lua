--[[mudlet
type: trigger
name: Dance - Hawkstep
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Highlighting
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
- pattern: ^Spiral steps bleed into a perfect staccato as for the briefest moment you move in a harrying hawkstep\.$
  type: 1
]]--

-- BLADEDANCE FIRE LINE (HAWKSTEP). User, 2026-08-06: highlight and echo these.
--
-- These lines are worth more than a highlight and the code says so. `ataxiaBasher_bardDance`
-- refuses to re-buy a dance it believes is already up (`ataxia.defences[def]`), and
-- `004_Defence_Sorting` records that hawkstep/wavedance have never been seen in a live DEF
-- capture -- so nothing was reliably SETTING that flag. This is the confirmation, so it sets
-- it, which is the established convention: an owned rotation needs a fire line, and a fire
-- line should feed the state its gate reads.
--
-- The three dances are MUTUALLY EXCLUSIVE (AB: "you can only dance one thing at a time, so
-- the hawkstep is exclusive with the dance of the harrying"), so landing one CLEARS the other
-- two. Without that, the first dance of a session would leave its flag set forever and the
-- gate would refuse the dance we actually want for the rest of the run.
--
-- Colour from 007_Custom_Colour_Table, verified present: this package WHOLESALE REPLACES
-- Mudlet's table, so a plausible-but-absent name makes fg() throw on every matching line.
-- Not the orange family (reserved for the user).
if ataxia and ataxia.defences then
  ataxia.defences.hawkstep = true
  ataxia.defences.harrying = nil
  ataxia.defences.wavedance = nil
end

selectString(line, 1)
setBold(true)
fg("deep_sky_blue")
deselect()
resetFormat()
ataxiaEcho("<deep_sky_blue>HAWKSTEP<reset> -- dancing.")
