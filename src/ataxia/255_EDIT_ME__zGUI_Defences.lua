-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > ZulahGUI - Saonji Edit > zGUI Redux > EDIT ME: zGUI Defences

function zgui.setupDefences()
-------------------------------------------------------------
	zgui.defs = zgui.defs or {}
	zgui.defs.classless = {
		["basic"] = {
			"insomnia",
			"cloak",
			"mindseye",	
			"selfishness"},
		["combat"] = {
			"selfishness",
			"insomnia",
			"blindness",
			"cloak",
			"mindseye",				
			"thirdeye",
			"deafness",
			"deathsight",
			"alertness",
			"kola",
			"skywatch",
			"groundwatch",
			"levitating",
			"temperance",
			"insulation",
			"poisonresist",
			"speed",
			"nightsight"},
	}
-------------------------------------------------------------
	zgui.defs.class = {
		["none"] = {},
    ["Alchemist"] = {},
    ["Apostate"] = {},
		["Bard"] = {
			"tune",
			"lay"},        
		["Blademaster"] = {
			"shinbinding",
			"shintrance",
			"shinclarity",
			"mindnet",
			"twoartsstance",
			"weathering",
			"toughness"},
    ["Depthswalker"] = {},
    ["Druid"] = {},
    ["Infernal"] = {},
    ["Jester"] = {},
		["Magi"] = {
			"stoneskin",
			"stonefist",
			"chargeshield",
			"diamondskin"},                	
		["Monk"] = {                   
			"kaitrance",
			"vitality",
			"mindnet",
			"splitmind",
			"weathering",
			"toughness",
			"regeneration",
			"boostedregeneration",
			"vitality",
			"resistance",
			"constitution"},              
    ["Occultist"] = {},
    ["Paladin"] = {},
    ["Priest"] = {},
    ["Psion"] = {},
    ["Runewarden"] = {},
    ["Sentinel"] = {},         
		["Serpent"] = {
			"hiding",
			"shroud",
			"scales",
			"pacing",
			"lipreading",
			"ghost",
			"secondsight"},
    ["Shaman"] = {},
    ["Sylvan"] = {},         
	}
	
end