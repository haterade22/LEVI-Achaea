--[[mudlet
type: trigger
name: Mnemosyne Reaper Tithe
hierarchy:
- Levi_Ataxia
- Ataxia
- Mnemosyne
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
- pattern: ^You reap a tithe of power from your fallen foe\.
  type: 1
]]--

-- Reaper boon: +1% damage dealt per denizen kill, announced by this line after
-- every kill. The game never shows the running total -- onReaperTithe counts the
-- tithes and echoes the cumulative bonus (and the line is its own proof of the
-- boon, so it also sets mnemReaper).
if ataxia.mnemosyne and ataxia.mnemosyne.onReaperTithe then
  ataxia.mnemosyne.onReaperTithe()
end
