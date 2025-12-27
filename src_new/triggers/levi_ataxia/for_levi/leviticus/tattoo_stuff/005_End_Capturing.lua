--[[mudlet
type: trigger
name: End Capturing
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Misc Triggers
- Tattoo Stuff
- Tattoo List
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'no'
  isPerlSlashGOption: 'no'
  isColorizerTrigger: 'no'
  isFilterTrigger: 'no'
  isSoundTrigger: 'no'
  isColorTrigger: 'no'
  isColorTriggerFg: 'no'
  isColorTriggerBg: 'no'
triggerType: 0
conditonLineDelta: 0
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ''
  type: 7
]]--

deleteLine()
echo("\n  ")
setUnderline(true)
fg("LightSlateGrey")
echo("[ Body Part ]   [ 1st Slot ] (Ch)   [ 2nd Slot ] (Ch)")
resetFormat()
setTriggerStayOpen("Tattoo List", 0) 
for slot, list in pairs(tattoosOnMe) do
	if slot == "Back" then
		if tattoosOnMe[slot][1] ~= "empty" and #tattoosOnMe[slot][1] == 0 then
			tattoosOnMe[slot][1] = "unlearned"
			tattoosOnMe[slot][2] = "unlearned"
		elseif #tattoosOnMe[slot][2] == 0 then
			tattoosOnMe[slot][2] = "unlearned"
		end
	else
		if tattoosOnMe[slot][2] ~= "empty" and #tattoosOnMe[slot][2] == 0 then
			tattoosOnMe[slot][2] = "unlearned"
		end
	end

	cecho("\n<green> "..utf8.char(186).." <NavajoWhite>"..slot..string.rep(" ", 13-string.len(slot)).."-")
	if tattoosOnMe[slot][1] ~= "empty" and tattoosOnMe[slot][1] ~= "unlearned" and #tattoosOnMe[slot][1] ~= 0 then
		cecho((tattoosOnMe[slot][1][3]=="Y" and "<ForestGreen>" or "<firebrick>").." "..tattoosOnMe[slot][1][1]:title())
		cecho(string.rep(" ", 11-string.len(tattoosOnMe[slot][1][1])).." -")
		if tattoosOnMe[slot][1][2] ~= "n/a" and tattoosOnMe[slot][1][2] ~= "art" then
			cecho((tonumber(tattoosOnMe[slot][1][2]) >= 10 and "<green> " or "<red> ")..tattoosOnMe[slot][1][2]..string.rep(" ", 4-string.len(tattoosOnMe[slot][1][2])).."<white>- ")
		elseif tattoosOnMe[slot][1][2] == "n/a" then
			cecho("<purple> "..utf8.char(186)..utf8.char(186).."<white>  - ")
		else
			cecho("<DodgerBlue> "..utf8.char(186)..utf8.char(186).."<white>  - ")
		end

	elseif tattoosOnMe[slot][1] == "empty" then
		cecho("<rosy_brown> Empty")
		cecho("       -     - ")
	else
		cecho("<SlateGrey> Unlearned")
	end

	if tattoosOnMe[slot][2] ~= "empty" and tattoosOnMe[slot][2] ~= "unlearned" then
		cecho((tattoosOnMe[slot][2][3]=="Y" and "<ForestGreen>" or "<firebrick>")..tattoosOnMe[slot][2][1]:title())
		cecho(string.rep(" ", 12-string.len(tattoosOnMe[slot][2][1])).."-")
		if tattoosOnMe[slot][2][2] ~= "n/a" and tattoosOnMe[slot][2][2] ~= "art" then
			cecho((tonumber(tattoosOnMe[slot][2][2]) >= 10 and "<green> " or "<red> ")..tattoosOnMe[slot][2][2]..string.rep(" ", 4-string.len(tattoosOnMe[slot][2][2])).."<white>- ")
		elseif tattoosOnMe[slot][2][2] == "n/a" then
			cecho("<purple> "..utf8.char(186)..utf8.char(186))
		else
			cecho("<DodgerBlue> "..utf8.char(186)..utf8.char(186))
		end

	elseif tattoosOnMe[slot][2] == "empty" then
		cecho("<rosy_brown>Empty")
	else
    if tattoosOnMe[slot][1] == "unlearned" then echo("         - ") end
		cecho("<SlateGrey>Unlearned")
	end	

end
cecho("\n<LightSlateGrey> "..utf8.char(186).."----------------------------------------------------"..utf8.char(186))
if #crucialTattoos > 0 then
	cecho("\n<LightSlateBlue>   Missing: <NavajoWhite>"..table.concat(crucialTattoos, ", ").."<LightSlateBlue>.")
	cecho("\n<LightSlateGrey> "..utf8.char(186).."----------------------------------------------------"..utf8.char(186))
end

send(" ")

