--[[mudlet
type: trigger
name: Party Afflictions
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Third Person
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
- pattern: '^\(Party\)\: (\w+) says\, "(\w+) hit with (\w+)."$'
  type: 1
- pattern: '^\(Party\)\: (\w+) says, "(\w+) has (\w+)."$'
  type: 1
- pattern: '^\(Party\)\: (\w+) says, "(\w+) has been hit with (\w+)."$'
  type: 1
- pattern: '^\(Party\)\: (\w+) says, "Rended (\w+)''s .+ with (\w+)."$'
  type: 1
- pattern: '^\(Party\): (\w+) says, "(\w+) wracked: (\w+)."$'
  type: 1
- pattern: '^\(Party\): (\w+) says, "Afflicted (\w+): (\w+)."$'
  type: 1
- pattern: '^\(Party\): (\w+) says, "(\w+): (\w+) (\w+)."$'
  type: 1
- pattern: '^\(Party\): (\w+) says, "(\w+): (\w+) (\w+) (\w+) (\w+)."$'
  type: 1
]]--

-- Every called word goes through paAff (ataxia/001_Miscellaneous_Aff_Tracking_Methods): it turns a
-- venom name into its affliction (curare -> paralysis) and adds that with tarAffed, so V3 holds it
-- and a cure can take it off. Until the 2026-11-08 deep review (H2) the raw word also went to
-- tarAffed and confirmAffV2 (= applyAffV3), two or three times over, which put "curare" into V3 as
-- an affliction of its own, while paAff wrote the real one to tAffs alone. The target is the second
-- name in every pattern (matches[3]) and the called words follow it. A Serin-only copy of the
-- "has" pattern, with the target first, is gone: the "has" pattern reads Serin's lines too, and
-- that copy's run reached isTargeted(matches[4]) = isTargeted(nil), which threw.
if matches[3] and isTargeted(matches[3]) then
  for i = 4, 7 do
    if matches[i] then paAff(matches[i]) end
  end
end
