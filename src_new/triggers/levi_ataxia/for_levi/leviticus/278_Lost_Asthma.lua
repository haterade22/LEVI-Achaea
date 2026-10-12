--[[mudlet
type: trigger
name: Lost Asthma
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Defence
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
- pattern: ^(\w+) takes a long drag off .+ pipe\.$
  type: 1
- pattern: '^A great gurgling sound is heard as (\w+) takes a long drag '
  type: 1
]]--
-- v4.7.415: any pipe name ("off an enamel bubble pipe", "off his pipe") and the bubble pipe's
-- "A great gurgling sound..." wording. The old one-word pattern matched only "off his pipe": 5 of the
-- 56 smokes in Mystor's logs (2026-10-11).

if matches[2] == target then
  tAffs.asthma = false
  erAff("asthma")
end