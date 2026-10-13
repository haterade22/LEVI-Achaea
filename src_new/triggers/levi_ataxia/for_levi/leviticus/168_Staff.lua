--[[mudlet
type: trigger
name: Staff
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- MONK 1
- Monk
- Shikudo Triggers
- Shikudo
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
- pattern: ^You must be wielding your trusty staff if you wish to adopt one of the Shikudo forms\.$
  type: 1
]]--

-- v4.7.420: wield the staff the dispatch offense wields: `skstaff <item>`, else the bare keyword
-- "staff" (shikudo.staffRef, 006). It sent staff489282, one player's item id.
send("wield " .. (shikudo and shikudo.staffRef and shikudo.staffRef() or "staff"))