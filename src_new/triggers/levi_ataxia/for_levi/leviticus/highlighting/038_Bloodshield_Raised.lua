--[[mudlet
type: trigger
name: Bloodshield Raised
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
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^A crimson shield springs into existence around you, encasing your entire body\.$
  type: 1
]]--

-- The Blood Maiden cloak's BLOODSHIELD is up: it blocks THE NEXT ATTACK against us, then it
-- is gone. Worth seeing, because the charge behind it costs FIVE kills to earn and the block
-- is a single event -- easy to miss entirely in combat spam.
--
-- This is also the CONFIRMATION for `activate bloodshield`, which basher/001 fires optimistically
-- (it clears `bloodshieldReady` on SEND, because no confirm line had been captured). Recording
-- it here means we now know the difference between "we asked" and "it worked".
--
-- firebrick bold. NOT "crimson": this package WHOLESALE-REPLACES color_table (misc_scripts/007),
-- so a plausible-sounding name that is not in that table makes fg() and cecho() THROW -- on
-- every bloodshield line. Same trap as the ansi_* typos a deep review caught. firebrick is the
-- nearest real red and keeps the pair (raised / winks out) recognisable. Not the orange family.
selectString(line, 1)
setBold(true)
fg("firebrick")
deselect()
resetFormat()
ataxiaTemp = ataxiaTemp or {}
ataxiaTemp.bloodshieldUp = true
if ataxiaEcho then ataxiaEcho("<firebrick>BLOODSHIELD<reset> up -- blocks the NEXT attack.") end
