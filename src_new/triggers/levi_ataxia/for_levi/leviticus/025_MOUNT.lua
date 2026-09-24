--[[mudlet
type: trigger
name: MOUNT
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- MINE ALL MINE
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
- pattern: You easily vault onto the back of (.+).
  type: 1
]]--

-- THE MOUNT WE JUST VAULTED ONTO BECOMES THE MOUNT (v4.7.339). This used to send
-- `curing mount <descriptive name>` straight off the line, and the game refused it -- "That is
-- not a valid mount that belongs to you." -- so nothing was set and every later VAULT / SPUR /
-- "come here" still pointed at whatever was configured before. `ataxiaBasher_vaultedOnto`
-- resolves the name to the ID learned from the mounts listing, stores it as the active mount and
-- tells the curing system. It also keeps the old `omount` global for whatever still reads it.
if ataxiaBasher_vaultedOnto then
  ataxiaBasher_vaultedOnto(matches[2])
else
  omount = matches[2]
end