--- test_trigger_wrap.lua -- triggers must match the line as the SERVER delivers it (v4.7.351)
--
-- Deep review, v4.7.344-350: the user's Achaea wraps at 119-124 columns (measured from the break
-- points in their own pastes), and three triggers this package shipped matched text that could
-- never arrive in one piece:
--
--   782 gravehands confirmation  148 chars, fragment began at column 88 -- the break went through
--                                it, so every room's summon read as lost and was cast twice
--   779 belch "room is fouled"   128 chars, anchored at both ends -- the foul-room hold never held
--   780 soulstorm landing        anchored full line -- fine for "Duke Semiro", not for "a bloated
--                                cabin boy", which is the refusal the user reported
--
-- plus the highlights for all three. Every test passed throughout, because they read the trigger
-- FILE for a phrase -- often a phrase the file's own comment contained. These run each trigger's
-- actual PATTERNS against the line wrapped the way the server wraps it, at the user's measured
-- bracket and at a narrower 100 for margin.

local TL = dofile("src_new/tests/trigger_lib.lua")
local TD = "src_new/triggers/levi_ataxia/for_levi/leviticus/"
local WIDTHS = { 100, 119, 124 }

local GRAVE_CAST = "You mutter words of death and decay, and suddenly the ground breaks open all around as hands of rotting flesh and white bone push out of the ground."
local GRAVE_BOON = "Putrescent flesh and rotting dermis grasp in vain at all present, the chill of the grave striking out amidst a rasping chorus of death."
local FOULED = "You take in a deep breath in preparation for your belch, but cough and sputter as you inhale the noxious air that surrounds you."
local BELCH_CAST = "You belch a cloud of stinking gas out of your lungs and into your surroundings."
local BELCH_BOON = "Your rotten breath befouls the air, plaguing all who stand before you with choking filth."
local ALREADY = "Necromantic essence still profanes a bloated cabin boy's soul."
local DECAY = "Your inaction causes the harmonisation of your body and mind to falter: you are now only 60 percent of the way to transcendence."
local BUILD = "Your body and mind continue to harmonise: you are 70 percent of the way to full transcendence."
local MJ_LAND = "You pull back the reins on your mount and jump off to the east."
local MJ_REFUSED = "You cannot do that while mounted."

-- The soulstorm line's length is set by the MOB, which is exactly why one name fitting proves
-- nothing. The last is deliberately long.
local MOBS = { "Duke Semiro", "an acolyte of Life", "a bloated cabin boy",
               "an extraordinarily bloated and festering cabin boy" }
local function storm(mob)
  return "You call forth an unholy tide of necromantic essence and release it, engulfing " .. mob
    .. " in a profane soulstorm."
end
local function withers(mob)
  return (mob:gsub("^%l", string.upper)) .. "'s form withers as the necromantic storm eats away at"
    .. " his lifeforce, draining him."
end

-- Does some physical row of `line` fire the trigger?
local function fires(file, line, w)
  local pats = TL.patterns(TD .. file)
  for _, row in ipairs(TL.wrap(line, w)) do
    if TL.anyMatches(pats, row) then return true end
  end
  return false
end

-- Is EVERY physical row matched (a highlight should colour the whole message)?
local function coloursAll(file, line, w)
  local pats = TL.patterns(TD .. file)
  for _, row in ipairs(TL.wrap(line, w)) do
    if not TL.anyMatches(pats, row) then return false, row end
  end
  return true
end

