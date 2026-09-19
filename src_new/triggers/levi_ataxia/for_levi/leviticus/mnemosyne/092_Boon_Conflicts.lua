--[[mudlet
type: trigger
name: Boon Conflicts
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
- pattern: ^Conflicts [Ww]ith:\s+(.+)$
  type: 1
]]--

-- BOON CONTEMPLATE's conflicts line (v4.7.325, user: "echo the conflicts and highlight them"):
--   Conflicts With:     Self-Preservation and Truther
-- Highlights each conflicting boon in the line -- red if we hold it this run -- and echoes the list.
-- Ungated on purpose: it helps a contemplate typed by hand just as much as the automatic ones.
local M = ataxia and ataxia.mnemosyne
if M and M.onConflictsLine then M.onConflictsLine(matches[2]) end
