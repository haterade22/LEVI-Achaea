--[[mudlet
type: script
name: Treaty Run
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Leviticus
- Mage
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

---------------------------------------------------
-- Magi treaty run (alias `treaties`, `treaties stop`)
-- Renews the Ashbeast and Stoneback treaties in our workshop (room 33671):
-- walk there, take the material from the rift (OUTR), TREATY FORM, wait for the
-- game's completion line, next treaty. No summon. Session state only
-- (ataxiaTemp.treatyRun). Sources: .claude/classes/magi.md, "Elemental Treaties & Summons".
---------------------------------------------------

ataxiaTreaty = ataxiaTreaty or {}

-- Edit the rift commodity names here if the rift names them otherwise.
ataxiaTreaty.WORKSHOP = 33671
ataxiaTreaty.ORDER = { "ashbeast", "stoneback" }
ataxiaTreaty.COMMODITY = { ashbeast = "charcoal", stoneback = "stone" }
ataxiaTreaty.WALK_TIMEOUT = 90      -- seconds to reach the workshop
ataxiaTreaty.FORM_TIMEOUT = 60      -- seconds per treaty, from the OUTR to the completion line
ataxiaTreaty.POLL = 0.5             -- seconds between eq/balance checks

local function say(msg)
  if ataxiaEcho then ataxiaEcho("Treaties: " .. msg) end
end

local function curRoom()
  local ok, num = pcall(function() return tonumber(gmcp.Room.Info.num) end)
  if ok then return num end
  return nil
end

-- Kill every handler and timer the run made, then drop the run.
local function cleanup()
  local run = ataxiaTemp and ataxiaTemp.treatyRun
  if not run then return end
  for _, k in ipairs({ "arrivedHandler", "failedHandler" }) do
    if run[k] then killAnonymousEventHandler(run[k]) end
  end
  for _, k in ipairs({ "walkTimer", "treatyTimer", "pollTimer", "recheckTimer" }) do
    if run[k] then killTimer(run[k]) end
  end
  ataxiaTemp.treatyRun = nil
end

function ataxiaTreaty_stop(reason)
  local run = ataxiaTemp and ataxiaTemp.treatyRun
  if not run then
    say("no treaty run is active.")
    return
  end
  local formed = #run.formed > 0 and table.concat(run.formed, ", ") or "none"
  cleanup()
  say("stopped: " .. tostring(reason or "stopped") .. ". Formed: " .. formed .. ".")
end

local function finish()
  local run = ataxiaTemp.treatyRun
  local formed = table.concat(run.formed, ", ")
  cleanup()
  say("done. Formed: " .. formed .. ".")
end

-- Send TREATY FORM once eq and balance are up; poll until then (the treaty timer bounds it).
local function attemptForm()
  local run = ataxiaTemp.treatyRun
  if not run then return end
  run.pollTimer = nil
  if run.sent then return end
  local v = ataxia and ataxia.vitals
  if v and v.eq and v.bal then
    run.sent = true
    send("treaty form " .. run.waiting)
  else
    run.pollTimer = tempTimer(ataxiaTreaty.POLL, attemptForm)
  end
end

local function nextTreaty()
  local run = ataxiaTemp.treatyRun
  if not run then return end
  run.index = run.index + 1
  local name = ataxiaTreaty.ORDER[run.index]
  if not name then return finish() end
  run.waiting, run.sent = name, false
  send("outr 1 " .. ataxiaTreaty.COMMODITY[name])
  run.treatyTimer = tempTimer(ataxiaTreaty.FORM_TIMEOUT, function()
    local r = ataxiaTemp.treatyRun
    if r then r.treatyTimer = nil end
    ataxiaTreaty_stop("timed out after " .. ataxiaTreaty.FORM_TIMEOUT .. " s waiting for the " .. name .. " treaty")
  end)
  attemptForm()
end

-- Called by the completion triggers with the treaty's lower-case name.
function ataxiaTreaty_onFormed(name)
  local run = ataxiaTemp and ataxiaTemp.treatyRun
  if not run or not run.waiting then return end   -- a manual treaty: not our run
  if name ~= run.waiting then
    say("ignored a completion for " .. tostring(name) .. "; waiting for " .. run.waiting .. ".")
    return
  end
  if run.treatyTimer then killTimer(run.treatyTimer); run.treatyTimer = nil end
  if run.pollTimer then killTimer(run.pollTimer); run.pollTimer = nil end
  run.formed[#run.formed + 1] = name
  say(name .. " treaty formed.")
  run.waiting = nil
  nextTreaty()
end

local function atWorkshop()
  local run = ataxiaTemp.treatyRun
  if run.arrivedHandler then killAnonymousEventHandler(run.arrivedHandler); run.arrivedHandler = nil end
  if run.failedHandler then killAnonymousEventHandler(run.failedHandler); run.failedHandler = nil end
  if run.walkTimer then killTimer(run.walkTimer); run.walkTimer = nil end
  say("in the workshop.")
  nextTreaty()
end

local function onArrived()
  local run = ataxiaTemp and ataxiaTemp.treatyRun
  if not run or run.waiting or run.index > 0 then return end
  if curRoom() == ataxiaTreaty.WORKSHOP then return atWorkshop() end
  -- GMCP can trail the mapper's event: look once more before giving up.
  if run.recheckTimer then return end
  run.recheckTimer = tempTimer(1, function()
    local r = ataxiaTemp.treatyRun
    if not r then return end
    r.recheckTimer = nil
    if curRoom() == ataxiaTreaty.WORKSHOP then atWorkshop()
    else ataxiaTreaty_stop("arrived, but room " .. tostring(curRoom()) .. " is not the workshop " .. ataxiaTreaty.WORKSHOP) end
  end)
end

local function onPathFail()
  if ataxiaTemp and ataxiaTemp.treatyRun then ataxiaTreaty_stop("no path to the workshop") end
end

function ataxiaTreaty_start()
  ataxiaTemp = ataxiaTemp or {}
  if ataxiaTemp.treatyRun then
    say("a run is already active (treaties stop ends it).")
    return
  end
  if ataxiaBasher and ataxiaBasher.enabled then
    say("not started: autobash is running. Turn it off first.")
    return
  end
  local room = curRoom()
  if not room then
    say("not started: the current room is unknown (no GMCP room number).")
    return
  end
  ataxiaTemp.treatyRun = { index = 0, formed = {} }
  if room == ataxiaTreaty.WORKSHOP then
    say("starting in the workshop.")
    return nextTreaty()
  end
  if not (mmp and mmp.gotoRoom) then
    ataxiaTreaty_stop("the mapper is not loaded, cannot walk to the workshop")
    return
  end
  local run = ataxiaTemp.treatyRun
  say("walking to the workshop (" .. ataxiaTreaty.WORKSHOP .. ").")
  run.arrivedHandler = registerAnonymousEventHandler("mmapper arrived", onArrived)
  run.failedHandler = registerAnonymousEventHandler("mmapper failed path", onPathFail)
  run.walkTimer = tempTimer(ataxiaTreaty.WALK_TIMEOUT, function()
    local r = ataxiaTemp.treatyRun
    if r then r.walkTimer = nil end
    ataxiaTreaty_stop("timed out after " .. ataxiaTreaty.WALK_TIMEOUT .. " s walking to the workshop")
  end)
  mmp.gotoRoom(ataxiaTreaty.WORKSHOP)
end
