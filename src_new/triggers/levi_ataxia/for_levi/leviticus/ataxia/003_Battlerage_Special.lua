--[[mudlet
type: trigger
name: Battlerage Special
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Basher
- Bashing
- Basher Lines
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'no'
  isPerlSlashGOption: 'no'
  isColorizerTrigger: 'no'
  isFilterTrigger: 'no'
  isSoundTrigger: 'no'
  isColorTrigger: 'no'
  isColorTriggerFg: 'no'
  isColorTriggerBg: 'no'
triggerType: 0
conditonLineDelta: 0
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^You direct nature to restrain .+, and vines flash from nothingness into being to bind \w+\.$
  type: 1
- pattern: The runes on your armour flare brightly as you adopt a defensive stance.
  type: 3
- pattern: ^You hurl a precise blast of Shin energy at (.+)'s eyes\.$
  type: 1
- pattern: ^You think back to the moment when you were reborn from your doom
  type: 1
- pattern: ^You draw (.+)'s attention with the wavering tip of one finger, then quickly snap your fingers in front of \w+
    face, the sudden sound temporarily blanking \w+ mind\.$
  type: 1
- pattern: A miasma of black flames springs up around you.
  type: 3
- pattern: ^You summon a polar vortex in a tight field around (.+), chilling the small pocket so intensely that time itself
    begins to slow\.$
  type: 1
- pattern: ^You let loose a steady stream of cold air around (.+), who begins to shiver uncontrollably\.$
  type: 1
- pattern: ^You hold out one hand towards (.+) as something made of shadow and ice rises from the ground and flies into \w+\.$
  type: 1
- pattern: ^You rummage quickly through (.+)'s mind, finding the link to fine motor control before exerting a small amount
    of psychic force and deadening it\.$
  type: 1
- pattern: ^You open your enormous maw and let loose a mighty roar at (.+), causing \w+ to quail in fear\.$
  type: 1
- pattern: ^You direct your voice in a high-pitched trill at (.+), dazing \w+\.$
  type: 1
]]--

ataxiaBasher.shielded = false
ataxiaTemp.ignoreCrits = false
bashStats.attacks = bashStats.attacks + 1

if gmcp.Char.Status.class == "Apostate" then
battleRage_Timers.special = tempTimer(44, [[battleRage_Timers.special = nil]])
if partyrelay then
      send("pt Battlerage - Charmed given to " ..target)
    end
end

if gmcp.Char.Status.class == "Black Dragon" then
battleRage_Timers.special = tempTimer(35, [[battleRage_Timers.special = nil]])
if partyrelay then
      send("pt Battlerage - Fear given to " ..target)
    end
end

if gmcp.Char.Status.class == "Monk" then
battleRage_Timers.special = tempTimer(32, [[battleRage_Timers.special = nil]])
if partyrelay then
      send("pt Battlerage - Clumsiness given to " ..target)
    end
end

if gmcp.Char.Status.class == "Psion" then
battleRage_Timers.special = tempTimer(36, [[battleRage_Timers.special = nil]])
end

if gmcp.Char.Status.class == "Magi" then
battleRage_Timers.special = tempTimer(36, [[battleRage_Timers.special = nil]])
if partyrelay then
      send("pt Battlerage - Aeon given to " ..target)
    end
end
if gmcp.Char.Status.class == "Runewarden" then
battleRage_Timers.special = tempTimer(46, [[battleRage_Timers.special = nil]])
end

if gmcp.Char.Status.class == "Infernal" then
battleRage_Timers.special = tempTimer(38, [[battleRage_Timers.special = nil]])
end

if gmcp.Char.Status.class == "Blue Dragon" then
battleRage_Timers.special = tempTimer(24, [[battleRage_Timers.special = nil]])
if partyrelay then
      send("pt Battlerage - Clumsiness given to " ..target)
    end
end

if gmcp.Char.Status.class == "Blademaster" then
battleRage_Timers.special = tempTimer(34, [[battleRage_Timers.special = nil]])
  if not ataxia.afflictions.aeon then
    if partyrelay then
      send("pt Battlerage - Stun given to " ..target)
    end
  end
end
if gmcp.Char.Status.class == "Pariah" then
battleRage_Timers.special = tempTimer(39, [[battleRage_Timers.special = nil]])
  if not ataxia.afflictions.aeon then
    if partyrelay then
      send("pt Battlerage - Clumsiness given to " ..target)
    end
  end
end
if gmcp.Char.Status.class == "Serpent" then
battleRage_Timers.special = tempTimer(42, [[battleRage_Timers.special = nil]])
  if not ataxia.afflictions.aeon then
    if partyrelay then
      send("pt Battlerage - Amnesia given to " ..target)
    end
  end
end

if gmcp.Char.Status.class == "Bard" then
battleRage_Timers.special = tempTimer(42, [[battleRage_Timers.special = nil]])
  if not ataxia.afflictions.aeon then
    if partyrelay then
      send("pt Battlerage - Amnesia given to " ..target)
    end
  end
end


if type(target) == "number" and ataxiaBasher.enabled then
	bashConsoleEcho("battlerage", "Used Special battlerage")
	if not ataxiaBasher.manual then
		deleteFull()
	end
end

