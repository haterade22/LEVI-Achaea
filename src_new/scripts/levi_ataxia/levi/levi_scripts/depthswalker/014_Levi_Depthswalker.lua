--[[mudlet
type: script
name: Levi_Depthswalker
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Leviticus
- DEPTHSWALKER
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--------------------------------------------------------------------------------
-- Backward-compat wrappers for old Depthswalker function names.
-- These route the old depthswalker_damageroute() and depthswalker_lockroute()
-- calls (from ^zz$ and ^xx$ aliases) through the new CC_Depthswalker system.
--------------------------------------------------------------------------------

function depthswalker_damageroute()
    depthswalker.setMode("damage")
    depthswalker.dispatch()
end

function depthswalker_lockroute()
    depthswalker.setMode("lock")
    depthswalker.dispatch()
end

-- Backward-compat for the old alias functions
function dw_fuckthem()
    depthswalker.dispatch()
end

function dw_leach()
    local oldMode = depthswalker.state.mode
    depthswalker.setMode("damage")
    depthswalker.dispatch()
    depthswalker.state.mode = oldMode
end

function dw_madness()
    local oldMode = depthswalker.state.mode
    depthswalker.setMode("madpression")
    depthswalker.dispatch()
    depthswalker.state.mode = oldMode
end

function dw_retribution()
    local oldMode = depthswalker.state.mode
    depthswalker.setMode("dictate")
    depthswalker.dispatch()
    depthswalker.state.mode = oldMode
end

function dw_degeneration()
    local oldMode = depthswalker.state.mode
    depthswalker.setMode("damage")
    depthswalker.dispatch()
    depthswalker.state.mode = oldMode
end

function dw_depression()
    local oldMode = depthswalker.state.mode
    depthswalker.setMode("lock")
    depthswalker.dispatch()
    depthswalker.state.mode = oldMode
end
