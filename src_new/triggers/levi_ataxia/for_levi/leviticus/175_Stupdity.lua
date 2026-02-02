--[[mudlet
type: trigger
name: Stupdity
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- MONK 1
- Tekura
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
- pattern: ^Your palm smashes into the bridge of (\w+)'s nose.$
  type: 1
]]--

if isTargeted(matches[2]) then
	tarAffedConfirmed("stupidity")
	if applyAffV3 then applyAffV3("stupidity") end
  if ataxia.settings.raid.enabled then
    send("pt stupidity on "..matches[2],false)
  end
end