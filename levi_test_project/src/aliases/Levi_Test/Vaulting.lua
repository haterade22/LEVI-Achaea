ataxia.mountid = tonumber(matches[3])
local opt = matches[2]
sendAll(
	("curing usevault "..(opt == "mount" and "no" or "yes")),
	("curing mount "..(ataxia.mountid == 0 and "clear" or ataxia.mountid)),
false)

ataxia_saveSettings(false)