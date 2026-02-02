--[[mudlet
type: trigger
name: Deepfreeze
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes K-S
- Magi
- Pummel-related
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
- pattern: You drain the heat from the air around your enemies, causing them to experience the cold of the abyss itself.
  type: 3
]]--

if targetIshere then
  if haveAff("nocaloric") then
    tarAffed("shivering", "frozen")
    if applyAffV3 then applyAffV3("shivering"); applyAffV3("frozen") end
  else
    tarAffed("nocaloric", "shivering")
    if applyAffV3 then applyAffV3("nocaloric"); applyAffV3("shivering") end
  end
end

ataxia_boxEcho("~ baby it's cold outside ~", "black:a_blue")