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

elseif tAffs.asthma and not tAffs.prone and ferocity_full == true and not tAffs.slickness and not tAffs.paralysis then
send("queue addclear free stand;falcon slay " ..target.. " ;dedication;combination " ..target.. " slice gecko smash mid;shieldstrike " ..target.. " low;assess " ..target)
elseif tAffs.asthma and not tAffs.prone and ferocity_full == true and tAffs.slickness and not tAffs.paralysis then
send("queue addclear free;stand;falcon slay " ..target.. " ;dedication;combination " ..target.. " slice slike smash mid;shieldstrike " ..target.. " low;assess " ..target)
elseif tAffs.asthma and not tAffs.prone and ferocity_full == true and not tAffs.slickness and tAffs.paralysis then
send("queue addclear free stand;falcon slay " ..target.. " ;dedication;combination " ..target.. " slice gecko smash high;shieldstrike " ..target.. " low;assess " ..target)
elseif tAffs.asthma and not tAffs.prone and ferocity_full == true and tAffs.slickness and tAffs.paralysis then
send("queue addclear free;stand;falcon slay " ..target.. " ;dedication;combination " ..target.. " slice slike smash high;shieldstrike " ..target.. " low;assess " ..target)

elseif engaged == false then
send("queue addclear free stand;falcon slay " ..target.. " ;dedication;combination " ..target.. " slice " ..svenom1.. " smash " ..sstrike.. " ;engage " ..target.. " ;assess " ..target)
else
send("queue addclear free stand;falcon slay " ..target.. " ;dedication;combination " ..target.. " slice " ..svenom1.. " smash " ..sstrike.. " ;assess " ..target)
end
end
send("wipe longsword;wield left longsword;wield right shield")
if not ataxia.afflictions.paralysis then
send("wipe longsword;wield left longsword;wield right shield")
if not tAffs.shield and php <= 34 then
send("queue addclear free stand;falcon slay " ..target.. " ;assess " ..target.. ";wield bastard;bisect " ..target.. ";engage " ..target)

elseif tAffs.rebounding or tAffs.shield and engaged == false then
send("queue addclear free stand;falcon slay " ..target.. " ;combination " ..target.. " raze smash " ..sstrike.. " ;engage " ..target.. " ;assess " ..target)
elseif tAffs.rebounding or tAffs.shield and engaged == true then
send("queue addclear free stand;falcon slay " ..target.. " ;combination " ..target.. " raze smash " ..sstrike.. " ;assess " ..target)

elseif tAffs.asthma and not tAffs.prone and ferocity_full == true and not tAffs.slickness then
send("queue addclear free stand;falcon slay " ..target.. " ;combination " ..target.. " slice gecko smash mid;shieldstrike " ..target.. " low;assess " ..target)
elseif tAffs.asthma and not tAffs.prone and ferocity_full == true and tAffs.slickness then
send("queue addclear free stand;falcon slay " ..target.. " ;combination " ..target.. " slice slike smash mid;shieldstrike " ..target.. " low;assess " ..target)
elseif tAffs.asthma and not tAffs.prone and ferocity_full == true and not tAffs.slickness and not tAffs.paralysis then
send("queue addclear free stand;falcon slay " ..target.. " ;combination " ..target.. " slice gecko smash mid;shieldstrike " ..target.. " low;assess " ..target)
elseif tAffs.asthma and not tAffs.prone and ferocity_full == true and tAffs.slickness and not tAffs.paralysis then
send("queue addclear free;stand;falcon slay " ..target.. " ;combination " ..target.. " slice slike smash mid;shieldstrike " ..target.. " low;assess " ..target)
elseif tAffs.asthma and not tAffs.prone and ferocity_full == true and not tAffs.slickness and tAffs.paralysis then
send("queue addclear free stand;falcon slay " ..target.. " ;combination " ..target.. " slice gecko smash high;shieldstrike " ..target.. " low;assess " ..target)
elseif tAffs.asthma and not tAffs.prone and ferocity_full == true and tAffs.slickness and tAffs.paralysis then
send("queue addclear free;stand;falcon slay " ..target.. " ;combination " ..target.. " slice slike smash high;shieldstrike " ..target.. " low;assess " ..target)


elseif engaged == false then
send("queue addclear free stand;falcon slay " ..target.. " ;combination " ..target.. " slice " ..svenom1.. " smash " ..sstrike.. " ;engage " ..target.. " ;assess " ..target)
else
send("queue addclear free stand;falcon slay " ..target.. " ;combination " ..target.. " slice " ..svenom1.. " smash " ..sstrike.. " ;assess " ..target)
end
end