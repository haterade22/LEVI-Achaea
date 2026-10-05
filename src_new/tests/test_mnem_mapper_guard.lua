--- test_mnem_mapper_guard.lua -- keep the mapper's gmcpmapupdates OFF in the tower (v4.7.377)
--
-- User: "if in mnemosyne, keep that off". With gmcpmapupdates on, the IRE mapper writes every
-- gmcp.Room.Info onto the mapped room of that number, and Mnemosyne dementia fakes those rooms.

local mock = require("mock_mudlet")

ataxia = ataxia or {}
ataxiaTemp = ataxiaTemp or {}
ataxiaBasher = ataxiaBasher or {}
local realEcho, realMmp, realBasher = ataxiaEcho, mmp, ataxiaBasher
local echoes = {}
ataxiaEcho = function(m) echoes[#echoes + 1] = m end

dofile("src_new/scripts/levi_ataxia/levi/ataxia/mnemosyne/016_Mapper_GMCP_Guard.lua")

-- The guard's own handlers, by the ids the file stored (other files register on these events
-- too, some by function NAME, so raising the event here would run strangers).
local function handler(event, key)
  local list = mock.named_handlers and mock.named_handlers[event]
  return list and list[ataxiaTemp[key]]
end
local onEnter = handler("mnemosyne entered", "mapperGuardEnterH")
local onLeft = handler("mnemosyne left", "mapperGuardLeftH")
local onPrompt = handler("gmcp.Char.Vitals", "mapperGuardTickH")

-- A stand-in for the mapper's settings proxy: a value per option, and setOption.
local sets
local function mapper(value, refuse)
  sets = 0
  local s = { gmcpmapupdates = value }
  function s:setOption(name, v, silent)
    sets = sets + 1
    if refuse or self[name] == nil then return end -- upstream prints "No such option!" and returns
    self[name] = v
  end
  mmp = { settings = s }
end
local function value() return mmp and mmp.settings and mmp.settings.gmcpmapupdates end

local function reset(inTower, owed)
  echoes = {}
  ataxiaBasher.inMnemosyne = inTower
  ataxiaBasher.mapperGmcpOwed = owed
end

describe("mapper gmcpmapupdates guard (v4.7.377)", function()
  it("registers its three handlers as functions", function()
    expect(type(onEnter)).toBe("function")
    expect(type(onLeft)).toBe("function")
    expect(type(onPrompt)).toBe("function")
  end)

  it("entering the tower turns it off and owes a restore", function()
    mapper(true); reset(true, nil)
    onEnter("mnemosyne entered")
    expect(value()).toBe(false)
    expect(ataxiaBasher.mapperGmcpOwed).toBe(true)
    expect(#echoes).toBe(1)
  end)

  it("leaving puts it back on and clears the debt", function()
    mapper(true); reset(true, nil)
    onEnter("mnemosyne entered")
    ataxiaBasher.inMnemosyne = false
    onLeft("mnemosyne left")
    expect(value()).toBe(true)
    expect(ataxiaBasher.mapperGmcpOwed).toBe(nil)
  end)

  it("never touches a user who had it off", function()
    mapper(false); reset(true, nil)
    onEnter("mnemosyne entered")
    onPrompt("gmcp.Char.Vitals")
    ataxiaBasher.inMnemosyne = false
    onLeft("mnemosyne left")
    expect(value()).toBe(false)
    expect(sets).toBe(0)
    expect(ataxiaBasher.mapperGmcpOwed).toBe(nil)
    expect(#echoes).toBe(0)
  end)

  it("an older mapper without the option: no setOption call at all", function()
    mapper(nil); reset(true, nil)
    onEnter("mnemosyne entered")
    onPrompt("gmcp.Char.Vitals")
    expect(sets).toBe(0)
    expect(ataxiaBasher.mapperGmcpOwed).toBe(nil)
  end)

  it("no mapper loaded: no error, nothing owed", function()
    mmp = nil; reset(true, nil)
    expect(ataxia_mnemMapperHold()).toBe(false)
    expect(ataxia_mnemMapperTick()).toBe(false)
    expect(ataxiaBasher.mapperGmcpOwed).toBe(nil)
  end)

  it("a refused set owes nothing", function()
    mapper(true, true); reset(true, nil)
    onEnter("mnemosyne entered")
    expect(value()).toBe(true)
    expect(ataxiaBasher.mapperGmcpOwed).toBe(nil)
    expect(#echoes).toBe(0)
  end)

  it("reload mid-climb (no enter event): the next prompt turns it off", function()
    mapper(true); reset(true, nil) -- inMnemosyne restored from disk, mapper loaded the user's value
    onPrompt("gmcp.Char.Vitals")
    expect(value()).toBe(false)
    expect(ataxiaBasher.mapperGmcpOwed).toBe(true)
  end)

  it("turned back on mid-climb: the next prompt turns it off again", function()
    mapper(true); reset(true, nil)
    onEnter("mnemosyne entered")
    mmp.settings.gmcpmapupdates = true -- mconfig gmcpmapupdates on
    onPrompt("gmcp.Char.Vitals")
    expect(value()).toBe(false)
    expect(ataxiaBasher.mapperGmcpOwed).toBe(true)
  end)

  it("one echo per switch, not per prompt", function()
    mapper(true); reset(true, nil)
    onEnter("mnemosyne entered")
    for _ = 1, 5 do onPrompt("gmcp.Char.Vitals") end
    expect(#echoes).toBe(1)
    expect(sets).toBe(1)
  end)

  it("a restore owed from an earlier session lands on the first prompt outside", function()
    mapper(false); reset(false, true) -- clean exit inside the tower: mapper saved off, we saved owed
    onPrompt("gmcp.Char.Vitals")
    expect(value()).toBe(true)
    expect(ataxiaBasher.mapperGmcpOwed).toBe(nil)
  end)

  it("owed while still in the tower: stays off", function()
    mapper(false); reset(true, true)
    onPrompt("gmcp.Char.Vitals")
    onLeft("mnemosyne left") -- a stray leave event while the flag still says inside
    expect(value()).toBe(false)
    expect(ataxiaBasher.mapperGmcpOwed).toBe(true)
  end)

  it("owed but the mapper is not loaded yet: keeps owing, restores once it is", function()
    mmp = nil; reset(false, true)
    expect(ataxia_mnemMapperTick()).toBe(false)
    expect(ataxiaBasher.mapperGmcpOwed).toBe(true)
    mapper(false)
    onPrompt("gmcp.Char.Vitals")
    expect(value()).toBe(true)
    expect(ataxiaBasher.mapperGmcpOwed).toBe(nil)
  end)

  it("outside the tower with nothing owed: the user's choice is left alone", function()
    mapper(true); reset(false, nil)
    onPrompt("gmcp.Char.Vitals")
    expect(value()).toBe(true)
    expect(sets).toBe(0)
  end)
end)

ataxiaEcho, mmp = realEcho, realMmp
ataxiaBasher = realBasher
if ataxiaBasher then ataxiaBasher.inMnemosyne, ataxiaBasher.mapperGmcpOwed = false, nil end
