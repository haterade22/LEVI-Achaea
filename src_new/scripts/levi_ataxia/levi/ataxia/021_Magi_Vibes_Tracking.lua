--[[mudlet
type: script
name: Magi Vibes Tracking
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- Combat
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

function magiVibes_isHere(what)
  vibes_inRoom = vibes_inRoom or {}
  local vibeEffects = {
    ["thrumming vibration"] = {name = "dissipate", effect = "drains mana"},
    ["hums irregularly"] = {name = "palpitation", effect = "deals damage"},
    ["loud ringing sound"] = {name = "alarm", effect = "alerts when enemy enters"},
    ["tremors vibration"] = {name = "tremors", effect = "prones/strips levitation"},
    ["barely heard tone"] = {name = "reverberation", effect = "protects vibes"},
    ["feeling of oppression"] = {name = "adduction", effect = "pulls unmassed enemies"},
    ["pleasant harmony"] = {name = "harmony", effect = "heals vitals/afflictions"},
    ["filled with tension"] = {name = "creeps", effect = "periodic shyness"},
    ["profound silence"] = {name = "silence", effect = "prevents talking in room"},
    ["crystal-clear tone"] = {name = "revelation", effect = "reveals hidden people"},
    ["discordant music"] = {name = "oscillate", effect = "periodic amnesia"},
    ["surroundings distort"] = {name = "disorientation", effect = "periodic dizziness"},
    ["vibrating circle of energy"] = {name = "energise", effect = "absorbs health from enemies"},
    ["high-pitched keening"] = {name = "stridulation", effect = "disrupts undeaf/strips deaf"},
    ["dust in the air"] = {name = "gravity", effect = "stops flying"},
    ["forest of small sharp crystals"] = {name = "forest", effect = "damage on prone"},
    ["dissonant hum"] = {name = "dissonance", effect = "causes dissonance affliction"},
    ["skin crawls"] = {name = "plague", effect = "hidden afflictions"},
    ["air vibrates"] = {name = "lullaby", effect = "periodic sleep"},
  }
  
  for line, list in pairs(vibeEffects) do
    if what:lower() == list.name then
      cecho("  -  <a_yellow>"..list.effect)
      vibes_inRoom[list.name] = true
      break
    elseif string.find(what, line) then
      deleteLine()
      cecho("\n<magenta>[<a_magenta>VIBE<magenta>]: <NavajoWhite>"..list.name:title().." active here - <a_yellow>"..list.effect..".")
      vibes_inRoom[list.name] = true
      break
    end
  end
end

function magiVibes_nextEmbed()
	if not next(ataxiaTemp.vibes) then
		ataxiaTemp.embeddingVibes = nil
		ataxiaEcho("All defined vibes have been embedded.")
	else
		ataxiaEcho("Embedding "..ataxiaTemp.vibes[1].." next.")
		send("queue addclear free embed "..ataxiaTemp.vibes[1],false)
	end
	
end