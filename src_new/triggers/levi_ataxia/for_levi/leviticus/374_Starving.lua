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
-- So: feed from the horn of plenty the moment we see a starvation state. The horn holds
-- 6 items and resets to us, so a wasted eat costs almost nothing; a missed one costs the
-- run. ataxia_hornFeed has its own 20s cooldown, so repeated lines can't spam probes.
--
-- Pattern 1 is the SCORE vitals row (confirmed verbatim from the log). The others are the
-- standing hunger warnings -- if the exact wording differs in play, add it here; the
-- mechanism is already correct.
if ataxia.settings.hornAuto == false then return end
local state = matches[2] or "starving"
if ataxia_hornFeed then
	if ataxia_hornFeed(state) and ataxia_boxEcho then
		ataxia_boxEcho("STARVING - EATING FROM HORN", "goldenrod")
	end
end
