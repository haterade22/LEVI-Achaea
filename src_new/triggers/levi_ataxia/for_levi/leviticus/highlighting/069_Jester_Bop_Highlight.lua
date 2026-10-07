--[[mudlet
type: trigger
name: Jester Bop Highlight
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
- pattern: You reach out and bop
  type: 2
- pattern: '^.{0,60}on the nose with your blackjack\.$'
  type: 1
- pattern: ^the nose with your blackjack\.$
  type: 1
- pattern: ^nose with your blackjack\.$
  type: 1
- pattern: ^with your blackjack\.$
  type: 1
- pattern: ^your blackjack\.$
  type: 1
- pattern: ^blackjack\.$
  type: 1
]]--

-- OUR BOP (v4.7.385, user: "Color this the same we did the serpent attacks"), the Jester basher's
-- swing above 50% target health (and below it in a crowd under Motley Bop):
--
--   You reach out and bop a dream horror on the nose with your blackjack.
--
-- Start of line for the first row. A long denizen name can make the server wrap it, and the break
-- can land anywhere in the tail, so there is one anchored pattern per place it can start.
--
-- `chartreuse` bold: the attack-LANDED colour, as for the Serpent bite (068). Highlight only.
selectString(line, 1)
fg("chartreuse")
setBold(true)
deselect()
resetFormat()
