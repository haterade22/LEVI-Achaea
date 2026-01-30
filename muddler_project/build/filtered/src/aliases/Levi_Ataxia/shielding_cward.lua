local atk = combatQueue()
local p1, p2, p3 = "", "", ""

if ataxia_isClass("magi") then
	atk = atk..(matches[2] == "ts" and "touch shield" or "curseward")
elseif ataxia_isClass("priest") then
	atk = atk..(matches[2] == "ts" and "angel aura" or "curseward")
else
	atk = atk..(matches[2] == "ts" and "touch shield" or "curseward")
end

send("queue addclear freestand " ..atk)