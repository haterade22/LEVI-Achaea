--[[mudlet
type: trigger
name: Hyena Too Far
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
- pattern: ^Your hyena is too far away for you to command like that\.$
  type: 1
]]--

-- The pet has wandered out of command range, so every maul from here on is a no-op until
-- she is back. Recall her and set her to follow so it does not happen again this room
-- (user-directed response).
--
-- This line ALSO means the maul never fired -- so release the cooldown we optimistically
-- armed from our own "You command your hyena to maul..." line (trigger 367). Without this
-- a single out-of-range order would cost a full 30s of maul uptime for nothing.
if not ataxiaTemp.hyenaRecallAt or (getEpoch() - ataxiaTemp.hyenaRecallAt) > 10 then
	ataxiaTemp.hyenaRecallAt = getEpoch()
	send("hyena recall" .. (ataxia.settings.separator or ";") .. "order hyena follow me", false)
	if ataxiaBasher_hyenaMaulReady then ataxiaBasher_hyenaMaulReady() end
	if ataxiaEcho then
		ataxiaEcho("Hyena out of range -- <green>recalled<reset> and set to follow (maul cooldown released).")
	end
end
