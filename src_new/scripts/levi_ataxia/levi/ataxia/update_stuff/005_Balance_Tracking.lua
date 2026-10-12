--[[mudlet
type: script
name: Balance Tracking
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- Gmcp Related
- Update Stuff
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

function ataxia_gotbal(which)
  if ataxia.settings.highlighting.bals then
    if not ataxiaBasher.enabled or ataxiaBasher.manual then
      if not autoHarvesting and not autoExtracting then
        if ataxia.fishing and not ataxia.fishing.enabled then
          cecho(" <green>(<DarkSlateBlue>"..( math.floor((getEpoch() - ataxia.bals.timestamps[which]) * 100) / 100).."s<green>)")
        end
      end
    end
  end

  -- getEpoch(), not os.clock(): Lua 5.1 defines os.clock as CPU time, which matches wall
  -- time only under Windows' C runtime (v4.7.419).
  ataxia.bals.timestamps[which] = getEpoch()
end

function ataxia_checkBalances()
  for _, balType in pairs(ataxia.bals.get) do
    local bool = gmcp.Char.Vitals[balType] == "1"
    if ataxia.bals.used[balType] and not bool then
      ataxia.bals.timestamps[balType] = getEpoch()
    end
    ataxia.bals.used[balType] = bool
  end
  
  if ataxia_isClass("bard") then
    local haveVoice = ataxia.vitals.voice == "Yes"
    if ataxia.bals.used.voice and not haveVoice then
      ataxia.bals.timestamps.voice = getEpoch()
    end
    ataxia.bals.used.voice = haveVoice
  end
end

if ataxia.bals.handler then
  killAnonymousEventHandler(ataxia.bals.handler)
end
ataxia.bals.handler = registerAnonymousEventHandler("gmcp.Char.Vitals", "ataxia_checkBalances")