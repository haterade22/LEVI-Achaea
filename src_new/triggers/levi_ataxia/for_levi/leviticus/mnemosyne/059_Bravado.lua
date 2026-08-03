--[[mudlet
type: trigger
name: Mnemosyne Bravado
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
- pattern: '^Bravado:\s+You are perpetually reckless'
  type: 1
]]--

-- Ongoing-effects row (captured live 2026-08-03):
--   "Bravado:  You are perpetually reckless and unable to benefit from shields, prismatic
--    barriers, or blood barriers."
--
-- This affix does not add a threat -- it REMOVES three of our answers, which is worse,
-- because every one of them keeps costing us something while returning nothing:
--   * `touch shield`          the danger-level response and the escape ladder's fallback
--   * Maran                   the emergency 5000hp PRISMATIC barrier -- and its charges
--                             regenerate ONE PER HOUR
--   * `activate bloodshield`  the Blood Maiden cloak's BLOOD barrier, one charge per 5 kills
--
-- The user's framing is the right one: "we will never know our health pool". With every
-- mitigation off, the number on the prompt is all there is -- nothing absorbs the spike and
-- nothing eats the burst. So their rule is to hit and run a denizen EARLIER: the swarm
-- tactics are the only mitigation the affix leaves standing (`S.threshold` clamps to
-- `swarm.bravadoThreshold`, default 2, and clamps DOWN only).
--
-- The three no-ops are gated on `ataxiaBasher_bravado()` / `mnemBravado` at their spend
-- sites. Note the shield case in particular: skipping it is not merely a saving, it is a
-- correction -- spending the round on a shield that cannot work also left the basher
-- believing it was covered.
--
-- Same telemetry-independent shape as the other affixes: status-row trigger, inMnemosyne
-- gate + transition guard in the handler, reset on run start, cleared on the confirmed end.
if ataxia and ataxia.mnemosyne and ataxia.mnemosyne.onBravadoSeen then
  ataxia.mnemosyne.onBravadoSeen()
end
