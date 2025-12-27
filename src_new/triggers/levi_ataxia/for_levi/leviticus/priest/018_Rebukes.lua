--[[mudlet
type: trigger
name: Rebukes
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes K-S
- Priest
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
- pattern: ^You decree that (\w+) shall (see|know) the (truth|horror) of (\w+)(.+).$
  type: 1
]]--

local rebukes = {
	chaos = "hallucinations",
	darkness = "paranoia",
	evil = "masochism"
}
local rtype = matches[5]:lower()

if isTargeted(matches[2]) then
	tarZealHit(rebukes[rtype])
	ataxiaTemp.prayerList = {}
end

