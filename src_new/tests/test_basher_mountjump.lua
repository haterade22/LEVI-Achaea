--- test_basher_mountjump.lua -- the jump verb follows the saddle (v4.7.345)
--
-- User: "When mounted, we should use mountjump instead of LEAP." -- "mountjump direction or MJ
-- direction."
--
-- The reason it is not cosmetic, in the user's own lines:
--
--   You cannot do that while mounted.                                        (the leap, refused)
--   You pull back the reins on your mount and jump off to the east.          (the mountjump)
--
-- A refused leap moves nothing, and in a Mnemosyne escape nothing is what kills: the banner
-- prints, the ladder waits on an arrival that never comes, and the room keeps hitting. So these
-- tests pin two things -- the verb follows the belief at every jump site, and the refusal both
-- teaches the belief AND recovers the move that was lost to it.

local mock = require("mock_mudlet")

local echoes = {}
function ataxiaEcho(msg) echoes[#echoes + 1] = tostring(msg) end
ataxia = ataxia or {}
ataxia.settings = ataxia.settings or {}
ataxia.settings.separator = ";"
ataxiaBasher = ataxiaBasher or {}
ataxiaTemp = ataxiaTemp or {}
gmcp = gmcp or {}

local NOW = 5000
local realEpoch = getEpoch
getEpoch = function() return NOW end

local ok, err = pcall(dofile, "src_new/scripts/levi_ataxia/levi/ataxia/basher/013_Mounts.lua")
if not ok then error("failed to load the mounts module: " .. tostring(err)) end

local function reset(room)
  NOW = 5000
  echoes = {}
  mock.sent_commands = {}
  gmcp.Room = { Info = { num = room or 200 } }
  ataxiaTemp.mounted, ataxiaTemp.lastJump = nil, nil
end

local function sentAll()
  return table.concat(mock.sent_commands, " | ")
end

-- =====================================================================================
describe("the belief: four lines say mounted, five say on foot", function()
  it("starts UNKNOWN and reads as on foot -- leap is the safe default", function()
    reset()
    expect(ataxiaTemp.mounted).toBeNil()
    expect(ataxiaBasher_isMounted()).toBeFalse()
    expect(ataxiaBasher_mountVerb("leap")).toBe("leap")
  end)

  it("the vault latches it, and the step-down clears it", function()
    reset()
    ataxiaBasher_mountedSet(true, "vaulted on")
    expect(ataxiaBasher_isMounted()).toBeTrue()
    expect(ataxiaBasher_mountVerb("leap")).toBe("mountjump")
    ataxiaBasher_mountedSet(false, "off the mount")
    expect(ataxiaBasher_isMounted()).toBeFalse()
    expect(ataxiaBasher_mountVerb("leap")).toBe("leap")
  end)

  it("says so when it CHANGES, and stays quiet when it repeats", function()
    reset()
    ataxiaBasher_mountedSet(true, "vaulted on")
    expect(#echoes).toBe(1)
    expect(echoes[1]:find("mountjump", 1, true) ~= nil).toBeTrue()
    ataxiaBasher_mountedSet(true, "vaulted on")
    ataxiaBasher_mountedSet(true, "mountjumped")
    expect(#echoes).toBe(1) -- the lines that teach it arrive constantly; only the change is news
  end)

  it("keeps the Bard's backflip when on foot -- the fallback is the caller's", function()
    reset()
    expect(ataxiaBasher_mountVerb("backflip")).toBe("backflip")
    ataxiaBasher_mountedSet(true)
    expect(ataxiaBasher_mountVerb("backflip")).toBe("mountjump")
  end)

  it("the mountjump landing proves mounted and spends the record", function()
    reset()
    ataxiaBasher_jumpSent("e", "mountjump")
    ataxiaBasher_mountjumpLanded("east")
    expect(ataxiaBasher_isMounted()).toBeTrue()
    expect(ataxiaTemp.lastJump).toBeNil()
  end)
end)

-- =====================================================================================
-- The refusal is the load-bearing line: it is how a wrong belief costs one command instead of a
-- run, and it is the only thing that gets the lost move back out.
describe("\"You cannot do that while mounted.\"", function()
  it("latches mounted AND re-sends the refused leap as a mountjump", function()
    reset()
    ataxiaBasher_jumpSent("s", "leap")   -- what the escape sent
    local did = ataxiaBasher_jumpRefusedMounted()
    expect(did).toBeTrue()
    expect(ataxiaBasher_isMounted()).toBeTrue()
    expect(sentAll():find("queue addclear free stand;mountjump s", 1, true) ~= nil).toBeTrue()
  end)

  it("re-sends the SAME direction -- the escape is still waiting on that arrival", function()
    reset()
    ataxiaBasher_jumpSent("nw", "leap")
    ataxiaBasher_jumpRefusedMounted()
    expect(sentAll():find("mountjump nw", 1, true) ~= nil).toBeTrue()
    expect(sentAll():find("mountjump s", 1, true)).toBeNil()
  end)

  it("recovers a Bard's refused BACKFLIP too -- the line is not leap-specific", function()
    reset()
    ataxiaBasher_jumpSent("e", "backflip")
    expect(ataxiaBasher_jumpRefusedMounted()).toBeTrue()
    expect(sentAll():find("mountjump e", 1, true) ~= nil).toBeTrue()
  end)

  it("recovers ONCE -- a second refusal has nothing left to re-send", function()
    reset()
    ataxiaBasher_jumpSent("s", "leap")
    ataxiaBasher_jumpRefusedMounted()
    mock.sent_commands = {}
    expect(ataxiaBasher_jumpRefusedMounted()).toBeFalse()
    expect(#mock.sent_commands).toBe(0)
  end)

  it("still latches mounted when there is no jump of ours to recover", function()
    reset() -- e.g. the user typed the leap by hand, or something else acrobatic was refused
    expect(ataxiaBasher_jumpRefusedMounted()).toBeFalse()
    expect(ataxiaBasher_isMounted()).toBeTrue()
    expect(#mock.sent_commands).toBe(0)
  end)

  it("drops a STALE record rather than firing a move nobody asked for", function()
    reset()
    ataxiaBasher_jumpSent("s", "leap")
    NOW = NOW + 30 -- half a minute later: this refusal belongs to some other command
    expect(ataxiaBasher_jumpRefusedMounted()).toBeFalse()
    expect(#mock.sent_commands).toBe(0)
    expect(ataxiaBasher_isMounted()).toBeTrue() -- ...but the state is still learned
  end)

  it("drops the record once we have LEFT the room -- the jump landed after all", function()
    reset(200)
    ataxiaBasher_jumpSent("s", "leap")
    gmcp.Room.Info.num = 201 -- we are somewhere else now
    expect(ataxiaBasher_jumpRefusedMounted()).toBeFalse()
    expect(#mock.sent_commands).toBe(0)
  end)

  it("spends the record even when it declines to act on it", function()
    reset(200)
    ataxiaBasher_jumpSent("s", "leap")
    gmcp.Room.Info.num = 201                 -- the jump landed; this refusal is not ours
    expect(ataxiaBasher_jumpRefusedMounted()).toBeFalse()
    expect(ataxiaTemp.lastJump).toBeNil()    -- ...and the record goes with it
    gmcp.Room.Info.num = 200                 -- walk back in, and refuse something else here
    expect(ataxiaBasher_jumpRefusedMounted()).toBeFalse()
    expect(#mock.sent_commands).toBe(0)      -- a move nobody asked for, had the record survived
  end)

  it("does not recover a MOUNTJUMP -- that refusal is about something else", function()
    reset()
    ataxiaBasher_jumpSent("s", "mountjump")
    expect(ataxiaBasher_jumpRefusedMounted()).toBeFalse()
    expect(#mock.sent_commands).toBe(0)
  end)

  it("arms the recovery's own record, so a second refusal cannot loop on it", function()
    reset()
    ataxiaBasher_jumpSent("s", "leap")
    ataxiaBasher_jumpRefusedMounted()
    expect(ataxiaTemp.lastJump.verb).toBe("mountjump")
    mock.sent_commands = {}
    expect(ataxiaBasher_jumpRefusedMounted()).toBeFalse() -- and so it stops
    expect(#mock.sent_commands).toBe(0)
  end)
end)

-- =====================================================================================
describe("bash mounts shows which verb is live", function()
  it("names the state, including that it is not known yet", function()
    reset()
    ataxiaBasher.mountIds = {}
    ataxiaBasher_mountsReport()
    expect(table.concat(echoes, " "):find("not known yet", 1, true) ~= nil).toBeTrue()
    reset()
    ataxiaBasher_mountedSet(true)
    ataxiaBasher_mountsReport()
    local all = table.concat(echoes, " ")
    expect(all:find("mountjump", 1, true) ~= nil).toBeTrue()
    expect(all:find("MOUNTED", 1, true) ~= nil).toBeTrue()
  end)
end)

-- =====================================================================================
-- The wiring. These read the shipped files rather than re-implementing them, because the bug
-- this feature exists to prevent is a jump site that quietly kept its literal "leap".
describe("every jump site asks for the verb", function()
  local function slurp(p)
    local f = io.open(p); local t = f:read("*a"); f:close(); return t
  end

  it("the swarm's tactical move and both wall escapes", function()
    local t = slurp("src_new/scripts/levi_ataxia/levi/ataxia/mnemosyne/009_Swarm_Tactics.lua")
    -- moveVerb answers mountjump before it ever looks at walls or class
    local mv = t:match("function S%.moveVerb.-\n end") or t:match("function S%.moveVerb.-\nend")
    expect(mv ~= nil).toBeTrue()
    expect(mv:find("ataxiaBasher_isMounted", 1, true) ~= nil).toBeTrue()
    expect(mv:find("mountjump", 1, true) < mv:find("backflip", 1, true)).toBeTrue()
    -- the wall escapes no longer hardcode the leap
    expect(t:find('sep .. "leap " .. S.backShort', 1, true)).toBeNil()
    expect(t:find('sep .. "leap "', 1, true)).toBeNil()
    -- ...and every one of them records what it sent, so the refusal can recover it
    local n = select(2, t:gsub("ataxiaBasher_jumpSent", ""))
    expect(n >= 3).toBeTrue()
  end)

  it("the explorer's wall leap", function()
    local t = slurp("src_new/scripts/levi_ataxia/levi/ataxia/mnemosyne/008_Explorer.lua")
    expect(t:find('sep .. "leap " .. short', 1, true)).toBeNil()
    expect(t:find("ataxiaBasher_mountVerb", 1, true) ~= nil).toBeTrue()
    expect(t:find("ataxiaBasher_jumpSent", 1, true) ~= nil).toBeTrue()
  end)

  it("the four lines are wired to the four triggers", function()
    local TD = "src_new/triggers/levi_ataxia/for_levi/leviticus/"
    expect(slurp(TD .. "735_Mounted_1.lua"):find("ataxiaBasher_mountedSet(true", 1, true) ~= nil).toBeTrue()
    expect(slurp(TD .. "736_Dismounted.lua"):find("ataxiaBasher_mountedSet(false", 1, true) ~= nil).toBeTrue()
    expect(slurp(TD .. "705_NO_MOUNT.lua"):find("ataxiaBasher_mountedSet(false", 1, true) ~= nil).toBeTrue()
    -- The guarded CALL, not the name: both files explain themselves in comments that mention the
    -- function, so a looser match passed against a trigger whose body had been emptied.
    local land = slurp(TD .. "737_Mountjump_Landed.lua")
    expect(land:find("You pull back the reins on your mount and jump off to the", 1, true) ~= nil).toBeTrue()
    expect(land:find("if ataxiaBasher_mountjumpLanded then", 1, true) ~= nil).toBeTrue()
    local ref = slurp(TD .. "738_Mounted_Refusal.lua")
    expect(ref:find("You cannot do that while mounted", 1, true) ~= nil).toBeTrue()
    expect(ref:find("if ataxiaBasher_jumpRefusedMounted then", 1, true) ~= nil).toBeTrue()
  end)
end)

-- Restore shared state for whoever runs after us (test files share one Lua state).
getEpoch = realEpoch
ataxiaTemp.mounted, ataxiaTemp.lastJump = nil, nil
ataxiaBasher.mountIds = nil
