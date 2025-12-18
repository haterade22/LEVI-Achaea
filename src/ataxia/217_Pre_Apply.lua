-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > Leviticus > Defence > Pre Apply

function getdirectionn()
random_direction = nil
for k, v in pairs(gmcp.Room.Info.exits) do
  random_direction = k
  break
end
end

function lpreapply()
getdirectionn() --random_direction for tumble

--Druid/Infernal 4 Limb Prep
if slc.percentages["left arm"] >= 90 and slc.percentages["left leg"] >= 90 and slc.percentages["right leg"] >= 90 and slc.percentages["right arm"] >= 90 and slc.percentages["left arm"] < 100 and slc.percentages["left leg"] < 100 and slc.percentages["right leg"] < 100 and slc.percentages["right arm"] < 100 and mypreapply == false then
  send("curing queue insert 1 restoration to legs")
  ataxia_boxEcho("WE ARE PREAPPLYING", "yellow")
  autotumbler = autotumbler or true
  if autotumbler == true then
    send("tumble " ..random_direction)
    
  end
  
end

--Double Leg Break
if slc.percentages["left leg"] >= 95 and slc.percentages["right leg"] >= 95 and slc.percentages["left leg"] < 100 and slc.percentages["right leg"] < 100  and mypreapply == false then
  send("curing queue insert 1 restoration to legs")
  ataxia_boxEcho("WE ARE PREAPPLYING", "yellow")
  
  autotumbler = autotumbler or true
  if autotumbler == true then
    send("tumble " ..random_direction)
  
  end

end

if slc.percentages["left leg"] >= 86 and slc.percentages["right leg"] >= 86 and slc.percentages["left leg"] < 100 and slc.percentages["right leg"] < 100  and mypreapply == false then
  send("curing queue insert 1 restoration to legs")
  ataxia_boxEcho("WE ARE PREAPPLYING", "yellow")
  autotumbler = autotumbler or true
  if autotumbler == true then
    send("tumble " ..random_direction)
  end
 

end





end