-- =====================================================================================
describe("the evaluator itself (so a pass means something)", function()
  it("wraps where the user's pastes broke", function()
    local rows = TL.wrap(DECAY, 119)
    expect(#rows).toBe(2)
    expect(rows[2]).toBe("transcendence.")
    rows = TL.wrap(GRAVE_CAST, 119)
    expect(rows[2]).toBe("bone push out of the ground.")
  end)

  it("reproduces the bug: the OLD patterns could not match the wrapped rows", function()
    local old779 = "^You take in a deep breath in preparation for your belch, but cough and sputter as you inhale the noxious air that surrounds you\\.$"
    local old782 = "hands of rotting flesh and white bone push out of the ground"
    for _, w in ipairs({ 119, 124 }) do
      for _, row in ipairs(TL.wrap(FOULED, w)) do expect(TL.matches(old779, 1, row)).toBeFalse() end
      for _, row in ipairs(TL.wrap(GRAVE_CAST, w)) do expect(TL.matches(old782, 0, row)).toBeFalse() end
    end
    -- ...and the old anchored soulstorm pattern fails exactly for the long name
    local old780 = "^You call forth an unholy tide of necromantic essence and release it, engulfing .+ in a profane soulstorm\\.$"
    expect(TL.matches(old780, 1, storm("Duke Semiro"))).toBeTrue()
    local hit = false
    for _, row in ipairs(TL.wrap(storm("a bloated cabin boy"), 119)) do
      hit = hit or TL.matches(old780, 1, row)
    end
    expect(hit).toBeFalse()
  end)

  it("refuses a pattern shape it cannot judge rather than passing it", function()
    local ok = pcall(TL.matches, "^foo[abc]bar", 1, "fooabar")
    expect(ok).toBeFalse()
  end)
end)

-- =====================================================================================
describe("state triggers fire on the line as the server delivers it", function()
  for _, w in ipairs(WIDTHS) do
    it("782 gravehands confirmation @" .. w, function()
      expect(fires("782_Gravehands_Up.lua", GRAVE_CAST, w)).toBeTrue()
    end)
    it("779 belch fouled-room refusal @" .. w, function()
      expect(fires("779_Belch_Fouled.lua", FOULED, w)).toBeTrue()
    end)
    it("778 belch landed, both lines @" .. w, function()
      expect(fires("778_Belch_Landed.lua", BELCH_CAST, w)).toBeTrue()
      expect(fires("778_Belch_Landed.lua", BELCH_BOON, w)).toBeTrue()
    end)
    it("780 soulstorm landing, every mob length @" .. w, function()
      for _, mob in ipairs(MOBS) do
        expect(fires("780_Soulstorm_Landed.lua", storm(mob), w)).toBeTrue()
      end
    end)
    it("781 soulstorm already @" .. w, function()
      expect(fires("781_Soulstorm_Already.lua", ALREADY, w)).toBeTrue()
    end)
    it("783/784 mountjump landing and the mounted refusal @" .. w, function()
      expect(fires("783_Mountjump_Landed.lua", MJ_LAND, w)).toBeTrue()
      expect(fires("784_Mounted_Refusal.lua", MJ_REFUSED, w)).toBeTrue()
    end)
    -- The count is captured from the FIRST row, so that is the row that must match.
    it("psion/001 reads both transcendence lines from their first row @" .. w, function()
      local pats = TL.patterns(TD .. "psion/001_Transcendence_Set.lua")
      expect(TL.anyMatches(pats, TL.wrap(DECAY, w)[1])).toBeTrue()
      expect(TL.anyMatches(pats, TL.wrap(BUILD, w)[1])).toBeTrue()
    end)
  end
end)

-- =====================================================================================
describe("highlights colour every row of their message", function()
  for _, w in ipairs(WIDTHS) do
    it("066 gravehands, both lines @" .. w, function()
      local ok, row = coloursAll("highlighting/066_Gravehands_Highlight.lua", GRAVE_CAST, w)
      expect(ok and "ok" or row).toBe("ok")
      ok, row = coloursAll("highlighting/066_Gravehands_Highlight.lua", GRAVE_BOON, w)
      expect(ok and "ok" or row).toBe("ok")
    end)
    it("065 soulstorm cast, every mob length @" .. w, function()
      for _, mob in ipairs(MOBS) do
        local ok, row = coloursAll("highlighting/065_Soulstorm_Highlight.lua", storm(mob), w)
        expect(ok and "ok" or row).toBe("ok")
      end
    end)
    it("065 soulstorm landing is at least marked @" .. w, function()
      for _, mob in ipairs(MOBS) do
        expect(fires("highlighting/065_Soulstorm_Highlight.lua", withers(mob), w)).toBeTrue()
      end
    end)
    it("064 belch, both lines @" .. w, function()
      expect((coloursAll("highlighting/064_Belch_Highlight.lua", BELCH_CAST, w))).toBeTrue()
      expect((coloursAll("highlighting/064_Belch_Highlight.lua", BELCH_BOON, w))).toBeTrue()
    end)
    -- The decay line's tail is its own row; psion/004 gags it (straight after psion/001 only).
    it("psion/004 catches the decay line's wrapped tail @" .. w, function()
      local rows = TL.wrap(DECAY, w)
      expect(#rows >= 2).toBeTrue()
      local pats = TL.patterns(TD .. "psion/004_Transcendence_Wrap_Tail.lua")
      expect(TL.anyMatches(pats, rows[#rows])).toBeTrue()
    end)
  end
end)

-- =====================================================================================
describe("and nothing that is not ours", function()
  -- The old fragment carried no actor, so another necromancer's cast confirmed ours and spent our
  -- one retry. The opening words are first-person.
  it("782 does not fire on someone else's gravehands", function()
    local theirs = "Soandso mutters words of death and decay, and suddenly the ground breaks open all around"
      .. " as hands of rotting flesh and white bone push out of the ground."
    for _, w in ipairs(WIDTHS) do
      expect(fires("782_Gravehands_Up.lua", theirs, w)).toBeFalse()
    end
  end)

  it("psion/004 leaves ordinary transcendence lines alone", function()
    local pats = TL.patterns(TD .. "psion/004_Transcendence_Wrap_Tail.lua")
    expect(TL.anyMatches(pats, "You have achieved transcendence: your body and mind operate as one.")).toBeFalse()
    expect(TL.anyMatches(pats, BUILD)).toBeFalse()
  end)

  it("the highlight tails are SHORT rows only -- never a whole unwrapped line", function()
    local pats = TL.patterns(TD .. "highlighting/066_Gravehands_Highlight.lua")
    -- the full, unwrapped cast is coloured by its opening pattern, not by a tail that swallowed it
    local tailOnly = {}
    for _, p in ipairs(pats) do
      if p.pat:find("^%^%.") then tailOnly[#tailOnly + 1] = p end
    end
    expect(#tailOnly).toBe(2)
    expect(TL.anyMatches(tailOnly, GRAVE_CAST)).toBeFalse()
    expect(TL.anyMatches(tailOnly, GRAVE_BOON)).toBeFalse()
  end)
end)

-- =====================================================================================
-- The tail gag, BEHAVIOURALLY: psion/001 stamps the moment, psion/004 gags the wrapped tail only
-- straight after it. A bare "transcendence." is too short a phrase to claim on its own.
describe("the transcendence tail gag runs only on OUR tail", function()
  local function run(file, m)
    matches = m
    local ok, err = pcall(dofile, TD .. file)
    matches = nil
    if not ok then error(err, 0) end
  end

  it("gags the tail straight after a decay line, and nothing later", function()
    local savedDF, savedEpoch = deleteFull, getEpoch
    local savedBasher = { enabled = ataxiaBasher and ataxiaBasher.enabled, manual = ataxiaBasher and ataxiaBasher.manual }
    ataxiaBasher = ataxiaBasher or {}
    ataxiaTemp = ataxiaTemp or {}
    local gagged, now = 0, 5000
    deleteFull = function() gagged = gagged + 1 end
    getEpoch = function() return now end
    ataxiaBasher.enabled, ataxiaBasher.manual = true, false
    local ok, err = pcall(function()
      run("psion/001_Transcendence_Set.lua", { "", "60" })   -- the first row: counted and gagged
      expect(ataxiaTemp.transcendence).toBe(60)
      expect(gagged).toBe(1)
      run("psion/004_Transcendence_Wrap_Tail.lua", { "transcendence." })  -- its tail: gagged
      expect(gagged).toBe(2)
      now = now + 30
      run("psion/004_Transcendence_Wrap_Tail.lua", { "transcendence." })  -- a stray one: left alone
      expect(gagged).toBe(2)
    end)
    deleteFull, getEpoch = savedDF, savedEpoch
    ataxiaBasher.enabled, ataxiaBasher.manual = savedBasher.enabled, savedBasher.manual
    ataxiaTemp.transcendence, ataxiaTemp.transcendLineAt = nil, nil
    if not ok then error(err, 0) end
  end)
end)

-- Mudlet's pattern types (tools/convert_to_muddler.py): 2 startOfLine, 3 exactMatch. v4.7.351's
-- evaluator had 3 as "starts with" -- nothing tested depended on it yet, and now nothing can.
describe("the evaluator's pattern types match Mudlet's", function()
  it("2 is start-of-line, 3 is exact", function()
    expect(TL.matches("You have", 2, "You have achieved transcendence.")).toBeTrue()
    expect(TL.matches("You have", 3, "You have achieved transcendence.")).toBeFalse()
    expect(TL.matches("You cannot do that while mounted.", 3, "You cannot do that while mounted.")).toBeTrue()
  end)
end)
