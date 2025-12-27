--[[mudlet
type: alias
name: Monk Custom Combo
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- LeviticusREG
- Leviticus
- Monks
- Monk
- Monk
- monkcustomcombo
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^(w|a|s|d|z|x|f|j|q|r|c)(w|a|s|d|z|x|e|f|q)(w|a|s|d|z|x|e|f|q)$
command: ''
packageName: ''
]]--

--stand and unwield stuff in your left and right hands
send("stand", false)
send("unwield left", false)
send("unwield right", false)

--stuff for the first letter, kick or a punching combo prefix
if matches[2] == "w" then
	comboPartOne = "wwk"
elseif matches[2] == "a" then
	comboPartOne = "mnk left"
elseif matches[2] == "s" then
	comboPartOne = "sdk"
elseif matches[2] == "d" then
	comboPartOne = "mnk right"
elseif matches[2] == "z" then
	comboPartOne = "snk left"
elseif matches[2] == "x" then
	comboPartOne = "snk right"
elseif matches[2] == "j" then
	comboPartOne = "jpk"
elseif matches[2] == "q" then
	comboPartOne = "axk"
elseif matches[2] == "f" then
	comboPartOne = "swk"
elseif matches[2] == "r" then
	comboPartOne = "rhk"
end

if matches[3] == "w" then
	comboPartTwo = "ucp"
elseif matches[3] == "a" then
	comboPartTwo = "spp left"
elseif matches[3] == "s" then
	comboPartTwo = "hkp"
elseif matches[3] == "d" then
	comboPartTwo = "spp right"
elseif matches[3] == "z" then
	comboPartTwo = "hfp left"
elseif matches[3] == "x" then
	comboPartTwo = "hfp right"
elseif matches[3] == "f" then
	comboPartTwo = "jbp arms"
elseif matches[3] == "e" then
	comboPartTwo = "jbp head"
elseif matches[3] == "q" then
	comboPartTwo = "pmp"
end

if matches[4] == "w" then
	comboPartThree = "ucp"
elseif matches[4] == "a" then
	comboPartThree = "spp left"
elseif matches[4] == "s" then
	comboPartThree = "hkp"
elseif matches[4] == "d" then
	comboPartThree = "spp right"
elseif matches[4] == "z" then
	comboPartThree = "hfp left"
elseif matches[4] == "x" then
	comboPartThree = "hfp right"
elseif matches[4] == "f" then
	comboPartThree = "jbp arms"
elseif matches[4] == "e" then
	comboPartThree = "jbp head"
elseif matches[4] == "q" then
	comboPartThree = "pmp"
end
if tAffs.shield then
comboPartOne = "rhk"
send("queue addclear freestand combo " .. target .. " " ..comboPartOne.. " " .. comboPartTwo .. " " .. comboPartThree)
else
send("queue addclear freestand combo " .. target .. " " .. comboPartOne .. " " .. comboPartTwo .. " " .. comboPartThree)
end
comboPartOne = nil
comboPartTwo = nil
comboPartThree = nil