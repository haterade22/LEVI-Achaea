-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > Leviticus > Windows > Limb Counter Window

tarcLabel = Geyser.Label:new({
  name = "tarcLabel",
  x = "0%", y = "-50%",
  width = "14%", height = "30.4%",
})

tarcLabel:setStyleSheet([[
  border: 1px solid #404040;
]])

tarc = Geyser.MiniConsole:new({
  name='tarc',
  color='black',
  x='16', y='20',
  width = '100%-20', height = '100%-30',
  fontSize = 12,
  font = "Bitstream Vera Sans Mono",
  autoWrap = true
}, tarcLabel)

function tarc.write()
  tarc:clear()
  
  --if target and target ~= "" and target ~= "None" and target ~= "none" and lb[target] then
  if target and target ~= "" and target ~= "None" and target ~= "none" then
   tarc:cecho("   Target: " .. target .. "\n\n")
    if ataxiaBasher.enabled then
      tarc:cecho("   Mob Health: " .. gmcp.IRE.Target.Info.hpperc .. "\n")
      tarc:cecho("   BattleR:    " ..ataxia.vitals.rage.. "\n")
      tarc:cecho("   Our Health: "..ataxia.vitals.hp..  "\n")
      tarc:cecho("   Our Willpo: "..ataxia.vitals.wp..  "\n")
      tarc:cecho("   Our Endur:  "..ataxia.vitals.ep..  "\n")
      tarc:cecho("   Our EXP:    "..ataxia.vitals.xp..  "\n")
      if gmcp.Char.Status.class == "Magi" or gmcp.Char.Status.class == "Blue Dragon" then
      tarc:cecho("   Our Willpow: "..ataxia.vitals.wp..  "\n")
      elseif gmcp.Char.Status.class == "Shaman" then
      tarc:cecho("   Our SwiftC: " ..curseCharge.."\n")     
      elseif gmcp.Char.Status.class == "Pariah" then
      tarc:cecho("Our Epitaph Number: "..ataxia.vitals.epitaph..  "\n")
      end
    end
  
   else 
    tarc:cecho("   Target: Sartan\n\n")
   end
   if ataxiaNDB.players[target] then
    tarc:cecho("   Limb Counter\n")
    for _, ln in ipairs({"head", "torso", "left arm", "right arm", "left leg", "right leg"}) do 
      tarc:cecho(string.format("%11s", ln) .. ": " .. lb[target].hits[ln] .. "\n")
    end
    end
    if gmcp.Char.Status.class == "Monk" then
    tarc:cecho("          Kai: " ..ataxia.vitals.class)
    tarc:cecho("\n         Kata: " ..katachain.. "")
      if ataxia.vitals.form then
        tarc:cecho("\n       Stance: " ..ataxia.vitals.form.. "\n")
      else
        tarc:cecho("\n       Stance: " ..ataxia.vitals.stance.. "\n")
      end
    end
    if gmcp.Char.Status.class == "Blademaster" then
    tarc:cecho("     Shin: " ..bmshin.. "\n\n")
    end
    if (gmcp.Char.Status.class == "Runewarden" or gmcp.Char.Status.class == "Infernal") and gmcp.Char.Vitals.charstats[3] == "Spec: Dual Blunt" or gmcp.Char.Vitals.charstats[4] == "Spec: Dual Blunt"  then 
    tarc:cecho("\n      Momentum: " ..mymomentum.. "\n\n")
    end
    --if ataxiaNDB.players[target] then
     --tarc:cecho(" Self Limb Counter\n")
      --for _, y in ipairs({"head", "torso", "left arm", "right arm", "left leg", "right leg"}) do 
       --tarc:cecho(string.format("%11s", y) .. ": " .. slc.percentages[y] .. "\n")
      
      --end
    --end
          
end