--- test_chat_colours.lua -- the chat window shows the GAME'S colours, on the right channel (v4.7.375)
--
-- Two faults, both in update_windows/001_showChat.lua:
--   1. v4.7.100 moved the handler to the Comm.Channel.Text event but kept reading the deprecated
--      Comm.Channel.Start FIRST. Start arrives after Text, so it named the PREVIOUS message's
--      channel: every line was coloured and routed as the one before it (a "You say" in clan
--      orange, the next clan line in says cyan).
--   2. The game's ANSI (the player's CONFIG COLOUR) was stripped and replaced by a fixed palette.
--
-- These tests load the REAL script and drive the real handler.

require("mock_mudlet")

local SRC = "src_new/scripts/levi_ataxia/levi/levi_scripts/update_windows/001_showChat.lua"

-- Test files share one Lua state: everything replaced here is restored at the end.
local saved = {
  decho = decho, cecho = cecho, enableTrigger = enableTrigger, zgui = zgui, gmcp = gmcp,
  ataxiaNDB = ataxiaNDB, ataxiaNDB_Exists = ataxiaNDB_Exists, muteList = muteList,
  ataxiaBasher_alert = ataxiaBasher_alert, only_to_misc = only_to_misc,
  starts = string.starts, contains = table.contains,
}

