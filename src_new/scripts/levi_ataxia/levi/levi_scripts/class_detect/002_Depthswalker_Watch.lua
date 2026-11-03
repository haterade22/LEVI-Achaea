--[[mudlet
type: script
name: Depthswalker Watch
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Leviticus
- Class Detect
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

-- DISPLAY ONLY. Nothing in this file sends a command to the game.
--
-- How two Depthswalkers killed us on 2026-11-03 (fightlogs 102138_Tabethys, rows 8749-9313, a group fight):
--   8.5 s before death  Akri attunes: "reaches past you, plunging Gattan'lier's hunger into your shadow".
--   3.9 s and 2.2 s     "As the scythe comes away, the writhing figure of your shadow clings to the blade."
--                       Kutcher, then Akri: the shadow goes into their phylactery.
--   0.02 s              "Drawing a shadow from a bone phylactery, Akri raises ... and plunges the blade ...":
--                       2,845 raw, all we had left, about 33% of the 8,741 that last read Full.
-- The same strike killed Antoninus (row 6790), failed on him just after his starburst (row 6814), and killed
-- Tabethys on 2026-10-27. .claude/classes/depthswalker.md calls it MUTILATE, a kill below 40% health. The wiki
-- says only "significant" damage, so the 40% is an INFERENCE. The wiki also says the victim must be in their
-- location, so leaving the room is a possible exit. No log shows that exit tried.
--
-- Trigger determine_class/031 feeds this. ataxia_promptLocks (can(x)/003) shows the label.

dwWatch = dwWatch or {}

-- Seconds a taken shadow stays on the prompt. A guess: no log shows how long a phylactery keeps one.
local HOLD = 60
-- Seconds before the same attune gets a new box.
local REPEAT = 30
-- A strike and its shadow line arrive in one packet (rows 9056 and 9059, 9155 and 9158).
local PACKET = 0.25
-- Under this health percent, the label also shows the number.
local LOW = 50

-- Transient, on ataxiaTemp. A restart empties it.
--   holders[name] = when that person took our shadow
--   attuned[name] = when that person last attuned to us
local function state()
  ataxiaTemp = ataxiaTemp or {}
  local st = ataxiaTemp.dwWatch
  if not st then
    st = { holders = {}, attuned = {} }
    ataxiaTemp.dwWatch = st
  end
  return st
end

-- One game line. `text` is what the trigger's pattern matched, and `name` is its capture.
function dwWatch.onLine(text, name)
  local st, now = state(), getEpoch()
  if text:find("reaches past you", 1, true) then
    if not st.attuned[name] or now - st.attuned[name] >= REPEAT then
      ataxia_boxEcho(name .. " attuned to you", "NavajoWhite:a_darkmagenta")
    end
    st.attuned[name] = now
  elseif text:find("clings to the blade", 1, true) then
    local who = (st.striker and now - st.strikeAt <= PACKET) and st.striker or "?"
    st.holders[who] = now
    ataxia_boxEcho("Shadow taken: " .. who .. " - leave, or stay above 40%", "white:red")
  elseif text:find("bone phylactery", 1, true) then
    st.spender, st.spendAt = name, now
  elseif text:find("piercing agony", 1, true) then
    -- The strike landed on us and we still read this line: that holder has spent our shadow.
    if st.spender and now - st.spendAt <= PACKET then st.holders[st.spender] = nil end
  elseif text:find("You have been slain", 1, true) then
    ataxiaTemp.dwWatch = nil
  else
    st.striker, st.strikeAt = name, now
  end
end

-- "SHADOW(Akri,Kutcher)", with " 38%" under LOW, or nil with no shadow held.
function dwWatch.promptLabel()
  local st = ataxiaTemp and ataxiaTemp.dwWatch
  if not st then return nil end
  local now, names = getEpoch(), {}
  for who, at in pairs(st.holders) do
    if now - at >= HOLD then
      st.holders[who] = nil
    else
      names[#names + 1] = who
    end
  end
  if #names == 0 then return nil end
  table.sort(names)
  local label = "SHADOW(" .. table.concat(names, ",") .. ")"
  local pct = ataxia and ataxia.vitals and tonumber(ataxia.vitals.hpp)
  if pct and pct < LOW then label = label .. " " .. pct .. "%" end
  return label
end
