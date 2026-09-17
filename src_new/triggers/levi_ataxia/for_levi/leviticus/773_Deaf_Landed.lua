--[[mudlet
type: trigger
name: Deaf Landed - Monk BM
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
- pattern: The world about you falls silent as the deafness trance sinks upon you.
  type: 3
]]--

-- DEAFNESS TRANCE LANDED. Live-captured 2026-09-17. This is the game's word that the in-flight
-- window is over, which is what lets `ataxia_SENSE_HOLD` be sized for a slow trance without
-- masking an opponent's strip: the hold collapses to a short grace here rather than being
-- served out in full (v4.7.271 -- stop predicting the window, listen for the announcement).
--
-- Deliberately does NOT write `ataxia.defences.deafness`. The landing is proof the ACTION
-- finished; GMCP Char.Defences remains the only authority on the STATE (v4.7.280). Fixed text
-- with no embedded name, so no wrap risk.
if ataxia_senseLanded then ataxia_senseLanded("deafness") end
