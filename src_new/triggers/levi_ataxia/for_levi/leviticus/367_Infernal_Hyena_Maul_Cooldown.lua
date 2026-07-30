--[[mudlet
type: trigger
name: Infernal Hyena Maul Cooldown
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Basher
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
- pattern: ^A daemonic hyena lets loose a woo?ping cackle as she lunges at
  type: 1
- pattern: ^You cannot yet order your hyena to maul another foe\.$
  type: 1
- pattern: ^A daemonic hyena snarls as she hurls herself at (?!you,)
  type: 1
- pattern: ^You command your hyena to maul (.+)\.$
  type: 1
]]--

-- The negative lookahead matters: when the pet turns on its OWNER the line reads
-- "...hurls herself at you, raking her claws across your face." That is not a maul, and
-- counting it as one put the maul on cooldown for a hit we never ordered. Trigger 372
-- handles the at-you case (orders her passive).
ataxiaBasher_hyenaMaulCooldown()

-- HIGHLIGHT the maul pair so it stands out as combat scrolls (v4.7.154). The highlight
-- lives here rather than in its own trigger because these exact patterns already match
-- here -- a second copy would be a duplicate-pattern trap. Three states, three colours,
-- and deliberately NOT the orange family (reserved by the user for something else):
--   our order        -> dark_sea_green (muted: intent, nothing has landed yet)
--   the maul landing -> chartreuse BOLD (the free damage actually happening)
--   the refusal      -> dim_grey (still on cooldown; nothing happened)
local col, bold = "chartreuse", true
if line:find("^You command your hyena") then
	col, bold = "dark_sea_green", false
elseif line:find("^You cannot yet order") then
	col, bold = "dim_grey", false
end
selectString(line, 1)
if bold then setBold(true) end
fg(col)
deselect()
resetFormat()