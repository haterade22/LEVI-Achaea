--- test_apostate_deadeyes.lua -- what our DEADEYES and STARE triggers record (v4.7.416)
-- An Apostate's own commands (Mystor's log, 2026-10-11, MIND SAPIENCE) show SICKEN giving manaleech
-- first and then slickness, never paralysis. These tests run the REAL trigger bodies and patterns
-- with their globals stubbed; every stub is restored.

local TL = dofile("src_new/tests/trigger_lib.lua")
local DIR = "src_new/triggers/levi_ataxia/for_levi/leviticus/"
local T = "Agathon"

local function run(file, ln, m2, m3, affs)
  local fh = assert(io.open(DIR .. file, "r"))
  local body = fh:read("*a"):match("%]%]%-%-\r?\n(.*)$")
  fh:close()
  local rec = { affs = {}, cured = {}, sent = {} }
  local stubs = {
    matches = { ln, m2, m3 }, line = ln, target = T,
    isTargeted = function(n) return n == T end,
    tarAffed = function(a) rec.affs[#rec.affs + 1] = a end,
    erAff = function(a) rec.cured[#rec.cured + 1] = a end,
    haveAff = function(a) return (affs or {})[a] == true end,
    tAffs = affs or {}, tarInsomnia = true, partyrelay = false,
    send = function(c) rec.sent[#rec.sent + 1] = c end,
    tempTimer = function() return 1 end, killTimer = function() end,
    ataxiaTemp = { deadeyesOne = (affs or {})._one, deadeyesTwo = (affs or {})._two, contemplate = true },
  }
  local saved = {}
  for k, v in pairs(stubs) do saved[k] = _G[k]; _G[k] = v end
  local ok, err = pcall(assert((loadstring or load)(body)))
  for k in pairs(stubs) do _G[k] = saved[k] end
  if not ok then error(err) end
  return rec
end

local function has(list, x)
  for _, v in ipairs(list) do if v == x then return true end end
  return false
end

describe("DEADEYES (462)", function()
  local function stare(eye, who) return "Summoning up the curse of " .. eye .. ", you stare at " .. who .. ", giving him the evil eye." end

  it("matches the real line", function()
    expect(TL.anyMatches(TL.patterns(DIR .. "462_NEW_DEADEYES.lua"), stare("sicken", T))).toBeTrue()
  end)

  it("SICKEN gives manaleech first, then slickness", function()
    expect(has(run("462_NEW_DEADEYES.lua", stare("sicken", T), "sicken", T).affs, "manaleech")).toBeTrue()
    local r = run("462_NEW_DEADEYES.lua", stare("sicken", T), "sicken", T, { manaleech = true })
    expect(has(r.affs, "slickness")).toBeTrue()
    expect(has(r.affs, "paralysis")).toBeFalse()
  end)

  it("a stare at someone else records nothing on our target", function()
    for _, eye in ipairs({ "clumsy", "stupid", "sicken", "paralysis", "impatience" }) do
      local r = run("462_NEW_DEADEYES.lua", stare(eye, "Claes"), eye, "Claes")
      expect(#r.affs).toBe(0)
      expect(#r.cured).toBe(0)
    end
  end)

  it("sensitivity on a deaf target strips deafness instead", function()
    local r = run("462_NEW_DEADEYES.lua", stare("sensitivity", T), "sensitivity", T, { deafness = true })
    expect(has(r.cured, "deafness")).toBeTrue()
    expect(has(r.affs, "sensitivity")).toBeFalse()
    r = run("462_NEW_DEADEYES.lua", stare("sensitivity", T), "sensitivity", T)
    expect(has(r.affs, "sensitivity")).toBeTrue()
  end)
end)

describe("STARE (002)", function()
  local ln = "You stare at " .. T .. ", giving him the evil eye."

  it("SICKEN gives manaleech first, then slickness, and nothing with both up", function()
    local r = run("apostate/002_Deadeyes.lua", ln, T, nil, { _one = "sicken" })
    expect(has(r.affs, "manaleech")).toBeTrue()
    r = run("apostate/002_Deadeyes.lua", ln, T, nil, { _one = "sicken", manaleech = true })
    expect(has(r.affs, "slickness")).toBeTrue()
    r = run("apostate/002_Deadeyes.lua", ln, T, nil, { _one = "sicken", manaleech = true, slickness = true })
    expect(#r.affs).toBe(0)
  end)

  it("the broken duplicate 001 is switched off", function()
    local fh = assert(io.open(DIR .. "apostate/001_Deadeyes2.lua", "r"))
    local s = fh:read("*a")
    fh:close()
    expect(s:find("isActive: 'no'", 1, true) ~= nil).toBeTrue()
  end)
end)
