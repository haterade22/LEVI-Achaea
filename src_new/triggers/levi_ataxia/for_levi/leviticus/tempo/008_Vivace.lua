--[[mudlet
type: trigger
name: Vivace
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes A-J
- Bard
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
- pattern: Your feet move in vivace perfected, speeding each step within a new blade's song.
  type: 3
]]--

-- CAPTURED LIVE 2026-09-16 (pasted by the user after TEMPO VIVACE) -- the wording v4.7.311
-- inferred from the three identical known lines, confirmed verbatim:
--
--   "Your feet move in vivace perfected, speeding each step within a new blade's song."
--
-- This is what the footwork flourish reads (`bardtempostance == "Vivace"` -> flourish at every
-- return to front), so with this line landing the policy is live.
bardtempostance = "Vivace"

--1,6,5
