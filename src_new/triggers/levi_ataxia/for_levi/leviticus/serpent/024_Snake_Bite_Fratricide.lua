--[[mudlet
type: trigger
name: Snake Bite Fratricide
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes K-S
- Serpent
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
- pattern: ^An? [\w' -]+ sinks its fangs into the neck of (\w+), injecting a potent dose of toxin\.$
  type: 1
]]--

-- A SERPENT'S PET SNAKE BITES SOMEONE: the bitten person gets fratricide.
--
--   A death adder sinks its fangs into the neck of Xylarys, injecting a potent dose of toxin.
--     (kb/raw/logs/ours/2026-11-03_081009_Froedine.log:2009, and 18 more rows in our logs)
--   A small grey-brown rattlesnake sinks its fangs into the neck of Valkael, injecting a potent dose of toxin.
--     (kb/raw/logs/2026-10-19_tabethys_magi-group_kalys_o6UKnyyy.txt:218-219, wrapped at the
--      old screen width)
--
-- On the victim's own seat the same bite reads "... sinks its fangs into your neck and injects a
-- potent dose of toxin" and is followed by "You have been afflicted with fratricide."
-- (kb/raw/logs/2026-11-01_nikita_depthswalker-vs-serpent_win_X8pRorzR.txt:235-237); all 46 fratricide
-- gains in the four Serpent victim logs come within three rows of a bite (.claude/classes/serpent.md,
-- "Three sources of relapsing effects"). The snake differs per Serpent (death adder, rattlesnake,
-- emerald tree snake, saw-scaled viper), so the name is not fixed here.
--
-- Until this trigger only a snap after the fratricide suggestion recorded fratricide (serpent/002,
-- onSnapped), so the offense's fratricide reads (impatienceConditionsMet, focusLockReady and the
-- relapse window in selectImpulse) missed the one our `order adder kill` gives every few seconds.
-- Any snake counts, ours or another Serpent's: the bitten target has fratricide either way. The
-- fang-barrier refusal is another line and gives nothing (706_Flayed_Sileris):
--   A death adder lunges for the throat of Xylarys, fangs sinking into his fang barrier defence.
--     (kb/raw/logs/ours/2026-11-03_081009_Froedine.log:897)
if isTargeted(matches[2]) then
    tarAffed("fratricide")
end
