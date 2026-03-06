ataxiaTemp.dollFashions = ataxiaTemp.dollFashions - 7
local limb = matches[2]:gsub(" ", "")
tarAffed("damaged"..limb)
if applyAffV3 then applyAffV3("damaged") end
cecho(" <yellow>(<a_red>"..ataxiaTemp.dollFashions.."<yellow>)")