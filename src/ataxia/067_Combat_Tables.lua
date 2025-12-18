-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Ataxia-DownloadThis > Ataxia > Combat > Combat Tables

function load_Combat_Tables()
	ataxiaTables.combat = {}
	ataxiaTables.combat.permitted = {"Bard", "Blademaster", "Psion", "Unnamable"}
	local class = gmcp.Char.Status.class:title()
  if class:find("Earth") then
    ataxia.vitals.shaping = 0
  end
	if not table.contains(ataxiaTables.combat.permitted, class) then
		ataxiaEcho("Combat vars not yet setup for this class. This won't actually affect anything, though.")
	else
		retrieve_CombatVariables(class)
	end
end

function retrieve_CombatVariables(class)
	local combatVars = {
		Bard = {
			clumsiness = "sing maqam at tar",
			confusion = "recite haiku at tar",
			claustrophobia = "sing isorhythm at tar",
			nausea = "recite poem at tar",
			vertigo = "sing pastorale at tar",
			generosity = "chant gimmegimme at tar",
			epilepsy = "sing ditty at tar",
			impatience = "sing limerick at tar",
			paranoia = "sing requiem at tar",
			paralysis = "recite epic at tar",
			addiction = "recite ode at tar",
			anorexia = "sing qasida at tar",
			stupidity = "sing passion at tar",
      dizziness = "sing maqam at tar",
		},
		Blademaster = {
			hamstring = "strike tar hamstring",
			slickness = "strike tar underarm",
			anorexia = "strike tar stomach",
			asthma = "strike tar throat",
			hypochondria = "strike tar chest",
			recklessness = "strike tar groin",
			stupidity = "strike tar temple",
			hallucinations = "strike tar eyes",
			paralysis = "strike tar neck",
			addiction = "strike tar kidneys",
			disloyalty = "strike tar nose",
			clumsiness = "strike tar ears",
			weariness = "strike tar shoulder",
		},
		Psion = {
			paralysis = "weave prepare disruption",
			haemophilia = "weave prepare laceration",
			clumsiness = "weave prepare dazzle",
			epilepsy = "weave prepare rattle",
			asthma = "weave prepare vapours",
		},
    Unnamable = {
      nausea = "croon revelation tar",
      horror = "unnamable horror tar",
      manaleech = "croon corrosion tar",
      addiction = "croon hunger tar",
    },
	}
	ataxiaTables.combat[class] = {}
	for aff, com in pairs(combatVars[class]) do
		ataxiaTables.combat[class][aff] = com 
	end
	ataxiaEcho("Combat vars retrieved for "..class.." - Held at ataxiaTables.combat."..class)
end