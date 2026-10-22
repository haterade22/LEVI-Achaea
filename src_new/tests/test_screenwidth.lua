--- test_screenwidth.lua -- `aconfig screenwidth` (v4.7.441)
-- The game must not split lines (CONFIG SCREENWIDTH 0): long trigger patterns match only a whole
-- line. The setting is saved, sent at once, and sent at every login.

require("mock_mudlet")

local ALIAS = "src_new/aliases/levi_ataxia/for_levi/levi_062424/configs/029_Screenwidth.lua"
local LOGIN = "src_new/scripts/levi_ataxia/levi/ataxia/login/001_Login_Function.lua"
local CHECK = "src_new/scripts/levi_ataxia/levi/ataxia/002_Check_For_Any_Missing_Variables.lua"

local function read(path)
  local f = assert(io.open(path)); local s = f:read("*a"); f:close(); return s
end

describe("aconfig screenwidth", function()
  local savedSend, savedSave, savedEcho, savedSettings = send, ataxia_saveSettings, ataxiaEcho, nil
  local sent, saves

  local function run(arg)
    sent, saves = {}, 0
    send = function(cmd) sent[#sent + 1] = cmd end
    ataxia_saveSettings = function() saves = saves + 1 end
    ataxiaEcho = function() end
    matches = { "aconfig screenwidth" .. (arg and (" " .. arg) or ""), arg }
    local ok, err = pcall(dofile, ALIAS)
    send, ataxia_saveSettings, ataxiaEcho = savedSend, savedSave, savedEcho
    if not ok then error(err, 0) end
  end

  it("saves a width and sends it at once", function()
    ataxia = ataxia or {}; savedSettings = ataxia.settings; ataxia.settings = {}
    run("0")
    expect(ataxia.settings.screenwidth).toBe(0)
    expect(saves).toBe(1)
    expect(sent[1]).toBe("config screenwidth 0")
    ataxia.settings = savedSettings
  end)

  it("off stops sending it", function()
    savedSettings = ataxia.settings; ataxia.settings = { screenwidth = 0 }
    run("off")
    expect(ataxia.settings.screenwidth).toBe(false)
    expect(#sent).toBe(0)
    ataxia.settings = savedSettings
  end)

  it("with no argument it only shows the setting", function()
    savedSettings = ataxia.settings; ataxia.settings = { screenwidth = 0 }
    run(nil)
    expect(saves).toBe(0)
    expect(#sent).toBe(0)
    ataxia.settings = savedSettings
  end)

  it("defaults to 0 and is sent at login", function()
    expect(read(CHECK):find("ataxia.settings.screenwidth = 0", 1, true) ~= nil).toBeTrue()
    expect(read(LOGIN):find('send("config screenwidth " .. ataxia.settings.screenwidth', 1, true) ~= nil).toBeTrue()
  end)
end)
