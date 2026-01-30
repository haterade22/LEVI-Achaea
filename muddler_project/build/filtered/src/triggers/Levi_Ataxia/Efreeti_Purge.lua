if isTargeted(matches[2]) then
	deleteLine()
	cecho("\n<a_brown>[<"..affs_to_colour.burns[1]..">"..affs_to_colour.burns[2].."<a_brown>] <CadetBlue>"..matches[1])
	
	if not haveAff("dehydrate") then
		tAffs.burns = 1
	else
		if not tAffs.burns or tAffs.burns <= 1 then
			tAffs.burns = 1
		end
	end
  if ataxia_isClass("Magi") then
	 cecho(" <DimGrey>[<red>"..tAffs.burns.."/5<DimGrey>]")
  end
end