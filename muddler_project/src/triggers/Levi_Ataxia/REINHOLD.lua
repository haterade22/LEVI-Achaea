local food = matches[2]
if food:find("cake") then 
send("cq all;eat cake")
elseif food:find("bowl") then
send("cq all;eat bowl")
elseif food:find("steak") then
send("cq all;eat steak")
elseif food:find("drumstick") then
send("cq all;eat drumstick")
end

--string.find(food,"something")