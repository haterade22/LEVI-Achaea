--[[mudlet
type: script
name: Mounts
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Basher
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--[[
    ============================================================================
    OUR OWN MOUNTS ARE NOT TARGETS  (v4.7.335, user-directed)
    ============================================================================

    User, pasting the listing: "These need to be not on the kill list as they are our mounts."

        Your loyal mounts are:
        A black Dardanic stallion22638 is at your fingertips.
        A lean grizzly bear135599 is at your feet.
        A war elephant193142 is at your fingertips.
        A massive dire wolf397877 is at your fingertips.
        A withered crypt worm651017 is at your fingertips.

    A mount in the room is an ordinary GMCP item with the monster attribute, so the basher reads it
    as a denizen, learns its name into the area's target list, and swings at it.

    BY ID, NEVER BY NAME. This is the whole design decision. `ataxiaBasher.ownDenizens` already
    excludes pets by keyword, and a keyword is exactly wrong here: "a massive dire wolf", "a lean
    grizzly bear" and "a war elephant" are REAL denizens in the game. Adding those words would
    blacklist every wild one in Achaea -- the target list would quietly lose its best rooms, and
    nothing would say why. The id in the listing ("stallion22638") is the item id GMCP reports, it
    belongs to that one creature, and it does not change when the mount is stabled or re-summoned.

    So: learn the ids here, and drop exactly those ids where the room contents are read
    (`ataxia_RoomContents_Update`). A wild dire wolf in the same room is still a target; ours is
    not in `denizensHere` at all, which is the one place everything downstream agrees on.

    LEARNED PASSIVELY. The listing is parsed whenever the game prints it -- no command is sent,
    because the command that produces it was never captured in a log and this tree does not guess
    game syntax (the horn's rule). Type your mounts command once a session, or whenever you tame
    one, and the ids stick: `ataxiaBasher` is saved to disk.
]]--

ataxiaBasher = ataxiaBasher or {}
ataxiaTemp = ataxiaTemp or {}

-- How long the header keeps the row parser open. The rows arrive in one burst; anything later is
-- some other screen that happens to look like a mount row.
local MOUNT_LIST_WINDOW = 3

-- "Your loyal mounts are:" -- arm the row parser and start a fresh reading, so a mount sold or
-- released disappears from the list rather than lingering forever.
function ataxiaBasher_onMountsHeader()
  ataxiaTemp.mountListUntil = ((getEpoch and getEpoch()) or os.time()) + MOUNT_LIST_WINDOW
  ataxiaTemp.mountListSeen = {}
  return true
end

-- One row: `name` is the text before the id ("A black Dardanic stallion"), `id` the digits.
-- Ignored unless a header armed us, so a lookalike line elsewhere cannot poison the list.
function ataxiaBasher_onMountRow(name, id)
  local until_ = tonumber(ataxiaTemp.mountListUntil) or 0
  if ((getEpoch and getEpoch()) or os.time()) > until_ then return false end
  id = tonumber(id)
  if not id then return false end
  name = tostring(name or ""):gsub("^%s+", ""):gsub("%s+$", "")
  ataxiaBasher.mountIds = ataxiaBasher.mountIds or {}
  ataxiaBasher.mountIds[id] = (name ~= "") and name or true
  ataxiaTemp.mountListSeen = ataxiaTemp.mountListSeen or {}
  ataxiaTemp.mountListSeen[id] = true
  -- ...and take the name off the saved target lists (v4.7.335). The id keeps us from ATTACKING
  -- one, but `bash list` is by name, so a mount learned before this still SAT on the kill list --
  -- which is what the user was looking at. Exact name only, never a substring: "dire wolf" would
  -- take half the bestiary with it. If a wild one of the same species turns up later, auto-learn
  -- puts the name back from THAT denizen, which is the right reason to have it.
  ataxiaBasher_purgeMountName(name)
  return true
end

-- Remove one exact mount name from every area's target list. Returns how many entries went.
function ataxiaBasher_purgeMountName(name)
  local want = tostring(name or ""):lower():gsub("^%s*an?%s+", ""):gsub("^%s*the%s+", "")
  want = want:gsub("^%s+", ""):gsub("%s+$", "")
  if want == "" or type(ataxiaBasher.targetList) ~= "table" then return 0 end
  local removed = 0
  for _, list in pairs(ataxiaBasher.targetList) do
    if type(list) == "table" then
      for i = #list, 1, -1 do
        local entry = tostring(list[i] or ""):lower():gsub("^%s*an?%s+", ""):gsub("^%s*the%s+", "")
        if entry == want then
          table.remove(list, i)
          removed = removed + 1
        end
      end
    end
  end
  if removed > 0 then
    ataxiaEcho("Mount <white>" .. tostring(name) .. "<reset> removed from " .. removed
      .. " target list(s) -- it is skipped by ID from now on.")
  end
  return removed
end

-- Is this room item one of our mounts? Called from the room-contents read, by id.
function ataxiaBasher_isMount(id)
  id = tonumber(id)
  if not id then return false end
  return (ataxiaBasher.mountIds and ataxiaBasher.mountIds[id]) and true or false
end

-- The id we learned for this descriptive name, or nil. The vault line names the creature
-- ("a lean grizzly bear"); the game wants the ID for anything that acts on it.
function ataxiaBasher_mountIdByName(name)
  local want = tostring(name or ""):lower():gsub("^%s*an?%s+", ""):gsub("^%s*the%s+", "")
  want = want:gsub("[%s%.]+$", ""):gsub("^%s+", "")
  if want == "" then return nil end
  for id, known in pairs(ataxiaBasher.mountIds or {}) do
    local k = tostring(known or ""):lower():gsub("^%s*an?%s+", ""):gsub("^%s*the%s+", "")
    k = k:gsub("[%s%.]+$", ""):gsub("^%s+", "")
    if k == want then return id end
  end
  return nil
end

-- WE JUST VAULTED ONTO ONE, SO THAT IS THE MOUNT (v4.7.339, user: "When I use VAULT (mount) ... It
-- doesnt set that mount as my mount, which it should always revault").
--
-- The old vault trigger sent `curing mount <descriptive name>` straight from the line, and the
-- game refused it: "That is not a valid mount that belongs to you." A name is not a handle --
-- every command that acts on the mount (CURING MOUNT, TELL <mount> COME HERE, VAULT, SPUR) wants
-- the id, which is exactly what the mounts listing gave us.
--
-- So: resolve the name we were just told to the id we learned, make it the ACTIVE mount for
-- `ataxia.getMount()` (which the flying, urn and no-steed paths all read), and tell the curing
-- system about it. With no listing read yet there is no id to use -- and sending the name again
-- would only repeat the refusal -- so it says what to do instead and changes nothing.
function ataxiaBasher_vaultedOnto(name)
  if type(name) ~= "string" or name == "" then return false end
  omount = name -- kept: the old global, still read elsewhere
  local id = ataxiaBasher_mountIdByName(name)
  if not id then
    ataxiaEcho("Vaulted onto <white>" .. name .. "<reset>, but no id is known for it -- list your "
      .. "mounts in game once and it becomes your mount automatically (<white>bash mounts<reset>).")
    return false
  end
  ataxia.settings = ataxia.settings or {}
  ataxia.settings.user = ataxia.settings.user or {}
  local was = ataxia.settings.user.mount
  ataxia.settings.user.mount = tostring(id)
  send("curing mount " .. id, false)
  if was ~= tostring(id) then
    ataxiaEcho("Mount set to <white>" .. name .. "<reset> (" .. id .. ") -- vault, spur and "
      .. "\"come here\" now use it.")
    if ataxia_saveSettings then pcall(ataxia_saveSettings) end
  end
  return id
end

-- `bash mounts` -- what we know, and how it was learned.
function ataxiaBasher_mountsReport()
  -- Which jump verb is live right now (v4.7.345). The belief is what decides whether an escape
  -- moves us or is refused, so it belongs in the one screen that explains the mounts.
  local mstate = (ataxiaTemp and ataxiaTemp.mounted == nil) and "not known yet"
    or (ataxiaBasher_isMounted() and "MOUNTED" or "on foot")
  ataxiaEcho("Jumps: <white>" .. ataxiaBasher_mountVerb("leap") .. "<reset> (" .. mstate .. ").")
  local ids = {}
  for id in pairs(ataxiaBasher.mountIds or {}) do ids[#ids + 1] = id end
  table.sort(ids)
  if #ids == 0 then
    return ataxiaEcho("No mounts learned yet -- list your mounts in game once and they will be "
      .. "skipped from then on (they are excluded by ID, so wild denizens of the same species "
      .. "are still targets).")
  end
  ataxiaEcho("Mounts skipped by the basher (" .. #ids .. "):")
  for _, id in ipairs(ids) do
    local name = ataxiaBasher.mountIds[id]
    cecho("\n  <cyan>" .. id .. "<reset>  " .. (type(name) == "string" and name or "(name unknown)"))
  end
end

-- ---------------------------------------------------------------------------
-- MOUNTJUMP, NOT LEAP  (v4.7.345, user-directed)
-- ---------------------------------------------------------------------------
--
-- User: "When mounted, we should use mountjump instead of LEAP." -- "mountjump direction or MJ
-- direction."
--
-- This is not a preference. While mounted the game REFUSES the leap outright (user, live):
--
--     You cannot do that while mounted.
--
-- ...and the jump is the movement this package ESCAPES with. Every leap in the Mnemosyne tactics
-- is there to cross something -- our own icewall, an affix wall, a swarm at the door -- so a
-- refused leap is a silent no-op in the anti-death ladder: the banner prints, nothing moves, and
-- the room keeps hitting. The verb has to follow the saddle.
--
-- NINE LINES TEACH THE STATE, AND SEVEN OF THEM ALREADY HAD TRIGGERS. That is why nothing here
-- is guessed:
--
--   mounted    "You easily vault onto the back of <mount>."                  (025 / 735)
--              "You climb up on <mount>."                                    (735)
--              "You pull back the reins on your mount and jump off to the east."   (783, new)
--              "You cannot do that while mounted."                           (784, new)
--   on foot    "You step down off of <mount>."                               (736)
--              "You lose purchase on <mount>."                               (736 -- thrown off)
--              "You have no mount on which to jump."                         (705)
--              "You need to be riding a proper mount to gallop."             (705)
--              "You must be mounted to trample."                             (705)
--
-- Each direction is taught by a REFUSAL as well as by a success, and that is what makes the
-- belief safe to act on: being wrong costs one refused command, after which the state is right.
-- No polling, no command we have never seen answered.
--
-- THE BELIEF LIVES IN `ataxiaTemp`, NOT IN `ataxiaBasher`. `ataxiaBasher` is saved to disk, and a
-- saved `mounted = true` would outlive the reload that put us back on our feet -- the same shape
-- as the HTTP queue that wedged for nine runs on a saved `_busy = true`. Session scratch starts
-- unknown and re-learns from the first line either way, which is strictly better than starting
-- confidently wrong.

-- How long a jump we sent stays recoverable. The refusal comes back on the same round, so this
-- only has to outlast one round trip; anything older is a different command being refused.
local JUMP_REFUSED_WINDOW = 4

local function roomNow()
  local r = gmcp and gmcp.Room and gmcp.Room.Info
  return (r and (r.num or r.id)) or nil
end

function ataxiaBasher_isMounted()
  return (ataxiaTemp and ataxiaTemp.mounted) and true or false
end

-- Latch the belief. Quiet unless it CHANGES -- the lines that teach it arrive all the time, and a
-- note per vault is information while a note per line is noise.
function ataxiaBasher_mountedSet(on, why)
  ataxiaTemp = ataxiaTemp or {}
  on = on and true or false
  local was = ataxiaTemp.mounted and true or false
  local first = (ataxiaTemp.mounted == nil)
  ataxiaTemp.mounted = on
  if (was ~= on or first) and ataxiaEcho then
    ataxiaEcho((on and "Mounted" or "On foot") .. (why and (" (" .. why .. ")") or "")
      .. " -- jumps use <white>" .. (on and "mountjump" or "leap") .. "<reset>.")
  end
  return on
end

-- The verb for a jump: MOUNTJUMP from the saddle, otherwise whatever the caller would have sent
-- (leap, or the Bard's backflip). One owner, so every jump site follows the same belief.
function ataxiaBasher_mountVerb(fallback)
  if ataxiaBasher_isMounted() then return "mountjump" end
  return fallback or "leap"
end

-- Remember the jump we just sent so a refusal can re-issue it. Direction AND room: if the room
-- has changed the jump LANDED, and a refusal arriving after that belongs to some other command.
function ataxiaBasher_jumpSent(dir, verb)
  ataxiaTemp = ataxiaTemp or {}
  if type(dir) ~= "string" or dir == "" then return false end
  ataxiaTemp.lastJump = {
    dir = dir,
    verb = verb or "leap",
    at = (getEpoch and getEpoch()) or os.time(),
    room = roomNow(),
  }
  return true
end

-- "You cannot do that while mounted." -- the leap was refused.
--
-- Two jobs, and the second is the one that saves a run: learn that we are mounted, and RE-ISSUE
-- the move we just lost as a mountjump. The refused leap moved nothing, while the escape that
-- queued it is still waiting on an arrival that will never come -- so without the re-issue the
-- ladder stalls until its timeout, which at crash HP is the death this verb exists to avoid.
--
-- IT ONLY RE-ISSUES A JUMP WE SENT, FROM THE ROOM WE SENT IT IN, WITHIN THE ROUND. We do not
-- know the full set of commands that earn this line. With no live record of our own, an unknown
-- sibling refusal costs the latch and nothing else. WITH one, the sibling does fire the re-issue
-- (worded precisely in v4.7.351; v4.7.346 claimed "the latch and nothing else" outright) -- and
-- that is still the right move rather than a stray one: the line says we are MOUNTED, so the leap
-- we recorded is refused too, or already was. A record already spent, stale, or belonging to a
-- room we have since left is dropped -- the latch alone is the fix then.
--
-- AND NEVER INTO A MOVE THAT OWNS THE ROOM (v4.7.351, deep review). Two things already hold
-- movement, and the re-issue defers to both. A TUMBLE in flight (`S.moveLocked`): a jump sent now
-- cancels it -- the rule every other move site in the swarm module already obeys, and the one
-- place that did not was this one. And LAVA: `M.onLava` owns movement there and re-sends its own
-- escape every struggle tick, while our `queue addclear free` would overwrite that queued escape
-- with a direction chosen for some other reason. The latch still happens; only the send waits.
--
-- TUMBLE IS NOT ONE OF THEM (user, v4.7.346: "tumble goes through while on a mount, by the way").
-- v4.7.345 guessed the opposite and flagged Roll Hide's panic tumble as a livelock waiting to
-- happen; it is not, the tumble sites need no conversion, and the guards above were never load-
-- bearing for it. Worth keeping as a reminder that "acrobatic" is our word, not the game's.
-- Why a recovered jump must not go out right now, or nil when it may. See above.
local function recoveryHeld()
  local M = ataxia and ataxia.mnemosyne
  local S = M and M.swarm
  if S and S.moveLocked and S.moveLocked() then return "a tumble is in flight" end
  if M and M.roomLava and M.roomLava() then return "standing in lava" end
  return nil
end

function ataxiaBasher_jumpRefusedMounted()
  ataxiaBasher_mountedSet(true, "the game refused a jump")
  ataxiaTemp = ataxiaTemp or {}
  local rec = ataxiaTemp.lastJump
  ataxiaTemp.lastJump = nil -- one refusal, one recovery
  if type(rec) ~= "table" or type(rec.dir) ~= "string" then return false end
  if rec.verb == "mountjump" then return false end -- already the mounted verb: not our refusal
  local nowT = (getEpoch and getEpoch()) or os.time()
  if (nowT - (tonumber(rec.at) or 0)) > JUMP_REFUSED_WINDOW then return false end
  local here = roomNow()
  if rec.room and here and rec.room ~= here then return false end -- it landed after all
  if recoveryHeld() then return false end -- a tumble or lava owns the move (v4.7.351)
  local sp = (ataxia and ataxia.settings and ataxia.settings.separator) or ";"
  send("queue addclear free stand" .. sp .. "mountjump " .. rec.dir)
  ataxiaBasher_jumpSent(rec.dir, "mountjump")
  if ataxiaEcho then
    ataxiaEcho("Jump refused while mounted -- re-sent as <white>mountjump " .. rec.dir .. "<reset>.")
  end
  return true
end

-- "You have no mount on which to jump." -- the MOUNTJUMP was refused (v4.7.351, deep review).
--
-- The mirror of the recovery above, and it was missing. A belief that we are mounted can go stale
-- -- we die in the saddle (the belief is session scratch, and it survived death until this same
-- release), the mount is killed, a denizen throws us with a line we have never captured -- and
-- then the escape that believed it sends `mountjump`, the game refuses it, 705 corrected the
-- belief, and the move itself was simply lost. At crash HP that is one escape too many.
--
-- Same bounds as the other direction: a MOUNTJUMP we sent, from this room, within the round, not
-- into a tumble or lava, consumed. Re-sent as LEAP, which every class has on foot and which still
-- crosses a wall; the Bard's quicker backflip is not worth a second guess at a moment like this.
-- All three 705 lines route here -- a trample or gallop refusal proves we are on foot just as
-- well -- and with no recorded mountjump the function only latches.
function ataxiaBasher_jumpRefusedOnFoot()
  ataxiaBasher_mountedSet(false, "the game says we have no mount")
  ataxiaTemp = ataxiaTemp or {}
  local rec = ataxiaTemp.lastJump
  if type(rec) ~= "table" or rec.verb ~= "mountjump" then return false end
  ataxiaTemp.lastJump = nil -- one refusal, one recovery
  if type(rec.dir) ~= "string" then return false end
  local nowT = (getEpoch and getEpoch()) or os.time()
  if (nowT - (tonumber(rec.at) or 0)) > JUMP_REFUSED_WINDOW then return false end
  local here = roomNow()
  if rec.room and here and rec.room ~= here then return false end
  if recoveryHeld() then return false end
  local sp = (ataxia and ataxia.settings and ataxia.settings.separator) or ";"
  send("queue addclear free stand" .. sp .. "leap " .. rec.dir)
  ataxiaBasher_jumpSent(rec.dir, "leap")
  if ataxiaEcho then
    ataxiaEcho("Mountjump refused -- no mount under us; re-sent as <white>leap " .. rec.dir .. "<reset>.")
  end
  return true
end

-- Death, and anything else after which we honestly do not know (v4.7.351, deep review). NIL, not
-- false: "unknown" reads as on foot, and BOTH refusals now recover, so the first jump afterwards
-- teaches the truth for the price of one round trip rather than one escape. Deliberately makes no
-- claim about the game -- only that our knowledge did not survive the death.
function ataxiaBasher_mountForget(why)
  ataxiaTemp = ataxiaTemp or {}
  ataxiaTemp.mounted = nil
  ataxiaTemp.lastJump = nil
  return true
end

-- "You pull back the reins on your mount and jump off to the east." -- the mountjump landed, so
-- we are certainly mounted and the record it was recovering is spent.
function ataxiaBasher_mountjumpLanded(dir)
  ataxiaBasher_mountedSet(true, "mountjumped")
  ataxiaTemp = ataxiaTemp or {}
  ataxiaTemp.lastJump = nil
  return dir
end

-- `bash mounts clear` -- forget them (a sold mount, or a bad reading).
function ataxiaBasher_mountsClear()
  local n = 0
  for _ in pairs(ataxiaBasher.mountIds or {}) do n = n + 1 end
  ataxiaBasher.mountIds = {}
  ataxiaEcho("Forgot <cyan>" .. n .. "<reset> mount(s). List them again to re-learn.")
  return n
end
