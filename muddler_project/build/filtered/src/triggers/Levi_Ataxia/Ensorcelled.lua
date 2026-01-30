pariah.bladePrepared = true
tarAffed("ensorcelled")

if pariah.ensorcell then killTimer(pariah.ensorcell) end
pariah.ensorcell = tempTimer(21, [[ erAff("ensorcelled") ]])