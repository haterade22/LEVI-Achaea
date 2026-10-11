--- test_prio_sync.lua -- the curing priority table reaches the server when it changes (v4.7.397)
--
-- A live CURING PRIORITY LIST (2026-10-10) showed the `normal` set holding January's values:
-- the table was only ever sent by `reset prios`, so two months of changes never reached SSC.
-- Now a fingerprint is stored when the table is sent, and login re-sends a changed table --
-- only into the `normal` set, confirmed by asking the game. Globals are restored at the end.

local mock = require("mock_mudlet")

local saved = {}
for _, k in ipairs({ "ataxiaEcho", "ataxia_saveSettings", "ataxia_curingsetRefresh",
  "ataxia_bashProfileActive", "ataxia_bashProfileOff", "tempTimer", "ataxia_sendCuringPriority" }) do
  saved[k] = _G[k]
end
-- The throttle re-arms a timer while over budget; with the instant timers below that would
-- recurse forever, so these tests send directly (the throttle has its own tests).
ataxia_sendCuringPriority = nil
local savedSig = ataxia.settings and ataxia.settings.prioSentSig

local echoes, saves = {}, 0
ataxiaEcho = function(m) echoes[#echoes + 1] = m end
ataxia_saveSettings = function() saves = saves + 1 end
ataxia_bashProfileActive = function() return false end
ataxia.settings = ataxia.settings or {}

-- Timers run immediately, so a whole send completes inside the call.
tempTimer = function(_, fn) if type(fn) == "function" then fn() end; return 1 end

dofile("src_new/scripts/levi_ataxia/levi/ataxia/ataxia/001_Default_Curing_Prios.lua")

local function reset(sig, current)
  mock.reset()
  echoes, saves = {}, 0
  ataxia.settings.prioSentSig = sig
  ataxia_curingsetRefresh = function(cb) cb(current and { current = current } or nil) end
end

-- Priorities written, counting every pair in a multi-set command (`curing priority a 1 b 2`).
local function prioWrites()
  local n = 0
  for _, c in ipairs(mock.sent_commands) do
    local rest = c:match("^curing priority (.+)$")
    if rest then
      for _ in rest:gmatch("%w+ %d+") do n = n + 1 end
    end
  end
  return n
end

local ok, err = pcall(function()
describe("curing priority sync", function()
  it("the fingerprint ignores table order and changes with any value", function()
    local a = ataxia_prioTableSig({ x = 1, y = 2 })
    expect(a).toBe(ataxia_prioTableSig({ y = 2, x = 1 }))
    expect(a == ataxia_prioTableSig({ x = 1, y = 3 })).toBeFalse()
  end)

  it("the decision: send only into normal, never into another or an unknown set", function()
    expect(ataxia_prioSyncDecide(false, "normal")).toBe("unchanged")
    expect(ataxia_prioSyncDecide(true, "normal")).toBe("send")
    expect(ataxia_prioSyncDecide(true, "serpent")).toBe("other-set")
    expect(ataxia_prioSyncDecide(true, "bash")).toBe("other-set")
    expect(ataxia_prioSyncDecide(true, nil)).toBe("unknown-set")
  end)

  it("a send records the fingerprint once the last batch is out", function()
    reset(nil, "normal")
    ataxia_sendDefaultPrios()
    expect(ataxia.settings.prioSentSig).toBe(ataxia_prioTableSig())
    expect(ataxia_prioTableChanged()).toBeFalse()
    expect(saves).toBe(1)
  end)

  it("login with a changed table and the normal set active: the whole table is sent", function()
    reset("stale", "normal")
    ataxia_prioSyncCheck()
    local n = 0
    for _ in pairs(ataxia_defaultCuringPrios()) do n = n + 1 end
    expect(prioWrites()).toBe(n)
    expect(ataxia_prioTableChanged()).toBeFalse()
  end)

  it("login with a changed table in another set: nothing is written, the user is told", function()
    reset("stale", "serpent")
    ataxia_prioSyncCheck()
    expect(prioWrites()).toBe(0)
    expect(table.concat(echoes, " ")).toContain("serpent")
    expect(ataxia_prioTableChanged()).toBeTrue()
  end)

  it("login when the set cannot be read: nothing is written", function()
    reset("stale", nil)
    ataxia_prioSyncCheck()
    expect(prioWrites()).toBe(0)
  end)

  it("login with an unchanged table: does not even ask the game", function()
    reset(ataxia_prioTableSig(), "normal")
    local asked = false
    ataxia_curingsetRefresh = function() asked = true end
    ataxia_prioSyncCheck()
    expect(asked).toBeFalse()
    expect(prioWrites()).toBe(0)
  end)

  it("the table goes out as multi-set commands, at most 20 pairs each (Announce #5450)", function()
    reset(nil, "normal")
    ataxia_sendDefaultPrios()
    local n = 0
    for _ in pairs(ataxia_defaultCuringPrios()) do n = n + 1 end
    expect(#mock.sent_commands).toBe(math.ceil(n / 20))
    for _, c in ipairs(mock.sent_commands) do
      local pairsIn = 0
      for _ in c:match("^curing priority (.+)$"):gmatch("%w+ %d+") do pairsIn = pairsIn + 1 end
      expect(pairsIn <= 20).toBeTrue()
    end
  end)

  it("a rate-limit refusal forgets the recorded send and retries once a minute at most", function()
    reset(ataxia_prioTableSig(), "normal")
    ataxiaTemp.prioSpamRetryAt = nil
    local retries = 0
    local realCheck = ataxia_prioSyncCheck
    ataxia_prioSyncCheck = function() retries = retries + 1 end
    local ok2, e2 = pcall(function()
      ataxia_prioSpamRejected()
      expect(ataxia.settings.prioSentSig).toBeNil()
      expect(retries).toBe(1)
      ataxia_prioSpamRejected()   -- the same burst prints the line several times
      expect(retries).toBe(1)
    end)
    ataxia_prioSyncCheck = realCheck
    ataxiaTemp.prioSpamRetryAt = nil
    if not ok2 then error(e2) end
  end)

  it("login sends it, at 20s", function()
    local fh = assert(io.open("src_new/scripts/levi_ataxia/levi/ataxia/login/001_Login_Function.lua"))
    local src = fh:read("*a"); fh:close()
    expect(src:find("tempTimer(20, [[if ataxia_prioSyncCheck then ataxia_prioSyncCheck() end]])", 1, true) ~= nil).toBeTrue()
  end)
end)
end)

for k, v in pairs(saved) do _G[k] = v end
ataxia.settings.prioSentSig = savedSig
if not ok then error(err) end
