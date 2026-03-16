--[[mudlet
type: script
name: Mob Damage DB
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Basher
- Bashing
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

-------------------------------------------------
--           Mob Damage Database                --
--  Tracks non-crit damage per class/stat/mob   --
-------------------------------------------------

db:create("mob_damage_db",
  {
    hits = {
      "class",
      "stat",
      "mob",
      "area",
      "min_damage",
      "max_damage",
      "hit_count",
      "when",
    },
  })
ataxia.data.db.mobdmgdb = db:get_database("mob_damage_db")

-- Class to primary stat mapping
ataxia.data.classPrimaryStat = {
  ["alchemist"] = "int",
  ["apostate"] = "int",
  ["bard"] = "str",
  ["blademaster"] = "str",
  ["depthswalker"] = "str",
  ["druid"] = "str",
  ["infernal"] = "str",
  ["jester"] = "str",
  ["magi"] = "int",
  ["monk"] = "str",
  ["occultist"] = "int",
  ["paladin"] = "str",
  ["pariah"] = "int",
  ["priest"] = "int",
  ["psion"] = "int",
  ["runewarden"] = "str",
  ["sentinel"] = "str",
  ["serpent"] = "dex",
  ["shaman"] = "int",
  ["sylvan"] = "int",
  ["unnamable"] = "str",
  ["red dragon"] = "str",
  ["blue dragon"] = "str",
  ["gold dragon"] = "str",
  ["silver dragon"] = "str",
  ["green dragon"] = "str",
  ["black dragon"] = "str",
}

-- Get the primary stat name and value for current class
function ataxia.data.db.getPrimaryStat()
  local class = string.lower(gmcp.Char.Status.class or "")
  local statName = ataxia.data.classPrimaryStat[class] or "str"
  local statValue = "0"
  if statName == "str" then
    statValue = ataxia.data.char.str or "0"
  elseif statName == "dex" then
    statValue = ataxia.data.char.dex or "0"
  elseif statName == "int" then
    statValue = ataxia.data.char.int or "0"
  elseif statName == "con" then
    statValue = ataxia.data.char.con or "0"
  end
  return statName, statValue
end

-------------------------------------------------
--  Record a non-crit hit against current mob   --
-------------------------------------------------
function ataxia.data.db.recordMobDamage(amount)
  if not ataxiaBasher or not ataxiaBasher.enabled then return end
  if not secondTarget or secondTarget == "" then return end

  local class = gmcp.Char.Status.class or "Unknown"
  local statName, statValue = ataxia.data.db.getPrimaryStat()
  local stat = statName .. " " .. statValue
  local mob = secondTarget
  local area = gmcp.Room.Info.area or "Unknown"

  -- Check if we already have a record for this class/stat/mob combo
  local existing = db:fetch(ataxia.data.db.mobdmgdb.hits,
    db:AND(
      db:eq(ataxia.data.db.mobdmgdb.hits.class, class),
      db:eq(ataxia.data.db.mobdmgdb.hits.stat, stat),
      db:eq(ataxia.data.db.mobdmgdb.hits.mob, mob)
    )
  )

  if existing and #existing > 0 then
    local row = existing[1]
    local newMin = math.min(tonumber(row.min_damage), amount)
    local newMax = math.max(tonumber(row.max_damage), amount)
    local newCount = tonumber(row.hit_count) + 1
    db:update(ataxia.data.db.mobdmgdb.hits, row._row_id, {
      min_damage = newMin,
      max_damage = newMax,
      hit_count = newCount,
      area = area,
      when = getEpoch(),
    })
  else
    db:add(ataxia.data.db.mobdmgdb.hits, {
      class = class,
      stat = stat,
      mob = mob,
      area = area,
      min_damage = amount,
      max_damage = amount,
      hit_count = 1,
      when = getEpoch(),
    })
  end
end

-------------------------------------------------
--  Display mob damage data                     --
-------------------------------------------------
function ataxia.data.db.showMobDamage(filter)
  local rows
  if filter and filter ~= "" then
    -- Check if filter matches a class name
    local lowerFilter = string.lower(filter)
    local isClass = ataxia.data.classPrimaryStat[lowerFilter] ~= nil
    if isClass then
      rows = db:fetch(ataxia.data.db.mobdmgdb.hits,
        db:like(ataxia.data.db.mobdmgdb.hits.class, "%" .. filter .. "%"))
    else
      -- Search mob name or area
      rows = db:fetch(ataxia.data.db.mobdmgdb.hits,
        db:OR(
          db:like(ataxia.data.db.mobdmgdb.hits.mob, "%" .. filter .. "%"),
          db:like(ataxia.data.db.mobdmgdb.hits.area, "%" .. filter .. "%")
        ))
    end
  else
    rows = db:fetch(ataxia.data.db.mobdmgdb.hits)
  end

  if not rows or #rows == 0 then
    ataxiaEcho("No mob damage data found" .. (filter and (" for: " .. filter) or "") .. ".")
    return
  end

  -- Sort by max_damage descending
  table.sort(rows, function(a, b) return tonumber(a.max_damage) > tonumber(b.max_damage) end)

  local header = string.format("\n  %-14s %-8s %-10s %-10s %-6s  %s",
    "Class", "Stat", "Max Dmg", "Min Dmg", "Hits", "Mob")
  cecho("\n<gold>" .. string.rep("-", 80))
  cecho("\n<gold>                        Mob Damage Records")
  cecho("\n<gold>" .. string.rep("-", 80))
  cecho("\n<purple>" .. header)
  cecho("\n<gold>" .. string.rep("-", 80))

  local maxShow = 50
  for i, row in ipairs(rows) do
    if i > maxShow then
      cecho("\n<purple>  ... and " .. (#rows - maxShow) .. " more rows. Use a filter to narrow results.")
      break
    end
    cecho(string.format("\n  <magenta>%-14s <cyan>%-8s <green>%-10s <yellow>%-10s <purple>%-6s  <magenta>%s",
      string.sub(row.class, 1, 13),
      string.sub(row.stat, 1, 7),
      tostring(row.max_damage),
      tostring(row.min_damage),
      tostring(row.hit_count),
      row.mob))
  end
  cecho("\n<gold>" .. string.rep("-", 80))
  cecho("\n<purple>  Total records: <gold>" .. #rows)
  cecho("\n<gold>" .. string.rep("-", 80) .. "\n")
end

-------------------------------------------------
--  Delete mob damage records                   --
-------------------------------------------------
function ataxia.data.db.deleteMobDamage(filter)
  if not filter or filter == "" then
    ataxiaEcho("Usage: ataxiadmg delete <mob name or class>")
    return
  end
  local lowerFilter = string.lower(filter)
  local isClass = ataxia.data.classPrimaryStat[lowerFilter] ~= nil
  local rows
  if isClass then
    rows = db:fetch(ataxia.data.db.mobdmgdb.hits,
      db:like(ataxia.data.db.mobdmgdb.hits.class, "%" .. filter .. "%"))
  else
    rows = db:fetch(ataxia.data.db.mobdmgdb.hits,
      db:like(ataxia.data.db.mobdmgdb.hits.mob, "%" .. filter .. "%"))
  end
  if rows then
    for _, row in ipairs(rows) do
      db:delete(ataxia.data.db.mobdmgdb.hits, row._row_id)
    end
    ataxiaEcho("Deleted " .. #rows .. " mob damage records matching: " .. filter)
  else
    ataxiaEcho("No records found matching: " .. filter)
  end
end

-------------------------------------------------
--  Reset all mob damage data                   --
-------------------------------------------------
function ataxia.data.db.resetMobDamage()
  local rows = db:fetch(ataxia.data.db.mobdmgdb.hits)
  if rows then
    for _, row in ipairs(rows) do
      db:delete(ataxia.data.db.mobdmgdb.hits, row._row_id)
    end
  end
  ataxiaEcho("All mob damage records have been cleared.")
end
