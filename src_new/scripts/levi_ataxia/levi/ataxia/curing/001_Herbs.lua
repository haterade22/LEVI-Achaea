--[[mudlet
type: script
name: Herbs
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- Combat
- Curing
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

function taTempers()
	if tAffs.anorexia then erAff("anorexia") end
  predictBal("herb", 1.55)	
	local temper = {"melancholic", "sanguine", "phlegmatic", "choleric"}
	local highest = ""
	local highest_value = 0
	local tied = {}

	for i=1, #temper do
		if tAffs[temper[i]] and tAffs[temper[i]] > highest_value then
			highest = temper[i]
			highest_value = tAffs[temper[i]]
			tied = { temper[i] }
		elseif tAffs[temper[i]] and tAffs[temper[i]] == highest_value then
			table.insert(tied, temper[i])
		end
	end
	
	if highest_value > 0 and #tied == 1 then
		highest = tied[1]
	elseif highest_value > 0 and #tied > 1 then
		highest = tied[math.random(1, #tied)]
	end
	
	if highest ~= "" then
		tAffs[highest] = tAffs[highest] - 1
		if tAffs[highest] == 0 or tAffs[highest] < 0 then
			tAffs[highest] = nil
		end
	end
end

function targetAte(herb)
	if tAffs.anorexia then erAff("anorexia") end
	for i=1, #curingTable[herb] do
		if haveAff(curingTable[herb][i]) then	
			if herb == "goldenseal" and curingTable[herb][i] ~= "impatience" then
				if haveAff("impatience") then
					lastGoldenseal = curingTable[herb][i]
					tempTimer(1, [[lastGoldenseal = nil]])
				end
			elseif herb == "ginseng" and curingTable[herb][i] == "haemophilia" then
				tAffs.bleed = 0
			elseif herb == "kelp" and haveAff("asthma") and haveSmokeAff() then
				lastKelp = curingTable[herb][i]
				tempTimer(0.4, [[ restoreLastKelp() ]])
			end
			erAff(curingTable[herb][i])
			break
		end
	end
  predictBal("herb", 1.55)	
end

function flushingsProc()
	if tAffs.anorexia then erAff("anorexia") end
  local fl = {"lethargy", "haemophilia", "addiction", "nausea", "scytherus", "darkshade"}
	for i=1, #fl do
		if haveAff(fl[i]) then	
			if fl[i] == "haemophilia" then
				tAffs.bleed = 0
      end
			erAff(fl[i])
			break
		end
	end
end