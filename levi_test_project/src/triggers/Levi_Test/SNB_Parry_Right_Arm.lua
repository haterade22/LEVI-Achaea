Deadeyes1 = nil
svenom1 = ""

tparrying = "right arm"
send("pt " ..target.. ": PARRYING " ..tparrying)



erAff("nausea")
if removeAffV3 then removeAffV3("nausea") end
tAffs.nausea = false