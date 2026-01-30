comboPartThree = false
comboPartFour = false

if matches[2] == "w" then
	comboPartOne = "head"
elseif matches[2] == "a" then
	comboPartOne = "left arm"
elseif matches[2] == "s" then
	comboPartOne = "torso"
elseif matches[2] == "d" then
	comboPartOne = "right arm"
elseif matches[2] == "z" then
	comboPartOne = "left leg"
elseif matches[2] == "x" then
	comboPartOne = "right leg"
end
  
if matches[3] == "w" then
	comboPartTwo = "head"
elseif matches[3] == "a" then
	comboPartTwo = "left arm"
elseif matches[3] == "s" then
	comboPartTwo = "torso"
elseif matches[3] == "d" then
	comboPartTwo = "right arm"
elseif matches[3] == "z" then
	comboPartTwo = "left leg"
elseif matches[3] == "x" then
	comboPartTwo = "right leg"
end

if matches[4] == "e" then
  comboPartThree = "expend"
end

if (targreb == true or targshield == true) and tengage == false then
send("cq all|stand|unwield left|unwield right|wield left morningstar511732|wield right morningstar511735|hyena slay " ..target.. " |hellforge invest " ..hellf.. " |fracture " .. target.. " |engage " ..target.. " |assess " ..target)
elseif (targreb == true or targshield == true) and tengage == true then
send("cq all|stand|unwield left|unwield right|wield left morningstar511732|wield right morningstar511735|hyena slay " ..target.. " |hellforge invest " ..hellf.. " |fracture " .. target.. " |assess " ..target)


elseif tengage == false and comboPartThree == "expend" then 
send("cq all|stand|wield left morningstar511732|wield right morningstar511735|hyena slay " ..target.. " |hellforge invest " ..hellf.. " |doublewhirl " .. target .. " " .. comboPartOne .. " expend " .. comboPartTwo.. " |assess " ..target.. " |engage " ..target)
elseif tengage == true and comboPartThree == "expend" then 
send("cq all|stand|wield left morningstar511732|wield right morningstar511735|hyena slay " ..target.. " |hellforge invest " ..hellf.. " |doublewhirl " .. target .. " " .. comboPartOne .. " expend " .. comboPartTwo.. " |assess " ..target)
end

