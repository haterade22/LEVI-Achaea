selectString(line,1)
fg("black")
bg("DodgerBlue")
if ataxia_isClass("runewarden") or ataxia_isClass("paladin") or ataxia_isClass("infernal") or ataxia_isClass("unnamable") then
  send("fury on")
end

tAffs.impaled = true
if applyAffV3 then applyAffV3("impaled") end

-- BM Brokenstar phase engine callback
if blademaster and blademaster.onImpaleSuccess then blademaster.onImpaleSuccess() end

disableTimer("Battlefury Perceive")