-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > Leviticus > MONK > BACKBREAKER > LIMB PREP FUNCTION

function limbpreptekura()

         
            mytablearm = {"right arm", "left arm", "torso"} 
            mytableleg = {"right leg", "left leg", "torso"} 
            




         
            mytablekicktorso = {"sdk"} 
            mytablekickleg = {"snk left", "snk right"} 
            mytablekickarm = {"mnk left", "mnk right"} 




    
         
            mytablepunchtorso = {"hkp"} 
            mytablepunchleg = {"hfp right", "hfp left"} 
            mytablepuncharm = {"spp right", "spp left"}





double_HFP = ataxiaTables.limbData.tekuraHFP + ataxiaTables.limbData.tekuraHFP
double_SPP = ataxiaTables.limbData.tekuraSPP + ataxiaTables.limbData.tekuraSPP

if (tLimbs.RL + ataxiaTables.limbData.tekuraHFP >= 100 and tLimbs.RL < 100)
and (tLimbs.LL + ataxiaTables.limbData.tekuraHFP >= 100 and tLimbs.LL < 100) then
 legs_prepped_punch = true
else legs_prepped_punch = false
end

if (tLimbs.RA + ataxiaTables.limbData.tekuraSPP >= 100 and tLimbs.RA < 100)
and (tLimbs.LA + ataxiaTables.limbData.tekuraSPP >= 100 and tLimbs.LA < 100) then
 arms_prepped_punch = true
else arms_prepped_punch = false
end

if tLimbs.RA + ataxiaTables.limbData.tekuraSPP >= 100 and tLimbs.RA < 100
then
rightarm_prepped_punch = true
else rightarm_prepped_punch = false
end

if tLimbs.RA + ataxiaTables.limbData.tekuraMNK >= 100 and tLimbs.RA < 100
then
rightarm_prepped_kick = true
else rightarm_prepped_kick = false
end

if tLimbs.LA + ataxiaTables.limbData.tekuraMNK >= 100 and tLimbs.LA < 100
then
leftarm_prepped_kick = true
else leftarm_prepped_kick = false
end

if tLimbs.LA + ataxiaTables.limbData.tekuraSPP >= 100 and tLimbs.LA < 100
then
leftarm_prepped_punch = true
else leftarm_prepped_punch = false
end

if tLimbs.RL + ataxiaTables.limbData.tekuraHFP >= 100 and tLimbs.RL < 100
then
rightleg_prepped_punch = true
else rightleg_prepped_punch = false
end

if tLimbs.RL + ataxiaTables.limbData.tekuraSNK >= 100 and tLimbs.RL < 100
then
rightleg_prepped_kick = true
else rightleg_prepped_kick = false
end

if tLimbs.LL + ataxiaTables.limbData.tekuraHFP >= 100 and tLimbs.LL < 100
then
leftleg_prepped_punch = true
else leftleg_prepped_punch = false
end

if tLimbs.LL + ataxiaTables.limbData.tekuraSNK >= 100 and tLimbs.LL < 100
then
leftleg_prepped_kick = true
else leftleg_prepped_kick = false
end

if tLimbs.T + ataxiaTables.limbData.tekuraHKP >= 100 and tLimbs.T < 100
then
torso_prepped_punch = true
else torso_prepped_punch = false
end

if tLimbs.T + ataxiaTables.limbData.tekuraSDK >= 100 and tLimbs.T < 100
then
torso_prepped_kick = true
else torso_prepped_kick = false
end

targetarm = mytablearm[math.random(#mytablearm)]

targetleg = mytableleg[math.random(#mytableleg)]

kickleg = mytablekickleg[math.random(#mytablekickleg)]

punchleg = mytablepunchleg[math.random(#mytablepunchleg)]

kickarm = mytablekickarm[math.random(#mytablekickarm)]

puncharm = mytablepuncharm[math.random(#mytablepuncharm)]

kicktorso = mytablekicktorso[math.random(#mytablekicktorso)]

punchtorso = mytablepunchtorso[math.random(#mytablepunchtorso)]


end