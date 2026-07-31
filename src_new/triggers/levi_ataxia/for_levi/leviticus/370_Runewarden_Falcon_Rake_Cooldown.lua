--[[mudlet
type: trigger
name: Runewarden Falcon Rake Cooldown
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
- pattern: ^You whistle to your falcon, commanding it to assail
  type: 1
- pattern: ^You cannot yet order your falcon to rake another foe\.$
  type: 1
- pattern: ^A razor-beaked falcon dives at (?!you,)
  type: 1
- pattern: ^A razor-beaked falcon rips out a chunk of (?!your flesh)
  type: 1
]]--

-- The two LANDING lines were added in v4.7.178 (the falcon has two attack animations --
-- talon dive and beak tear). They re-arm the cooldown from the moment the rake actually
-- landed rather than from the moment we ordered it, which is the more accurate stamp;
-- re-arming is idempotent (the safety timer is killed and recreated).
--
-- The negative lookaheads matter, and they are the falcon twin of the hyena's. When the
-- pet turns on its OWNER the lines read "...dives at you, raking your face..." and
-- "...rips out a chunk of your flesh...". That is not a rake we ordered, and counting it
-- would put the rake on cooldown for a hit we never asked for. Trigger 376 handles the
-- at-you case (orders the falcon passive).
ataxiaBasher_falconRakeCooldown()

-- HIGHLIGHT the rake set so it stands out as combat scrolls (v4.7.178, user-directed --
-- "like the Infernal Hyena attack"). Mirrors trigger 367 exactly, including WHY the
-- highlight lives here rather than in its own file: these patterns already match here, and
-- a second copy would be a duplicate-pattern trap. Same three states, same three colours,
-- and deliberately NOT the orange family (reserved by the user):
--   our order        -> dark_sea_green (muted: intent, nothing has landed yet)
--   the rake landing -> chartreuse BOLD (the free damage actually happening)
--   the refusal      -> dim_grey (still on cooldown; nothing happened)
local col, bold = "chartreuse", true
if line:find("^You whistle to your falcon") then
	col, bold = "dark_sea_green", false
elseif line:find("^You cannot yet order") then
	col, bold = "dim_grey", false
end
selectString(line, 1)
if bold then setBold(true) end
fg(col)
deselect()
resetFormat()
