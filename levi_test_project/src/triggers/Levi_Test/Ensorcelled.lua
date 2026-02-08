pariah.bladePrepared = true
tarAffed("ensorcelled")
if applyAffV3 then applyAffV3("ensorcelled") end

if pariah.ensorcell then killTimer(pariah.ensorcell) end
pariah.ensorcell = tempTimer(21, [[ erAff("ensorcelled") ; if removeAffV3 then removeAffV3("ensorcelled") end]])