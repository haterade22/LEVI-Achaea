function disable_harvester()
	mmp.pause("off")
	autoHarvesting = false
	ataxiaBasher.enabled = false
	ataxiaBasher.paused = false
	ataxiaBasher.manual = false
	ataxiaBasher.areabash = false
	ataxiaEcho("Harvesting systems disengaged.")
	raiseEvent("basher disabled")
	ataxiaHarvester_manual_harvesting = false
end

function enable_harvester()
	mmp.pause("off")
	ataxiaBasher_generatePath()
	autoHarvesting = true
	ataxiaBasher.enabled = true
	harvest_goto = ataxiaBasher_path[1]
	harvest_in_room = {}
	autoHarvest_rooms = {}	
	ataxiaEcho("Complete control sacrificed. Beginning the harvest.")
	ataxiaHarvester_manual_harvesting = false
	raiseEvent("basher enabled")
end

function enable_harvesterm()
	ataxiaHarvester_manual_harvesting = true
	autoHarvesting = true
	ataxiaBasher.enabled = true
  ataxiaBasher.manual = true
	harvest_in_room = {}
	autoHarvest_rooms = {}
	ataxiaEcho("Harvesting systems engaged.")
	raiseEvent("basher enabled")
end

function disable_extractor()
	mmp.pause("off")
	autoExtracting = false
	ataxiaBasher.enabled = false
	ataxiaBasher.paused = false
	ataxiaBasher.manual = false
	ataxiaBasher.areabash = false
	ataxiaEcho("Extraction systems disengaged.")
	raiseEvent("basher disabled")
	ataxiaHarvester_manual_extracting = false
end

function enable_extractor()
	mmp.pause("off")
	ataxiaBasher_generatePath()
	autoExtracting = true
	ataxiaBasher.enabled = true
	harvest_goto = ataxiaBasher_path[1]
	harvest_in_room = {}
	autoHarvest_rooms = {}	
	ataxiaEcho("Complete control sacrificed. Beginning extraction process.")
	ataxiaHarvester_manual_extracting = false
	raiseEvent("basher enabled")
end

function enable_extractorm()
	ataxiaHarvester_manual_extracting = true
	autoExtracting = true
	ataxiaBasher.enabled = true
  ataxiaBasher.manual = true
	harvest_in_room = {}
	autoHarvest_rooms = {}
	ataxiaEcho("Extracting systems engaged.")
	raiseEvent("basher enabled")
end