--[[mudlet
type: script
name: dmap Window
hierarchy:
- Dementia_Mapper
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--[[
    ============================================================================
    dmap.map - widget (Adjustable.Container grid)  [ported from LEVI 006_Window]
    ============================================================================
    Draggable 4x4 mini-map of the per-ripple room graph. Shows only while in a
    ripple; wipes each ripple. Current room green, rooms with unexplored exits
    gold-bordered `?`, others grey. Click a room to auto-walk there over the
    recorded graph. Position auto-persists (name-keyed Adjustable.Container).
    ============================================================================
]]--

dmap = dmap or {}
dmap.map = dmap.map or {}
local MAP = dmap.map

local LEVEL = 4 -- every Mnemosyne ripple is a fixed 4x4 room grid

local STYLE = {
  empty = "background-color: rgba(0,0,0,0); border: 0px;",
  placeholder = "background-color: rgba(45,45,45,120); border: 1px solid #2b2b2b;",
  room = "background-color: rgba(70,70,70,255); border: 1px solid #303030; qproperty-alignment: AlignCenter; color: #bbbbbb; font-size: 7pt;",
  unexplored = "background-color: rgba(95,80,20,255); border: 2px solid #d4b000; qproperty-alignment: AlignCenter; color: #ffffff; font-size: 7pt;",
  current = "background-color: rgba(0,150,0,255); border: 2px solid #33ff33; qproperty-alignment: AlignCenter; color: #ffffff; font-size: 7pt;",
}

function MAP._enabled()
  return dmap.config == nil or dmap.config.mapEnabled ~= false
end

-- ---------------------------------------------------------------------------
-- Build
-- ---------------------------------------------------------------------------

function MAP.build()
  if MAP.window then return end
  local ok = pcall(function()
    MAP.window = Adjustable.Container:new({
      name = "dmap.map.window",
      x = "72%", y = "6%", width = "22%", height = "26%",
      adjLabelstyle = "background-color:rgba(0,0,0,235); border: 1px solid #404040;",
      buttonstyle = [[QLabel{ border-radius: 4px; background-color: rgba(140,140,140,100%);}
                      QLabel::hover{ background-color: rgba(160,160,160,100%);}]],
      titleText = "Dementia Map",
      titleStyle = "color: gray; font-size: 8pt;",
      lockStyle = "border: 1px solid #404040;",
    }, main)
    MAP.window:changeMenuStyle("dark")
    MAP.container = Geyser.Container:new({
      name = "dmap.map.back", x = 2, y = 2, width = "100%-4", height = "100%-4",
    }, MAP.window)
    MAP.cells = {}
    MAP.window:hide()
  end)
  if not ok then MAP.window = nil end
end

function MAP._cell(id)
  if MAP.cells[id] then return MAP.cells[id] end
  local lbl = Geyser.Label:new({ name = "dmap.map.cell." .. id }, MAP.container)
  MAP.cells[id] = lbl
  return lbl
end

-- ---------------------------------------------------------------------------
-- Render
-- ---------------------------------------------------------------------------

function MAP.render()
  if not MAP.window then return end

  local at, hasAny = {}, false
  for _, r in pairs(MAP.rooms or {}) do
    if r.x ~= nil and r.visited then
      at[r.x .. "," .. r.y] = r
      hasAny = true
    end
  end
  if not hasAny then
    for _, lbl in pairs(MAP.cells or {}) do lbl:hide() end
    return
  end

  local minx, maxx, miny, maxy
  local function span(x, y)
    minx = math.min(minx or x, x); maxx = math.max(maxx or x, x)
    miny = math.min(miny or y, y); maxy = math.max(maxy or y, y)
  end
  for _, r in pairs(at) do span(r.x, r.y) end
  for _, r in pairs(MAP.rooms or {}) do
    if r.x ~= nil and r.visited then
      for _, d in ipairs(MAP.unexploredExits(r.num)) do
        local off = MAP.OFFSETS[d]
        if off and not at[(r.x + off[1]) .. "," .. (r.y + off[2])] then
          span(r.x + off[1], r.y + off[2])
        end
      end
    end
  end

  local cur = MAP.current and MAP.rooms[MAP.current]
  local cx = (cur and cur.x) or math.floor((minx + maxx) / 2)
  local cy = (cur and cur.y) or math.floor((miny + maxy) / 2)
  local function fit(lo, hi, c)
    local n = hi - lo + 1
    if n < LEVEL then
      local addHi = math.ceil((LEVEL - n) / 2)
      lo = lo - (LEVEL - n - addHi); hi = hi + addHi
    elseif n > LEVEL then
      lo = c - math.floor(LEVEL / 2); hi = lo + LEVEL - 1
    end
    return lo, hi
  end
  minx, maxx = fit(minx, maxx, cx)
  miny, maxy = fit(miny, maxy, cy)
  local cols, rows = maxx - minx + 1, maxy - miny + 1

  local cw, ch = 100 / cols, 100 / rows
  for _, lbl in pairs(MAP.cells or {}) do lbl:hide() end
  for row = 1, rows do
    for col = 1, cols do
      local gx = minx + (col - 1)
      local gy = maxy - (row - 1) -- invert so north (higher y) is at the top
      local r = at[gx .. "," .. gy]
      local lbl = MAP._cell(row .. "_" .. col)
      lbl:move((col - 1) * cw .. "%", (row - 1) * ch .. "%")
      lbl:resize(cw .. "%", ch .. "%")
      if r then
        local st = STYLE.room
        if r.num == MAP.current then
          st = STYLE.current
        elseif MAP.hasUnexplored(r.num) then
          st = STYLE.unexplored
        end
        lbl:setStyleSheet(st)
        lbl:echo(MAP.hasUnexplored(r.num) and "?" or "")
        lbl:setClickCallback(function() MAP.walkTo(r.num) end)
        pcall(function() lbl:setToolTip(tostring(r.name or ("#" .. tostring(r.num)))) end)
      else
        lbl:setStyleSheet(STYLE.placeholder)
        lbl:echo("")
        lbl:setClickCallback(function() end)
        pcall(function() lbl:setToolTip("unexplored") end)
      end
      lbl:show()
    end
  end
end

-- ---------------------------------------------------------------------------
-- Click-to-walk
-- ---------------------------------------------------------------------------

function MAP.walkTo(num)
  if not MAP.current then return end
  local steps = MAP.path(MAP.current, num) or MAP.pathKnown(MAP.current, num)
  if not steps then
    return dmap.echo("<indian_red>No known path to that room<reset> (no walked/known route yet).")
  end
  if #steps == 0 then return end
  send("queue addclear free " .. steps[1])
  for i = 2, #steps do send("queue add free " .. steps[i]) end
  dmap.echo("Walking " .. #steps .. " room(s) to #" .. tostring(num) .. ".")
end

-- ---------------------------------------------------------------------------
-- Show / hide / status / toggle
-- ---------------------------------------------------------------------------

function MAP.autoShow()
  if not MAP.window then return end
  if MAP._enabled() and MAP.inMnem() then
    MAP.window:show()
  else
    MAP.window:hide()
  end
end

function MAP.status()
  local n, visited, placed = 0, 0, 0
  for _, r in pairs(MAP.rooms or {}) do
    n = n + 1
    if r.visited then visited = visited + 1 end
    if r.x ~= nil then placed = placed + 1 end
  end
  local minx, maxx, miny, maxy = MAP.bounds()
  dmap.echo("<gold>Dementia map:<reset> inMnem=" .. tostring(MAP.inMnem())
    .. " enabled=" .. tostring(MAP._enabled())
    .. " rooms=" .. n .. " visited=" .. visited .. " placed=" .. placed
    .. " current=" .. tostring(MAP.current)
    .. " ripple=" .. tostring(MAP._ripple)
    .. " bounds=" .. tostring(minx) .. "," .. tostring(maxx) .. "," .. tostring(miny) .. "," .. tostring(maxy))
end

function MAP.toggle(state)
  dmap.config = dmap.config or {}
  if state == nil then state = not MAP._enabled() end
  dmap.config.mapEnabled = state and true or false
  MAP.autoShow()
  dmap.echo("Dementia map " .. (dmap.config.mapEnabled and "<green>ON" or "<grey>off") .. ".")
end

-- Build once at load (and again on sysLoadEvent in case `main` wasn't ready).
MAP.build()
if MAP._buildHandler then killAnonymousEventHandler(MAP._buildHandler) end
MAP._buildHandler = registerAnonymousEventHandler("sysLoadEvent", function()
  if not MAP.window then MAP.build() end
  MAP.autoShow()
end)
