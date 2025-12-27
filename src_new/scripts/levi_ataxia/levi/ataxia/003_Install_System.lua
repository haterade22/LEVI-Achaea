--[[mudlet
type: script
name: Install System
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

function ataxia_installSystem()
	send("config prompt all")
  send("config screenwidth 0")
	send("curing on")
	send("curing afflictions on")
	send("curing defences on")
	send("config advancedcuring on")
  send("config showqueuealerts on")
  send("config wrapwidth 0")
	send("curing batch on")
	send("curing priority health")
	send("curing reporting on")
	send("curing siphealth 80")
	send("curing sipmana 80")
	send("curing mosshealth 70")
	send("curing mossmana 70")
	send("curing clotat 30")
	send("config ragemsg off")
  send("curing fallback on")

	ataxia_defaultSettings()
  
end

function ataxia_updateApplied(_, name)
	if name:find("Ataxia") or name:find("ataxia") then
		ataxiaEcho("System package has been successfully installed.")
		checkedMissingVariables = false
		ataxiaCheckForMissing()
		system_packageName = name
		
		ataxia_changeLog()
	end
end
registerAnonymousEventHandler("sysInstallPackage", "ataxia_updateApplied")

