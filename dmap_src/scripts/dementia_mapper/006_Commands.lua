--[[mudlet
type: script
name: dmap Commands
hierarchy:
- Dementia_Mapper
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

-- `dmap ...` command dispatch (wired from the alias in aliases/dementia_mapper/001_dmap).
dmap = dmap or {}

function dmap.command(args)
  args = tostring(args or ""):gsub("^%s+", ""):gsub("%s+$", "")
  local cmd, rest = args:match("^(%S*)%s*(.-)$")
  cmd = (cmd or ""):lower()
  rest = (rest or ""):lower()
  local map = dmap.map or {}

  if cmd == "" or cmd == "help" then
    dmap.echo("<gold>Dementia Mapper<reset> — commands:")
    cecho("\n   <cyan>dmap map [on|off]<reset>      toggle / set the mini-map window")
    cecho("\n   <cyan>dmap show|hide<reset>         force the window on/off")
    cecho("\n   <cyan>dmap status<reset>            dump map state (rooms, bounds, current)")
    cecho("\n   <cyan>dmap explore [on|off|status]<reset>  auto-sweep the ripple")
    cecho("\n   <cyan>dmap attack <command><reset>  set the auto-explore combat command (@id/@name), or 'off'")
    cecho("\n   <cyan>dmap swarm <n|off><reset>     at n+ denizens, retreat to the cleared room and funnel (off by default)")
  elseif cmd == "map" then
    if map.toggle then map.toggle(rest == "on" and true or rest == "off" and false or nil) end
  elseif cmd == "show" then
    if map.window then map.window:show() end
  elseif cmd == "hide" then
    if map.window then map.window:hide() end
  elseif cmd == "status" then
    if map.status then map.status() end
  elseif cmd == "explore" then
    if rest == "off" then
      if dmap.exploreStop then dmap.exploreStop("user") else dmap.echo("explorer not loaded.") end
    elseif rest == "status" then
      if dmap.exploreStatus then dmap.exploreStatus() else dmap.echo("explorer not loaded.") end
    else
      if dmap.exploreStart then dmap.exploreStart() else dmap.echo("explorer not loaded.") end
    end
  elseif cmd == "attack" then
    -- Everything after "attack" is the raw command template (case preserved via the alias arg).
    dmap.echo("Use the alias form: the raw template is set from your typed command. Set 'off' to clear.")
  elseif cmd == "swarm" then
    if rest == "off" or rest == "" then
      dmap.config.swarmThreshold = nil
      dmap.echo("Swarm-lite <grey>off<reset> (crowded rooms are fought in place).")
    else
      local n = tonumber(rest)
      if n and n >= 2 then
        dmap.config.swarmThreshold = n
        dmap.echo("Swarm-lite <green>ON<reset>: at <cyan>" .. n .. "+<reset> denizens, retreat to the cleared room and funnel.")
      else
        dmap.echo("Usage: dmap swarm <n>  (n >= 2)  |  dmap swarm off")
      end
    end
  else
    dmap.echo("unknown command '<red>" .. cmd .. "<reset>' — try <cyan>dmap help<reset>.")
  end
end

-- Set the auto-explore combat command from a raw (case-preserved) template. `@id`/`@name`
-- are substituted with the denizen being cleared; "off"/"none" clears it (map-only mode).
function dmap.setAttack(raw)
  raw = tostring(raw or ""):gsub("^%s+", ""):gsub("%s+$", "")
  if raw == "" or raw:lower() == "off" or raw:lower() == "none" then
    dmap.config.attack = nil
    dmap.echo("Auto-explore combat <grey>cleared<reset> (map-only: the sweep waits for you to clear each room).")
    return
  end
  dmap.config.attack = function(id, name)
    local out = raw:gsub("@id", tostring(id or "")):gsub("@name", tostring(name or ""))
    send(out)
  end
  dmap.echo("Auto-explore combat set: <cyan>" .. raw .. "<reset>")
end
