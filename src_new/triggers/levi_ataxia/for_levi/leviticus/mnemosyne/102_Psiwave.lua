--[[mudlet
type: trigger
name: Psiwave
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
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
- pattern: ^Psiwave\s+\d+\s+\w+
  type: 1
]]--

-- A row in the BOONS list confirms Psiwave is active (v4.7.355):
--
--   "Your psionics radiate ability now deals magic damage to all denizens in your location."
--
-- PSI RADIATE (AB 2714, 4.00s of equilibrium) then replaces PSI SHATTER as the Psion's equilibrium
-- attack -- the paid one and the free full-transcendence one (user: "When we have this boon please
-- use this instead of shatter"). `psionEqAttack`, basher/002.
--
-- Only inside the tower (the gate every boon row carries since v4.7.351). Cleared on Mnemosyne run
-- start/end. Type BOONS to re-sync if needed.
if ataxiaBasher and ataxiaBasher.inMnemosyne then psionPsiwave = true end
