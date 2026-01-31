--[[mudlet
type: alias
name: Limb Target
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- LeviticusREG
- Leviticus
- Knight
- RUNIE
- SNB
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^scc$
command: ''
packageName: ''
]]--


shieldstrike()
snblimblock()

send("wipe longsword;wield left longsword;wield right shield")

if timpale == true then
send("queue addclear free disembowel " ..target)

elseif php <= 34 and not tAffs.shield then
send("queue addclear free stand;falcon slay " ..target.. " ;assess " ..target.. ";wield bastard;bisect " ..target.. ";engage " ..target)

elseif (lb[target].hits["right leg"] >= 100) or (lb[target].hits["left leg"] >= 100) and (lb[target].hits["torso"] >= 100) and tAffs.prone then
send("queue addclear free stand;falcon slay " ..target.. " ;impale " ..target.. " ;club " ..target.. " ;fury on;assess " ..target)

elseif tAffs.rebounding or tAffs.shield  and engaged == false then
send("queue addclear free stand;falcon slay " ..target.. " ;combination " ..target.. " raze smash " ..sstrike.. " ;engage " ..target.. " ;assess " ..target)

elseif tAffs.rebounding or tAffs.shield  and engaged == true then
send("queue addclear free stand;falcon slay " ..target.. " ;combination " ..target.. " raze smash " ..sstrike.. " ;assess " ..target)


elseif tAffs.nausea then
  if (lb[target].hits["right leg"] >= 92) and (lb[target].hits["torso"] >= 100) and ferocity_full == true then
send("queue addclear free stand;falcon slay " ..target.. " ;combination " ..target.. " slice right leg " ..svenom1.. " smash " ..sstrike.. " ;shieldstrike " ..target.. " low;assess " ..target)
elseif (lb[target].hits["right leg"] >= 92) and (lb[target].hits["torso"] >= 100) then
send("queue addclear free stand;falcon slay " ..target.. " ;combination " ..target.. " slice right leg " ..svenom1.. " trip;assess " ..target)

elseif (lb[target].hits["left leg"] >= 92) and (lb[target].hits["torso"] >= 100) and ferocity_full == true then
send("queue addclear free stand;falcon slay " ..target.. " ;combination " ..target.. " slice left leg " ..svenom1.. " smash " ..sstrike.. " ;shieldstrike " ..target.. " low;assess " ..target)
elseif (lb[target].hits["left leg"] >= 92) and (lb[target].hits["torso"] >= 100) then
send("queue addclear free stand;falcon slay " ..target.. " ;combination " ..target.. " slice left leg " ..svenom1.. " trip;assess " ..target)


--elseif (lb[target].hits["right leg"] >= 92) or (lb[target].hits["left leg"] >= 92) and (lb[target].hits["torso"] <= 92) and ferocity_full == true then
--send("queue addclear free stand;falcon slay " ..target.. " ;combination " ..target.. " slice torso " ..svenom1.. " smash " ..sstrike.. " ;shieldstrike " ..target.. " low;assess " ..target)

elseif (lb[target].hits["right leg"] >= 92) or (lb[target].hits["left leg"] >= 92) and (lb[target].hits["torso"] <= 92) then
send("queue addclear free stand;falcon slay " ..target.. " ;combination " ..target.. " slice torso " ..svenom1.. " smash " ..sstrike.. " ;assess " ..target)

elseif (lb[target].hits["right leg"] <= 92)  and ferocity_full == true then
send("queue addclear free stand;falcon slay " ..target.. " ;combination " ..target.. " slice right leg " ..svenom1.. " smash " ..sstrike.. " ;shieldstrike " ..target.. " low;assess " ..target)
elseif (lb[target].hits["right leg"] <= 92) then
send("queue addclear free stand;falcon slay " ..target.. " ;combination " ..target.. " slice right leg " ..svenom1.. " trip;assess " ..target)

elseif (lb[target].hits["left leg"] <= 92) and ferocity_full == true then
send("queue addclear free stand;falcon slay " ..target.. " ;combination " ..target.. " slice left leg " ..svenom1.. " smash " ..sstrike.. " ;shieldstrike " ..target.. " low;assess " ..target)
elseif (lb[target].hits["left leg"] <= 92) then
send("queue addclear free stand;falcon slay " ..target.. " ;combination " ..target.. " slice left leg " ..svenom1.. " trip;assess " ..target)
  
  end

elseif tAffs.asthma and not tAffs.prone and ferocity_full == true and not tAffs.slickness then
send("queue addclear free stand;falcon slay " ..target.. " ;combination " ..target.. " slice gecko smash mid;shieldstrike " ..target.. " low;assess " ..target)

elseif tAffs.asthma and not tAffs.prone and ferocity_full == true and tAffs.slickness then
send("queue addclear free stand;falcon slay " ..target.. " ;combination " ..target.. " slice slike smash mid;shieldstrike " ..target.. " high;assess " ..target)

elseif not tAffs.asthma and not tAffs.prone and ferocity_full == true and not tAffs.slickness then
send("queue addclear free stand;falcon slay " ..target.. " ;combination " ..target.. " slice slike smash mid;shieldstrike " ..target.. " mid;assess " ..target)

elseif engaged == false then
send("queue addclear free stand;falcon slay " ..target.. " ;combination " ..target.. " slice " ..svenom1.. " smash " ..sstrike.. " ;engage " ..target.. " ;assess " ..target)

else
send("queue addclear free stand;falcon slay " ..target.. " ;combination " ..target.. " slice " ..svenom1.. " smash " ..sstrike.. " ;assess " ..target)
end

