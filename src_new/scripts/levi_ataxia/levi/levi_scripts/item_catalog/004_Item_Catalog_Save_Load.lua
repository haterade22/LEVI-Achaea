--[[mudlet
type: script
name: Item Catalog Save Load
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Item Catalog
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--[[
    ============================================================================
    ITEM CATALOG - SAVE / LOAD
    ============================================================================
    Persists itemCatalog.items and itemCatalog.config to disk.
    Uses Mudlet's table.save/table.load matching the ataxia pattern.
    ============================================================================
]]--

itemCatalog = itemCatalog or {}

-- =============================================================================
-- SAVE
-- =============================================================================

function itemCatalog.save()
  if not itemCatalog.items then return end

  local separator = string.char(getMudletHomeDir():byte()) == "/" and "/" or "\\"
  local loc = getMudletHomeDir() .. separator .. "itemcatalog"

  -- Build save data
  local saveData = {
    items = itemCatalog.items,
    config = itemCatalog.config,
    version = itemCatalog.version,
  }

  table.save(loc, saveData)

  -- Profile backup
  _ataxia_backup = _ataxia_backup or {}
  _ataxia_backup.itemcatalog = {}
  table.load(loc, _ataxia_backup.itemcatalog)
end

-- =============================================================================
-- LOAD
-- =============================================================================

function itemCatalog.load()
  local separator = string.char(getMudletHomeDir():byte()) == "/" and "/" or "\\"
  local loc = getMudletHomeDir() .. separator .. "itemcatalog"

  local source = nil
  if io.exists(loc) then
    source = {}
    table.load(loc, source)
  elseif _ataxia_backup and _ataxia_backup.itemcatalog then
    source = _ataxia_backup.itemcatalog
  end

  if source then
    -- Load items
    if source.items then
      for id, data in pairs(source.items) do
        local numId = tonumber(id) or id
        if type(data) == "table" and data.name then
          itemCatalog.items[numId] = data
        end
      end
    end

    -- Load config (merge, don't replace)
    if source.config then
      for k, v in pairs(source.config) do
        itemCatalog.config[k] = v
      end
    end

    local count = 0
    for _ in pairs(itemCatalog.items) do count = count + 1 end
    if count > 0 then
      itemCatalog.decho("Loaded " .. count .. " cataloged items from disk.")
    end
  end
end

-- =============================================================================
-- AUTO-INIT: Load on script load if data exists
-- =============================================================================

itemCatalog.load()
