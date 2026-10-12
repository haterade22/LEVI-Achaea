--- test_monk_aliases.lua -- the Monk branch of the vv alias (153_Fourth_Attack_(All_Classes)), v4.7.419
-- Runs the alias's REAL body. On a Shikudo monk vv called shikudo.setMode("godmode"), which only the
-- switched-off 008_CC_Shikudo_Offense_ALL defines, so every press threw. It also holds GodMode (009),
-- vv's old route, to its retirement: switched off, with a RETIRED note whose line numbers stay true.
-- Every global this file replaces is restored at the end (one shared Lua state for all test files).

local before = {}
for k, v in pairs(_G) do before[k] = v end

local VV = "src_new/aliases/levi_ataxia/for_levi/levi_062424/153_Fourth_Attack_(All_Classes).lua"
local GODMODE = "src_new/scripts/levi_ataxia/levi/levi_scripts/shikudo/009_CC_Shikudo_GodMode.lua"

local function slurp(path)
  local fh = assert(io.open(path, "r"))
  local s = fh:read("*a")
  fh:close()
  return s
end

-- The body below the YAML header, as Mudlet runs it (test_shikudo_offense.lua's idiom). Compiled
-- before any global is replaced, so a load failure cannot leave the shared state half-changed.
local vvBody = assert(slurp(VV):match("%]%]%-%-\r?\n(.*)$"), "no YAML header in " .. VV)
local vv = assert((loadstring or load)(vvBody, "=vv"))

local calls
local function spy(name)
  return function() calls[name] = (calls[name] or 0) + 1 end
end

-- A Monk. 004_ataxia_Vitals_Update resets ataxia.vitals.stance to false on every update, and only
-- its Stance branch sets it: a Shikudo's charstats carry a Form and no Stance, so it stays false; a
-- Tekura's Stance charstat sets it to the stance's name.
local function monk(stance)
  calls = {}
  gmcp = { Char = { Status = { class = "Monk" } } }
  ataxia = { vitals = { stance = stance } }
end

-- One press. A throw is reported as the error itself, which is what the user saw in Mudlet.
local function press()
  local ok, err = pcall(vv)
  if not ok then error("vv threw: " .. tostring(err), 2) end
end

describe("vv on a Shikudo monk (no stance)", function()
  it("runs the dispatch offense while there is no Telepathy variant, and does not throw", function()
    monk(false)
    -- No setMode (only the switched-off 008 defines it), and no dispatchMind: vv must work before
    -- its Telepathy variant exists.
    shikudo = { dispatch = spy("dispatch") }
    press()
    expect(calls.dispatch).toBe(1)
  end)

  it("runs dispatchMind instead once it exists, and not the plain dispatch", function()
    monk(false)
    shikudo = { dispatch = spy("dispatch"), dispatchMind = spy("dispatchMind") }
    press()
    expect(calls.dispatchMind).toBe(1)
    expect(calls.dispatch).toBeNil()
  end)
end)

describe("vv on a Tekura monk (a stance)", function()
  it("is unchanged: TK6 with kai cripple, and no Shikudo offense", function()
    monk("Horse")
    tekura6 = { config = { kaiMode = "surge" }, dispatch = { run = spy("tk6") } }
    shikudo = { dispatch = spy("dispatch"), dispatchMind = spy("dispatchMind") }
    press()
    expect(calls.tk6).toBe(1)
    expect(tekura6.config.kaiMode).toBe("cripple")
    expect(calls.dispatch).toBeNil()
    expect(calls.dispatchMind).toBeNil()
  end)
end)

describe("GodMode (009), vv's old route, stays switched off", function()
  -- Its run() throws on the first tick: it calls shikudo_breakPoint, which only the switched-off
  -- 008 defines (009's RETIRED note lists the rest). Read from the YAML header only, the field the
  -- converter reads (attributes.isActive), never from a comment.
  it("ships with isActive 'no'", function()
    local header = assert(slurp(GODMODE):match("^%-%-%[%[mudlet\r?\n(.-)%]%]%-%-"), "no YAML header in " .. GODMODE)
    expect(header:match("\n%s*isActive:%s*'(%a+)'")).toBe("no")
  end)
end)

-- 009's RETIRED note records why GodMode was switched off and what a later route should salvage,
-- and it says both by LINE NUMBER, so two rules keep it true for as long as the file exists.
-- (1) A line number may point only into a file that does not move: 009 itself (retired), the
-- switched-off 008 (deleted with it) and kb/raw (kept verbatim). Live code is cited by name. The
-- first cut cited 004_ataxia_Vitals_Update:84-85 for the Kai charstat, and the kai reader shipped in
-- the same release (v4.7.419) moved that branch three lines down before the note had shipped.
-- (2) Every line number points at the code the note names. A line added to the note moves every
-- 009 anchor below it.
local FROZEN = {
  ["008"] = "src_new/scripts/levi_ataxia/levi/levi_scripts/shikudo/008_CC_Shikudo_Offense_ALL.lua",
  ["Shikudo.wiki"] = "kb/raw/wiki/Shikudo.wiki",
}
local function frozen(file)
  return FROZEN[file] or (file:match("^kb/raw/") and file) or nil
end

-- The note, with a path it wraps after a slash ("kb/raw/logs/", then the file name) joined up.
local function retiredNote()
  local src = slurp(GODMODE)
  local from = assert(src:find("RETIRED (v4.7.419)", 1, true), "no RETIRED note in " .. GODMODE)
  local to = assert(src:find("]]--", from, true), "the RETIRED note is not closed")
  return (src:sub(from, to):gsub("/\r?\n%s*", "/"))
end

-- Lines a..b of a file, as one string.
local function linesOf(path, a, b)
  local fh = assert(io.open(path, "r"), "no such file: " .. path)
  local out, n = {}, 0
  for line in fh:lines() do
    n = n + 1
    if n > b then break end
    if n >= a then out[#out + 1] = line end
  end
  fh:close()
  return table.concat(out, "\n")
end

-- What each line number in the note points at. `cite` is the note's own text, in 009 unless it
-- names a file; the note's bare ":261" continues "Shikudo.wiki:89".
local ANCHORS = {
  { cite = "(line 787)", has = { "shikudo_breakPoint(5000)" } },
  { cite = "(line 150 is the first)", has = { "ld.shikRuku" } },
  { cite = "158-159", has = { "gm.llFLASH =", "gm.rlFLASH =" } },
  { cite = "178-180", has = { "gm.executeReady =", "gm.hPREP" } },
  { cite = "238-241", has = { 'gm.kick = "spinkick"' } },
  { cite = "(line 821)", has = { "ataxia.vitals.kai >= 11", "kaiboost" } },
  { cite = "(355-375:", has = { "k >= 12", "k >= 10" } },
  { cite = "(310-321)", has = { '"frontkick left"', "gm.LA <= gm.RA" } },
  { cite = "(198-212)", has = { "local function shouldLight" } },
  { cite = "(310-351)", has = { "local sim = {}", "sim.RA" } },
  { cite = "(542-550)", has = { '"ruku left"', '"ruku right"', '"flashheel right"' } },
  { cite = "(008:67)", has = { "function shikudo.setMode(" } },
  { cite = "(008:124)", has = { "function shikudo_breakPoint(" } },
  { cite = "(Shikudo.wiki:127)", has = { "single blow" } },
  { cite = "Shikudo.wiki:89,", has = { "|attacks=", "FLASHHEEL" } },
  { cite = ":261)", file = "kb/raw/wiki/Shikudo.wiki", has = { "|attacks=", "SPINKICK" } },
  { cite = "kb/raw/players/shikudo-2026-10-11.txt:22", has = { "shooting for 10 kata in rain with 2x arm prep" } },
  { cite = "kb/raw/logs/2026-10-11_mystor_shikudo-vs-infernal-dwc_win_vNTjvghY.txt:7455",
    has = { "combo Agathon flashheel left ruku right ruku left" } },
}

describe("009's RETIRED note", function()
  it("cites a line number only in 009, the switched-off 008 or kb/raw, never in live code", function()
    local live, last = {}, ""
    for file, n in retiredNote():gmatch("([%w_%./%-]*):(%d+)") do
      if file == "" then file = last end
      last = file
      if not frozen(file) then live[#live + 1] = file .. ":" .. n end
    end
    expect(table.concat(live, ", ")).toBe("")
  end)

  it("points every line number at the code or text it names", function()
    local note = retiredNote()
    for _, a in ipairs(ANCHORS) do
      expect(note).toContain(a.cite)
      local file, from, to = a.cite:match("([%w_%./%-]*):(%d+)%-?(%d*)")
      if from then
        file = assert(a.file or frozen(file), a.cite .. " cites a file whose lines move")
      else
        file, from, to = GODMODE, a.cite:match("(%d+)%-?(%d*)")
      end
      local text = linesOf(file, tonumber(from), tonumber(to) or tonumber(from))
      for _, want in ipairs(a.has) do
        if not text:find(want, 1, true) then
          error(a.cite .. " should point at '" .. want .. "', but it reads:\n" .. text, 0)
        end
      end
    end
  end)
end)

-- Restore the shared Lua state.
for k in pairs(_G) do
  if before[k] == nil then _G[k] = nil end
end
for k, v in pairs(before) do _G[k] = v end
