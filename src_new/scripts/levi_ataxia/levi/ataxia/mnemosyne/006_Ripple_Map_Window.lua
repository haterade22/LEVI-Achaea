--[[mudlet
type: script
name: Mnemosyne Ripple Map Window
hierarchy:
- Levi_Ataxia
- Ataxia
- Mnemosyne
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--[[
    ============================================================================
    MNEMOSYNE RIPPLE MAP - widget (Adjustable.Container grid)
    ============================================================================
    Draggable grid mini-map for the per-ripple room graph built in 005. Shows
    only while in Mnemosyne; wipes each ripple. Current room is green, rooms with
    unexplored exits are gold-bordered, others grey. Click a room to auto-walk
    there through the recorded graph. Position auto-persists (name-keyed
    Adjustable.Container); the on/off toggle lives in ataxia.settings.reporting.

    Depends on 005_Ripple_Map.lua and 001_HTTP_Client.lua (for echo/_cfg).
    ============================================================================
]]--

ataxia.mnemosyne = ataxia.mnemosyne or {}
ataxia.mnemosyne.map = ataxia.mnemosyne.map or {}
local MAP = ataxia.mnemosyne.map

local GRID_MAX = 11 -- max cells rendered per side (window on current room if larger)

local STYLE = {
  empty = "background-color: rgba(0,0,0,0); border: 0px;",
  room = "background-color: rgba(70,70,70,255); border: 1px solid #303030; qproperty-alignment: AlignCenter; color: #bbbbbb; font-size: 7pt;",
  unexplored = "background-color: rgba(95,80,20,255); border: 2px solid #d4b000; qproperty-alignment: AlignCenter; color: #ffffff; font-size: 7pt;",
  current = "background-color: rgba(0,150,0,255); border: 2px solid #33ff33; qproperty-alignment: AlignCenter; color: #ffffff; font-size: 7pt;",
}

function MAP._enabled()
  local c = (ataxia.mnemosyne._cfg and ataxia.mnemosyne._cfg()) or {}
  if c.mapEnabled == nil then c.mapEnabled = true end
  return c.mapEnabled == true
end

local function inMnem()
  return ataxiaBasher ~= nil and ataxiaBasher.inMnemosyne == true
end

-- ---------------------------------------------------------------------------
-- Build
-- ---------------------------------------------------------------------------

function MAP.build()
  if MAP.window then return end
  local ok = pcall(function()
    MAP.window = Adjustable.Container:new({
      name = "ataxia.mnemosyne.map.window",
      x = "72%", y = "6%", width = "22%", height = "26%",
      adjLabelstyle = "background-color:rgba(0,0,0,235); border: 1px solid #404040;",
      buttonstyle = [[QLabel{ border-radius: 4px; background-color: rgba(140,140,140,100%);}
                      QLabel::hover{ background-color: rgba(160,160,160,100%);}]],
      titleText = "Ripple Map",
      titleStyle = "color: gray; font-size: 8pt;",
      lockStyle = "border: 1px solid #404040;",
    }, main)
    MAP.window:changeMenuStyle("dark")
    MAP.container = Geyser.Container:new({
      name = "ataxia.mnemosyne.map.back", x = 2, y = 2, width = "100%-4", height = "100%-4",
    }, MAP.window)
    MAP.cells = {}
    MAP.window:hide()
  end)
  if not ok then MAP.window = nil end
end

function MAP._cell(id)
  if MAP.cells[id] then return MAP.cells[id] end
  local lbl = Geyser.Label:new({ name = "ataxia.mnemosyne.map.cell." .. id }, MAP.container)
  MAP.cells[id] = lbl
  return lbl
end

-- ---------------------------------------------------------------------------
-- Render
-- ---------------------------------------------------------------------------

function MAP.render()
  if not MAP.window then return end
  local minx, maxx, miny, maxy = MAP.bounds()
  if not minx then
    for _, lbl in pairs(MAP.cells or {}) do lbl:hide() end
    return
  end

  -- Clamp to a GRID_MAX window, centred on the current room if the map is larger.
  local cx = (MAP.current and MAP.rooms[MAP.current] and MAP.rooms[MAP.current].x) or math.floor((minx + maxx) / 2)
  local cy = (MAP.current and MAP.rooms[MAP.current] and MAP.rooms[MAP.current].y) or math.floor((miny + maxy) / 2)
  local half = math.floor(GRID_MAX / 2)
  if (maxx - minx + 1) > GRID_MAX then minx, maxx = cx - half, cx + half end
  if (maxy - miny + 1) > GRID_MAX then miny, maxy = cy - half, cy + half end
  local cols, rows = maxx - minx + 1, maxy - miny + 1

  local at = {}
  for _, r in pairs(MAP.rooms) do
    if r.x ~= nil then at[r.x .. "," .. r.y] = r end
  end

  local cw, ch = 100 / cols, 100 / rows
  for _, lbl in pairs(MAP.cells or {}) do lbl:hide() end
  for row = 1, rows do
    for col = 1, cols do
      local gx = minx + (col - 1)
      local gy = maxy - (row - 1) -- invert so north (higher y) is at the top
      local r = at[gx .. "," .. gy]
      if r then
        local lbl = MAP._cell(row .. "_" .. col)
        lbl:move((col - 1) * cw .. "%", (row - 1) * ch .. "%")
        lbl:resize(cw .. "%", ch .. "%")
        local st = STYLE.room
        if r.num == MAP.current then
          st = STYLE.current
        elseif MAP.hasUnexplored(r.num) then
          st = STYLE.unexplored
        end
        lbl:setStyleSheet(st)
        lbl:echo(MAP.hasUnexplored(r.num) and "?" or "")
        lbl:setClickCallback("ataxia.mnemosyne.map.onCellClick", r.num)
        lbl:setToolTip(tostring(r.name or ("#" .. tostring(r.num))))
        lbl:show()
      end
    end
  end
end

-- ---------------------------------------------------------------------------
-- Click-to-walk
-- ---------------------------------------------------------------------------

function MAP.onCellClick(num)
  MAP.walkTo(num)
end

function MAP.walkTo(num)
  if not MAP.current then return end
  local steps = MAP.path(MAP.current, num)
  if not steps then
    return ataxia.mnemosyne.echo("<indian_red>No known path to that room<reset> (you may not have walked a route there yet).")
  end
  if #steps == 0 then return end
  -- Queue the moves via the game's free queue (same mechanism the movement
  -- aliases use), so they execute one per balance in order.
  send("queue addclear free " .. steps[1])
  for i = 2, #steps do send("queue add free " .. steps[i]) end
  ataxia.mnemosyne.echo("Walking " .. #steps .. " room(s) to #" .. tostring(num) .. ".")
end

-- ---------------------------------------------------------------------------
-- Show / hide
-- ---------------------------------------------------------------------------

function MAP.autoShow()
  if not MAP.window then return end
  if MAP._enabled() and inMnem() then
    MAP.window:show()
  else
    MAP.window:hide()
  end
end

function MAP.toggle(state)
  local c = ataxia.mnemosyne._cfg()
  if state == nil then state = not MAP._enabled() end
  c.mapEnabled = state and true or false
  if ataxia_saveSettings then ataxia_saveSettings(false) end
  MAP.autoShow()
  ataxia.mnemosyne.echo("Ripple map " .. (c.mapEnabled and "<green>ON" or "<grey>off") .. ".")
end

-- Build once at load (and again on sysLoadEvent in case `main` wasn't ready).
MAP.build()
if MAP._buildHandler then killAnonymousEventHandler(MAP._buildHandler) end
MAP._buildHandler = registerAnonymousEventHandler("sysLoadEvent", function()
  if not MAP.window then MAP.build() end
  MAP.autoShow()
end)
