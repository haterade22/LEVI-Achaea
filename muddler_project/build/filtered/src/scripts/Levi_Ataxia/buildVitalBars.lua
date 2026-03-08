-------------------------------------------------
--  ataxia.bars — Configurable Movable Vital Bars
--
--  Each bar is an Adjustable.Container with a
--  Geyser.Gauge inside. Positions auto-save.
--
--  Alias: levibars          — show status
--         levibars on/off   — master toggle
--         levibars <name>   — toggle individual bar
--         levibars reset    — reset all positions
-------------------------------------------------

ataxia.bars = ataxia.bars or {}
ataxia.bars.config = ataxia.bars.config or {}

-- Default bar definitions: order, colors, data source
local barDefs = {
  health = {
    order = 1,
    label = "Health",
    frontStyle = [[
      background-color: QLinearGradient(x1:0, y1:0, x2:0, y2:1,
        stop:0 #00cc00, stop:0.1 #88ff88, stop:0.49 #00cc00, stop:0.5 #009900, stop:1 #006600);
      border-top: 1px black solid; border-left: 1px black solid;
      border-bottom: 1px black solid; border-radius: 7; padding: 3px;
    ]],
    backStyle = [[
      background-color: QLinearGradient(x1:0, y1:0, x2:0, y2:1,
        stop:0 #555555, stop:0.1 #333333, stop:0.49 #222222, stop:0.5 #111111, stop:1 #333333);
      border-width: 1px; border-color: DimGrey; border-style: solid;
      border-radius: 7; padding: 3px;
    ]],
  },
  mana = {
    order = 2,
    label = "Mana",
    frontStyle = [[
      background-color: QLinearGradient(x1:0, y1:0, x2:0, y2:1,
        stop:0 #0044cc, stop:0.1 #6699ff, stop:0.49 #0055ff, stop:0.5 #0044cc, stop:1 #002299);
      border-top: 1px black solid; border-left: 1px black solid;
      border-bottom: 1px black solid; border-radius: 7; padding: 3px;
    ]],
    backStyle = [[
      background-color: QLinearGradient(x1:0, y1:0, x2:0, y2:1,
        stop:0 #555555, stop:0.1 #333333, stop:0.49 #222222, stop:0.5 #111111, stop:1 #333333);
      border-width: 1px; border-color: DimGrey; border-style: solid;
      border-radius: 7; padding: 3px;
    ]],
  },
  willpower = {
    order = 3,
    label = "Willpower",
    frontStyle = [[
      background-color: QLinearGradient(x1:0, y1:0, x2:0, y2:1,
        stop:0 #cc8800, stop:0.1 #ffcc44, stop:0.49 #cc8800, stop:0.5 #aa6600, stop:1 #664400);
      border-top: 1px black solid; border-left: 1px black solid;
      border-bottom: 1px black solid; border-radius: 7; padding: 3px;
    ]],
    backStyle = [[
      background-color: QLinearGradient(x1:0, y1:0, x2:0, y2:1,
        stop:0 #555555, stop:0.1 #333333, stop:0.49 #222222, stop:0.5 #111111, stop:1 #333333);
      border-width: 1px; border-color: DimGrey; border-style: solid;
      border-radius: 7; padding: 3px;
    ]],
  },
  endurance = {
    order = 4,
    label = "Endurance",
    frontStyle = [[
      background-color: QLinearGradient(x1:0, y1:0, x2:0, y2:1,
        stop:0 #888800, stop:0.1 #cccc44, stop:0.49 #888800, stop:0.5 #666600, stop:1 #444400);
      border-top: 1px black solid; border-left: 1px black solid;
      border-bottom: 1px black solid; border-radius: 7; padding: 3px;
    ]],
    backStyle = [[
      background-color: QLinearGradient(x1:0, y1:0, x2:0, y2:1,
        stop:0 #555555, stop:0.1 #333333, stop:0.49 #222222, stop:0.5 #111111, stop:1 #333333);
      border-width: 1px; border-color: DimGrey; border-style: solid;
      border-radius: 7; padding: 3px;
    ]],
  },
  cape = {
    order = 5,
    label = "Cape",
    frontStyle = [[
      background-color: QLinearGradient(x1:0, y1:0, x2:0, y2:1,
        stop:0 #621616, stop:0.1 #640a0a, stop:0.49 #8a0000, stop:0.5 #560000, stop:1 #260000);
      border-top: 1px DimGrey solid; border-left: 1px DimGrey solid;
      border-bottom: 1px DimGrey solid; border-radius: 7; padding: 3px;
    ]],
    backStyle = [[
      background-color: QLinearGradient(x1:0, y1:0, x2:0, y2:1,
        stop:0 #555555, stop:0.1 #555555, stop:0.49 #333333, stop:0.5 #333333, stop:1 #555555);
      border-width: 1px; border-color: DimGrey; border-style: solid;
      border-radius: 7; padding: 3px;
    ]],
  },
}

-- Ordered list of bar names
local barOrder = {"health", "mana", "willpower", "endurance", "cape"}

-------------------------------------------------
-- Save / Load config
-------------------------------------------------
local function getConfigPath()
  return getMudletHomeDir() .. "/ataxia_bars_config.lua"
end

function ataxia.bars.saveConfig()
  local save = {}
  save.enabled = ataxia.bars.config.enabled or {}
  save.masterEnabled = ataxia.bars.config.masterEnabled
  table.save(getConfigPath(), save)
end

function ataxia.bars.loadConfig()
  local path = getConfigPath()
  if io.exists(path) then
    local save = {}
    table.load(path, save)
    ataxia.bars.config.enabled = save.enabled or {}
    if save.masterEnabled ~= nil then
      ataxia.bars.config.masterEnabled = save.masterEnabled
    end
  end

  -- Defaults: health, mana, cape on; wp/ep off
  if ataxia.bars.config.masterEnabled == nil then
    ataxia.bars.config.masterEnabled = false
  end
  if not ataxia.bars.config.enabled then ataxia.bars.config.enabled = {} end
  if ataxia.bars.config.enabled.health == nil then ataxia.bars.config.enabled.health = true end
  if ataxia.bars.config.enabled.mana == nil then ataxia.bars.config.enabled.mana = true end
  if ataxia.bars.config.enabled.willpower == nil then ataxia.bars.config.enabled.willpower = false end
  if ataxia.bars.config.enabled.endurance == nil then ataxia.bars.config.enabled.endurance = false end
  if ataxia.bars.config.enabled.cape == nil then ataxia.bars.config.enabled.cape = true end
end

-------------------------------------------------
-- Build a single bar
-------------------------------------------------
local function buildBar(name)
  local def = barDefs[name]
  if not def then return end

  local bar = {}
  ataxia.bars[name] = bar

  bar.window = Adjustable.Container:new({
    name = "ataxia.bars." .. name .. ".window",
    x = 0, y = 0,
    width = 250, height = 35,
    adjLabelstyle = "background-color:rgba(0,0,0,0%);",
    buttonstyle = [[
      QLabel{ border-radius: 3px; background-color: rgba(140,140,140,100%);}
      QLabel::hover{ background-color: rgba(160,160,160,50%);}
    ]],
    buttonFontSize = 5,
    buttonsize = 10,
  }, main)

  bar.container = Geyser.Container:new({
    name = "ataxia.bars." .. name .. ".back",
    x = 0, y = 0,
    width = "100%", height = "100%",
  }, bar.window)

  bar.gauge = Geyser.Gauge:new({
    name = "ataxia.bars." .. name .. ".gauge",
    x = "2%", y = "2%",
    width = "96%", height = "96%",
  }, bar.container)

  bar.gauge.front:setStyleSheet(def.frontStyle)
  bar.gauge.back:setStyleSheet(def.backStyle)
  bar.gauge:setValue(0, 100)

  setFontSize("ataxia.bars." .. name .. ".gauge", 9)

  if ataxia.bars.config.masterEnabled and ataxia.bars.config.enabled[name] then
    bar.window:show()
  else
    bar.window:hide()
  end
end

-------------------------------------------------
-- Build all bars
-------------------------------------------------
function ataxia.bars.buildAll()
  ataxia.bars.loadConfig()
  for _, name in ipairs(barOrder) do
    buildBar(name)
  end
end

-------------------------------------------------
-- Show / Hide helpers
-------------------------------------------------
function ataxia.bars.showAll()
  for _, name in ipairs(barOrder) do
    if ataxia.bars[name] and ataxia.bars[name].window then
      if ataxia.bars.config.enabled[name] then
        ataxia.bars[name].window:show()
      end
    end
  end
end

function ataxia.bars.hideAll()
  for _, name in ipairs(barOrder) do
    if ataxia.bars[name] and ataxia.bars[name].window then
      ataxia.bars[name].window:hide()
    end
  end
end

-------------------------------------------------
-- Toggle master on/off
-------------------------------------------------
function ataxia.bars.toggle(state)
  if state == "on" then
    ataxia.bars.config.masterEnabled = true
    ataxia.bars.showAll()
  elseif state == "off" then
    ataxia.bars.config.masterEnabled = false
    ataxia.bars.hideAll()
  else
    ataxia.bars.config.masterEnabled = not ataxia.bars.config.masterEnabled
    if ataxia.bars.config.masterEnabled then
      ataxia.bars.showAll()
    else
      ataxia.bars.hideAll()
    end
  end
  ataxia.bars.saveConfig()
end

-------------------------------------------------
-- Toggle individual bar
-------------------------------------------------
function ataxia.bars.toggleBar(name)
  if not barDefs[name] then
    ataxia.echo("Unknown bar: " .. tostring(name) .. ". Valid: health, mana, willpower, endurance, cape")
    return
  end
  ataxia.bars.config.enabled[name] = not ataxia.bars.config.enabled[name]
  if ataxia.bars[name] and ataxia.bars[name].window then
    if ataxia.bars.config.masterEnabled and ataxia.bars.config.enabled[name] then
      ataxia.bars[name].window:show()
    else
      ataxia.bars[name].window:hide()
    end
  end
  local status = ataxia.bars.config.enabled[name] and "<green>ON" or "<red>OFF"
  ataxia.echo(barDefs[name].label .. " bar: " .. status)
  ataxia.bars.saveConfig()
end

-------------------------------------------------
-- Reset all positions
-------------------------------------------------
function ataxia.bars.resetPositions()
  for _, name in ipairs(barOrder) do
    if ataxia.bars[name] and ataxia.bars[name].window then
      ataxia.bars[name].window:hide()
      ataxia.bars[name].window = nil
    end
  end
  -- Rebuild with default positions
  for _, name in ipairs(barOrder) do
    -- Clear saved position by recreating with autoLoad=false temporarily
    local bar = {}
    ataxia.bars[name] = bar
    bar.window = Adjustable.Container:new({
      name = "ataxia.bars." .. name .. ".window",
      x = 0, y = 0,
      width = 250, height = 35,
      autoLoad = false,
      adjLabelstyle = "background-color:rgba(0,0,0,0%);",
      buttonstyle = [[
        QLabel{ border-radius: 3px; background-color: rgba(140,140,140,100%);}
        QLabel::hover{ background-color: rgba(160,160,160,50%);}
      ]],
      buttonFontSize = 5,
      buttonsize = 10,
    }, main)

    bar.container = Geyser.Container:new({
      name = "ataxia.bars." .. name .. ".back",
      x = 0, y = 0,
      width = "100%", height = "100%",
    }, bar.window)

    bar.gauge = Geyser.Gauge:new({
      name = "ataxia.bars." .. name .. ".gauge",
      x = "2%", y = "2%",
      width = "96%", height = "96%",
    }, bar.container)

    local def = barDefs[name]
    bar.gauge.front:setStyleSheet(def.frontStyle)
    bar.gauge.back:setStyleSheet(def.backStyle)
    bar.gauge:setValue(0, 100)
    setFontSize("ataxia.bars." .. name .. ".gauge", 9)

    if ataxia.bars.config.masterEnabled and ataxia.bars.config.enabled[name] then
      bar.window:show()
    else
      bar.window:hide()
    end
  end
  ataxia.echo("Vital bar positions reset to defaults")
end

-------------------------------------------------
-- Status display
-------------------------------------------------
function ataxia.bars.status()
  local master = ataxia.bars.config.masterEnabled and "<green>ON" or "<red>OFF"
  ataxia.echo("Vital Bars: " .. master)
  for _, name in ipairs(barOrder) do
    local enabled = ataxia.bars.config.enabled[name]
    local status = enabled and "<green>ON" or "<red>OFF"
    ataxia.echo("  " .. barDefs[name].label .. ": " .. status)
  end
  ataxia.echo("Commands: <white>levibars on/off<reset> | <white>levibars <name><reset> | <white>levibars reset")
end

-------------------------------------------------
-- Update function — called from ataxiagui_updateVitals
-------------------------------------------------
function ataxia.bars.update()
  if not ataxia.bars.config.masterEnabled then return end
  if not ataxia.vitals or not ataxia.vitals.hp then return end

  -- Health
  if ataxia.bars.health and ataxia.bars.health.gauge and ataxia.bars.config.enabled.health then
    ataxia.bars.health.gauge:setValue(ataxia.vitals.hpp, 100)
    ataxia.bars.health.gauge:echo("<center><b>" .. ataxia.vitals.hp .. "</b>")
  end

  -- Mana
  if ataxia.bars.mana and ataxia.bars.mana.gauge and ataxia.bars.config.enabled.mana then
    ataxia.bars.mana.gauge:setValue(ataxia.vitals.mpp, 100)
    ataxia.bars.mana.gauge:echo("<center><b>" .. ataxia.vitals.mp .. "</b>")
  end

  -- Willpower
  if ataxia.bars.willpower and ataxia.bars.willpower.gauge and ataxia.bars.config.enabled.willpower then
    ataxia.bars.willpower.gauge:setValue(ataxia.vitals.wpp, 100)
    ataxia.bars.willpower.gauge:echo("<center><b>" .. ataxia.vitals.wp .. "</b>")
  end

  -- Endurance
  if ataxia.bars.endurance and ataxia.bars.endurance.gauge and ataxia.bars.config.enabled.endurance then
    ataxia.bars.endurance.gauge:setValue(ataxia.vitals.epp, 100)
    ataxia.bars.endurance.gauge:echo("<center><b>" .. ataxia.vitals.ep .. "</b>")
  end

  -- Cape is updated by zgui.showCape/zgui.renewCape, not here
end

-------------------------------------------------
-- Cape bar update — called from zgui.showCape
-------------------------------------------------
function ataxia.bars.updateCape()
  if not ataxia.bars.config.masterEnabled then return end
  if not ataxia.bars.cape or not ataxia.bars.cape.gauge then return end
  if not ataxia.bars.config.enabled.cape then return end
  if not zgui.cape then return end

  local watch = zgui.cape.watch or 0
  local count = zgui.cape.count or 0

  if watch < 240 then
    local remaining = 240 - watch
    ataxia.bars.cape.gauge:setValue(remaining, 240)
    if count > 49 then
      ataxia.bars.cape.gauge:echo("<center><b>FULL - " .. remaining .. " seconds</b>")
    else
      ataxia.bars.cape.gauge:echo("<center><b>" .. count .. "/50 - " .. remaining .. " seconds</b>")
    end
  else
    ataxia.bars.cape.gauge:setValue(0, 240)
    ataxia.bars.cape.gauge:echo("")
  end
end

-------------------------------------------------
-- Dispatch for alias
-------------------------------------------------
function ataxia.bars.dispatch(args)
  if not args or args == "" then
    ataxia.bars.status()
  elseif args == "on" then
    ataxia.bars.toggle("on")
    ataxia.echo("Vital Bars: <green>ON")
  elseif args == "off" then
    ataxia.bars.toggle("off")
    ataxia.echo("Vital Bars: <red>OFF")
  elseif args == "reset" then
    ataxia.bars.resetPositions()
  elseif barDefs[args] then
    ataxia.bars.toggleBar(args)
  else
    ataxia.echo("Unknown: " .. args .. ". Use: on, off, reset, health, mana, willpower, endurance, cape")
  end
end
