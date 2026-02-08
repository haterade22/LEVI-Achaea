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

    -- Find all matching afflictions
    local candidates = {}
    for i=1, #curingTable[herb] do
        local aff = curingTable[herb][i]
        if haveAff(aff) then
            table.insert(candidates, {aff = aff, priority = i})
        end
    end

    if #candidates == 0 then
        predictBal("herb", 1.55)
        return
    end

    -- Single candidate - definitely that one
    if #candidates == 1 then
        local aff = candidates[1].aff
        if herb == "goldenseal" and aff ~= "impatience" then
            if haveAff("impatience") then
                lastGoldenseal = aff
                tempTimer(1, [[lastGoldenseal = nil]])
            end
        elseif herb == "ginseng" and aff == "haemophilia" then
            tAffs.bleed = 0
        end
        erAff(aff)
    else
        -- Multiple candidates
        if herb == "kelp" and haveAff("asthma") then
            -- Kelp with asthma: wait for smoke to disambiguate
            lastKelpAffs = {}
            for _, c in ipairs(candidates) do
                lastKelpAffs[c.aff] = true
            end

            -- Timeout: if no smoke in 2s, asthma wasn't cured
            if kelpDisambiguateTimer then killTimer(kelpDisambiguateTimer) end
            kelpDisambiguateTimer = tempTimer(2, function()
                if lastKelpAffs then
                    -- No smoke = still have asthma, cure highest priority non-asthma
                    local kelps = {"hypochondria", "parasite", "weariness", "healthleech", "clumsiness", "sensitivity"}
                    for i=1, #kelps do
                        if lastKelpAffs[kelps[i]] then
                            erAff(kelps[i])
                            ataxiaEcho("No smoke: " .. kelps[i] .. " cured, asthma still present.")
                            break
                        end
                    end
                    lastKelpAffs = nil
                end
                kelpDisambiguateTimer = nil
            end)
        elseif herb == "goldenseal" then
            -- Goldenseal: use priority order, track for impatience backtrack
            local aff = candidates[1].aff
            if aff ~= "impatience" and haveAff("impatience") then
                lastGoldenseal = aff
                tempTimer(1, [[lastGoldenseal = nil]])
            end
            erAff(aff)
        else
            -- Other herbs: use priority order
            local aff = candidates[1].aff
            if herb == "ginseng" and aff == "haemophilia" then
                tAffs.bleed = 0
            end
            erAff(aff)
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