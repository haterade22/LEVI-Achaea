--[[mudlet
type: trigger
name: Sipped Something
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
- pattern: ^(\w+) takes a drink from (.+).$
  type: 1
]]--

if isTargeted(matches[2]) then
tdeliverance = false
  if passiveFailsafe then restorePassiveCure() end
	erAff("anorexia")

	-- A sip cures voyria, except while Latency holds the target: no immunity cure works then
	-- (about 13 s, kb Pestilence.wiki; misc/005_Latency keeps pariah.state.latencyTimer for 12 s).
	-- A second, unguarded erase used to follow this one, so the guard never held and the Pariah
	-- route re-sent voyria it had already given (2026-11-08 deep review, F18). Nil-safe like the
	-- passives' voyriaBlock: with no pariah table a sip still erases.
	if haveAff("voyria") and not (pariah and pariah.state and pariah.state.latencyTimer) then
		erAff("voyria")
	end

	if haveAff("nospeed") then
		tempTimer(3, [[ erAff("nospeed") ]])
	end
  
  if ataxiaTemp.lastAssess then ataxiaTemp.lastAssess = ataxiaTemp.lastAssess + 21 end
  
	targetIshere = true
  -- 2H Runewarden: a sip means health over fracture cures -> stack with PRECISION (v4.7.465).
  if rw2h and rw2h.onTargetSipped then rw2h.onTargetSipped() end
end