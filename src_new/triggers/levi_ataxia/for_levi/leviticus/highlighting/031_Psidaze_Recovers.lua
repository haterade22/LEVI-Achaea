--[[mudlet
type: trigger
name: Psidaze Recovers
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
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
- pattern: ^Sparkles of psi energy cease their distracting dance around (.+)'s vision\.$
  type: 1
]]--

-- Golden Dragon Psidaze WORE OFF (live capture 2026-07-28): the denizen's amnesia
-- ended. Muted highlight so the control drop still reads, plus a one-line uptime
-- measurement -- the landed confirmation (trigger 028) stamped gdragonBrAt.psidaze,
-- so the delta here is the REAL amnesia duration vs the 41s cooldown (the wishlist
-- question: does control coverage have a gap?).
selectString(line,1)
fg("dim_grey")
deselect()
resetFormat()

if ataxiaTemp and ataxiaTemp.gdragonBrAt and ataxiaTemp.gdragonBrAt.psidaze then
	local dur = (((getEpoch and getEpoch()) or os.time()) - ataxiaTemp.gdragonBrAt.psidaze)
	if dur > 0 and dur < 120 and ataxiaEcho then
		ataxiaEcho("Psidaze amnesia lasted ~" .. math.floor(dur + 0.5) .. "s (cooldown 41s).")
	end
end

-- Precise denizen-state clear: the wear-off line names the mob, so resolve it to an
-- id (preferring one actually carrying amnesia) and drop the aff.
if ataxiaBasher and ataxiaBasher.enabled and ataxiaBasher_dsResolveNameToId and ataxiaBasher_dsClearAff then
	local id = ataxiaBasher_dsResolveNameToId(matches[2], nil, "amnesia")
	if id then ataxiaBasher_dsClearAff(id, "amnesia") end
end
