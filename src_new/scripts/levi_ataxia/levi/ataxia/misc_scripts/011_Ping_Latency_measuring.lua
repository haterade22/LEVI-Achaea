--[[mudlet
type: script
name: Ping/Latency measuring
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- Misc Scripts
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

local pingCalculation = pingCalculation or {}

--Calculate average ping.
function ataxia_getPing()
  local x, y = #pingCalculation, 0
  for i, p in pairs(pingCalculation) do
    y = y + p
  end
  return y/x
end

function ataxia_pingCheck()
  table.insert(pingCalculation, 1, getNetworkLatency())
  if #pingCalculation > 15 then
    table.remove(pingCalculation, 16)
  end
end

registerAnonymousEventHandler("sysDataSendRequest", "ataxia_pingCheck")