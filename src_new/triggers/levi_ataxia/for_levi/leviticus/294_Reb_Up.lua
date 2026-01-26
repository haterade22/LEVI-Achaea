--[[mudlet
type: trigger
name: Reb Up
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- BM
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
- pattern: ^The attack rebounds back onto you!$
  type: 1
]]--

tAffs.rebounding = true

-- V3 tracking support
if affConfigV3 and affConfigV3.enabled and applyAffV3 then
	applyAffV3("rebounding")
end
-- V2 tracking support
if ataxia and ataxia.settings and ataxia.settings.useAffTrackingV2 then
    if confirmAffV2 then
        confirmAffV2("rebounding")
    elseif tAffsV2 then
        tAffsV2.rebounding = 2
    end
end