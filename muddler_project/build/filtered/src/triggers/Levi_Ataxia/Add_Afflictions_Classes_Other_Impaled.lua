selectString(line,1)
fg("black")
bg("DodgerBlue")
if ataxia_isClass("runewarden") or ataxia_isClass("paladin") or ataxia_isClass("infernal") or ataxia_isClass("unnamable") then
  send("fury on")
end

tAffs.impaled = true

disableTimer("Battlefury Perceive")