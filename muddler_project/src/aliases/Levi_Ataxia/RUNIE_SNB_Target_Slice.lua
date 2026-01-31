snbsoftlock()
shieldstrike()

send("wipe longsword;wield left longsword;wield right shield")
send("target nothing")

if ataxia.afflictions.paralysis then
if not tAffs.shield and php <= 34 then
send("queue addclear free stand;falcon slay " ..target.. " ;dedication;assess " ..target.. ";wield bastard;bisect " ..target.. ";engage " ..target)

elseif tAffs.rebounding or tAffs.shield and engaged == false then
send("queue addclear free stand;falcon slay " ..target.. " ;dedication;combination " ..target.. " raze smash " ..sstrike.. " ;engage " ..target.. " ;assess " ..target)
elseif tAffs.rebounding or tAffs.shield and engaged == true then
send("queue addclear free stand;falcon slay " ..target.. " ;dedication;combination " ..target.. " raze smash " ..sstrike.. " ;assess " ..target)

elseif (tAffs.asthma and not tAffs.prone) and ferocity_full == true and (not tAffs.slickness and not tAffs.paralysis) then
send("queue addclear free stand;falcon slay " ..target.. " ;dedication;combination " ..target.. " slice " ..ltarget.. " gecko smash mid;shieldstrike " ..target.. " low;assess " ..target)
elseif (tAffs.asthma and not tAffs.prone) and ferocity_full == true and (tAffs.slickness and not tAffs.paralysis) then
send("queue addclear free;stand;falcon slay " ..target.. " ;dedication;combination " ..target.. " slice " ..ltarget.. " slike smash mid;shieldstrike " ..target.. " low;assess " ..target)
elseif (tAffs.asthma and not tAffs.prone) and ferocity_full == true and (not tAffs.slickness and tAffs.paralysis) then
send("queue addclear free stand;falcon slay " ..target.. " ;dedication;combination " ..target.. " slice " ..ltarget.. " gecko smash high;shieldstrike " ..target.. " low;assess " ..target)
elseif (tAffs.asthma and not tAffs.prone) and ferocity_full == true and (tAffs.slickness and tAffs.paralysis) then
send("queue addclear free;stand;falcon slay " ..target.. " ;dedication;combination " ..target.. " slice " ..ltarget.. " slike smash high;shieldstrike " ..target.. " low;assess " ..target)

elseif engaged == false then
send("queue addclear free stand;falcon slay " ..target.. " ;dedication;combination " ..target.. " slice " ..ltarget.. " " ..svenom1.. " smash " ..sstrike.. " ;engage " ..target.. " ;assess " ..target)
else
send("queue addclear free stand;falcon slay " ..target.. " ;dedication;combination " ..target.. " slice " ..ltarget.. " " ..svenom1.. " smash " ..sstrike.. " ;assess " ..target)
end
end

send("wield left longsword;wield right shield")

if not ataxia.afflictions.paralysis then
send("wield left longsword;wield right shield")
if not tAffs.shield and php <= 34 then
send("queue addclear free stand;falcon slay " ..target.. " ;assess " ..target.. ";wield bastard;bisect " ..target.. ";engage " ..target)

elseif tAffs.rebounding or tAffs.shield and engaged == false then
send("queue addclear free stand;falcon slay " ..target.. " ;combination " ..target.. " raze smash " ..sstrike.. " ;engage " ..target.. " ;assess " ..target)
elseif tAffs.rebounding or tAffs.shield and engaged == true then
send("queue addclear free stand;falcon slay " ..target.. " ;combination " ..target.. " raze smash " ..sstrike.. " ;assess " ..target)

elseif (tAffs.asthma and not tAffs.prone) and ferocity_full == true and (not tAffs.slickness and not tAffs.paralysis) then
send("queue addclear free stand;falcon slay " ..target.. " ;combination " ..target.. " slice " ..ltarget.. " gecko smash mid;shieldstrike " ..target.. " low;assess " ..target)
elseif (tAffs.asthma and not tAffs.prone) and ferocity_full == true and (tAffs.slickness and not tAffs.paralysis) then
send("queue addclear free;stand;falcon slay " ..target.. " ;combination " ..target.. " slice " ..ltarget.. " slike smash mid;shieldstrike " ..target.. " low;assess " ..target)
elseif (tAffs.asthma and not tAffs.prone) and ferocity_full == true and (not tAffs.slickness and tAffs.paralysis) then
send("queue addclear free stand;falcon slay " ..target.. " ;combination " ..target.. " slice " ..ltarget.. " gecko smash high;shieldstrike " ..target.. " low;assess " ..target)
elseif (tAffs.asthma and not tAffs.prone) and ferocity_full == true and (tAffs.slickness and tAffs.paralysis) then
send("queue addclear free;stand;falcon slay " ..target.. " ;combination " ..target.. " slice " ..ltarget.. " slike smash high;shieldstrike " ..target.. " low;assess " ..target)

elseif engaged == false then
send("queue addclear free stand;falcon slay " ..target.. " ;combination " ..target.. " slice " ..ltarget.. " " ..svenom1.. " smash " ..sstrike.. " ;engage " ..target.. " ;assess " ..target)
else
send("queue addclear free stand;falcon slay " ..target.. " ;combination " ..target.. " slice " ..ltarget.. " " ..svenom1.. " smash " ..sstrike.. " ;assess " ..target)
end
end