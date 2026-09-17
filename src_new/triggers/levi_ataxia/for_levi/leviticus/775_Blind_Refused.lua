--[[mudlet
type: trigger
name: Blind Refused - Monk BM
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
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
- pattern: You are already blind.
  type: 3
]]--

-- BLIND REFUSED -- already up. Live-captured 2026-09-17 (both refusals pasted by the user, so
-- neither wording is inferred). A refusal is a FREE STATE PROBE: it says no trance started AND
-- that the defence is up. Same reasoning that wired the Fury refusal ("You're already raged with
-- fury!", highlighting/056) and the shin-augment already-channelling line.
--
-- Takes the FULL hold rather than the landed line's grace, and does NOT write
-- `ataxia.defences.blindness` -- see the note on ataxia_senseRefused in
-- deffing/007_Sense_Keepers.lua for why writing it here would be a livelock rather than a
-- correction. Fixed text, no embedded name, no wrap risk.
if ataxia_senseRefused then ataxia_senseRefused("blindness") end
