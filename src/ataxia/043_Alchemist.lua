-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Ataxia-DownloadThis > Ataxia > System-related > Class Things > Alchemist

function needToSalt()
  local prio = {"hellsight", "hypochondria", "impatience", "whisperingmadness", "timeloop"}
  local others = {"addiction", "slickness", "sensitivity", "anorexia", "asthma", "lethargy", "healthleech"}
  
  local need = false
  local ot = 0
  
  for _, aff in pairs(prio) do
    if affed(aff) then
      need = true
      break
    end
  end
  
  if not need then
    for _, aff in pairs(others) do
      if affed(aff) then
        ot = ot + 1
        if ot >= 2 then
          need = true
          break
        end
      end
    end
  end
  
  if affed("paralysis") then
    need = false
  end
	return need
end