--[[mudlet
type: trigger
name: Transcendence Wrap Tail
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Class Stuff
- Psion
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
- pattern: '^(?:\S+ ){0,4}transcendence\.$'
  type: 1
]]--

-- THE WRAPPED TAIL OF A TRANSCENDENCE LINE (v4.7.351, deep review).
--
-- The decay line is 128 characters and the server wraps it, so it reaches us as two rows. Since
-- v4.7.349 psion/001 matches the first and calls deleteFull() -- which removes THAT row and then
-- only removes the next one if it is a prompt. The next one is the tail ("transcendence."), so it
-- was left alone on screen, context-free, on every decay tick; and the one-shot that would have
-- gagged the prompt had been spent on it. Before v4.7.349 the pattern never matched at all, so
-- both halves simply printed -- the fix to the counter is what created this.
--
-- Only straight after psion/001 has fired: a bare "transcendence." is too short a phrase to
-- claim on its own, and the timestamp is what makes it OURS.
local at = tonumber(ataxiaTemp and ataxiaTemp.transcendLineAt) or 0
local nowT = (getEpoch and getEpoch()) or os.time()
if (nowT - at) <= 1 and ataxiaBasher.enabled and not ataxiaBasher.manual then
	deleteFull()
end
