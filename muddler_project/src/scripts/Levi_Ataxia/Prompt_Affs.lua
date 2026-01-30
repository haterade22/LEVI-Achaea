--[[mudlet
type: script
name: Prompt Affs
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- System-related
- Curing Stuff
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

function ataxia_promptAffs()
	if not affs_to_colour then populate_aff_colours() end
	local aff_str = ""

	if (rTabSize(ataxia.afflictions) == 0 or ataxia.afflictions == {}) and not ataxia.afflictions.unknown and ataxia.vitals.bleed < 100 then
		return ""
	else
		aff_str = "<tomato> ["
		if ataxia.vitals.bleed >= 100 then
			aff_str = aff_str.." <a_red>bld(<NavajoWhite>"..ataxia.vitals.bleed.."<a_red>)"
		end
		if ataxia.afflictions.unknown then
			aff_str = aff_str.." "
			for i=1, ataxia.afflictions.unknown do
				aff_str = aff_str.."<brown>?"
			end
		end
		for aff,boo in pairs(ataxia.afflictions) do
			if type(boo) ~= "number" then
				local foundAff = false
				for conv, tab in pairs(affs_to_colour) do
					if aff == conv then
						aff_str = aff_str.." <"..tab[1]..">"..tab[2]
						foundAff = true
						break
					end
				end
				if not foundAff then aff_str = aff_str.." <NavajoWhite>"..aff end
			elseif tonumber(boo) ~= 0 then
				if aff == "temperedsanguine" then
					aff_str = aff_str.." <a_red>TS(<white>"..boo.."<a_red>)"
				elseif aff == "temperedphlegmatic" then
					aff_str = aff_str.." <NavajoWhite>TP(<white>"..boo.."<NavajoWhite>)"
				elseif aff == "temperedcholeric" then
					aff_str = aff_str.." <DarkGreen>TC(<white>"..boo.."<DarkGreen>)"
				elseif aff == "temperedmelancholic" then
					aff_str = aff_str.." <DodgerBlue>TM(<white>"..boo.."<DodgerBlue>)"
				elseif aff == "skullfractures" then
					aff_str = aff_str.." <a_darkred>Sf(<white>"..boo.."<a_darkred>)"
				elseif aff == "torntendons" then
					aff_str = aff_str.." <a_darkred>Tt(<white>"..boo.."<a_darkred>)"
				elseif aff == "crackedribs" then
					aff_str = aff_str.." <a_red>Cr(<white>"..boo.."<a_darkred>)"
        	elseif aff == "crescendo" then
					aff_str = aff_str.." <a_red>Cres(<white>"..boo.."<a_darkred>)"
				elseif aff == "wristfractures" then
					aff_str = aff_str.." <a_red>Wf(<white>"..boo.."<a_darkred>)"
				elseif aff == "pressure" then
					aff_str = aff_str.." <purple>Pr(<white>"..boo.."<purple>)"
				elseif aff == "burning" then
					aff_str = aff_str.." <orange>burns(<white>"..boo.."<orange>)"
				elseif aff == "unweavingmind" then
					aff_str = aff_str.." <a_yellow>UWM(<white>"..boo.."<a_yellow>)"
				elseif aff == "unweavingbody" then
					aff_str = aff_str.." <sienna>UWB(<white>"..boo.."<sienna>)"
				elseif aff == "unweavingspirit" then
					aff_str = aff_str.." <NavajoWhite>UWS(<white>"..boo.."<NavajoWhite>)"	
        elseif aff == "horror" then
          aff_str = aff_str.." <magenta>HORROR(<white>"..boo.."<magenta>)"
        elseif aff == "pyre" then
          aff_str = aff_str.." <magenta>PYRE(<white>"..boo.."<magenta>)"
				end
			end
		end
    aff_str = aff_str .. ataxia_promptLocks()
    -- Add Damnation warning when fighting Paladin with head broken + pyre/burning
    if getDamnationPromptWarning then
      aff_str = aff_str .. getDamnationPromptWarning()
    end
		aff_str = aff_str .. " <tomato>]"
	end
	return aff_str
end--[[mudlet
type: script
name: Prompt Affs
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- System-related
- Curing Stuff
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

function ataxia_promptAffs()
	if not affs_to_colour then populate_aff_colours() end
	local aff_str = ""

	if (rTabSize(ataxia.afflictions) == 0 or ataxia.afflictions == {}) and not ataxia.afflictions.unknown and ataxia.vitals.bleed < 100 then
		return ""
	else
		aff_str = "<tomato> ["
		if ataxia.vitals.bleed >= 100 then
			aff_str = aff_str.." <a_red>bld(<NavajoWhite>"..ataxia.vitals.bleed.."<a_red>)"
		end
		if ataxia.afflictions.unknown then
			aff_str = aff_str.." "
			for i=1, ataxia.afflictions.unknown do
				aff_str = aff_str.."<brown>?"
			end
		end
		for aff,boo in pairs(ataxia.afflictions) do
			if type(boo) ~= "number" then
				local foundAff = false
				for conv, tab in pairs(affs_to_colour) do
					if aff == conv then
						aff_str = aff_str.." <"..tab[1]..">"..tab[2]
						foundAff = true
						break
					end
				end
				if not foundAff then aff_str = aff_str.." <NavajoWhite>"..aff end
			elseif tonumber(boo) ~= 0 then
				if aff == "temperedsanguine" then
					aff_str = aff_str.." <a_red>TS(<white>"..boo.."<a_red>)"
				elseif aff == "temperedphlegmatic" then
					aff_str = aff_str.." <NavajoWhite>TP(<white>"..boo.."<NavajoWhite>)"
				elseif aff == "temperedcholeric" then
					aff_str = aff_str.." <DarkGreen>TC(<white>"..boo.."<DarkGreen>)"
				elseif aff == "temperedmelancholic" then
					aff_str = aff_str.." <DodgerBlue>TM(<white>"..boo.."<DodgerBlue>)"
				elseif aff == "skullfractures" then
					aff_str = aff_str.." <a_darkred>Sf(<white>"..boo.."<a_darkred>)"
				elseif aff == "torntendons" then
					aff_str = aff_str.." <a_darkred>Tt(<white>"..boo.."<a_darkred>)"
				elseif aff == "crackedribs" then
					aff_str = aff_str.." <a_red>Cr(<white>"..boo.."<a_darkred>)"
        	elseif aff == "crescendo" then
					aff_str = aff_str.." <a_red>Cres(<white>"..boo.."<a_darkred>)"
				elseif aff == "wristfractures" then
					aff_str = aff_str.." <a_red>Wf(<white>"..boo.."<a_darkred>)"
				elseif aff == "pressure" then
					aff_str = aff_str.." <purple>Pr(<white>"..boo.."<purple>)"
				elseif aff == "burning" then
					aff_str = aff_str.." <orange>burns(<white>"..boo.."<orange>)"
				elseif aff == "unweavingmind" then
					aff_str = aff_str.." <a_yellow>UWM(<white>"..boo.."<a_yellow>)"
				elseif aff == "unweavingbody" then
					aff_str = aff_str.." <sienna>UWB(<white>"..boo.."<sienna>)"
				elseif aff == "unweavingspirit" then
					aff_str = aff_str.." <NavajoWhite>UWS(<white>"..boo.."<NavajoWhite>)"	
        elseif aff == "horror" then
          aff_str = aff_str.." <magenta>HORROR(<white>"..boo.."<magenta>)"
        elseif aff == "pyre" then
          aff_str = aff_str.." <magenta>PYRE(<white>"..boo.."<magenta>)"
				end
			end
		end
    aff_str = aff_str .. ataxia_promptLocks()
    -- Add Damnation warning when fighting Paladin with head broken + pyre/burning
    if getDamnationPromptWarning then
      aff_str = aff_str .. getDamnationPromptWarning()
    end
		aff_str = aff_str .. " <tomato>]"
	end
	return aff_str
end