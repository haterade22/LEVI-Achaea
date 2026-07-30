--[[mudlet
type: trigger
name: Battlerage Ready
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Basher
- Bashing
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
- pattern: ^You can use (\w+) again\.$
  type: 1
- pattern: ^Your (\w+) ability could be used again but you lack the necessary Rage\.$
  type: 1
]]--

--[[
    The game's own battlerage cooldown feed -- see basher/011 for the full rationale.

    Both wordings mean the same thing: the named ability's cooldown has JUST expired.
    The second is simply the first seen through an empty rage bar. Captured live on
    2026-07-30 for Collide, Bulwark, Etch and Cullingblade.

    Numbered 328 so it sits immediately before 329 (the "must wait" rejection), which
    is the same signal inverted -- together they bracket the true cooldown window from
    the server rather than from our client-side guess.
]]--

if ataxiaBasher_brReady then
	ataxiaBasher_brReady(matches[2])
end
