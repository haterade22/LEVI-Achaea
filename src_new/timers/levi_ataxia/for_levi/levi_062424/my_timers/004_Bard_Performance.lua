--[[mudlet
type: timer
name: Bard Performance
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- leviticus
- Levi Ataxia
- MY TIMERS
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTimer: 'no'
  isOffsetTimer: 'no'
time: '00:15:00.000'
command: ''
packageName: ''
]]--

bardperformance = false

-- 15-min performance expired: renew it if we're still bashing (helper wields the lyre
-- first, recomposes, and re-arms this timer). The next blade attack re-wields the rapier.
if gmcp and gmcp.Char and gmcp.Char.Status and gmcp.Char.Status.class == "Bard" and ataxiaBasher_bardCompose then
   ataxiaBasher_bardCompose()
end