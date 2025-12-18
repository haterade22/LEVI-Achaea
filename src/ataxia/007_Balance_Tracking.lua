-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Ataxia-DownloadThis > Ataxia > Gmcp Related > Update Stuff > Balance Tracking

function ataxia_gotbal(which)
 ataxiaBasher_stormhammer()  
  if ataxia.settings.highlighting.bals then
    if not ataxiaBasher.enabled or ataxiaBasher.manual then
      if not autoHarvesting and not autoExtracting then
        if ataxia.fishing and not ataxia.fishing.enabled then
          cecho(" <green>(<DarkSlateBlue>"..( math.floor((os.clock() - ataxia.bals.timestamps[which]) * 100) / 100).."s<green>)")
        end
      end
    end
  end

  ataxia.bals.timestamps[which] = os.clock()
end

function ataxia_checkBalances()
 ataxiaBasher_stormhammer()  
  for _, balType in pairs(ataxia.bals.get) do
    local bool = gmcp.Char.Vitals[balType] == "1"
    if ataxia.bals.used[balType] and not bool then
      ataxia.bals.timestamps[balType] = os.clock()
    end
    ataxia.bals.used[balType] = bool
  end
  
  if ataxia_isClass("bard") then
    local haveVoice = ataxia.vitals.voice == "Yes"
    if ataxia.bals.used.voice and not haveVoice then
      ataxia.bals.timestamps.voice = os.clock()
    end
    ataxia.bals.used.voice = haveVoice
  end
end

if ataxia.bals.handler then
  killAnonymousEventHandler(ataxia.bals.handler)
end
ataxia.bals.handler = registerAnonymousEventHandler("gmcp.Char.Vitals", "ataxia_checkBalances")