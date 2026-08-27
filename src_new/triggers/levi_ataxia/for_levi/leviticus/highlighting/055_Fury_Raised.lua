--[[mudlet
type: trigger
name: Fury Raised
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Highlighting
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
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
packageName: ''
patterns:
- pattern: ^Your eyes rage with fury\.$
  type: 1
]]--
-- FURY IS UP. The confirmation for `FURY ON`, captured 2026-08-20.
--
-- `ataxiaBasher_infFury` has carried a note since it was written saying its state was
-- optimistic "because no fury on/off game line has been captured yet -- if one shows up,
-- confirm from it instead". This is that line, and 056 is its sibling.
--
-- Worth confirming rather than trusting the send: the Fury of Ages boon QUADRUPLES endurance
-- costs, and the keeper's whole job is to drop fury before endurance strands us. A keeper that
-- is wrong about whether fury is up either burns willpower re-raising something already raised,
-- or believes it dropped something that is still draining.
if ataxiaBasher_furyConfirmed then ataxiaBasher_furyConfirmed() end

selectString(line, 1)
setBold(true)
fg("orange_red")
deselect()
resetFormat()
