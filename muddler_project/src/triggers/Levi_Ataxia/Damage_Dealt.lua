local amount = tonumber(matches[2])
local dtype = matches[3]

if bashStats then
  bashStats.totalDamage = (bashStats.totalDamage or 0) + amount
  bashStats.currentBalanceDamage = (bashStats.currentBalanceDamage or 0) + amount
  if not bashStats.damageByType then bashStats.damageByType = {} end
  bashStats.damageByType[dtype] = (bashStats.damageByType[dtype] or 0) + amount
end