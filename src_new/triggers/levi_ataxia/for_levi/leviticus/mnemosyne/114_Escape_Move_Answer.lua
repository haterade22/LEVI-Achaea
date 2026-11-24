--[[mudlet
type: trigger
name: Escape Move Answer
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
- pattern: You must regain balance first.
  type: 3
- pattern: You must regain equilibrium first.
  type: 3
- pattern: You are recovering equilibrium and cannot move yet.
  type: 3
- pattern: '^\[System\]: Running queued \w+ command: LVMOVE'
  type: 1
- pattern: '^\[System\]: Added LVMOVE to your \w+ queue\.'
  type: 1
- pattern: ^(.+) was added to your (.+) queue\.$
  type: 1
]]--

-- THE GAME'S ANSWER TO A WATCHED ESCAPE MOVE (v4.7.515, from the malagma death of 2026-11-24).
-- Each of these lines is deleted on screen by another trigger: the refusals by 006_GAG and
-- clean-up/002, every `[System]` line by 006_GAG, the holds by 001 and 007. Three `stand;leap ne`
-- sends drew no visible answer at all. This trigger deletes nothing. While the swarm watches a move
-- of ours (S._moveWatch), S.onMoveLine says the line in the swarm's words, and a refusal tells the
-- watch to re-send as soon as we can move. With no move watched it does nothing.
if ataxia.mnemosyne and ataxia.mnemosyne.swarm and ataxia.mnemosyne.swarm.onMoveLine then
  ataxia.mnemosyne.swarm.onMoveLine(line)
end
