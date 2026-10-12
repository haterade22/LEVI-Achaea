--- test_shikudo_offense.lua -- the live Shikudo offense (006 dispatch, 007 lock), phase 2 (v4.7.417)
-- Loads the REAL scripts. Every global they create or change is restored at the end (one shared
-- Lua state for all test files).

local before = {}
for k, v in pairs(_G) do before[k] = v end

local SH = "src_new/scripts/levi_ataxia/levi/levi_scripts/shikudo/"
ataxia = { vitals = {}, settings = {}, balances = {} }
ataxiaTemp = {}
tAffs = {}
target = "Agathon"
cecho = function() end
for _, f in ipairs({ SH .. "006_CC_Shikudo_Dispatch.lua", SH .. "007_CC_Shikudo_Lock.lua" }) do
  local ok, err = pcall(dofile, f)
  if not ok then error("Failed to load " .. f .. ": " .. tostring(err)) end
end

describe("the lock offense's Telepathy (007)", function()
  local function pick(eq, affs, locked)
    ataxia.vitals = { eq = eq }
    tAffs = affs or {}
    mindlocked = locked or false
    return shikudoLock.selectTelepathy()
  end

  it("sends MIND commands, needs equilibrium (ataxia.vitals.eq), and needs no lock first", function()
    local soft = { asthma = true, anorexia = true, slickness = true }
    expect(pick(true, soft)).toBe("mind impatience Agathon")
    expect(pick(true, { asthma = true, anorexia = true, slickness = true, impatience = true })).toBe("mind batter Agathon")
    expect(pick(true, {})).toBe("mind paralyse Agathon")
    expect(pick(true, { paralysis = true })).toBeNil()
    expect(pick(false, soft)).toBeNil()
  end)

  it("never sends the old bare words", function()
    for _, affs in ipairs({ {}, { asthma = true, anorexia = true, slickness = true } }) do
      local c = pick(true, affs) or ""
      expect(c:find("^mind ") ~= nil).toBeTrue()
      expect(c:find("mindlock", 1, true)).toBeNil()
    end
  end)
end)

describe("Crescent reads the ASSESS health (006)", function()
  it("fires on a prone target at 50% or less, from ataxiaTemp.lastAssess", function()
    ataxia.vitals = { form = "Maelstrom" }
    tAffs = { prone = true }
    ataxiaTemp = { lastAssess = 40 }
    expect(shikudo.selectKick()).toBe("crescent")
    ataxiaTemp = { lastAssess = 60 }
    expect(shikudo.selectKick()).toBe("risingkick head")
  end)
end)

describe("a refused transition keeps the kata (shikudo/002)", function()
  it("does not zero the count", function()
    local fh = assert(io.open("src_new/triggers/levi_ataxia/for_levi/leviticus/shikudo/002_Reset_Failsafe.lua", "r"))
    local body = fh:read("*a"):match("%]%]%-%-\r?\n(.*)$")
    fh:close()
    ataxia.vitals = { kata = 3 }
    assert((loadstring or load)(body))()
    expect(ataxia.vitals.kata).toBe(3)
  end)
end)

-- Restore the shared Lua state.
for k in pairs(_G) do
  if before[k] == nil then _G[k] = nil end
end
for k, v in pairs(before) do _G[k] = v end
