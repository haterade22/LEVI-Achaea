--[[mudlet
type: trigger
name: Health Lost By Type
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
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
- pattern: ^Health lost: (\d+) \(([^)]+)\)\.?$
  type: 1
]]--

-- "Health lost: 1488 (physical cutting)."
--
-- INCOMING damage, tallied by type for the session (user request 2026-08-03: "what damage
-- type we are targeted with the most in a session, in the window").
--
-- Kept separate from `bashStats.damageByType`, which is our OUTGOING damage -- the two would
-- be trivially easy to conflate and the resulting panel would be nonsense. Incoming lives in
-- `bashStats.incomingByType` / `incomingTotal` / `incomingHits`.
--
-- The useful output is WHICH TYPE, not how much: it is what picks the resistance paragon, the
-- Blademaster infuse to keep up, and which curing priorities matter -- and it is invisible in
-- the scroll, where each of these lines is one of hundreds.
--
-- The type is captured whole ("physical cutting", not just "cutting"): the game names a
-- category and a subtype, and collapsing them would merge things that want different answers.
-- `[^)]+` rather than `.+` so a trailing parenthesis in some future wording cannot swallow the
-- close bracket, and the final period is optional because that has varied elsewhere.
if bashStats_recordIncoming then
  bashStats_recordIncoming(tonumber(matches[2]), matches[3])
end
