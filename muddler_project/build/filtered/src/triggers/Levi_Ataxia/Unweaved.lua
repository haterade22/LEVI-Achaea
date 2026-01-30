if tAffs.unweavingbody and not (tAffs.unweavingmind or not tAffs.unweavingspirit) then
--
elseif tAffs.unweavingmind and (not tAffs.unweavingbody or not tAffs.unweavingspirit) then
--
elseif tAffs.unweavingspirit and (not tAffs.unweavingmind or not tAffs.unweavingbody) then
--
elseif tAffs.unweavingspirit and (matches[4] == "body" or matches[4] == "mind") then
tarAffed("prone")
elseif tAffs.unweavingbody and (matches[4] == "mind" or matches[4] == "spirit") then
tarAffed("prone")
elseif tAffs.unweavingmind and (matches[4] == "body" or matches[4] == "spirit") then
tarAffed("prone")
end


if pprepare == "disruption" and matches[4] == "mind" then
send("pt " ..target..": Unweavemind and Paralysis ")
elseif  pprepare == "laceration" and matches[4] == "mind" then
send("pt " ..target..": Unweavemind and Haemophilia")
elseif  pprepare == "dazzle" and matches[4] == "mind" then
send("pt " ..target..": Unweavemind and Clumsiness")
elseif  pprepare == "rattle" and matches[4] == "mind" then
send("pt " ..target..": Unweavemind and Epilepsy")
elseif  pprepare == "vapours" and matches[4] == "mind" then
send("pt " ..target..": Unweavemind and Asthma")
end

if  pprepare == "disruption" and matches[4] == "spirit" then
send("pt " ..target..": Unweavespirit and Paralysis ")
elseif  pprepare == "laceration" and matches[4] == "spirit" then
send("pt " ..target..": Unweavespirit and Haemophilia")
elseif  pprepare == "dazzle" and matches[4] == "spirit" then
send("pt " ..target..": Unweavespirit and Clumsiness")
elseif  pprepare == "rattle" and matches[4] == "spirit" then
send("pt " ..target..": Unweavespirit and Epilepsy")
elseif  pprepare == "vapours" and matches[4] == "spirit" then
send("pt " ..target..": Unweavespirit and Asthma")
end

if  pprepare == "disruption" and matches[4] == "body" then
send("pt " ..target..": Unweavebody and Paralysis ")
elseif  pprepare == "laceration" and matches[4] == "body" then
send("pt " ..target..": Unweavebody and Haemophilia")
elseif  pprepare == "dazzle" and matches[4] == "body" then
send("pt " ..target..": Unweavebody and Clumsiness")
elseif  pprepare == "rattle" and matches[4] == "body" then
send("pt " ..target..": Unweavebody and Epilepsy")
elseif  pprepare == "vapours" and matches[4] == "body" then
send("pt " ..target..": Unweavebody and Asthma")
end





