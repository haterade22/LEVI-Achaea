--[[mudlet
type: trigger
name: Jump Refused While Mounted
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Misc Triggers
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
- pattern: ^You cannot do that while mounted\.$
  type: 1
]]--

-- THE LEAP WAS REFUSED (v4.7.345, user, live: "You cannot do that while mounted."). This is the
-- line that makes the whole belief safe to act on: guess wrong about the saddle and the game
-- corrects us here, on the same round, for the price of one refused command.
--
-- `ataxiaBasher_jumpRefusedMounted` does two things -- latch MOUNTED, and re-issue the jump we
-- just lost as a mountjump. The second is the one that matters: the escape that queued that leap
-- is waiting on an arrival that will never come, so without it the anti-death ladder stalls until
-- its timeout. It re-issues only a jump WE sent, from the room we sent it in, within the round.
if ataxiaBasher_jumpRefusedMounted then ataxiaBasher_jumpRefusedMounted() end
