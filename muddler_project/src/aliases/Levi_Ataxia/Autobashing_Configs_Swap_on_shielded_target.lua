--Ideally this will make it so you just don't bother razing shield if there's another target in room to hit.

if not ataxiaBasher.shieldswap then
	ataxiaBasher.shieldswap = true
else
	ataxiaBasher.shieldswap = false
end
ataxiaEcho( (ataxiaBasher.shieldswap and "Will" or "Won't") .. " look for a new target when denizens shield.")