--[[mudlet
type: script
name: Firelord Stuff
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

--if string.find(ataxiaTemp.class, "fire") then ataxiaTemp.firelord = {} end

function firelord_Branded()
  cinsertText("<maroon>BRAND<white>0 <brown>| ")
  ataxiaTemp.firelord.brand = 0
end

function firelord_Lower()
  ataxiaTemp.firelord.brand = ataxiaTemp.firelord.brand - 1
  if ataxiaTemp.firelord.brand <= 0 then
    cinsertText("<maroon>BRAND<white>0 <brown>| ")
  elseif ataxiaTemp.firelord.brand <= 1 then
    cinsertText("<maroon>BRAND<yellow>"..ataxiaTemp.firelord.brand.." <brown>| ")
  elseif ataxiaTemp.firelord.brand <= 3 then
    cinsertText("<maroon>BRAND<orange>"..ataxiaTemp.firelord.brand.." <brown>| ")
  else
    cinsertText("<maroon>BRAND<red>"..ataxiaTemp.firelord.brand.." <brown>| ")
  end
end

function firelord_Raise()
  ataxiaTemp.firelord.brand = ataxiaTemp.firelord.brand + 1
  if ataxiaTemp.firelord.brand >= 4 then ataxiaTemp.firelord.brand = 4 end
  if ataxiaTemp.firelord.brand <= 0 then
    cinsertText("<maroon>BRAND<white>0 <brown>| ")
  elseif ataxiaTemp.firelord.brand <= 1 then
    cinsertText("<maroon>BRAND<yellow>"..ataxiaTemp.firelord.brand.." <brown>| ")
  elseif ataxiaTemp.firelord.brand <= 3 then
    cinsertText("<maroon>BRAND<orange>"..ataxiaTemp.firelord.brand.." <brown>| ")
  else
    cinsertText("<maroon>BRAND<red>"..ataxiaTemp.firelord.brand.." <brown>| ")
  end
  if ataxiaTemp.firelord.brand == 4 then cecho("\n     <orange>-=<yellow> brand is maxed<orange>=-") end
end

--[[
function tarGained(event, affList )
	if not affs_to_colour then populate_aff_colours() end
	
	local cstring = "<maroon>["
	
	if event == "tar afflicted" then
		for num, aff in pairs(affList) do
			if affs_to_colour[aff] then
				cstring = cstring.."<"..affs_to_colour[aff][1]..">"..affs_to_colour[aff][2]:upper()
			else
				cstring = cstring.."<white>"..string.sub(aff, 1, 3):upper()
			end
			if num ~= #affList then cstring = cstring.."<maroon>|" end
		end
		cstring = cstring.."<maroon>] "
		cinsertText(cstring)
	end
	
	if ataxiaTemp.showingAffs then
		displayTargetAffs()
	end
end]]