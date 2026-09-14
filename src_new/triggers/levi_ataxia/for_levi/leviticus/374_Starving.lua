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
- pattern: ^\|\s+Hunger\s+:\s+(.+?)(?:\s{2,}|\s*$)
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
-- PATTERN 1 IS THE WHOLE SCORE HUNGER ROW (widened in v4.7.303). It used to match only the
-- three emergency states; it now captures WHATEVER the row says -- the text up to the column
-- gap before "Sobriety" -- and hands it to `ataxia_hungerSeen`, which owns the decision:
-- emergency states feed at once (corpse first with Obligate Carnivore, else the horn), any
-- other state below "utterly satiated" is Healing Metabolism upkeep, and "utterly satiated"
-- closes an upkeep episode. The classification lives in the SCRIPT, not here, because a guard
-- inside a trigger is a guard the test suite cannot see (v4.7.260).
--
-- Patterns 2-4 are the standing hunger warnings -- always an emergency. If the exact wording
-- differs in play, add it here; the mechanism is already correct. The 5s re-fire throttle
-- moved into `ataxia_hornOnHungry` in v4.7.303 so a SCORE reading is never swallowed by it.
if ataxia.settings.hornAuto == false then return end
local outcome
if matches[2] then
	outcome = ataxia_hungerSeen and ataxia_hungerSeen(matches[2])
else
	outcome = ataxia_hornOnHungry and ataxia_hornOnHungry("starving") and "emergency"
end
if outcome == "emergency" and ataxia_boxEcho then
	ataxia_boxEcho("STARVING - EATING", "goldenrod")
end
