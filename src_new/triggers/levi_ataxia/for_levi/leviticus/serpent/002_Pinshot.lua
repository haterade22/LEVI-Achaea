--[[mudlet
type: trigger
name: Pinshot
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Serpent
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
- pattern: ^Your arrow slams into the foot of (\w+)\.$
  type: 1
]]--

-- The pinshot is in THIS person for 21 s (the game's duration and this trigger's own countdown;
-- was 30). tpinshot holds the name, so the opener (serpent/002 buildOpener) skips the bow only for
-- that target: it was true for anyone, so a new target within 21 s got no pinshot. A new pinshot
-- replaces the old clear timer, which would otherwise clear the new one early (2026-11-08 review,
-- F33).
if tpinshotTimer then killTimer(tpinshotTimer) end
tpinshot = matches[2]
tpinshotTimer = tempTimer(21, [[tpinshot = false; tpinshotTimer = nil]])

  cecho("\n")
  ataxia_boxEcho(matches[2].." PINSHOT !!!", "black:orange")
  cecho("\n")
  
  PinshotTimer0 = tempTimer(0,[[cecho("<orange>\n[PINSHOT]: <yellow>hindered movement on <red>"..target.." <yellow>for <white>21 seconds...\n") PinshotTimer0 = nil]])
  PinshotTimer6 = tempTimer(6,[[cecho("<orange>\n[PINSHOT]: <yellow>hindered movement on <red>"..target.." <yellow>for <white>15 seconds...\n") PinshotTimer6 = nil]])
  PinshotTimer11 = tempTimer(11,[[cecho("<orange>\n[PINSHOT]: <yellow>hindered movement on <red>"..target.." <yellow>for <white>10 seconds...\n") PinshotTimer11 = nil]])
  PinshotTimer16 = tempTimer(16,[[cecho("<orange>\n[PINSHOT]: <yellow>hindered movement on <red>"..target.." <yellow>for <white>5 seconds...\n") PinshotTimer16 = nil]])
  PinshotTimer = tempTimer(21,[[cecho("<orange>\n[PINSHOT]: <red>"..target.." <salmon>no longer<yellow> hindered by pinshot!!!\n") PinshotTimer = nil]])
