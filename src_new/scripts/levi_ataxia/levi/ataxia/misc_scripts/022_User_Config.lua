--[[mudlet
type: script
name: User Config
hierarchy:
- Levi_Ataxia
- Misc Scripts
attributes:
  isActive: 'yes'
  isFolder: 'no'
]]--

---------------------------------------------------------------------------
-- User Config Helpers
-- Centralizes access to user-configurable weapon IDs, mount name,
-- artefact IDs, and earring locations. All values read from
-- ataxia.settings at call time (not cached at init), so changes
-- via the Setup Wizard take effect immediately.
---------------------------------------------------------------------------

--- Initialise ataxia.settings.user subtable with defaults.
-- Called from ataxiaCheckForMissing() and on first load.
function ataxia_initUserConfig()
  ataxia.settings.user = ataxia.settings.user or {}
  local u = ataxia.settings.user

  u.mount = u.mount or nil
  u.artefacts = u.artefacts or {}
  u.artefacts.pendant = u.artefacts.pendant or nil
  u.artefacts.bracelet = u.artefacts.bracelet or nil
  u.artefacts.belt = u.artefacts.belt or nil
  u.artefacts.ring = u.artefacts.ring or nil
  u.artefacts.earrings = u.artefacts.earrings or {}

  -- Ensure weapons table exists with all slots
  ataxia.settings.weapons = ataxia.settings.weapons or {}
  local w = ataxia.settings.weapons
  -- Core DWC slots (already used by Setup Wizard)
  w.weapon1 = w.weapon1 or nil
  w.weapon2 = w.weapon2 or nil
  -- Additional weapon slots
  w.battleaxe = w.battleaxe or nil
  w.staff = w.staff or nil
  w.staff2 = w.staff2 or nil
  w.mstar1 = w.mstar1 or nil
  w.mstar2 = w.mstar2 or nil
  w.flail1 = w.flail1 or nil
  w.flail2 = w.flail2 or nil
  w.longsword = w.longsword or nil
  w.warhammer = w.warhammer or nil
  w.bastard = w.bastard or nil
  w.lash = w.lash or nil
  w.fang = w.fang or nil
  w.scythe = w.scythe or nil
  w.dagger = w.dagger or nil
  w.rapier = w.rapier or nil
  w.bow = w.bow or nil
  w.daegger = w.daegger or nil
end

--- Get a configured weapon by slot name.
-- @param slot string  Slot key (e.g. "weapon1", "mstar1", "staff")
-- @return string  The weapon ID string, or a generic fallback
function ataxia.getWeapon(slot)
  local w = ataxia.settings and ataxia.settings.weapons
  if w and w[slot] then return w[slot] end

  -- Generic fallback: just the base weapon type name
  local fallbacks = {
    weapon1 = "scimitar", weapon2 = "scimitar",
    mstar1 = "morningstar", mstar2 = "morningstar",
    flail1 = "flail", flail2 = "flail",
    staff = "staff", staff2 = "staff",
    battleaxe = "battleaxe",
    longsword = "longsword", warhammer = "warhammer",
    bastard = "bastard", lash = "whip",
    fang = "dirk", scythe = "scythe",
    dagger = "dagger", rapier = "rapier",
    bow = "bow", daegger = "daegger",
  }
  return fallbacks[slot] or slot
end

--- Get the configured mount/companion name.
-- @return string  The mount name, or "mount" as fallback
function ataxia.getMount()
  local u = ataxia.settings and ataxia.settings.user
  if u and u.mount then return u.mount end
  return "mount"
end

--- Get a configured artefact by slot.
-- @param slot string  Artefact slot (e.g. "pendant", "bracelet", "belt", "ring")
-- @return string|nil  The artefact ID string, or nil if not configured
function ataxia.getArtefact(slot)
  local u = ataxia.settings and ataxia.settings.user
  if u and u.artefacts and u.artefacts[slot] then
    return u.artefacts[slot]
  end
  return nil
end

--- Get a configured earring by location name.
-- @param location string  Location shortname (e.g. "axios", "aegoth")
-- @return string|nil  The earring ID string, or nil if not configured
function ataxia.getEarring(location)
  local u = ataxia.settings and ataxia.settings.user
  if u and u.artefacts and u.artefacts.earrings then
    return u.artefacts.earrings[location]
  end
  return nil
end
