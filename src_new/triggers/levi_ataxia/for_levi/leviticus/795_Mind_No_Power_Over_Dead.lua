--[[mudlet
type: trigger
name: Mind No Power Over Dead
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
- pattern: ^Your mental abilities have no power over the dead\.$
  type: 1
]]--

-- A MIND command at a corpse. The 2026-10-27 log has ten in three seconds after a kill. Our target
-- is dead: the Shikudo offenses send nothing at it until the room shows it again (006,
-- shikudo.targetUsable; v4.7.456).
if shikudo and shikudo.markDead and type(target) == "string" then shikudo.markDead(target) end
