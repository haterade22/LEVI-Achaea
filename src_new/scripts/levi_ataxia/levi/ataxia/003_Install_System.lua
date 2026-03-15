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
  send("config commandseparator ;")
  send("config usequeueing yes")

	ataxia_defaultSettings()

	-- Show precache config so user can set herb/mineral outrift amounts
	ataxiaEcho("Configure your herb and mineral precaching below. Use (+) and (-) to adjust:")
	ataxia_precacheShow()

	-- Prompt user about parry modes
	cecho("\n")
	ataxiaEcho("Set your parry mode with: <green>parryy <mode>")
	cecho("\n  <white>AUTO       <green>Class-aware auto parry (adapts to enemy attack patterns)")
	cecho("\n  <white>STAND      <green>Focus on parrying what will get/keep you standing")
	cecho("\n  <white>DEFEND     <green>Focus on parrying what's closest to breaking, with weights")
	cecho("\n  <white>MANUAL     <green>Manually set your parrying")
	cecho("\n  <white>RANDOMARM  <green>Parries a random arm (2.5s cooldown between swaps)")
	cecho("\n  <white>RANDOMLEG  <green>Parries a random leg (2.5s cooldown between swaps)")
	cecho("\n  <DimGrey>  e.g.: parryy auto\n")

	-- Prompt user to create a defence profile
	cecho("\n")
	ataxiaEcho("Set up a defence profile to manage your defences:")
	cecho("\n  <NavajoWhite>1. Create a profile:    <green>aconfig profile create <name>")
	cecho("\n  <NavajoWhite>2. Switch to it:        <green>defswitch <name>")
	cecho("\n  <NavajoWhite>3. Add defences:        <green>defs valid <DimGrey>— shows clickable [D]efup/[K]eepup toggles")
	cecho("\n  <NavajoWhite>4. View your profile:   <green>ashow defup")
	cecho("\n  <DimGrey>  e.g.: aconfig profile create pvp\n")
end

function ataxia_updateApplied(_, name)
	if name:find("Ataxia") or name:find("ataxia") then
		ataxiaEcho("System package has been successfully installed.")
		checkedMissingVariables = false
		ataxiaCheckForMissing()
		system_packageName = name
		
		if ataxia_changeLog then ataxia_changeLog() end
	end
end
registerAnonymousEventHandler("sysInstallPackage", "ataxia_updateApplied")

