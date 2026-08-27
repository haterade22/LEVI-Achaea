--[[mudlet
type: trigger
name: Fury Already Up
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
- pattern: ^You're already raged with fury!$
  type: 1
]]--
-- FURY WAS ALREADY UP -- which is the same fact as 055, in the wording of a refusal.
--
-- This is what makes the wade-entry check free (`M._furyCheck`, explorer 008): we send
-- `fury on` at every descent without asking whether it is needed, because if it is not, the
-- game answers with this line and we learn the state anyway. A redundant send is a state probe.
--
-- THE GAME'S WORD OUTRANKS OUR BOOKKEEPING -- the rule this codebase keeps re-learning
-- (v4.7.266 distortion, v4.7.270 augment refusal, v4.7.271 cooldown). Gating the entry check on
-- our own `infFuryOn` flag would make it verify itself and never notice being wrong.
if ataxiaBasher_furyConfirmed then ataxiaBasher_furyConfirmed() end

selectString(line, 1)
fg("indian_red")
deselect()
resetFormat()
