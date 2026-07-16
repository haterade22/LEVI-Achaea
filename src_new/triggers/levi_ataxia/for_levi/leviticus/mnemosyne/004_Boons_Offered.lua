--[[mudlet
type: trigger
name: Mnemosyne Boons Offered
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
- pattern: flickers of power that may aide you
  type: 1
]]--

-- The boon screen only ever prints inside a wade, so it is proof we are still in it -- even
-- when Creville's Legacy (incurable dementia) has rewritten the room around it (observed: the
-- boon screen printed under "Tangled forest."). Assert BEFORE the handlers below, so they see
-- the correct in-Mnemosyne context.
if ataxiaBasher_mnemHere then ataxiaBasher_mnemHere("boon screen") end

ataxia.mnemosyne.onBoonsOffered()
if ataxia.mnemosyne.onBoonScreen then ataxia.mnemosyne.onBoonScreen() end -- explorer: ripple done
