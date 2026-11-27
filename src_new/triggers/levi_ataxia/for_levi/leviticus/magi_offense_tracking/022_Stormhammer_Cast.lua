--[[mudlet
type: trigger
name: Stormhammer Cast
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Mage
- Magi Offense Tracking
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
mFgColor: ''
mBgColor: ''
mSoundFile: ''
colorTriggerFgColor: ''
colorTriggerBgColor: ''
patterns:
- pattern: ^The sky above grows dark as you call upon powerful magics\.
  type: 1
]]--

-- OUR STORMHAMMER WENT OUT. The line, from Tabethys's own log (another player, a Magi, PvP, one
-- target; kb/raw/logs/2026-10-19_tabethys_magi-group_kalys_o6UKnyyy.txt:547-548 and 732-733):
--   The sky above grows dark as you call upon powerful magics. Raising your hands balefully, you cause
--   lightning bolts, the hammer of the storm, to shoot from your hands and slam into Kalys.
-- The first sentence is matched: it holds no name, so it fits one wrapped row for any target list.
-- CONFIRMED for one player target; UNCONFIRMED for two or three denizens (no capture of ours). The
-- Magi kite (mnemosyne/018) steps out of the fight room on this line, and stops itself if our
-- equilibrium goes twice with no cast line (K.MISS_MAX), so a different wording cannot wedge it.
if ataxia and ataxia.mnemosyne and ataxia.mnemosyne.magiKite and ataxia.mnemosyne.magiKite.onCast then
  pcall(ataxia.mnemosyne.magiKite.onCast, "stormhammer")
end
