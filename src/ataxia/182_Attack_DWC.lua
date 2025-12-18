-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > Leviticus > RuneWarden > DWC RUNIE > Attack DWC

function dwcattack()

if tAffs.rebounding or tAffs.shield and engaged == false then
send("queue addclear free wield left scimitar405398;wield right scimitar405403;grip;falcon slay " ..target..";assess "..target..";rsl " ..target.. " " ..envenom2..";engage " ..target)
elseif tAffs.rebounding or tAffs.shield and engaged == true then
send("queue addclear free wield left scimitar405398;wield right scimitar405403;grip;falcon slay " ..target..";assess "..target..";rsl " ..target.. " " ..envenom2)
elseif use_bisect == true then
send("queue addclear free wield bastard;grip;assess "..target..";bisect "..target.." curare;engage " ..target)
elseif not engaged then
send("queue addclear free wield left scimitar405398;wield right scimitar405403;grip;falcon slay " ..target..";assess "..target..";dsl " ..target.. " " ..envenom1.. " " ..envenom2..";engage " ..target)
else
send("queue addclear free wield left scimitar405398;wield right scimitar405403;grip;falcon slay " ..target..";assess "..target..";dsl " ..target.. " " ..envenom1.. " " ..envenom2)
  end

end

