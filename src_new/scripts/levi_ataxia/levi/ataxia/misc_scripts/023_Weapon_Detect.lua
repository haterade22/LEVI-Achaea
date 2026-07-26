--[[mudlet
type: script
name: Weapon Detect
hierarchy:
- Levi_Ataxia
- Misc Scripts
attributes:
  isActive: 'yes'
  isFolder: 'no'
]]--

---------------------------------------------------------------------------
-- Weapon Detection System
-- Parses WEAPONLIST output to auto-detect weapons and assign to config slots.
-- Usage: ataxia.scanWeapons() or "ataxia setup weapons scan"
--
-- Flow:
--   1. Sends WEAPONLIST
--   2. Parses each weapon line (type + ID + stats)
--   3. Groups by weapon type, auto-suggests slot assignments
--   4. Displays results and prompts user to confirm or adjust
--   5. "ataxia setup weapons confirm" saves to ataxia.settings.weapons
---------------------------------------------------------------------------

ataxia.weaponDetect = ataxia.weaponDetect or {}

-- Weapon type → config slot mapping
-- Dual-wield types get two slots; single types get one.
local TYPE_SLOTS = {
  scimitar    = {"weapon1", "weapon2"},
  morningstar = {"mstar1", "mstar2"},
  flail       = {"flail1", "flail2"},
  staff       = {"staff", "staff2"},
  battleaxe   = {"battleaxe"},
  longsword   = {"longsword"},
  warhammer   = {"warhammer"},
  bastard     = {"bastard"},
  whip        = {"lash"},
  dirk        = {"fang"},
  scythe      = {"scythe"},
  dagger      = {"dagger"},
  rapier      = {"rapier"},
  bow         = {"bow"},
  daegger     = {"daegger"},
  lash        = {"lash"},
  fang        = {"fang"},
  stiletto    = {"stiletto", "stiletto2", "stiletto3"},
  blackjack   = {"blackjack"},
  axe         = {"axe"},
}

-- Friendly slot descriptions for display
local SLOT_HINTS = {
  weapon1  = "DWC right hand",
  weapon2  = "DWC left hand",
  mstar1   = "DWB right hand",
  mstar2   = "DWB left hand",
  flail1   = "flail right hand",
  flail2   = "flail left hand",
  staff    = "Magi / primary staff",
  staff2   = "Monk Shikudo staff",
  battleaxe = "2H / DWC execute",
  longsword = "Sword and Board",
  warhammer = "Two-Handed",
  bastard  = "Two-Handed bastard",
  lash     = "whip (Serpent)",
  fang     = "dirk (Dragon)",
  scythe   = "Depthswalker",
  dagger   = "dagger",
  rapier   = "Bard rapier",
  bow      = "ranged",
  daegger  = "Apostate daegger",
}

--- Clean up any active temp triggers and timer from a scan.
local function cleanupScan()
  local det = ataxia.weaponDetect
  if det.triggers then
    for _, tid in ipairs(det.triggers) do
      killTrigger(tid)
    end
    det.triggers = {}
  end
  if det.timer then
    killTimer(det.timer)
    det.timer = nil
  end
  det.scanning = false
end

--- Extract the weapon type from a full item ID.
-- e.g. "staff569815" -> "staff",  "morningstar511732" -> "morningstar"
local function parseType(fullId)
  return fullId:match("^(%a+)%d+$")
end

--- Auto-suggest slot assignments from detected weapons.
-- Groups weapons by type, assigns to slots in TYPE_SLOTS order.
-- For paired types: sorted by Dmg descending (best weapon = slot 1).
local function suggestSlots(detected)
  local suggested = {}
  local byType = {}

  for _, w in ipairs(detected) do
    byType[w.type] = byType[w.type] or {}
    table.insert(byType[w.type], w)
  end

  for wtype, weapons in pairs(byType) do
    local slots = TYPE_SLOTS[wtype]
    if slots then
      -- Sort by damage descending so best weapon gets slot 1
      table.sort(weapons, function(a, b) return (a.dmg or 0) > (b.dmg or 0) end)
      for i, w in ipairs(weapons) do
        if slots[i] then
          suggested[slots[i]] = w.id
        end
      end
    end
  end

  return suggested
end

