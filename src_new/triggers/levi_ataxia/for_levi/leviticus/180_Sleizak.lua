--[[mudlet
type: trigger
name: Sleizak
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Runie
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
- pattern: ^The (\w+) rune upon .+ flashes as you strike (\w+)\.$
  type: 1
]]--

if matches[2] == "sleizak" then
tarAffed("nausea")
if applyAffV3 then applyAffV3("nausea") end
tarAffed("weariness")
if applyAffV3 then applyAffV3("weariness") end
end

if matches[2] == "inguz" then
tarAffed("crackedribs")
if applyAffV3 then applyAffV3("crackedribs") end
tarAffed("paralysis")
if applyAffV3 then applyAffV3("paralysis") end
end