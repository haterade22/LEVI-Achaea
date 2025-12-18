-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Ataxia-DownloadThis > Ataxia > Combat > Offensive Things > Monk > Shikudo Limb Counter

function shikudo_addDamage(attack, limb)
	local limbs = {
		["head"] = "H",
		["torso"] = "T",
		["left leg"] = "LL",
		["right leg"] = "RL",
		["left arm"] = "LA",
		["right arm"] = "RA",
	}
	local l = limbs[limb]

  if not shikudo_limbDamage[attack] then
    ataxiaEcho("Formula for "..attack.." not calculated?")
  else
    local x = shikudo_limbDamage[attack]
    if ataxia.defences.hyperfocus and ataxiaTemp.hyperLimb == limb then
      x = x/2
    end
    
    tLimbs[l] = tLimbs[l] + x
    
    if tLimbs[l] > 99.8 then
      cecho("\n<red> -= "..limb.." broke! =-")
      if limb == "head" then tAffs.stupidity = true end
			target_limbBroke(limb)
      targetLimbs_updateTimers(limb)
    else
      targetLimbs_updateTimers(limb)
    end
  end
end


function shikudo_breakPoint(health)
	shikudo_limbDamage = {}
  local staffMod = ataxia.shikudoLevel or 1
  
  shikudo_limbDamage.dart           = math.floor((.0440*health+156)*staffMod)
  shikudo_limbDamage.spinkicktorso  = math.floor((.0910*health+145)*staffMod)
  shikudo_limbDamage.spinkickhead   = math.floor((.2700*health+457)*staffMod)
  shikudo_limbDamage.thrust         = math.floor((.111*health+187)*staffMod)
  shikudo_limbDamage.needle         = math.floor((.1057*health+295)*staffMod)
  shikudo_limbDamage.risingkick     = math.floor((.0451*health+261)*staffMod)
  shikudo_limbDamage.flashheel      = math.floor((.0451*health+261)*staffMod)
  shikudo_limbDamage.frontkick      = math.floor((.0451*health+261)*staffMod)
  shikudo_limbDamage.kuro           = math.floor((.0451*health+261)*staffMod)
  shikudo_limbDamage.jinzuku        = math.floor((.0451*health+261)*staffMod) 
  shikudo_limbDamage.ruku           = math.floor((.0451*health+261)*staffMod)
  shikudo_limbDamage.hiraku         = math.floor((.04260*health+290)*staffMod)
  shikudo_limbDamage.hiru           = math.floor((.04260*health+290)*staffMod)
  shikudo_limbDamage.livestrike     = math.floor((.0775*health+360)*staffMod)
  shikudo_limbDamage.nervestrike    = math.floor((.0775*health+360)*staffMod)

  for atk, dmg in pairs(shikudo_limbDamage) do
    shikudo_limbDamage[atk] = (shikudo_limbDamage[atk]/health)*100
    shikudo_limbDamage[atk] = tonumber( string.format("%2.2f", shikudo_limbDamage[atk]) )
  end
  cecho("  <red>"..utf8.char(186).."<yellow>"..utf8.char(186).."<green>"..utf8.char(186))
end

function shikudo_findCombo(queuedAttack)
  local sp = ataxia.settings.separator or "::"
  local shikSplit = string.split(queuedAttack, sp)
  local shikudoCombo = false
  for _, com in pairs(shikSplit) do
    if com:find("combo") then
      shikudoCombo = string.split(com)
      break
    end
  end
  
  if shikudoCombo then
    ataxiaTemp.shikCombo = {}
    local kicks = {"flashheel", "risingkick", "frontkick", "spinkick", "crescent"}
    local staff = {"shatter", "thrust", "dart", "hiraku", "hiru", "ruku", "kuro", "livestrike", "nervestrike", "needle", "jinzuku"}
    local hit = ""
    for num, act in pairs(shikudoCombo) do
      if table.contains(kicks, act) then
        ataxiaTemp.shikCombo.kick = act
      elseif table.contains(staff, act) then
        if shikudoCombo[num+1] == "light" then
          hit = act.." light"
        else
          hit = act
        end
        if ataxiaTemp.shikCombo.attackone then
          ataxiaTemp.shikCombo.attacktwo = hit
        else
          ataxiaTemp.shikCombo.attackone = hit
        end
      end
    end
    if table.contains(shikudoCombo, "sweep") then
      ataxiaTemp.shikCombo.attackone = "sweep"; ataxiaTemp.shikCombo.attacktwo = "sweep"
    end
    if not ataxiaBasher.enabled then
      cecho("\n<a_darkblue>[<DimGrey>"..shikudoCombo[2]:upper().."<a_darkblue>]: ")
      cecho("<DimGrey>"..(ataxiaTemp.shikCombo.kick and ataxiaTemp.shikCombo.kick.." - " or ""))
      cecho("<DimGrey>"..(ataxiaTemp.shikCombo.attackone and ataxiaTemp.shikCombo.attackone.." - " or ""))
      cecho("<DimGrey>"..(ataxiaTemp.shikCombo.attacktwo and ataxiaTemp.shikCombo.attacktwo.."." or "."))
    end
    --display(shikudoCombo)
  end
end

function shikudo_lightAttack(atkName)
  if ataxiaTemp.shikCombo.attackone and ataxiaTemp.shikCombo.attackone:find(atkName) then
    if ataxiaTemp.shikCombo.attackone:find("light") then
      return true       
    end
    ataxiaTemp.shikCombo.attackone = nil
  elseif ataxiaTemp.shikCombo.attacktwo and ataxiaTemp.shikCombo.attacktwo:find(atkName) then
    if ataxiaTemp.shikCombo.attacktwo:find("light") then
      return true
    end
    ataxiaTemp.shikCombo.attacktwo = nil   
  end
  return false
end