--[[mudlet
type: trigger
name: Gallowshumour Highlight
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
- pattern: With a sinister grin, you launch into a brutal routine of macabre slapstick
  type: 2
- pattern: '^.{0,80}with bone-rattling blows and grim quips\.$'
  type: 1
- pattern: ^bone-rattling blows and grim quips\.$
  type: 1
- pattern: ^rattling blows and grim quips\.$
  type: 1
- pattern: ^blows and grim quips\.$
  type: 1
- pattern: ^and grim quips\.$
  type: 1
- pattern: ^grim quips\.$
  type: 1
]]--

-- OUR GALLOWSHUMOUR (v4.7.385, user: "Same thing with this"), the Jester basher's swing below 50%
-- target health (AB 2680):
--
--   With a sinister grin, you launch into a brutal routine of macabre slapstick, pummelling the
--   tragically stoic a dream horror with bone-rattling blows and grim quips.
--
-- ~150 characters, so it ALWAYS wraps (this user's server width is 119-124). The first row is
-- matched by its opening phrase; the second by one anchored pattern per place the break can land.
-- `chartreuse` bold, as for the Serpent bite (068). Highlight only.
selectString(line, 1)
fg("chartreuse")
setBold(true)
deselect()
resetFormat()
