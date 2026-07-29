--[[mudlet
type: trigger
name: Damage Dealt
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Basher
- Bashing
- Basher Lines
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
- pattern: ^Damage dealt: (\d+) \((\w+)\)\.$
  type: 1
]]--

local amount = tonumber(matches[2])
local dtype = matches[3]

if bashStats then
  bashStats.totalDamage = (bashStats.totalDamage or 0) + amount
  bashStats.currentBalanceDamage = (bashStats.currentBalanceDamage or 0) + amount
  if not bashStats.damageByType then bashStats.damageByType = {} end
  bashStats.damageByType[dtype] = (bashStats.damageByType[dtype] or 0) + amount

  -- Record non-crit damage to mob damage DB
  if not bashStats.lastHitWasCrit then
    if ataxia.data and ataxia.data.db and ataxia.data.db.recordMobDamage then
      ataxia.data.db.recordMobDamage(amount)
    end
  end

  -- Rage probe (basher/009): pairs this hit with the rage we had, to measure a
  -- rage-threshold damage bonus from live play. MUST run before the crit flag is
  -- reset below -- the probe excludes crits from its means.
  if ataxiaBasher_rageProbeHit then
    pcall(ataxiaBasher_rageProbeHit, amount, dtype, bashStats.lastHitWasCrit)
  end

  bashStats.lastHitWasCrit = false
end