if matches[3] == "arm" then
    if not ataxia.parrying then
	   ataxia_createParry()
    end
  ataxia.settings.use.parry = true
  if not ataxia.parry == "randomarm" then
    ataxia.parry = "randomarm"
  end
elseif matches[3] == "leg" then
  if not ataxia.parrying then
	 ataxia_createParry()
  end
    ataxia.settings.use.parry = true
  if not ataxia.parry == "randomleg" then
    ataxia.parry = "randomleg"
  end
end