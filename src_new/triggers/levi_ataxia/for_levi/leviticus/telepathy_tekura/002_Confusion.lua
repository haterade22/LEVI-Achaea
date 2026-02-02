--[[mudlet
type: trigger
name: Confusion
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
- pattern: ^You direct a powerful pulse of telepathic energy into (\w+), throwing \w+ mind into chaos and confusion.$
  type: 1
]]--

if isTargeted(matches[2]) then
	tarAffedConfirmed("confusion")
	if applyAffV3 then applyAffV3("confusion") end
  if ataxia.settings.raid.enabled then
    if partyrelay and not ataxia.afflictions.aeon then
    send("pt confusion on "..matches[2],false)
    end
  end
end