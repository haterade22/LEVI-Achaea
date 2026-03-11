--[[mudlet
type: script
name: Armour Paragons
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Gear System
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

-- Armour & Paragon Management System
-- Configurable profiles for paragon slots, traits, and armour morphing
-- Auto-swaps on basher enable/disable
-- Usage: armour [add|remove|set|show|auto|bash|pvp|morph|scan|help]

--------------------------------------------------------------------------------
-- NAMESPACE
--------------------------------------------------------------------------------

ataxia = ataxia or {}
ataxia.armour = ataxia.armour or {}

--------------------------------------------------------------------------------
-- CLASS → ARMOUR TYPE MAP
--------------------------------------------------------------------------------

ataxia.armour.classArmourType = {
  -- Full plate
  Infernal = "fullplate", Paladin = "fullplate",
  Runewarden = "fullplate", Unnamable = "fullplate",
  -- Cloth
  Magi = "cloth", Psion = "cloth", Pariah = "cloth",
  ["Red Dragon"] = "cloth", ["Blue Dragon"] = "cloth",
  ["Black Dragon"] = "cloth", ["Silver Dragon"] = "cloth",
  ["Gold Dragon"] = "cloth", ["Golden Dragon"] = "cloth",
  ["Green Dragon"] = "cloth",
  Airlord = "cloth", Earthlord = "cloth",
  Firelord = "cloth", Waterlord = "cloth",
  -- Leather
  Monk = "leather", Bard = "leather",
  -- Ringmail
  Alchemist = "ringmail", Apostate = "ringmail",
  -- Scalemail
  Serpent = "scalemail", Jester = "scalemail",
  Shaman = "scalemail", Depthswalker = "scalemail",
  Occultist = "scalemail", Blademaster = "scalemail",
  -- Chainmail
  Druid = "chainmail", Sentinel = "chainmail", Sylvan = "chainmail",
  -- Splintmail
  Priest = "splintmail",
}

--------------------------------------------------------------------------------
-- PARAGON TYPE REFERENCE (keyword → display name with effect)
-- Used by registerParagon() to resolve raw game names to clean display
--------------------------------------------------------------------------------

ataxia.armour.PARAGON_TYPES = {
  -- Damage resistance
  fuscous       = "fuscous (~5% blunt resist)",
  vinaceous     = "vinaceous (~5% cutting resist)",
  viridescent   = "viridescent (~7% poison resist)",
  piceous       = "piceous (~7% asphyx resist)",
  citreous      = "citreous (~7% magic resist)",
  aurous        = "aurous (~7% psychic resist)",
  cyaneous      = "cyaneous (~7% cold resist)",
  oleaginous    = "oleaginous (~7% fire resist)",
  caliginous    = "caliginous (~7% electricity resist)",
  metalliferous = "metalliferous (7.5% shifting resist)",
  -- Morphing
  tetrahedral   = "tetrahedral (morph, 1hr CD)",
  octahedral    = "octahedral (morph, 20min CD)",
  deltahedral   = "deltahedral (morph, 10min CD)",
  -- Combat/utility
  aeneaous      = "aeneaous (absorption)",
  prismatic     = "prismatic (auto-barrier <25% HP)",
  icosagon      = "icosagon (20% crit boost)",
  crucious      = "crucious (crit multiplier)",
  rufescent     = "rufescent (revenge dmg boost)",
  -- Regen/resource
  torpous       = "torpous (2x end/wp regen sleep)",
  niveous       = "niveous (5% dmg->EP)",
  serendipitous = "serendipitous (5% dmg->WP)",
  -- Storage/utility
  cupreous      = "cupreous (20 item container)",
  dodecahedron  = "dodecahedron (20 items + stasis)",
  euphonious    = "euphonious (discuss denizens)",
}

--------------------------------------------------------------------------------
-- CONFIGURATION (persisted)
--------------------------------------------------------------------------------

ataxia.armour.config = ataxia.armour.config or {
  autoSwap = false,
  bashProfile = nil,
  pvpProfile = nil,
  morphParagonId = "paragon424404",
  currentArmourType = nil,
  lastMorphTime = 0,
  morphCooldown = 600, -- 10 minutes
  profiles = {},
  paragons = {},       -- auto-detected: {["paragon123456"] = "a crucious paragon"}
}

--------------------------------------------------------------------------------
-- RUNTIME STATE (not persisted)
--------------------------------------------------------------------------------

ataxia.armour.state = ataxia.armour.state or {
  swapping = false,
  currentSlots = {nil, nil, nil},
  eventHandlers = {},
  scanning = false,     -- true during ii paragon scan
  probing = false,      -- true during probe armour scan
  probeSlotIndex = 0,   -- tracks which embrasure line we're on
}

--------------------------------------------------------------------------------
-- ECHO
--------------------------------------------------------------------------------

function ataxia.armour.echo(text)
  cecho("\n<dark_orchid>[<light_slate_blue>Armour<dark_orchid>]<lavender>: <plum>" .. text)
end

--------------------------------------------------------------------------------
-- PERSISTENCE (self-contained, like gearAudit)
--------------------------------------------------------------------------------

function ataxia.armour.save()
  local sep = package.config:sub(1, 1)
  local filepath = getMudletHomeDir() .. sep .. "armourconfig"
  table.save(filepath, ataxia.armour.config)

  _ataxia_backup = _ataxia_backup or {}
  _ataxia_backup.armourconfig = {}
  table.load(filepath, _ataxia_backup.armourconfig)
end

function ataxia.armour.load()
  local sep = package.config:sub(1, 1)
  local filepath = getMudletHomeDir() .. sep .. "armourconfig"
  if io.exists(filepath) then
    local loaded = {}
    table.load(filepath, loaded)
    -- Merge into existing config (preserves defaults for new fields)
    for k, v in pairs(loaded) do
      ataxia.armour.config[k] = v
    end
  elseif _ataxia_backup and _ataxia_backup.armourconfig then
    for k, v in pairs(_ataxia_backup.armourconfig) do
      ataxia.armour.config[k] = v
    end
  end
end

--------------------------------------------------------------------------------
-- DEFAULT PROFILES (seeded on first load)
--------------------------------------------------------------------------------

function ataxia.armour.seedDefaults()
  if next(ataxia.armour.config.profiles) then return end

  ataxia.armour.config.profiles = {
    bash = {
      slots = {"paragon361796", "paragon343178", "paragon514466"},
      traits = {"quick-witted", "fully fit", "marksman", "lucky",
                "master contemplator", "decorated", "brilliance", "in service"},
      armourType = nil,
    },
    magepve = {
      slots = {"paragon361796", "paragon343178", "paragon514466"},
      traits = {"quick-witted", "fully fit", "marksman", "lucky",
                "master contemplator", "decorated", "brilliance", "in service"},
      armourType = nil,
    },
    serppve = {
      slots = {"paragon361796", "paragon500167", "paragon514466"},
      traits = {},
      armourType = nil,
    },
    stickpve = {
      slots = {"paragon361796", "paragon417591", "paragon514466"},
      traits = {"nimble", "fully fit", "marksman", "lucky",
                "master contemplator", "decorated", "improved physique", "in service"},
      armourType = nil,
    },
    pariahpve = {
      slots = {"paragon361796", "paragon500167", "paragon514466"},
      traits = {"nimble", "fully fit", "marksman", "lucky",
                "master contemplator", "decorated", "brilliance", "in service"},
      armourType = nil,
    },
    bmpve = {
      slots = {},
      traits = {"nimble", "fully fit", "marksman", "lucky",
                "master contemplator", "decorated", "health inspector", "in service"},
      armourType = nil,
    },
    pvp = {
      slots = {"paragon500167", "paragon424404", "paragon417591"},
      traits = {"quick-witted", "fully fit", "marksman", "health inspector",
                "master contemplator", "decorated", "brilliance", "in service"},
      armourType = nil,
    },
    stickpvp = {
      slots = {"paragon500167", "paragon514466", "paragon417591"},
      traits = {"nimble", "fully fit", "marksman", "health inspector",
                "master contemplator", "decorated", "improved physique", "in service"},
      armourType = nil,
    },
  }

  -- Seed default paragon names
  if not next(ataxia.armour.config.paragons) then
    ataxia.armour.config.paragons = {
      ["paragon417591"] = "aeneaous (absorption)",
      ["paragon361796"] = "icosagon (20% crit)",
      ["paragon514466"] = "crucious (crit multiplier)",
      ["paragon500167"] = "metalliferous (7.5% resist)",
      ["paragon343178"] = "serendipitous (5% dmg->WP)",
      ["paragon424404"] = "deltahedral (morphing)",
    }
  end

  ataxia.armour.config.bashProfile = "bash"
  ataxia.armour.config.pvpProfile = "pvp"
  ataxia.armour.save()
  ataxia.armour.echo("Seeded default profiles: bash, pvp, stickpvp, magepve, serppve, stickpve, pariahpve, bmpve")
end

--------------------------------------------------------------------------------
-- PARAGON NAME LOOKUP
--------------------------------------------------------------------------------

function ataxia.armour.paragonName(id)
  if not id then return "(empty)" end
  return ataxia.armour.config.paragons[id] or id
end

function ataxia.armour.resolveParagonName(rawName)
  -- Try to match a keyword from PARAGON_TYPES in the raw game name
  if not rawName then return nil end
  local lower = rawName:lower()
  for keyword, displayName in pairs(ataxia.armour.PARAGON_TYPES) do
    if lower:find(keyword, 1, true) then
      return displayName
    end
  end
  return rawName  -- fallback to raw name if no match
end

function ataxia.armour.registerParagon(id, name)
  if not id or not name then return end
  ataxia.armour.config.paragons[id] = ataxia.armour.resolveParagonName(name)
  ataxia.armour.save()
end

--------------------------------------------------------------------------------
-- MORPH LOGIC
--------------------------------------------------------------------------------

function ataxia.armour.canMorph()
  local elapsed = os.time() - (ataxia.armour.config.lastMorphTime or 0)
  return elapsed >= (ataxia.armour.config.morphCooldown or 600)
end

function ataxia.armour.morphCooldownRemaining()
  local elapsed = os.time() - (ataxia.armour.config.lastMorphTime or 0)
  local remaining = (ataxia.armour.config.morphCooldown or 600) - elapsed
  return math.max(0, remaining)
end

function ataxia.armour.getArmourTypeForClass()
  if not gmcp or not gmcp.Char or not gmcp.Char.Status then return nil end
  local class = gmcp.Char.Status.class
  return ataxia.armour.classArmourType[class]
end

function ataxia.armour.resolveArmourType(profileArmourType)
  if not profileArmourType then return nil end
  if profileArmourType == "auto" then
    return ataxia.armour.getArmourTypeForClass()
  end
  return profileArmourType
end

function ataxia.armour.morph(armourType)
  if not armourType then
    ataxia.armour.echo("No armour type specified.")
    return
  end

  if armourType == "auto" then
    armourType = ataxia.armour.getArmourTypeForClass()
    if not armourType then
      ataxia.armour.echo("Could not determine armour type for current class.")
      return
    end
  end

  if ataxia.armour.config.currentArmourType == armourType then
    ataxia.armour.echo("Armour is already " .. armourType .. ".")
    return
  end

  if not ataxia.armour.canMorph() then
    local remaining = ataxia.armour.morphCooldownRemaining()
    local mins = math.floor(remaining / 60)
    local secs = remaining % 60
    ataxia.armour.echo("Morph on cooldown. " .. mins .. "m " .. secs .. "s remaining.")
    return
  end

  send("morpharmour armour into " .. armourType)
  ataxia.armour.config.lastMorphTime = os.time()
  ataxia.armour.config.currentArmourType = armourType
  ataxia.armour.save()
  ataxia.armour.echo("Morphing armour to " .. armourType .. ".")
end

--------------------------------------------------------------------------------
-- SWAP EXECUTION
--------------------------------------------------------------------------------

function ataxia.armour.swap(profileName)
  local profile = ataxia.armour.config.profiles[profileName]
  if not profile then
    ataxia.armour.echo("Profile '" .. profileName .. "' not found.")
    return
  end

  if ataxia.armour.state.swapping then
    ataxia.armour.echo("Already swapping. Please wait.")
    return
  end

  ataxia.armour.state.swapping = true
  local sp = ataxia.settings and ataxia.settings.separator or "::"

  -- 1. Send traits immediately (no balance cost)
  if profile.traits and #profile.traits > 0 then
    local traitCmds = {}
    for _, trait in ipairs(profile.traits) do
      table.insert(traitCmds, "trait select " .. trait .. " confirm")
    end
    send(table.concat(traitCmds, ";"))
  end

  -- 2. Handle morphing if needed
  local targetArmourType = ataxia.armour.resolveArmourType(profile.armourType)
  if targetArmourType and targetArmourType ~= ataxia.armour.config.currentArmourType then
    if ataxia.armour.canMorph() then
      send("morpharmour armour into " .. targetArmourType)
      ataxia.armour.config.lastMorphTime = os.time()
      ataxia.armour.config.currentArmourType = targetArmourType
    else
      local remaining = ataxia.armour.morphCooldownRemaining()
      local mins = math.floor(remaining / 60)
      local secs = remaining % 60
      ataxia.armour.echo("<yellow>Morph on cooldown (" .. mins .. "m " .. secs .. "s). Skipping morph.")
    end
  end

  -- 3. Pry + insert with 2s delay
  if profile.slots and #profile.slots > 0 then
    -- Check if swap is actually needed
    local needsSwap = false
    for i = 1, 3 do
      if ataxia.armour.state.currentSlots[i] ~= (profile.slots[i] or nil) then
        needsSwap = true
        break
      end
    end

    if needsSwap then
      tempTimer(2, function()
        local cmds = {}
        -- Pry all first
        table.insert(cmds, "pry armour embrasure 1")
        table.insert(cmds, "pry armour embrasure 2")
        table.insert(cmds, "pry armour embrasure 3")
        -- Insert new
        for i, paragonId in ipairs(profile.slots) do
          if paragonId and paragonId ~= "" then
            table.insert(cmds, "insert " .. paragonId .. " into armour embrasure " .. i)
          end
        end
        send(table.concat(cmds, ";"))

        -- Update state
        ataxia.armour.state.currentSlots = {
          profile.slots[1] or nil,
          profile.slots[2] or nil,
          profile.slots[3] or nil,
        }
        ataxia.armour.state.swapping = false
        ataxia.armour.save()
        ataxia.armour.echo("Swapped to profile: <white>" .. profileName)
      end)
    else
      ataxia.armour.state.swapping = false
      ataxia.armour.echo("Paragons already match profile '<white>" .. profileName .. "<plum>'. Traits sent.")
    end
  else
    ataxia.armour.state.swapping = false
    ataxia.armour.echo("Profile '<white>" .. profileName .. "<plum>' has no paragon slots. Traits sent.")
  end
end

--------------------------------------------------------------------------------
-- PROFILE MANAGEMENT
--------------------------------------------------------------------------------

function ataxia.armour.addProfile(name)
  if not name or name == "" then
    ataxia.armour.echo("Usage: armour add <name>")
    return
  end
  name = name:lower()
  if ataxia.armour.config.profiles[name] then
    ataxia.armour.echo("Profile '" .. name .. "' already exists.")
    return
  end
  ataxia.armour.config.profiles[name] = {
    slots = {},
    traits = {},
    armourType = nil,
  }
  ataxia.armour.save()
  ataxia.armour.echo("Created profile: <white>" .. name)
end

function ataxia.armour.removeProfile(name)
  if not name or name == "" then
    ataxia.armour.echo("Usage: armour remove <name>")
    return
  end
  name = name:lower()
  if not ataxia.armour.config.profiles[name] then
    ataxia.armour.echo("Profile '" .. name .. "' not found.")
    return
  end
  ataxia.armour.config.profiles[name] = nil
  if ataxia.armour.config.bashProfile == name then ataxia.armour.config.bashProfile = nil end
  if ataxia.armour.config.pvpProfile == name then ataxia.armour.config.pvpProfile = nil end
  ataxia.armour.save()
  ataxia.armour.echo("Removed profile: <white>" .. name)
end

function ataxia.armour.setSlot(name, slotNum, paragonId)
  name = (name or ""):lower()
  local profile = ataxia.armour.config.profiles[name]
  if not profile then
    ataxia.armour.echo("Profile '" .. name .. "' not found.")
    return
  end
  slotNum = tonumber(slotNum)
  if not slotNum or slotNum < 1 or slotNum > 3 then
    ataxia.armour.echo("Slot must be 1, 2, or 3.")
    return
  end
  if not paragonId or paragonId == "" then
    ataxia.armour.echo("Usage: armour set <name> slot<N> <paragonID>")
    return
  end
  -- Ensure slots table exists and is big enough
  profile.slots = profile.slots or {}
  profile.slots[slotNum] = paragonId
  ataxia.armour.save()
  ataxia.armour.echo("Set " .. name .. " slot " .. slotNum .. " = <white>" .. ataxia.armour.paragonName(paragonId))
end

function ataxia.armour.setTraits(name, traitStr)
  name = (name or ""):lower()
  local profile = ataxia.armour.config.profiles[name]
  if not profile then
    ataxia.armour.echo("Profile '" .. name .. "' not found.")
    return
  end
  if not traitStr or traitStr == "" then
    ataxia.armour.echo("Usage: armour set <name> traits <trait1> <trait2> ...")
    return
  end
  local traits = {}
  for trait in traitStr:gmatch("%S+") do
    table.insert(traits, trait)
  end
  profile.traits = traits
  ataxia.armour.save()
  ataxia.armour.echo("Set " .. name .. " traits: <white>" .. table.concat(traits, ", "))
end

function ataxia.armour.setArmourType(name, armourType)
  name = (name or ""):lower()
  local profile = ataxia.armour.config.profiles[name]
  if not profile then
    ataxia.armour.echo("Profile '" .. name .. "' not found.")
    return
  end
  if not armourType or armourType == "" then
    ataxia.armour.echo("Usage: armour set <name> armourtype <type|auto|none>")
    return
  end
  if armourType == "none" or armourType == "nil" then
    profile.armourType = nil
    ataxia.armour.echo("Cleared armour type for " .. name .. ".")
  else
    profile.armourType = armourType
    ataxia.armour.echo("Set " .. name .. " armour type: <white>" .. armourType)
  end
  ataxia.armour.save()
end

--------------------------------------------------------------------------------
-- DISPLAY
--------------------------------------------------------------------------------

function ataxia.armour.listProfiles()
  local autoStr = ataxia.armour.config.autoSwap and "<green>ON" or "<red>OFF"
  local bashStr = ataxia.armour.config.bashProfile or "<dark_grey>(none)"
  local pvpStr = ataxia.armour.config.pvpProfile or "<dark_grey>(none)"
  local armourStr = ataxia.armour.config.currentArmourType or "<dark_grey>(unknown)"
  local morphStr = ataxia.armour.canMorph() and "<green>Ready" or
    ("<yellow>" .. math.floor(ataxia.armour.morphCooldownRemaining() / 60) .. "m " ..
     (ataxia.armour.morphCooldownRemaining() % 60) .. "s")

  cecho("\n<cyan>===== Armour Paragon Profiles =====")
  cecho("\n<grey>Auto-swap: " .. autoStr .. "<grey>  |  Bash: <white>" .. bashStr ..
        "<grey>  |  PvP: <white>" .. pvpStr)
  cecho("\n<grey>Armour type: <white>" .. armourStr .. "<grey>  |  Morph: " .. morphStr)
  cecho("\n<cyan>---")

  local count = 0
  for name, profile in pairs(ataxia.armour.config.profiles) do
    count = count + 1
    local slotNames = {}
    for i = 1, 3 do
      table.insert(slotNames, ataxia.armour.paragonName(profile.slots and profile.slots[i]))
    end
    local traitStr = ""
    if profile.traits and #profile.traits > 0 then
      traitStr = table.concat(profile.traits, ", ")
      if #traitStr > 60 then traitStr = traitStr:sub(1, 57) .. "..." end
    end
    local typeStr = profile.armourType and (" | morph: " .. profile.armourType) or ""

    local marker = ""
    if name == ataxia.armour.config.bashProfile then marker = " <yellow>[BASH]" end
    if name == ataxia.armour.config.pvpProfile then marker = marker .. " <magenta>[PVP]" end

    cecho("\n<green>[" .. name .. "]" .. marker)
    cecho("\n<grey>  slots: <white>" .. table.concat(slotNames, " / ") .. typeStr)
    if traitStr ~= "" then
      cecho("\n<grey>  traits: <light_grey>" .. traitStr)
    end
  end

  if count == 0 then
    cecho("\n<dark_grey>  No profiles defined. Use 'armour add <name>' to create one.")
  end

  cecho("\n<cyan>---")
  cecho("\n<grey>Type '<white>armour <name><grey>' to swap. '<white>armour help<grey>' for commands.\n")
end

function ataxia.armour.showProfile(name)
  name = (name or ""):lower()
  local profile = ataxia.armour.config.profiles[name]
  if not profile then
    ataxia.armour.echo("Profile '" .. name .. "' not found.")
    return
  end

  cecho("\n<cyan>===== Profile: " .. name .. " =====")
  for i = 1, 3 do
    local id = profile.slots and profile.slots[i]
    cecho("\n<grey>  Slot " .. i .. ": <white>" .. (id or "(empty)") ..
          " <dark_grey>(" .. ataxia.armour.paragonName(id) .. ")")
  end
  if profile.traits and #profile.traits > 0 then
    cecho("\n<grey>  Traits: <white>" .. table.concat(profile.traits, ", "))
  else
    cecho("\n<grey>  Traits: <dark_grey>(none)")
  end
  cecho("\n<grey>  Armour type: <white>" .. (profile.armourType or "(none)"))
  cecho("\n")
end

function ataxia.armour.showParagons()
  cecho("\n<cyan>===== Known Paragons =====")
  local count = 0
  for id, name in pairs(ataxia.armour.config.paragons) do
    count = count + 1
    cecho("\n<yellow>  " .. id .. " <grey>- <white>" .. name)
  end
  if count == 0 then
    cecho("\n<dark_grey>  No paragons detected. Use 'armour scan' to detect.")
  end
  cecho("\n")
end

function ataxia.armour.showParagonTypes()
  cecho("\n<cyan>===== All Paragon Types =====")
  -- Group by category
  local categories = {
    {"Damage Resistance", {"fuscous", "vinaceous", "viridescent", "piceous", "citreous",
                           "aurous", "cyaneous", "oleaginous", "caliginous", "metalliferous"}},
    {"Morphing",          {"tetrahedral", "octahedral", "deltahedral"}},
    {"Combat/Utility",    {"aeneaous", "prismatic", "icosagon", "crucious", "rufescent"}},
    {"Regen/Resource",    {"torpous", "niveous", "serendipitous"}},
    {"Storage/Utility",   {"cupreous", "dodecahedron", "euphonious"}},
  }
  for _, cat in ipairs(categories) do
    cecho("\n<green>  " .. cat[1] .. ":")
    for _, key in ipairs(cat[2]) do
      local display = ataxia.armour.PARAGON_TYPES[key] or key
      cecho("\n<grey>    <white>" .. display)
    end
  end
  cecho("\n")
end

--------------------------------------------------------------------------------
-- SCAN (auto-detect paragons + current embrasures)
--------------------------------------------------------------------------------

function ataxia.armour.scan()
  ataxia.armour.state.scanning = true
  ataxia.armour.state.probing = false
  ataxia.armour.state.probeSlotIndex = 0
  send("ii paragon")
  -- probe armour after a short delay to let ii finish
  tempTimer(2, function()
    ataxia.armour.state.scanning = false
    ataxia.armour.state.probing = true
    ataxia.armour.state.probeSlotIndex = 0
    send("probe armour")
    tempTimer(2, function()
      ataxia.armour.state.probing = false
      ataxia.armour.save()
      ataxia.armour.echo("Scan complete. Found " .. ataxia.armour.tableSize(ataxia.armour.config.paragons) .. " paragons.")
    end)
  end)
end

function ataxia.armour.tableSize(t)
  local count = 0
  for _ in pairs(t or {}) do count = count + 1 end
  return count
end

--------------------------------------------------------------------------------
-- BASHER EVENT HANDLERS
--------------------------------------------------------------------------------

function ataxia.armour.onBasherEnabled()
  if not ataxia.armour.config.autoSwap then return end
  if not ataxia.armour.config.bashProfile then return end
  if not ataxia.armour.config.profiles[ataxia.armour.config.bashProfile] then return end
  ataxia.armour.echo("Basher enabled — swapping to '<white>" .. ataxia.armour.config.bashProfile .. "<plum>'")
  ataxia.armour.swap(ataxia.armour.config.bashProfile)
end

function ataxia.armour.onBasherDisabled()
  if not ataxia.armour.config.autoSwap then return end
  if not ataxia.armour.config.pvpProfile then return end
  if not ataxia.armour.config.profiles[ataxia.armour.config.pvpProfile] then return end
  ataxia.armour.echo("Basher disabled — swapping to '<white>" .. ataxia.armour.config.pvpProfile .. "<plum>'")
  ataxia.armour.swap(ataxia.armour.config.pvpProfile)
end

--------------------------------------------------------------------------------
-- EVENT REGISTRATION (with cleanup on reload)
--------------------------------------------------------------------------------

function ataxia.armour.registerEvents()
  for _, id in ipairs(ataxia.armour.state.eventHandlers) do
    killAnonymousEventHandler(id)
  end
  ataxia.armour.state.eventHandlers = {}

  local h1 = registerAnonymousEventHandler("basher enabled", function()
    ataxia.armour.onBasherEnabled()
  end)
  local h2 = registerAnonymousEventHandler("basher disabled", function()
    ataxia.armour.onBasherDisabled()
  end)

  table.insert(ataxia.armour.state.eventHandlers, h1)
  table.insert(ataxia.armour.state.eventHandlers, h2)
end

--------------------------------------------------------------------------------
-- HELP
--------------------------------------------------------------------------------

function ataxia.armour.help()
  cecho("\n<cyan>+----------------------------------------------------------------------+")
  cecho("\n<cyan>|                    <white>ARMOUR PARAGON COMMANDS<cyan>                         |")
  cecho("\n<cyan>+----------------------------------------------------------------------+")
  cecho("\n<cyan>| <green>armour<cyan>                       - Show all profiles & status           |")
  cecho("\n<cyan>| <green>armour <name><cyan>                - Swap to a profile                    |")
  cecho("\n<cyan>| <green>armour add <name><cyan>            - Create a new profile                 |")
  cecho("\n<cyan>| <green>armour remove <name><cyan>         - Delete a profile                     |")
  cecho("\n<cyan>| <green>armour set <n> slot1 <id><cyan>    - Set paragon in slot 1 (1-3)          |")
  cecho("\n<cyan>| <green>armour set <n> slot2 <id><cyan>    - Set paragon in slot 2                |")
  cecho("\n<cyan>| <green>armour set <n> slot3 <id><cyan>    - Set paragon in slot 3                |")
  cecho("\n<cyan>| <green>armour set <n> traits <...><cyan>  - Set trait list (space-separated)     |")
  cecho("\n<cyan>| <green>armour set <n> armourtype <t><cyan> - Set morph target (type/auto/none)   |")
  cecho("\n<cyan>| <green>armour auto on|off<cyan>           - Toggle auto-swap on basher           |")
  cecho("\n<cyan>| <green>armour bash <name><cyan>           - Set bash profile                     |")
  cecho("\n<cyan>| <green>armour pvp <name><cyan>            - Set PvP profile                      |")
  cecho("\n<cyan>| <green>armour show <name><cyan>           - Show profile details                 |")
  cecho("\n<cyan>| <green>armour morph <type|auto><cyan>     - Manually morph armour now            |")
  cecho("\n<cyan>| <green>armour scan<cyan>                  - Detect paragons (ii paragon + probe) |")
  cecho("\n<cyan>| <green>armour paragons<cyan>              - Show known paragons                  |")
  cecho("\n<cyan>| <green>armour types<cyan>                 - Show all paragon types & effects     |")
  cecho("\n<cyan>| <green>armour help<cyan>                  - Show this help                       |")
  cecho("\n<cyan>+----------------------------------------------------------------------+\n")
end

--------------------------------------------------------------------------------
-- COMMAND DISPATCHER
--------------------------------------------------------------------------------

function ataxia.armour.dispatch(args)
  args = (args or ""):match("^%s*(.-)%s*$") -- trim
  if args == "" then
    ataxia.armour.listProfiles()
    return
  end

  local cmd, rest = args:match("^(%S+)%s*(.*)$")
  cmd = cmd:lower()

  -- Check if cmd is a profile name first
  if ataxia.armour.config.profiles[cmd] and rest == "" then
    ataxia.armour.swap(cmd)
    return
  end

  if cmd == "add" then
    ataxia.armour.addProfile(rest)
  elseif cmd == "remove" or cmd == "rm" or cmd == "delete" then
    ataxia.armour.removeProfile(rest)
  elseif cmd == "set" then
    -- Parse: <name> <field> <value...>
    local name, field, value = rest:match("^(%S+)%s+(%S+)%s+(.+)$")
    if not name then
      ataxia.armour.echo("Usage: armour set <name> <slot1|slot2|slot3|traits|armourtype> <value>")
      return
    end
    field = field:lower()
    if field == "slot1" then
      ataxia.armour.setSlot(name, 1, value:match("^%s*(.-)%s*$"))
    elseif field == "slot2" then
      ataxia.armour.setSlot(name, 2, value:match("^%s*(.-)%s*$"))
    elseif field == "slot3" then
      ataxia.armour.setSlot(name, 3, value:match("^%s*(.-)%s*$"))
    elseif field == "traits" then
      ataxia.armour.setTraits(name, value)
    elseif field == "armourtype" or field == "type" or field == "morph" then
      ataxia.armour.setArmourType(name, value:match("^%s*(.-)%s*$"))
    else
      ataxia.armour.echo("Unknown field: " .. field .. ". Use slot1/slot2/slot3/traits/armourtype.")
    end
  elseif cmd == "auto" then
    if rest:lower() == "on" then
      ataxia.armour.config.autoSwap = true
      ataxia.armour.save()
      ataxia.armour.echo("Auto-swap <green>ON<plum>.")
    elseif rest:lower() == "off" then
      ataxia.armour.config.autoSwap = false
      ataxia.armour.save()
      ataxia.armour.echo("Auto-swap <red>OFF<plum>.")
    else
      ataxia.armour.echo("Usage: armour auto on|off")
    end
  elseif cmd == "bash" then
    local name = rest:lower()
    if name == "" then
      ataxia.armour.echo("Current bash profile: <white>" .. (ataxia.armour.config.bashProfile or "(none)"))
      return
    end
    if not ataxia.armour.config.profiles[name] then
      ataxia.armour.echo("Profile '" .. name .. "' not found.")
      return
    end
    ataxia.armour.config.bashProfile = name
    ataxia.armour.save()
    ataxia.armour.echo("Bash profile set to: <white>" .. name)
  elseif cmd == "pvp" then
    local name = rest:lower()
    if name == "" then
      ataxia.armour.echo("Current PvP profile: <white>" .. (ataxia.armour.config.pvpProfile or "(none)"))
      return
    end
    if not ataxia.armour.config.profiles[name] then
      ataxia.armour.echo("Profile '" .. name .. "' not found.")
      return
    end
    ataxia.armour.config.pvpProfile = name
    ataxia.armour.save()
    ataxia.armour.echo("PvP profile set to: <white>" .. name)
  elseif cmd == "show" then
    if rest == "" then
      ataxia.armour.listProfiles()
    else
      ataxia.armour.showProfile(rest)
    end
  elseif cmd == "morph" then
    ataxia.armour.morph(rest:lower())
  elseif cmd == "scan" then
    ataxia.armour.scan()
  elseif cmd == "paragons" then
    ataxia.armour.showParagons()
  elseif cmd == "types" then
    ataxia.armour.showParagonTypes()
  elseif cmd == "help" or cmd == "?" then
    ataxia.armour.help()
  else
    -- Maybe it's a profile name with extra args? Try as profile
    if ataxia.armour.config.profiles[cmd] then
      ataxia.armour.swap(cmd)
    else
      ataxia.armour.echo("Unknown command: " .. cmd .. ". Type 'armour help' for usage.")
    end
  end
end

--------------------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------------------

-- Load config
ataxia.armour.load()
ataxia.armour.seedDefaults()
ataxia.armour.registerEvents()

-- Re-resolve paragon names using lookup table (cleans up raw game names)
if ataxia.armour.config.paragons then
  local dirty = false
  for id, name in pairs(ataxia.armour.config.paragons) do
    local resolved = ataxia.armour.resolveParagonName(name)
    if resolved ~= name then
      ataxia.armour.config.paragons[id] = resolved
      dirty = true
    end
  end
  if dirty then ataxia.armour.save() end
end

-- Auto-detect armour type from class if unknown
if not ataxia.armour.config.currentArmourType then
  local detected = ataxia.armour.getArmourTypeForClass()
  if detected then
    ataxia.armour.config.currentArmourType = detected
    ataxia.armour.save()
  end
end
