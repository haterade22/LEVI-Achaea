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

	-- Find all matching afflictions and their confidence levels
	local candidates = {}
	for i=1, #curingTable[herb] do
		local aff = curingTable[herb][i]
		if haveAff(aff) then
			local conf = getAffConfidence and getAffConfidence(aff) or 1.0
			table.insert(candidates, {aff = aff, confidence = conf, priority = i})
		end
	end

	if #candidates == 0 then
		-- No matching afflictions, nothing to cure
		predictBal("herb", 1.55)
		return
	end

	-- If only one candidate, it's definitely the one being cured
	if #candidates == 1 then
		local aff = candidates[1].aff
		if herb == "goldenseal" and aff ~= "impatience" then
			if haveAff("impatience") then
				lastGoldenseal = aff
				tempTimer(1, [[lastGoldenseal = nil]])
			end
		elseif herb == "ginseng" and aff == "haemophilia" then
			tAffs.bleed = 0
		elseif herb == "kelp" and haveAff("asthma") and haveSmokeAff() then
			lastKelp = aff
			tempTimer(0.4, [[ restoreLastKelp() ]])
		end
		erAff(aff)
	else
		-- Multiple candidates - uncertain which was cured
		-- For kelp with asthma: reduce ALL to 0.5, wait for smoke to disambiguate
		if herb == "kelp" and haveAff("asthma") then
			-- Store all kelp afflictions that might have been cured
			lastKelpAffs = {}
			for _, c in ipairs(candidates) do
				lastKelpAffs[c.aff] = true
				-- Reduce confidence of ALL matching afflictions to 0.5
				if setAffConfidence then
					setAffConfidence(c.aff, 0.5)
				end
			end
			-- Don't remove any yet - wait for smoke or other action to disambiguate
		else
			-- For non-kelp herbs or kelp without asthma: use priority-based reduction
			local bestCandidate = candidates[1]
			for i=2, #candidates do
				if candidates[i].confidence > bestCandidate.confidence + 0.3 then
					bestCandidate = candidates[i]
				end
			end

			local affToCure = bestCandidate.aff

			-- Special handling
			if herb == "goldenseal" and affToCure ~= "impatience" then
				if haveAff("impatience") then
					lastGoldenseal = affToCure
					tempTimer(1, [[lastGoldenseal = nil]])
				end
			elseif herb == "ginseng" and affToCure == "haemophilia" then
				tAffs.bleed = 0
			end

			-- Use confidence reduction if available, otherwise fall back to erAff
			if reduceAffConfidence then
				local removed = reduceAffConfidence(affToCure, 0.5)
				if removed then
					if ataxiaTemp.showingAffs then
						displayTargetAffs()
					elseif zgui then
						zgui.showTarAffs()
					end
					raiseEvent("target cured aff", affToCure)
				end
			else
				erAff(affToCure)
			end
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