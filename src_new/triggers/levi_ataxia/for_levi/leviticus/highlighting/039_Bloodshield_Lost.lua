--[[mudlet
type: trigger
name: Bloodshield Lost
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
- pattern: ^The crimson shield surrounding you winks out of existence\.$
  type: 1
]]--

-- The bloodshield is GONE -- it blocked its one attack (or lapsed). The pair matters more than
-- either line alone: raised (038) then winks out tells us the charge actually did its job, and
-- the next one costs another five kills.
--
-- Echoed as well as highlighted (user request 2026-08-03): the raise is easy to spot because we
-- asked for it, but the LOSS arrives unannounced in the middle of somebody else's attack, and
-- it is the half that changes what we should do next -- we are bare again.
selectString(line, 1)
setBold(true)
fg("firebrick")
deselect()
resetFormat()
ataxiaTemp = ataxiaTemp or {}
ataxiaTemp.bloodshieldUp = nil
if ataxiaEcho then ataxiaEcho("<firebrick>BLOODSHIELD<reset> gone -- that attack is blocked; we are bare again.") end
