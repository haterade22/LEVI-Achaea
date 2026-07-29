--[[mudlet
type: trigger
name: Hyena Turned On Us
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
- pattern: ^A daemonic hyena snarls as she hurls herself at you,
  type: 1
]]--

-- OUR OWN PET IS ATTACKING US (live 2026-07-29). The daemonic hyena turns on its owner
-- after being attacked -- which the basher was doing, because "a daemonic hyena" was not
-- in ataxiaBasher.ownDenizens and so became a legitimate target (seen at 4% on the mob
-- bar). The list is fixed, but a hyena that has ALREADY flipped keeps clawing, so order
-- her down: PASSIVE stops her attacking anything, including us.
--
-- Note the trailing ", " in the pattern: the maul line for a real foe opens identically
-- ("...hurls herself at a royal guard...") and is handled by trigger 367; only the
-- second-person form ends with "at you,".
if ataxiaBasher and ataxiaBasher.enabled then
	if not ataxiaTemp.hyenaPassiveAt or (getEpoch() - ataxiaTemp.hyenaPassiveAt) > 10 then
		ataxiaTemp.hyenaPassiveAt = getEpoch()
		send("order hyena passive", false)
		if ataxiaEcho then
			ataxiaEcho("<red>Your hyena is attacking YOU<reset> -- ordered passive. "
				.. "(She is on the own-denizen list now, so the basher will not target her.)")
		end
	end
end
