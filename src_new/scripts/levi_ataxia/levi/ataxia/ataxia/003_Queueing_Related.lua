--[[mudlet
type: script
name: Queueing Related
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- Combat
- Offensive Things
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

function combatQueue()
	local sp = ataxia.settings.separator

  local t = "g body"..sp.."g gold"..sp.."stand"..sp
  
  --Deliverance
  if tdeliverance == true then
    if partyrelay and not ataxia.afflictions.aeon then
      send("pt "..target.. ": Has Deliverance - DO NOT HIT - Need NEW Target")
      send("pt "..target.. ": Has Deliverance - DO NOT HIT - Need NEW Target")
    end
  send("cq all")
  ataxiaEcho("TARGET HAS DELIVERANCE - PICKING NEW TARGET")
  expandAlias("nt")
  end
  --Jester Bomb
  if havebomb == true then
    send("cq all;put bomb in pack;put bomb in pack;put bomb in pack;put bomb in pack")
  end
  
  --Jester AEON Cheese \ OCCIE Wheel Cheese \ Sentinel Riftlock \ Pariah Voyria Kill
  --
  -- THROTTLED (v4.7.275). This branch fires once per DISPATCH, and each pass sends `cq all`,
  -- which clears our own attack queue. In the 2026-08-19 Grulk log `preventriftlock` stayed set
  -- (it only clears on a successful shield, and a lemming stripped every shield in ~2s), so we
  -- re-shielded and re-cleared repeatedly: six balances spent to block our own offense.
  --
  -- The throttle matters more since v4.7.275 added blademaster.retryTick, which dispatches on
  -- the PROMPT rather than only on a keypress -- without it, an un-clearable cheese flag would
  -- send `cq all` several times a second and offense could never resume.
  if jestercheese == true or myaeon == true or preventriftlock == true or stoplatency == true then
    ataxiaTemp = ataxiaTemp or {}
    local now = (getEpoch and getEpoch()) or os.time()
    if not ataxiaTemp.cheeseAt or (now - ataxiaTemp.cheeseAt) >= 4 then
      ataxiaTemp.cheeseAt = now
      ataxiaEcho("CLASS CHEESE INCOMMING")
      if gmcp.Char.Status.class == "Magi" then
        send("cq all;cast reflection at me")
      else
        send("cq all;touch shield")
      end
    end
  end
 if gmcp.Char.Status.class == "Psion" then 
 if affed("asthma") and (affed("slickness") or affed("bloodfire")) and affed("anorexia") and affed("paralysis") and affed("impatience") or affed("sandfever") then
  send("cq all;psi manipulate touch tree")
 end
 end
   
   
   
	if ataxia.settings and ataxia.settings.use and ataxia.settings.use.parry and ataxia.parry ~= "manual" then
		if ataxia.parrying.shouldparry ~= ataxia.parrying.limb then
			t = t.." " ..sp.." parry " ..ataxia.parrying.shouldparry..sp
		end
	end

	if tChaseTimer and not targetIshere then
      if dir_left ~= "fly" and dir_left ~= "ether" and dir_left ~= "forcefly" then
			t = t..dir_left..sp
		elseif dir_left == "forcefly" and not affed("tension") then
			t = t.."land"..sp
		elseif dir_left == "fly" then
			if ataxia_isClass("Alchemist") then
				t = t.."educe lead "..target
			elseif ataxia_isClass("Psion") then
				t = t.."weave prepare disruption"..sp.."weave launch "..target
       
			else
				t = t.."touch tentacle "..target..sp
			end
		end
	end

	return t
end

function depthswalkerQueue()
	local sp = ataxia.settings.separator
	local t = "stand"..sp

	if ataxia.settings and ataxia.settings.use and ataxia.settings.use.parry and ataxia.parry ~= "manual" then
		if ataxia.parrying.shouldparry ~= ataxia.parrying.limb then
			t = t.."parry "..ataxia.parrying.shouldparry..sp
		end
	end

	if tChaseTimer and not targetIshere then
		if dir_left ~= "fly" and dir_left ~= "ether" and dir_left ~= "forcefly" then
			t = t..dir_left..sp
		elseif dir_left == "forcefly" and not affed("tension") then
			t = t.."land"..sp
		elseif dir_left == "fly" and ataxiaTables.depthswalker.wordBal and haveWord("heila") then
			t = t.."intone heila"..sp
		else
			t = t.."touch tentacle "..target..sp
		end
	end
	
	if haveAff("shield") or attuningPerson then
		t = t.."wield shield dagger"..sp
		attuningPerson = nil
	else
		t = t.."wield shield scythe"..sp.."wipe scythe"..sp
	end
	return t
end

function resetNeededAffs()
	tarNeeds = {}
	table.insert(tarNeeds, "paralysis")
	table.insert(tarNeeds, "impatience")
	table.insert(tarNeeds, getLockingAffliction())
	table.insert(tarNeeds, "asthma")
	table.insert(tarNeeds, "vertigo")
	table.insert(tarNeeds, "dizziness")
	table.insert(tarNeeds, "anorexia")
	table.insert(tarNeeds, "slickness")
end

function predictBal(bal, time)
  balTime = balTime or {}
  balTime[bal] = getEpoch() + time
end

function getPredictBal(bal)
  return balTime[bal] or getEpoch() + 0.01
end