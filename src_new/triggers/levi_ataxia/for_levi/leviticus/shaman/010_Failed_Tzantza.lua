--[[mudlet
type: trigger
name: Failed Tzantza
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes K-S
- Shaman
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
- pattern: You sense that your victim is not adequately prepared to undertake the Tzantza curse.
  type: 3
- pattern: Your trance is disrupted, and your surroundings are brought back into focus with a jolt, the curse upon your tongue
    left unuttered.
  type: 3
]]--

local tzAffs = {"agoraphobia", "claustrophobia", "dementia", "epilepsy", "masochism", "recklessness",
	"vertigo", "confusion", "dizziness", "impatience", "paranoia", "stupidity", "addiction"}

if line:find("not adequately prepared") then
	for i,v in pairs(tzAffs) do
		if haveAff(v) then
			erAff(v)
		end
	end
	selectString(line,1)
	fg("red")
	resetFormat()
end

tzantzacurse = false
send("curing on")
ataxiaEcho("System has been <green>unpaused.")