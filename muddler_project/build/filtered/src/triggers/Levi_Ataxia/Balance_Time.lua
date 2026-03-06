local balTime = tonumber(line:match("BALANCE:%s*(%d+%.?%d*)"))

if balTime and bashStats then
  bashStats.lastBalanceTime = balTime
  bashStats.lastBalanceDamage = bashStats.currentBalanceDamage or 0
  bashStats.currentBalanceDamage = 0
  if tarc and tarc.write then tarc.write() end
end