--systemDefup("none")

send("get 50 ink from palette;inr all")

if ataxia_isClass("runewarden") or ataxia_isClass("infernal") or ataxia_isClass("paladin") then
	send("falcon sanctuary")
  send("hyena sanctuary")
elseif ataxia_isClass("unnamable") then
  send("hound sanctuary")
end
send("inr all")

--if shaman then shaman.save() end

ataxiaTemp.keepout = {}
ataxiaTemp.qqtimer = tempTimer(30, [[ataxiaTemp.qqtimer = nil; populate_keepOut(); ataxia_precacheQueue()]])

raiseEvent("logging out")