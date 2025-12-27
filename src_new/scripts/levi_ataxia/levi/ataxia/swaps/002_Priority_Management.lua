--[[mudlet
type: script
name: Priority Management
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- System-related
- Curing Stuff
- Priority-related
- Swaps
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Ataxia-DownloadThis > Ataxia > System-related > Curing Stuff > Priority-related > Swaps > Priority Management

function ataxia_checkMissingSwaps()
  -- impSnap removed: Serpents no longer deliver impatience via SNAP, they use Impulse instead
  if not ataxia.prioritySwaps.paraAst then
    ataxia.prioritySwaps.paraAst = {active = true, desc = "Prioritise paralysis over slickness when asthma blocks smoking."}
  end
  if not ataxia.prioritySwaps.astWear then
    ataxia.prioritySwaps.astWear = {active = true, desc = "Prioritise asthma to prevent impulse when weariness present vs Serpent."}
  end
  if not ataxia.prioritySwaps.fratLock then
    ataxia.prioritySwaps.fratLock = {active = true, desc = "Prioritise fratricide when approaching softlock (asthma + slickness)."}
  end

end

function ataxia_resetSwaps()
	ataxia.prioritySwaps = {
		scyPara = {active = false, desc = "Raise scytherus prio if we have paralysis."},
		conDis = {active = false, desc = "Raise confusion prio if we're disrupted."},
		astImp = {active = true, desc = "Impatience prio swap for alchemist and serpents."},
		brSlick = {active = true, desc = "Raise slickness prio if kelp stacked."},
		hypoImp = {active = true, desc = "Prio hypochondria over impatience if stacked."},
		dShade = {active = true, desc = "Manage darkshade when it's about to complete."},
		ravaged = {active = false, desc = "Automatically prio mana sipping while ravagedmind is active."},
		magi = {active = false, desc = "Automatic handling for burns and frozen status."},
    psionBleed = {active = false, desc = "Elevate haemophilia once bleed is stacked up."},
    -- impSnap removed: Serpents no longer deliver impatience via SNAP, they use Impulse instead
    parshield = {active = false, desc = "Temporarily ignore paralysis when shielding."},
    WATER = {active = false, desc = "Don't get latched."},
    paraAst = {active = true, desc = "Prioritise paralysis over slickness when asthma blocks smoking."},
    astWear = {active = true, desc = "Prioritise asthma to prevent impulse when weariness present vs Serpent."},
    fratLock = {active = true, desc = "Prioritise fratricide when approaching softlock (asthma + slickness)."},
	}
	ataxia_Echo("Priority management has been set to default. Check aconfig prios for details.")
end

function ataxia_displaySwaps()
	if not ataxia.prioritySwaps then
		ataxia_resetSwaps()
		return
  else
    ataxia_checkMissingSwaps()
	end
	ataxia_Echo("Priority swaps and their details.")
	echo("\n")
	for prio, info in pairs(ataxia.prioritySwaps) do
		if not info.active then
			fg("red")
		else
			fg("green")
		end

		echoLink(prio, [[ ataxia_toggleSwap("]]..prio..[[")]], "Toggle priority swapping for "..prio..".", true)
		cecho(string.rep(" ", 10-string.len(prio)).."<NavajoWhite> "..info.desc.."\n")
	end
	send(" ")
end

function ataxia_toggleSwap(prio)
	if not ataxia.prioritySwaps then
		ataxia_resetSwaps()
		return
	end
	if not ataxia.prioritySwaps[prio].active then
		ataxia.prioritySwaps[prio].active = true
		ataxia_Echo("Priority enabled for "..prio..".")
	else
		ataxia_Echo("Priority disabled for "..prio..".")
		ataxia.prioritySwaps[prio].active = false
	end
	ataxia_saveSettings(false)
end