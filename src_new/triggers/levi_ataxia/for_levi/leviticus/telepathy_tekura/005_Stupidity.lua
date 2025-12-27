--[[mudlet
type: trigger
name: Stupidity
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Affs Post Queue - Gated
- Classes K-S
- Monk
- Telepathy/Tekura
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
- pattern: ^You cast a net of stupidity over (\w+)'s mind.$
  type: 1
- pattern: ^Your palm smashes into the bridge of (\w+)'s nose.$
  type: 1
]]--

if isTargeted(matches[2]) then
	tarAffed("stupidity")
  if ataxia.settings.raid.enabled then
    send("pt stupidity on "..matches[2],false)
  end
end