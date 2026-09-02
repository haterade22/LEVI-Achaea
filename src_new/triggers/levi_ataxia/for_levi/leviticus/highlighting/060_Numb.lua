--[[mudlet
type: trigger
name: Numbness Raised
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
- pattern: ^You grit your teeth and will your pain out of existence\.$
  type: 1
]]--

-- NUMB IS UP (AB Numbness, Kaido 894 -- self, 3.00s equilibrium).
--
-- The line has been NAMED in this package since v4.7.124 -- `basher/002_Class_Bashing.lua:2227`
-- quotes it verbatim in the Senseless Flurry comment -- and never captured, so it scrolled past
-- unmarked in every log. A line documented but not wired is indistinguishable from one we never
-- saw (the v4.7.260 `realExits` lesson: dead output reads exactly like a missing feature).
--
-- Worth seeing on sight because NUMB CHANGES WHAT THE HP NUMBER MEANS. It defers 40% of incoming
-- damage into one later blow, so while it is up the prompt stops tracking how the fight is going
-- -- which is why `ataxiaBasher_senselessFlurryNumb` is CROWD-GATED (review HIGH): the rate
-- watchdog, the danger levels and the escape ladder are all HP-threshold machines and numb blinds
-- every one of them until the lump lands. Knowing exactly when that window opened is the point.
--
-- `turquoise`, bold: bright as asked, cold like the effect, and -- checked against the whole
-- `highlighting/` folder -- the one bright colour there carrying no competing meaning already.
-- Verified present in `007_Custom_Colour_Table.lua`, which WHOLESALE REPLACES Mudlet's palette,
-- so a plausible-but-absent name would throw at render time rather than at build.
--
-- HIGHLIGHT ONLY, deliberately. This is also the ability's true CONFIRMATION, and it is tempting
-- to hang the Senseless Flurry attempt-hold off it -- but that hold exists to cover GMCP lag on
-- `ataxia.defences.numbness`, and the defence flag is what actually stops the refresh. Clearing
-- the hold here would only let us re-numb sooner, which is the opposite of what it guards.
selectString(line, 1)
fg("turquoise")
setBold(true)
deselect()
resetFormat()
