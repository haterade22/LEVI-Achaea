--[[mudlet
type: trigger
name: Smoked
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Remove Afflictions
- Groups
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
- pattern: 'A great gurgling sound is heard as (\w+) takes a long drag '
  type: 1
- pattern: ^(\w+) takes a .+ pipe.$
  type: 1
- pattern: ^(\w+) takes a few short puffs from \w+ pipe.$
  type: 1
]]--

if isTargeted(matches[2]) then
tdeliverance = false
  if passiveFailsafe then restorePassiveCure() end

	-- Kill disambiguation timer - smoke proves asthma is cured
	if kelpDisambiguateTimer then killTimer(kelpDisambiguateTimer); kelpDisambiguateTimer = nil end

	-- Smoking proves asthma was cured (they couldn't smoke with asthma)
	erAff("asthma")

	-- If we had uncertain kelp afflictions, now we know: asthma was cured
	-- Keep other kelp affs (they weren't cured)
	if lastKelpAffs then
		lastKelpAffs = nil
		ataxiaEcho("Smoke confirmed: asthma cured, other kelp affs still present.")
	end

	-- Legacy backtrack support
	if lastKelp and lastKelp ~= "asthma" then
		tAffs[lastKelp] = true
		lastKelp = nil
		ataxiaEcho("Backtracked asthma being cured with last eat.")
	elseif lastKelp and lastKelp == "asthma" then
		lastKelp = nil
	end

	local sAffs = {"aeon", "deadening", "tension",
		"disloyalty","manaleech", "slickness", "unweavingspirit"}


	if haveAff("hellsight") and not haveAff("inquisition") then
		erAff("hellsight")		
	else	
		for i=1, #sAffs do
			if tAffs[sAffs[i]] then
				erAff(sAffs[i])
				break
			end
		end	
	end
	
	if ataxiaTemp.snapTimer then killTimer(ataxiaTemp.snapTimer); ataxiaTemp.snapTimer = nil end
	
	targetIshere = true
end