--- Display scan results and prompt user to confirm.
local function presentResults()
  local det = ataxia.weaponDetect
  local detected = det.detected or {}

  if #detected == 0 then
    ataxia_Echo("No weapons detected from WEAPONLIST.")
    return
  end

  local suggested = suggestSlots(detected)
  det.suggested = suggested

  -- Group by type for display
  local byType = {}
  local typeOrder = {}
  for _, w in ipairs(detected) do
    if not byType[w.type] then
      byType[w.type] = {}
      typeOrder[#typeOrder + 1] = w.type
    end
    table.insert(byType[w.type], w)
  end

  cecho("\n\n<dark_orchid>" .. string.rep(string.char(226, 148, 128), 60))
  cecho("\n<light_slate_blue>  Weapon Scan Results")
  cecho("\n<dark_orchid>" .. string.rep(string.char(226, 148, 128), 60) .. "\n")

  for _, wtype in ipairs(typeOrder) do
    local weapons = byType[wtype]
    cecho("\n  <NavajoWhite>" .. wtype:sub(1,1):upper() .. wtype:sub(2) .. " <dim_grey>(" .. #weapons .. " found):\n")
    for i, w in ipairs(weapons) do
      local dmgStr = w.dmg and tostring(w.dmg) or "?"
      cecho("    <plum>[" .. i .. "]<lavender> " .. w.id .. "  <dim_grey>Dmg:" .. dmgStr)
      -- Show which slot this is suggested for
      for slot, sid in pairs(suggested) do
        if sid == w.id then
          local hint = SLOT_HINTS[slot] or ""
          cecho("  <green>-> " .. slot)
          if hint ~= "" then cecho(" <dim_grey>(" .. hint .. ")") end
          break
        end
      end
      cecho("\n")
    end
  end

  -- Show summary of assignments
  cecho("\n<dark_orchid>" .. string.rep(string.char(226, 148, 128), 60))
  cecho("\n<light_slate_blue>  Suggested Assignments\n")

  local slotOrder = {"weapon1", "weapon2", "mstar1", "mstar2", "staff", "staff2",
    "battleaxe", "longsword", "warhammer", "bastard", "lash", "fang", "scythe",
    "dagger", "rapier", "bow", "daegger", "flail1", "flail2",
    "stiletto", "stiletto2", "stiletto3", "blackjack", "axe"}

  local hasAny = false
  for _, slot in ipairs(slotOrder) do
    if suggested[slot] then
      local hint = SLOT_HINTS[slot] or ""
      cecho("\n  <plum>" .. string.format("%-12s", slot) .. "<lavender> = <white>" .. suggested[slot])
      if hint ~= "" then cecho("  <dim_grey>(" .. hint .. ")") end
      hasAny = true
    end
  end
  if not hasAny then
    cecho("\n  <dim_grey>(no automatic assignments)")
  end

  cecho("\n\n<dark_orchid>" .. string.rep(string.char(226, 148, 128), 60))
  cecho("\n<NavajoWhite>  Commands:\n")
  cecho("  <light_slate_blue>ataxia setup weapons confirm       <dim_grey>Save these assignments\n")
  cecho("  <light_slate_blue>ataxia setup weapons set <slot> <id> <dim_grey>Change a slot before saving\n")
  cecho("  <light_slate_blue>ataxia setup weapons swap <s1> <s2>  <dim_grey>Swap two slot assignments\n")
  cecho("  <light_slate_blue>ataxia setup weapons scan           <dim_grey>Re-scan\n")
  cecho("\n")
end

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------

--- Start a weapon scan by sending WEAPONLIST and parsing output.
function ataxia.scanWeapons()
  local det = ataxia.weaponDetect
  det.detected = {}
  det.suggested = {}
  det.scanning = false
  det.state = "waiting"
  cleanupScan()
  det.triggers = {}

  -- Header line: "Weapon                                Dmg ..."
  det.triggers[#det.triggers + 1] = tempRegexTrigger(
    "^Weapon\\s+Dmg\\s+To-hit",
    function()
      if det.state == "waiting" then
        det.state = "header_seen"
        det.scanning = true
      end
    end
  )

  -- Separator lines: "------..."
  det.triggers[#det.triggers + 1] = tempRegexTrigger(
    "^-{10,}",
    function()
      if det.state == "header_seen" then
        det.state = "capturing"
      elseif det.state == "capturing" then
        det.state = "done"
        cleanupScan()
        presentResults()
      end
    end
  )

  -- Weapon data lines: "scimitar405398                        64       180         245         n/a"
  det.triggers[#det.triggers + 1] = tempRegexTrigger(
    "^(\\w+\\d+)\\s+(\\d+)\\s+(\\d+)\\s+(\\d+)\\s+(\\S+)",
    function()
      if det.state ~= "capturing" then return end
      local fullId = matches[2]
      local dmg = tonumber(matches[3])
      local tohit = tonumber(matches[4])
      local speed = tonumber(matches[5])
      local wtype = parseType(fullId)
      if wtype then
        det.detected[#det.detected + 1] = {
          id = fullId,
          type = wtype,
          dmg = dmg,
          tohit = tohit,
          speed = speed,
        }
      end
    end
  )

  -- Timeout safety
  det.timer = tempTimer(8, function()
    if det.state ~= "done" then
      cleanupScan()
      ataxia_Echo("Weapon scan timed out. Make sure you're connected and try again.")
    end
  end)

  send("WEAPONLIST", false)
  ataxia_Echo("Scanning weapons...")
end

--- Confirm and save the suggested weapon assignments.
function ataxia.confirmWeapons()
  local det = ataxia.weaponDetect
  local suggested = det.suggested

  if not suggested or not next(suggested) then
    ataxia_Echo("No weapon assignments to confirm. Run: <white>ataxia setup weapons scan")
    return
  end

  ataxia.settings.weapons = ataxia.settings.weapons or {}
  local count = 0
  for slot, wid in pairs(suggested) do
    ataxia.settings.weapons[slot] = wid
    count = count + 1
  end

  -- Also sync DWC config if loaded
  if infernalDWC and infernalDWC.config then
    if suggested.weapon1 then infernalDWC.config.weapon1 = suggested.weapon1 end
    if suggested.weapon2 then infernalDWC.config.weapon2 = suggested.weapon2 end
    if suggested.battleaxe then infernalDWC.config.battleaxe = suggested.battleaxe end
  end
  if infernalGroupLock and infernalGroupLock.config then
    if suggested.weapon1 then infernalGroupLock.config.weapon1 = suggested.weapon1 end
    if suggested.weapon2 then infernalGroupLock.config.weapon2 = suggested.weapon2 end
  end
  if infernalDWC2L and infernalDWC2L.config then
    if suggested.weapon1 then infernalDWC2L.config.weapon1 = suggested.weapon1 end
    if suggested.weapon2 then infernalDWC2L.config.weapon2 = suggested.weapon2 end
    if suggested.battleaxe then infernalDWC2L.config.battleaxe = suggested.battleaxe end
  end

  ataxia_saveSettings(false)
  ataxia_Echo("Saved " .. count .. " weapon assignments.")
  det.suggested = {}
end

--- Swap two slot assignments in the pending suggestions.
function ataxia.swapWeaponSlots(slot1, slot2)
  local det = ataxia.weaponDetect
  local suggested = det.suggested

  if not suggested then
    ataxia_Echo("No pending scan results. Run: <white>ataxia setup weapons scan")
    return
  end

  local tmp = suggested[slot1]
  suggested[slot1] = suggested[slot2]
  suggested[slot2] = tmp

  ataxia_Echo("Swapped " .. slot1 .. " <-> " .. slot2)
  if suggested[slot1] then
    ataxia_Echo("  " .. slot1 .. " = " .. suggested[slot1])
  end
  if suggested[slot2] then
    ataxia_Echo("  " .. slot2 .. " = " .. suggested[slot2])
  end
  ataxia_Echo("Type <white>ataxia setup weapons confirm<lavender> to save.")
end

--- Set a single slot in pending suggestions (before confirm).
function ataxia.setWeaponSlotPending(slot, weaponId)
  local det = ataxia.weaponDetect
  det.suggested = det.suggested or {}
  det.suggested[slot] = weaponId
  local hint = SLOT_HINTS[slot] or ""
  ataxia_Echo("Set " .. slot .. " = " .. weaponId .. (hint ~= "" and (" (" .. hint .. ")") or ""))
  ataxia_Echo("Type <white>ataxia setup weapons confirm<lavender> to save.")
end
