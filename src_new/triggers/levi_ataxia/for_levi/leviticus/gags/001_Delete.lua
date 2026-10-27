--[[mudlet
type: trigger
name: Delete
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- MONK 1
- Monk
- Shikudo Triggers
- Shikudo
- Gags
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
- pattern: ^Taking a firm hold of .+ you whip it in a wide sweep
  type: 1
- pattern: ^You whip .+ at \w+ in a controlled arc
  type: 1
- pattern: ^With pinpoint precision, you drive .+ at the throat
  type: 1
- pattern: ^Lunging forward, you drive the end of .+ viciously
  type: 1
- pattern: ^Stepping to the side of \w+, you drive .+ at (his|her)
  type: 1
- pattern: ^Stepping forward, you drive .+ at the face of
  type: 1
- pattern: ^You spin a full rotation, bringing .+ around
  type: 1
- pattern: ^Whirling .+ in a tight arc, you bring
  type: 1
- pattern: ^Bracing your back foot, you lunge forward with .+ at the
  type: 1
- pattern: ^Snapping back into a ready stance, you whirl .+ in a long
  type: 1
- pattern: ^You lash out with a straight kick at the shoulder of (\w+)\.$
  type: 1
]]--
-- Our own staff strike lines, gagged. v4.7.420: each pattern is an EARLY FRAGMENT with any staff
-- (`.+`), not a whole line naming "a twisted oaken staff". The strike line carries the staff's name
-- and runs to 147 columns, so the server wraps it (119-124 for this user); the ruku-arm line is 121
-- columns with that staff, so its whole-line pattern never matched. One fragment now covers ruku's
-- arm and torso lines in each wording ("controlled arc", "full rotation"); the old list gagged only
-- the arm in the second. Lines: attacker log :2455, :1807, :1732, :774, :955, :951; the first-strike
-- wordings of needle, jinzuku, hiraku and hiru are the ones our strike triggers 564/566/178/575 use.

-- PvP only. The old patterns ended in a one-word name, so a denizen ("...at the legs of a black
-- bear.") never matched them; the fragments end before the name, so without this they gag our
-- strikes while bashing too (v4.7.420 review). PvE as the basher's triggers 337/338 tell it: a
-- numeric target, or the basher on.
if type(target) ~= "string" or (ataxiaBasher and ataxiaBasher.enabled) then return end
-- With the [SK] combo line on (shikudo/012, v4.7.456) our strikes stay on screen: the user wants
-- to SEE them ("so I can actually see if we are hitting someone"), and a deleted strike row moved
-- the affliction tags of the rows below it onto the wrong line. `skecho off` gags them again.
if shikudoEcho and shikudoEcho.enabled and shikudoEcho.enabled() then return end

deleteFull()
-- A row that does not finish its sentence was wrapped: gag the next row too, or its tail is left
-- alone on screen (the idiom of highlighting/071).
if not line:match("%.%s*$") then
  tempLineTrigger(1, 1, function() deleteLine() end)
end