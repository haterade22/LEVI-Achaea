--[[mudlet
type: trigger
name: Cull
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes A-J
- Depthwalker
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
- pattern: ^You lay into (\w+) with a vicious blow from Agith'maal's ire\.$
  type: 1
]]--

if type(target) ~= "number" and isTargeted(matches[2]) and #envenomList > 0 then
	tarAffed(envenomList[1])
	table.remove(envenomList, 1)
	targetIshere = true
	disableTimer("TargetOutOfRoom")

	if haveAff("timeloop") then
		checkTimeloop = false
		enableTrigger("Timeloop Failsafe Update")
	end
end
if type(target) ~= "number" and isTargeted(matches[2]) then
  -- The cull packet executed: commit its attune (dwattune off), as 481 does
  -- for a reap. And honour dwassess -- this follow-up used to send ASSESS
  -- unconditionally, which costs equilibrium without Health Inspector.
  if depthswalker and depthswalker.onReapLanded then depthswalker.onReapLanded() end
  local sep = ataxia.settings.separator or "::"
  if depthswalker and depthswalker.config and depthswalker.config.assess == false then
    send("contemplate "..target)
  else
    send("assess "..target..sep.."contemplate "..target)
  end
end
tcull = false