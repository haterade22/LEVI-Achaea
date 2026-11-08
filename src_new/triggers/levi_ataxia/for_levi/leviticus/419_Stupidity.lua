--[[mudlet
type: trigger
name: Stupidity
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Third Person
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
- pattern: ^(\w+) makes a strangled meowing noise and quickly shuts up, blushing\.$
  type: 1
- pattern: ^(\w+) picks (\w+) nose absently\.$
  type: 1
- pattern: ^(\w+) breaks down and sobs uncontrollably\.$
  type: 1
- pattern: ^(\w+) gets down on one knee and serenades the world\.$
  type: 1
- pattern: ^(\w+) falls to \w+ knees in worship\.$
  type: 1
- pattern: ^(\w+) hugs \w+ compassionately\.$
  type: 1
- pattern: ^(\w+) grunts a bit and then lets out a loud \"OINK\!\"$
  type: 1
- pattern: ^(\w+) waggles \w+ eyebrows comically\.$
  type: 1
- pattern: ^(\w+) wails like an old woman\.$
  type: 1
- pattern: ^"The voices! The voices! Get them out of my head!!" (\w+) moans, holding \w+ head\.$
  type: 1
- pattern: ^(\w+) fondles \w+ absently\.$
  type: 1
- pattern: ^(\w+) stumbles and pokes \w+ in the eye\.$
  type: 1
- pattern: ^(\w+) attempts to do a standing backflip, but merely stumbles over \w+ own feet\.$
  type: 1
- pattern: ^(\w+) looks around vainly for a partner to tango with\.$
  type: 1
- pattern: ^(\w+) pulls down \w+ pants and moons the world\.$
  type: 1
- pattern: ^(\w+) flaps \w+ arms madly\.$
  type: 1
- pattern: ^(\w+) giggles happily\.$
  type: 1
- pattern: ^Tears fill (\w+)'s eyes and begin to slowly run down \w+ face\.$
  type: 1
- pattern: ^(\w+) sweeps across the floor, leaping and twirling like a true master\.$
  type: 1
- pattern: ^You cast a net of stupidity over (\w+)'s mind\.$
  type: 1
- pattern: ^(\w+) twitches spasmodically\.$
  type: 1
- pattern: ^With a gravity, \w+ sings the Passion of Imithia at (\w+).$
  type: 1
]]--

-- Every pattern captures the target's name first. The voices line was "^(\w+) moans, holding his
-- head", which the game's line (it starts with the quote, and says her for a woman) never matched.
-- It and the nine lines after it in the header were added in the 2026-11-08 deep review (F47),
-- copied from the logs: kb/raw/logs/ours/2026-11-07_164635_Saibel.log:1752 (voices), 1763 (fondles),
-- 1812 (pokes); kb/raw/logs/2026-11-01_nikita_depthswalker-vs-serpent_win_X8pRorzR.txt:1498 (moons),
-- 1502 (tango), 4626 (flaps), 5754 (giggles), 5794 (tears), 5931 (twirling); and
-- kb/raw/logs/2026-10-11_runewarden-snb-vs-shikudo_defender.txt:1798 (backflip). Seven of them are
-- stupidity in the first person (kb/combat/fights/2026-10-11_mystor_shikudo-vs-apostate_win_LcJC-rJ5.md);
-- fondles, moons and tango come in among those in the same fights (defender.txt:1745-1874).
if isTargeted(matches[2]) then
	tarAffed("stupidity")

	-- V3 integration: collapse branches (proves stupidity present)
	if onTargetStupidActionV3 then onTargetStupidActionV3() end
end