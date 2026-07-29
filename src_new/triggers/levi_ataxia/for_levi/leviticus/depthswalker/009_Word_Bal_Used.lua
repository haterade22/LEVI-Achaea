--[[mudlet
type: trigger
name: Word Bal Used
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Class Stuff
- Depthswalker
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
- pattern: ^Imbuing your voice with power, you intone, "(.+)".$
  type: 1
- pattern: ^Taking a steadying breath, you turn your focus inward and proclaim, "(.+)"\.$
  type: 1
]]--

-- TWO wordings, ONE balance (live capture 2026-07-29). Outward-facing words print
-- "Imbuing your voice with power, you intone, ..."; self-buffs from the Augmentation
-- tree print "Taking a steadying breath, you turn your focus inward and proclaim, ...".
-- The second form was previously unmatched, so `wordBal` stayed TRUE after e.g. Mainaas
-- and the next word would be sent into a balance we didn't have. It IS the same balance:
-- Mainaas proclaimed at 12:15:06.4 and "You may intone another word of power." printed at
-- 12:15:12.5 -- 6.1s, matching Mainaas's 6.50s word balance.

if matches[2] ~= "Thir" then
	ataxiaTables.depthswalker.wordBal = false
end

-- NAKAIL is the Depthswalker shield-break, and it has NO fire-line of its own anywhere
-- in the game text we've captured -- this intone echo is the one line guaranteed to
-- print. Without clearing the flag here the shielded round (which deliberately emits no
-- battlerage) never runs 330/331/332, so `ataxiaBasher.shielded` stayed true forever and
-- nakail re-fired every round, burning 17 rage AND the word balance. v4.7.142.
if matches[2]:lower() == "nakail" and ataxiaBasher and ataxiaBasher.enabled
   and type(target) == "number" then
	ataxiaBasher.shielded = false
	if ataxiaBasher_dsClearAff then ataxiaBasher_dsClearAff(target, "shielded") end
	if ataxiaBasher_dsAlert then
		ataxiaBasher_dsAlert("NAKAIL on "..tostring(target).." -- shield stripped", "orange")
	end
end