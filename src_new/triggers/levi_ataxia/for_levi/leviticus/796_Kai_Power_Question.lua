--[[mudlet
type: trigger
name: Kai Power Question
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
- pattern: ^How are you wanting to use the Kai power\?$
  type: 1
]]--

-- The game's answer to a KAI command it cannot read. Eight in the 2026-10-27 group log, and no
-- sender in the package builds one, so this names the last command that carried KAI (monk/004,
-- ataxia_kaiSendSeen) for the fix (v4.7.456).
if ataxia_kaiRefused then ataxia_kaiRefused() end
