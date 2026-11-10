-- test_srd_alias.lua -- `srd`, the group damage alias (v4.7.485).
-- Two aliases match ^srd$ and Mudlet fires both, so each one must act for its own class only:
-- a Serpent runs scytherus mode (the camus damage route), a Shikudo monk keeps the group damage
-- route, and neither fires for the other. Runs the real alias bodies. Every global this file
-- replaces is restored at the end (one shared Lua state for all test files).

local before = {}
for k, v in pairs(_G) do before[k] = v end

local BASE = "src_new/aliases/levi_ataxia/for_levi/levi_062424/"
local SERPENT = BASE .. "serpent/006_Group_Damage.lua"
local SHIKUDO = BASE .. "shikudo/009_Group_Damage.lua"

local function slurp(path)
  local fh = assert(io.open(path, "r"))
  local s = fh:read("*a")
  fh:close()
  return s
end

-- The body below the YAML header, as Mudlet runs it. Compiled before any global changes.
local function body(path)
  local src = assert(slurp(path):match("%]%]%-%-\r?\n(.*)$"), "no YAML header in " .. path)
  return assert((loadstring or load)(src, "=" .. path))
end

local serpentSrd = body(SERPENT)
local shikudoSrd = body(SHIKUDO)

local calls, order
local function spy(name)
  return function()
    calls[name] = (calls[name] or 0) + 1
    order[#order + 1] = name
  end
end

local function press(class)
  calls, order = {}, {}
  gmcp = { Char = { Status = { class = class } } }
  serp_setmode_scytherus = spy("scytherus")
  serp_ekanelia_offense = spy("attack")
  shikudoDmg = { group = spy("shikudoGroup") }
  serpentSrd()
  shikudoSrd()
end

describe("srd alias headers", function()
  it("both aliases match ^srd$", function()
    expect(slurp(SERPENT):match("\nregex:%s*(%S+)")).toBe("^srd$")
    expect(slurp(SHIKUDO):match("\nregex:%s*'?([^'%s]+)")).toBe("^srd$")
  end)
end)

describe("srd as a Serpent", function()
  it("sets scytherus mode, then sends one attack, in that order", function()
    press("Serpent")
    expect(calls.scytherus).toBe(1)
    expect(calls.attack).toBe(1)
    expect(order[1]).toBe("scytherus")
    expect(order[2]).toBe("attack")
  end)

  it("does not run the Shikudo group damage route", function()
    press("Serpent")
    expect(calls.shikudoGroup).toBeNil()
  end)
end)

describe("srd as a Monk", function()
  it("runs the Shikudo group damage route once", function()
    press("Monk")
    expect(calls.shikudoGroup).toBe(1)
  end)

  it("does not touch the Serpent offense", function()
    press("Monk")
    expect(calls.scytherus).toBeNil()
    expect(calls.attack).toBeNil()
  end)
end)

describe("srd as any other class", function()
  it("runs neither route", function()
    press("Magi")
    expect(calls.scytherus).toBeNil()
    expect(calls.attack).toBeNil()
    expect(calls.shikudoGroup).toBeNil()
  end)
end)

for k in pairs(_G) do
  if before[k] == nil then _G[k] = nil end
end
for k, v in pairs(before) do _G[k] = v end
