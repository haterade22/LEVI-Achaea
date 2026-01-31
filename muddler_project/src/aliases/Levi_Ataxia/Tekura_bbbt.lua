if ataxia.vitals.class >= 10 and ataxia.vitals.stance ~= "Bear" and tAffs.prone then
send("queue addclear free kai transition bear;bbt " ..target)
elseif ataxia.vitals.class <= 9 and tAffs.prone then
send("queue addclear free bbt " ..target)
else
send("queue addclear free bbt " ..target)
end