--[[mudlet
type: script
name: Bonuses Window
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
    THE BONUSES PANEL  (v4.7.287, `mnem bonuses`)
    ============================================================================

    Renders what `011_Bonuses.lua` aggregates. The split is the one this module set already uses:
    `005_Ripple_Map` holds the pure graph and is unit-tested; `006_Ripple_Map_Window` holds the
    Geyser and is not, because it needs `main`. Everything here is drawing.

    Adjustable.Container, like all 25 windows in this package -- position and size auto-persist,
    and it inherits the save/load handling. The community window this was modelled on used
    `Geyser.UserWindow` (a true OS window, parkable on a second monitor); that would have been a
    new pattern here with its own position handling written from scratch.

    A MiniConsole rather than one Geyser.Label per row (the community file's approach): the row
    count is not fixed -- it grows with every boon claimed -- and a console scrolls, wraps and
    takes cecho colour tags for free, where N labels would need creating, sizing and destroying
    as the list changes.
]]--

local M = ataxia.mnemosyne
M.bonuses = M.bonuses or {}
local B = M.bonuses

local function cfg() return M._cfg() end

local function enabled()
  local c = cfg()
  if c.bonusesEnabled == nil then c.bonusesEnabled = false end
  return c.bonusesEnabled == true
end
B._enabled = enabled

-- ---------------------------------------------------------------------------
-- Build
-- ---------------------------------------------------------------------------

function B.build()
  if B.window then return end
  -- pcall'd exactly like the map: a bare/test environment has no Geyser and no `main`, and a
  -- window that cannot be built must not take the module down with it.
  local ok = pcall(function()
    B.window = Adjustable.Container:new({
      name = "ataxia.mnemosyne.bonuses.window",
      x = "72%", y = "34%", width = "26%", height = "44%",
      adjLabelstyle = "background-color:rgba(0,0,0,235); border: 1px solid #404040;",
      buttonstyle = [[QLabel{ border-radius: 4px; background-color: rgba(140,140,140,100%);}
                      QLabel::hover{ background-color: rgba(160,160,160,100%);}]],
      titleText = "Bonuses",
      titleStyle = "color: gray; font-size: 8pt;",
      lockStyle = "border: 1px solid #404040;",
    }, main)
    B.window:changeMenuStyle("dark")
    B.console = Geyser.MiniConsole:new({
      name = "ataxiaMnemBonuses",
      x = 2, y = 2, width = "100%-4", height = "100%-4",
      autoWrap = true, color = "black", fontSize = 8,
    }, B.window)
    B.window:hide()
  end)
  if not ok then B.window = nil end
end

-- ---------------------------------------------------------------------------
-- Render
-- ---------------------------------------------------------------------------

function B.render()
  if not (B.window and B.console) then return end
  if not enabled() then return end

  local ok, sections = pcall(M.bonusSections)
  if not ok or type(sections) ~= "table" then return end

  B.console:clear()

  if #sections == 0 then
    -- SAY WHY IT IS EMPTY. A blank panel and a broken panel look identical, and this one is
    -- legitimately blank for most of a session -- outside a run there is nothing to show.
    B.console:cecho("\n <dim_grey>no boons claimed this run.\n")
    return
  end

  for _, sec in ipairs(sections) do
    B.console:cecho("\n <gold>" .. sec.title .. "\n")
    for _, row in ipairs(sec.rows) do
      B.console:cecho("  <" .. row.colour .. ">" .. row.text .. "<reset>\n")
    end
  end
end

-- ---------------------------------------------------------------------------
-- Show / hide / toggle
-- ---------------------------------------------------------------------------

-- Unlike the ripple map this is NOT gated on being in the tower. Boons persist for the whole run
-- and the panel is as useful on the riverbank deciding whether to dive again as it is mid-ripple;
-- gating it on `inMnem()` would blank it exactly when you are reading it to plan.
function B.autoShow()
  if not B.window then return end
  if enabled() then B.window:show() else B.window:hide() end
end

function B.toggle(state)
  local c = cfg()
  if state == nil then state = not enabled() end
  c.bonusesEnabled = state and true or false
  if ataxia_saveSettings then ataxia_saveSettings(false) end
  B.autoShow()
  B.render()
  M.echo("Bonuses panel " .. (c.bonusesEnabled and "<green>ON" or "<grey>off") .. ".")
end

-- Console fallback, so the aggregation is readable even with the panel off (and in a client
-- where Geyser failed to build). Same data, same order -- one source, two surfaces.
function B.report()
  local ok, sections = pcall(M.bonusSections)
  if not ok or type(sections) ~= "table" or #sections == 0 then
    return M.echo("<gold>Bonuses<reset> -- nothing claimed this run.")
  end
  M.echo("<gold>Bonuses<reset> -- this run")
  for _, sec in ipairs(sections) do
    cecho("\n  <NavajoWhite>" .. sec.title)
    for _, row in ipairs(sec.rows) do
      cecho("\n    <" .. row.colour .. ">" .. row.text .. "<reset>")
    end
  end
  cecho("\n")
end

-- Re-render on the events that can change the answer: a claim, a ripple (new affixes), and the
-- attunement read that decides INERT. Cheap -- the aggregation is a few dozen table reads.
function B.refresh()
  if B.window and enabled() then B.render() end
end

B.build()
if B._buildHandler then killAnonymousEventHandler(B._buildHandler) end
B._buildHandler = registerAnonymousEventHandler("sysLoadEvent", function()
  if not B.window then B.build() end
  B.autoShow()
  B.refresh()
end)