local shown, alerts = {}, 0
decho = function(win, text) shown[#shown + 1] = { win = win, text = text } end
cecho = function(win, text) shown[#shown + 1] = { win = win, text = text } end
enableTrigger = function() end
zgui = {}
ataxiaNDB = { divine = {} }
ataxiaNDB_Exists = function(name) return name == "Agathon" or name == "Tabethys" end
muteList = {}
ataxiaBasher_alert = function() alerts = alerts + 1 end
string.starts = string.starts or function(s, p) return s:sub(1, #p) == p end
table.contains = table.contains or function(t, v)
  for _, x in pairs(t) do if x == v then return true end end
  return false
end
gmcp = { Char = { Status = { name = "Levi" } }, Comm = { Channel = {} } }

local ok, err = pcall(dofile, SRC)
if not ok then error("failed to load " .. SRC .. ": " .. tostring(err)) end

local A = ataxiagui_chatAnsiToDecho
local ESC = "\27"

local function msg(channel, talker, text, staleStart)
  shown, alerts = {}, 0
  gmcp.Comm.Channel.Start = staleStart
  gmcp.Comm.Channel.Text = { channel = channel, talker = talker, text = text }
  zgui.showChat()
end

local function windows()
  local w = {}
  for _, s in ipairs(shown) do w[#w + 1] = s.win end
  return table.concat(w, ",")
end

describe("chat colours: ANSI -> decho (the game's CONFIG COLOUR)", function()
  it("bold cyan (Says = 14) becomes 0,255,255 and the trailing reset returns to colour 7", function()
    local out = A(ESC .. "[0;1;36mYou say, \"Blah.\"" .. ESC .. "[0;37m")
    expect(out).toBe("<0,255,255>You say, \"Blah.\"<192,192,192>")
  end)

  it("plain text with no escapes is the game default, colour 7", function()
    expect(A("Hello")).toBe("<192,192,192>Hello")
  end)

  it("normal and bright red are different colours (CONFIG COLOUR 1 vs 9)", function()
    expect(A(ESC .. "[31mx")).toBe("<128,0,0>x")
    expect(A(ESC .. "[1;31mx")).toBe("<255,0,0>x")
    expect(A(ESC .. "[91mx")).toBe("<255,0,0>x")
  end)

  it("bold black is the grey of CONFIG COLOUR 8", function()
    expect(A(ESC .. "[1;30mx")).toBe("<128,128,128>x")
  end)

  it("22 turns bold off and 39 resets the foreground", function()
    expect(A(ESC .. "[1;33ma" .. ESC .. "[22mb" .. ESC .. "[39mc"))
      .toBe("<255,255,0>a<128,128,0>b<192,192,192>c")
  end)

  it("256-colour and truecolour foregrounds", function()
    expect(A(ESC .. "[38;5;208mx")).toBe("<255,135,0>x")
    expect(A(ESC .. "[38;5;244mx")).toBe("<128,128,128>x")
    expect(A(ESC .. "[38;5;12mx")).toBe("<0,0,255>x")
    expect(A(ESC .. "[38;2;10;20;30mx")).toBe("<10,20,30>x")
  end)

  it("background codes are dropped and do not disturb the foreground", function()
    expect(A(ESC .. "[1;36;44ma" .. ESC .. "[48;5;17mb")).toBe("<0,255,255>ab")
  end)

  it("non-colour escapes are removed, never printed", function()
    local out = A(ESC .. "[2Ka" .. ESC .. "[?25lb" .. ESC .. "c")
    expect(out).toBe("<192,192,192>abc")
    expect(out:find(ESC, 1, true)).toBeNil()
  end)

  it("a non-string is an empty line, not an error", function()
    expect(A(nil)).toBe("")
  end)
end)

describe("chat colours: the channel comes from the message, not the stale Start", function()
  it("Text.channel wins over a Start left over from the previous message", function()
    gmcp.Comm.Channel.Start = "says"
    gmcp.Comm.Channel.Text = { channel = "clt1", talker = "Agathon", text = "x" }
    expect(ataxiagui_chatChannel()).toBe("clt1")
  end)

  it("Start is only a fallback for a Text with no channel", function()
    gmcp.Comm.Channel.Start = "ct"
    gmcp.Comm.Channel.Text = { talker = "Agathon", text = "x" }
    expect(ataxiagui_chatChannel()).toBe("ct")
    gmcp.Comm.Channel.Text = { channel = "", talker = "Agathon", text = "x" }
    expect(ataxiagui_chatChannel()).toBe("ct")
  end)

  it("no Comm.Channel at all is an empty channel", function()
    local c = gmcp.Comm
    gmcp.Comm = nil
    expect(ataxiagui_chatChannel()).toBe("")
    gmcp.Comm = c
  end)
end)

describe("chat colours: the handler (the screenshot's sequence)", function()
  local clanText = ESC .. "[0;33m(Holocaust Inc): Agathon says, \"Want me to shank his ribs?\"" .. ESC .. "[0;37m"
  local sayText = ESC .. "[0;1;36mYou say in Mhaldorian in a strong, calm voice, \"Duanatharan.\"" .. ESC .. "[0;37m"

  it("a clan line after a say goes to Clans + All in the CLAN's colour", function()
    msg("clt1", "agathon", clanText, "says")
    expect(windows()).toBe("Clans,All")
    expect(shown[1].text).toContain("<128,128,0>(Holocaust Inc)")
    expect(shown[1].text:find("<0,255,255>", 1, true)).toBeNil()
  end)

  it("our own say after a clan line goes to All only, in the SAYS colour", function()
    msg("says", "You", sayText, "clt1")
    expect(windows()).toBe("All")
    expect(shown[1].text).toContain("<0,255,255>You say in Mhaldorian")
  end)

  it("a tell from a known player goes to Tells + All and raises the alert", function()
    msg("tell Agathon", "Agathon", ESC .. "[0;1;33mAgathon tells you, \"hi.\"" .. ESC .. "[0;37m", "clt1")
    expect(windows()).toBe("Tells,All")
    expect(shown[1].text).toContain("<255,255,0>Agathon tells you")
    expect(alerts).toBe(1)
  end)

  it("a muted talker is not shown", function()
    muteList = { Tabethys = true }
    msg("clt1", "Tabethys", clanText, "clt1")
    muteList = {}
    expect(#shown).toBe(0)
  end)
end)

decho, cecho, enableTrigger, zgui, gmcp = saved.decho, saved.cecho, saved.enableTrigger, saved.zgui, saved.gmcp
ataxiaNDB, ataxiaNDB_Exists, muteList = saved.ataxiaNDB, saved.ataxiaNDB_Exists, saved.muteList
ataxiaBasher_alert, only_to_misc = saved.ataxiaBasher_alert, saved.only_to_misc
string.starts, table.contains = saved.starts, saved.contains
