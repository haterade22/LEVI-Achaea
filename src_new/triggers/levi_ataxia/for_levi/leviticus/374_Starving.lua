--[[mudlet
type: trigger
name: Starving
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Basher
- Bashing
- Basher Lines
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
- pattern: ^\|\s+Hunger\s+:\s+(starving to death|famished|ravenous)
  type: 1
- pattern: ^You are starving to death\.$
  type: 1
- pattern: ^You are famished\.$
  type: 1
- pattern: ^You feel absolutely famished\.$
  type: 1
]]--

-- STARVATION IS A COMBAT EMERGENCY, not a flavour message. It knocks you UNCONSCIOUS,
-- and while unconscious NOTHING in this system can help you: no curing, no flee, no
-- attack, no escape ladder. The 2026-07-29 jungle log is the proof -- pass out, then a
-- wall of "You are unconscious and thus incapable of action." while a puma, two
-- cockatrices and our own hyena took ~10k health off us.
--
-- So: feed the moment we see a starvation state. ataxia_hornOnHungry (v4.7.294) tries a
-- forced corpse-eat FIRST when Obligate Carnivore is held -- a corpse is already in the pack,
-- where a horn charge is one of six on its own refill clock -- and falls back to the horn
-- otherwise. This line used to call ataxia_hornFeed directly, which bypassed that precedence
-- entirely: Obligate Carnivore's starvation behaviour was unreachable from the only place
-- starvation is ever detected (found in review, 2026-09-03). ataxia_hornFeed keeps its own
-- 20s cooldown either way, so repeated lines can't spam probes.
--
-- Pattern 1 is the SCORE vitals row (confirmed verbatim from the log). The others are the
-- standing hunger warnings -- if the exact wording differs in play, add it here; the
-- mechanism is already correct.
--
-- THIS TRIGGER, not either helper, owns the re-fire throttle. ataxia_carnivoreEat's own cooldown
-- is deliberately BYPASSED here (force=true, since starvation must not wait on a throttle written
-- for upkeep) and the horn's 20s cooldown only covers ITS OWN branch -- so with nothing here, the
-- vitals row alone (prints every prompt while starving persists) would re-run `corpseCleanup()`
-- and re-send `ii corpse` on every single prompt for as long as starvation lasts. `starvingAt`
-- (5s, well under the vitals row's own prompt cadence but plenty for the eat to land) is a floor,
-- not a lockout: STARVING_RETRY is short specifically so a probe that finds no corpse retries soon.
local STARVING_RETRY = 5
if ataxia.settings.hornAuto == false then return end
ataxiaTemp = ataxiaTemp or {}
local nowT = (getEpoch and getEpoch()) or os.time()
if (nowT - (tonumber(ataxiaTemp.starvingRespondAt) or 0)) < STARVING_RETRY then return end
ataxiaTemp.starvingRespondAt = nowT
local state = matches[2] or "starving"
if ataxia_hornOnHungry then
	if ataxia_hornOnHungry(state) and ataxia_boxEcho then
		ataxia_boxEcho("STARVING - EATING", "goldenrod")
	end
end
