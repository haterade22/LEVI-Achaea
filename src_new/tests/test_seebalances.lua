--- test_seebalances.lua -- `aconfig seebalances`
-- CONFIG SEEBALANCES makes the game print each cost (`Balance used: 2.8s.`), so every fight log holds
-- the true costs. The setting is saved, sent at once, and sent at every login, as with
-- `aconfig screenwidth` (test_screenwidth.lua).

require("mock_mudlet")

local ALIAS = "src_new/aliases/levi_ataxia/for_levi/levi_062424/configs/032_Seebalances.lua"
local LOGIN = "src_new/scripts/levi_ataxia/levi/ataxia/login/001_Login_Function.lua"
local CHECK = "src_new/scripts/levi_ataxia/levi/ataxia/002_Check_For_Any_Missing_Variables.lua"
local WIZARD = "src_new/scripts/levi_ataxia/levi/ataxia/misc_scripts/020_Setup_Wizard.lua"

local function read(path)
  local f = assert(io.open(path)); local s = f:read("*a"); f:close(); return s
end

local function has(s, needle) return s:find(needle, 1, true) ~= nil end

describe("aconfig seebalances", function()
  local savedSend, savedSave, savedEcho = send, ataxia_saveSettings, ataxiaEcho
  local savedSettings
  local sent, saves

  -- Every setting change runs through here, and the shared settings table is put back.
  local function run(arg, settings)
    ataxia = ataxia or {}
    savedSettings = ataxia.settings
    ataxia.settings = settings
    sent, saves = {}, 0
    send = function(cmd) sent[#sent + 1] = cmd end
    ataxia_saveSettings = function() saves = saves + 1 end
    ataxiaEcho = function() end
    matches = { "aconfig seebalances" .. (arg and (" " .. arg) or ""), arg }
    local ok, err = pcall(dofile, ALIAS)
    send, ataxia_saveSettings, ataxiaEcho = savedSend, savedSave, savedEcho
    local result = ataxia.settings.seebalances
    ataxia.settings = savedSettings
    if not ok then error(err, 0) end
    return result
  end

  it("on saves it and sends it at once", function()
    expect(run("on", {})).toBeTrue()
    expect(saves).toBe(1)
    expect(sent[1]).toBe("config seebalances yes")
  end)

  it("off stores false, not nil, and sends nothing", function()
    -- A nil is "missing", and the load-time check would put true back.
    expect(run("off", { seebalances = true })).toBe(false)
    expect(saves).toBe(1)
    expect(#sent).toBe(0)
  end)

  it("with no argument it only shows the setting", function()
    expect(run(nil, { seebalances = true })).toBeTrue()
    expect(saves).toBe(0)
    expect(#sent).toBe(0)
  end)

  -- The user has not played enough with it to say that the extra line breaks nothing (2026-11-01).
  it("defaults to off", function()
    expect(has(read(CHECK), "ataxia.settings.seebalances = false")).toBeTrue()
    expect(has(read(CHECK), "ataxia.settings.seebalances = true")).toBeFalse()
  end)

  it("login sends it behind the setting, and quietly", function()
    local src = read(LOGIN)
    local gate = src:find("if ataxia.settings.seebalances then", 1, true)
    local sendAt = src:find('send("config seebalances yes", false)', 1, true)
    expect(gate ~= nil).toBeTrue()
    expect(sendAt ~= nil).toBeTrue()
    expect(gate < sendAt).toBeTrue()
  end)

  it("the setup wizard shows it and names the command", function()
    local src = read(WIZARD)
    expect(has(src, "ataxia.settings.seebalances")).toBeTrue()
    expect(has(src, "aconfig seebalances <on|off>")).toBeTrue()
  end)
end)
