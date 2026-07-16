--[[mudlet
type: trigger
name: Mnemosyne Survey Elsewhere
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Basher
- Bashing
- Basher Lines
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
- pattern: ^You are in (.+?)\.?$
  type: 1
]]--

-- SURVEY answered with a REAL location -> we are genuinely out of the Mnemosyne.
--
-- This is the ONLY thing that clears ataxiaBasher.inMnemosyne. The area cannot do it: the
-- Mnemosyne boon "Creville's Legacy" (attack 20% faster, INCURABLE dementia -- and it echoes
-- up to 3x) fakes gmcp.Room.Info wholesale -- area/num/exits/coords/desc are all a coherent,
-- plausible REAL room (observed: "the Northern Ithmia", num 774, real neighbouring exits).
-- SURVEY is free and still reports the truth through it, so it is the sole authority:
--   You have no idea where you are.              <- the dementia tell
--   Your environment conforms to that of Forest. <- the lie (matches the faked environment)
--   You are in wading the Mnemosyne.             <- the truth (trigger 351)
--
-- Gated on ataxiaTemp.mnemSurveyPending so only the answer to OUR survey counts -- an
-- unrelated "You are in ..." line can never knock us out of the tower.
-- The still-in-Mnemosyne case is trigger 351.
if matches[2]:find("Mnemosyne") then return end
if ataxiaBasher_mnemLeftFor then ataxiaBasher_mnemLeftFor(matches[2]) end
