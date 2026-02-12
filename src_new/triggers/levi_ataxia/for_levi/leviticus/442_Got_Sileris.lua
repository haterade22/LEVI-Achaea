--[[mudlet
type: trigger
name: Got Sileris
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Third Person
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
- pattern: ^A supple metallic shell of quicksilver has formed around (\w+).$
  type: 1
- pattern: ^(\w+) applies a quicksilver droplet to \w+\.$
  type: 1
]]--

if isTargeted(matches[2]) then
	tAffs.fangbarrier = true
	if applyAffV3 then applyAffV3("fangbarrier") end
	tAffs.sileris = true
	if applyAffV3 then applyAffV3("sileris") end
  confirmAffV2("fanbarrier")
  confirmAffV2("sileris")
  if serpent and serpent.state then serpent.state.geckoStripAttempted = false end
end
