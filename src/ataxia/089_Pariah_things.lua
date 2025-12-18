-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Ataxia-DownloadThis > Ataxia > Combat > Offensive Things > Pariah things

function ataxia_resetPariah()
  if pariah then
    if pariah.infest then killTimer(pariah.infest) end
    if pariah.ensorcell then killTimer(pariah.ensorcell) end
  end 
  pariah = {
    bladePrepared = false,
    burrow = false
  }
  ataxia_Echo("Reset pariah variables.")
  send("swarms",false)
end

function pariah_canGraph(logo)
  local graphs = {
    serpent = {"nest", "skein"},
    bear = {"jackal", "scarab"},
    sun = {"serpent"},
    nest = {"bear", "scales"},
    scales = {"skein"},
    skein = {"scarab"},
    scarab = {"jackal", "scales"},
    jackal = {"serpent"},
  }
  if logo == "scorpion" then
    if ataxia.vitals.epitaph >= 4 then
      return true
    else
      return false
    end
  elseif not pariah.lastLogograph then
    return true
  elseif table.contains(graphs[pariah.lastLogograph], logo) then
    return true
  else
    return false
  end
end

function pariah_canVirulence()
  if checkAffList({"rebbies", "sandfever", "flushings", "pyramides"}, 3) then
    return true
  else
    return false
  end
end  

function pariah_doVirulence()   
  local need = {"rebbies", "sandfever", "flushings", "pyramides"}
  local plague = false
  
  for _, aff in pairs(need) do
    if not haveAff(aff) then
      plague = aff
      break
    end
  end
  if not plague then plague = "mycalium" end
  return plague
end



