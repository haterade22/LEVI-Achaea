--[[mudlet
type: script
name: Check For Any Missing Variables
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- System-related
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

function ataxiaCheckForMissing()
	checkedMissingVariables = true
  local sp
	if ataxia then
    ataxia.settings.separator = ";"
    sp = ataxia.settings.separator
  end
  
  if ataxia.settings.highlighting == nil then
    ataxia.settings.highlighting = {}
    ataxiaEcho("Highlight settings not found. Changed to default.")
    ataxiaEcho("See 'item highlighting' alias for more info.")
  end
  
  if ataxia.usegui == nil then
    ataxia.usegui = true
    ataxiaEcho("Using default GUI for the system.")
  end
  
  if ataxia.settings.goldcommand == nil then
    ataxia.settings.goldcommand = "get gold"..sp.."put gold in pack"
    ataxiaEcho("Gold grabbing command defaulted to: <green>"..ataxia.settings.goldcommand)
    ataxiaEcho("<green>aconfig goldgrab (command)<NavajoWhite> to set it.")
  end
  
	if ataxia.settings.lustlist == nil then
		ataxia.settings.lustlist = {}
		ataxiaEcho("Lust settings not found. Changed to default.")
		ataxiaEcho("<green>lustallow <name><NavajoWhite> to use.")
		ataxiaEcho("Will also remove if they're already on the list.")
		ataxiaEcho("For queueing purposes you can also call ataxia_needReject() to check if you need to reject.")
		ataxiaEcho("If it returns true, ataxiaTemp.reject will be set to the person.")
		ataxiaEcho("<green>lustallow list<NavajoWhite> will show everyone on the list.")
	end
	
	if ataxia.settings.relayingto == nil then
		ataxia.settings.relayingto = false
		ataxiaEcho("Channel relay setting not found, adding it in. Default is faulse.")
		ataxiaEcho("<green>aconfig relay <channel> <NavajoWhite>to change.")
		ataxiaEcho("<green>aconfig relay clt2 <NavajoWhite>for example.")
		ataxiaEcho("'false' or 'off' will disable callouts again.")
	end
	
	if ataxiaBasher.rageraze == nil then
		ataxiaBasher.rageraze = false
		ataxiaEcho("Battlerage razing option not found; defaulting to false.")
		ataxiaEcho("<green>bash rageraze on/off <NavajoWhite>to change.")
	end
	
	if ataxia.prioritySwaps and ataxia.prioritySwaps.ravaged == nil then
		ataxia.prioritySwaps.ravaged = {active = false, desc = "Automatically prio mana sipping while ravagedmind is active."}
		ataxiaEcho("Ravagedmind priority swap not found. Added it to swaps; default is off.")
	end
	
  if ataxia.prioritySwaps and ataxia.prioritySwaps.psionBleed == nil then
		ataxia.prioritySwaps.psionBleed = {active = false, desc = "Automatic prio on haemophilia once bleed is stacked."}
		ataxiaEcho("Psionbleed priority swap not found. Added it to swaps; default is off.")  
  end
  
  if ataxia.prioritySwaps and ataxia.prioritySwaps.parshield == nil then
    ataxia.prioritySwaps.parshield = {active = false, desc = "Temporarily ignore paralysis on shielding."}
    ataxiaEcho("Parshield priority swap not found. Added it to swaps; default is off.")
  end
  
	if ataxia.prioritySwaps and ataxia.prioritySwaps.magi == nil then
		ataxia.prioritySwaps.magi = {active = false, desc = "Automatic handling for burns and frozen status."}
		ataxiaEcho("Magi priority swap not found. Added it to swaps; default is off.")
	end
	
	if not ataxia.settings.roomshorten then
		ataxiaEcho("Room condense setting not found. Defaulting to normal; see changelog for information.")
		ataxia.settings.roomshorten = "normal"
	end
	
	if ataxiaBasher.treeblackout == nil then
		ataxiaBasher.treeblackout = false
		ataxiaEcho("Bashing Tree Setting not found: Reverting to default; won't use tree when blacked out while bashing.")
		cecho("\n     <NavajoWhite>aconfig treeblackout <NavajoWhite> to toggle.")
	end
	
	if ataxia.settings.autogallop == nil then
		ataxia.settings.autogallop = false
		ataxiaEcho("Auto Gallop Setting not found: Reverting to default; won't toggle gallop when mounted.")
		cecho("\n     <NavajoWhite>aconfig gallop <on/off> to toggle.")
	end
	
	if not ataxia.sylvanStuff then
		ataxia.sylvanStuff = {propagateList = {arms = false, legs = false, head = false, body = false}}
		ataxiaEcho("Sylvan stuff defaulted to normal values. Check <red>aconfig sylvan help<Navajowhite> for info.")
		ataxiaEcho("If you're not a Sylvan then ignore this.")
	end
	end
