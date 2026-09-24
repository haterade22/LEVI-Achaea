--[[mudlet
type: script
name: Mnemosyne Reporter API
hierarchy:
- Levi_Ataxia
- Ataxia
- Mnemosyne
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--[[
    ============================================================================
    MNEMOSYNE RUN TRACKER - REPORTER API
    ============================================================================
    One thin function per API endpoint, plus in-memory run state.

    These are the mechanism; they fire whenever a token is set (so manual `mnem`
    commands work even with auto-reporting off). Triggers gate on M._auto()/
    M._inRun() before calling these.

    RUN STATE IS MEANT TO BE IN-MEMORY ONLY -- on load we re-sync via /run_exists rather than
    trusting a stored copy (the server is the source of truth). For a long time this comment was
    simply WRONG, and it is worth understanding why, because the same trap catches anything else
    parked under `ataxia`:

      * `M.run` is a plain table hanging off `ataxia.mnemosyne`, and `ataxia_saveSettings` does
        `table.save(file, sanitizeForSave(ataxia))` -- WHOLESALE. `sanitizeForSave` strips only
        functions, metatabled objects and GUI snapshots, so a table of ordinary scalars goes
        straight to disk.
      * On load, `deepMerge` ends in an unconditional `dst[k] = v` for non-tables, so the stored
        value WINS over the freshly-initialised one.

    So `active`, `ripple`, `publicId`, `lastOffered`, `lives` and `waveProgress` all survived a
    reload. `M._clearStaleRun()` (below, called from `ataxia_loadSettings`) is what now makes the
    first sentence true. Anything transient added here must be cleared there, or moved to
    `ataxiaTemp`, which is never serialized.

    The HTTP client's queue (`M._queue`/`M._busy`, 001) is the same trap and is handled by its own
    `M._resumeQueue`, called from the loader right after this: its answer is REPLAY, not reset --
    a queued request is unsent work, not stale belief. A saved `_busy = true` wedged every report
    for about nine runs before v4.7.336.

    Depends on 001_HTTP_Client.lua (loads first).

    Also calls FORWARD into 007_History.lua (`M.boonInfo`, `M._rerollCount`/`M._rerollReset` in
    004_Parsers) -- both load AFTER this file. That is safe because those calls only fire at a
    boon screen, long after the whole package has loaded, and each is guarded (`M.boonInfo and
    ...`). Do not turn any of them into a load-time call.
    ============================================================================
]]--

ataxia.mnemosyne = ataxia.mnemosyne or {}
local M = ataxia.mnemosyne

M.run = M.run or { active = false, publicId = nil, ripple = 0 }
M.run.pendingMonsters = M.run.pendingMonsters or {} -- buffered mob spawn lines
M.run.lastOffered = M.run.lastOffered or {} -- canonical names from the last boons-offered block

-- Reset all per-run buffers/counters. Called synchronously at run start/end so a
-- fast first GO!/wade-status can never hit a stale ripple guard or flush a
-- previous run's leftover monsters.
function M._resetRun()
  M.run.ripple = 0
  M.run.publicId = nil
  M.run.pendingMonsters = {}
  M.run.lastOffered = {}
  M.run.paused = nil -- a genuine start/end clears any pending pause-resume
  -- WADE STATUS numbers (v4.7.278). Lives are per RUN, so they are cleared HERE and
  -- deliberately NOT in onRipple beside the affixes -- an affix is re-read from every ripple's
  -- status block, a life spent is spent for the rest of the dive.
  M.run.lives = nil
  M.run.waveProgress = nil
  -- Rerolls are counted per BOON SCREEN, and the count is inferred (see M._rerollBump in
  -- 004_Parsers). The state itself lives on `ataxiaTemp`, NOT here -- `M.run` is serialized to
  -- disk with the rest of `ataxia`, so a counter kept here would come back from a reload with
  -- whatever value was last saved. Reset through the owner so there is exactly one way to do it.
  --
  -- BOTH halves, because clearing only the count is worse than clearing neither: a chain left
  -- open means the next run's FIRST offer screen is read as continuing it, and it necessarily
  -- differs from the (now empty) previous names -- so it would post reroll_count 1 for a screen
  -- nobody rerolled.
  if M._rerollReset then M._rerollReset() end
  -- ...and the deferred offer that belonged to the run just ended.
  if M._dropPendingOffer then M._dropPendingOffer() end
  -- ...and the bosses named in it (the corpse-eat skip list, `ataxia_corpseInedible`).
  if ataxiaTemp then ataxiaTemp.mnemBossNames = nil end
end

-- WIPE ANYTHING THAT CAME BACK FROM DISK (v4.7.299).
--
-- The header above explains how run state reaches disk at all. This is the counterpart: on load,
-- forget everything we think we know about a run and let the game and the server re-establish it.
--
-- WHY A LOAD-TIME RESET RATHER THAN A SAVE-TIME EXCLUSION: the save path is a single generic
-- walk over `ataxia`, and special-casing one namespace inside it would put knowledge of this
-- module in a function that should not have any. A defensive reset at load is also the pattern
-- this codebase already uses for exactly this failure (`ataxiaBasher_berserkersEdgeRevert`,
-- v4.7.297), and it is ordered correctly by construction: it runs from inside
-- `ataxia_loadSettings`, after the merge, rather than racing it from a second `sysLoadEvent`
-- handler whose order relative to the loader is not defined.
--
-- IT IS NOT ONLY TELEMETRY THAT SUFFERS. `_resetRun` is reached only through `startRun`/`endRun`,
-- both of which sit BELOW the `_auto()` gate -- so with reporting off (the shipped default)
-- nothing ever cleared this state, while several NON-telemetry consumers read it:
-- `run.boss` steers the Bard's dance choice and makes the legend deck refuse Xylthus (a card
-- cannot bind a boss), and `run.ripple` feeds the swarm's depth-scaled thresholds. A stale boss
-- from a previous session is a wrong dance and a withheld card until the next Objective line.
--
-- `active` is cleared HERE but not in `_resetRun`, because `startRun` deliberately sets it true
-- and then calls `_resetRun` -- clearing it there would undo the caller. `boss` likewise: it is
-- re-learned from every ripple's Objective line, so `_resetRun` leaves it alone, but on load
-- there is no ripple line yet and a stale one would be live until the next.
function M._clearStaleRun()
  M.run = M.run or {}
  M.run.active = false
  M.run.boss = nil
  M._resetRun()
  -- The capture slot's lock is the same shape as the HTTP client's `_busy` (v4.7.336): a boolean
  -- that is only true while something of THIS session holds it. Saved mid-capture it comes back
  -- true with no capture behind it, and `_boonFillTrickle` / the per-screen contemplate refuse
  -- forever. (`_captureLines` itself copes -- it force-finishes a stale capture -- but nothing
  -- else would ever clear the flag.)
  M._capturing = false
end

-- Send any buffered monster spawns as one combined string, then clear.
function M._flushMonsters()
  local pm = M.run.pendingMonsters
  if type(pm) == "table" and #pm > 0 then
    M.reportMonsters(table.concat(pm, "; "))
  end
  M.run.pendingMonsters = {}
end

-- ---------------------------------------------------------------------------
-- Lifecycle
-- ---------------------------------------------------------------------------

function M.startRun()
  if not M._hasToken() then return M.decho("startRun skipped (no token)") end
  -- Optimistic, synchronous local reset (don't wait for the async response).
  M.run.active = true
  M._resetRun()
  if M._historyNewRun then M._historyNewRun() end -- bump the local run counter for history
  M._enqueue("/run_start", {}, function(parsed)
    if parsed and parsed.public_id then
      M.run.publicId = parsed.public_id
      M.echo("<green>Run started<reset> (id: " .. tostring(parsed.public_id) .. ")")
    else
      M.echo("Run started, but response had no public_id.")
    end
  end, function(err)
    -- /run_start failed (e.g. HTTP 500): undo the optimistic active flag so we
    -- don't keep firing ripple/monsters/boss/effects/boons at a run the server
    -- never created. The next run's /run_start (or a reload's runExists) recovers.
    M.run.active = false
    M.echo("<indian_red>Run start failed<reset> (" .. tostring(err) .. "); reporting paused until the next run.")
  end)
end

-- Resume detection: ask the server whether a run is already in progress and
-- sync our ripple to it. Safe to call on load or when enabling mid-run.
function M.runExists()
  if not M._hasToken() then return end
  M._enqueue("/run_exists", {}, function(parsed)
    if parsed and parsed.exists then
      M.run.active = true
      M.run.ripple = tonumber(parsed.ripple) or M.run.ripple or 0
      M.decho("Resumed in-progress run at ripple " .. tostring(M.run.ripple))
    else
      M.run.active = false
    end
  end)
end

-- TELL THE SERVER THE RUN IS PAUSED (v4.7.298).
--
-- `/run_pause` has existed on the API for as long as we have been posting to it and we have
-- never called it. `WHISPER ... beseech that it grow still` suspends a run WITHOUT ending it
-- server-side, and v4.7.88 taught the client half of that -- `M.run.paused`, so the next wade
-- resumes via `/run_exists` rather than minting a fresh `public_id` that would orphan the dive's
-- progress. The server was simply never told, so from the tracker's side a paused run is
-- indistinguishable from a player who stopped mid-dive and came back an hour later.
--
-- Fire-and-forget by design: the local flag is what drives the resume, and it is set by the
-- caller BEFORE this is reached. A failed POST therefore costs the tracker a pause marker and
-- costs us nothing -- so there is deliberately no onError undo here, unlike `startRun`, whose
-- optimistic `active` flag would otherwise keep firing at a run the server never created.
function M.reportRunPause()
  if not M._hasToken() then return M.decho("runPause skipped (no token)") end
  M._enqueue("/run_pause", {}, function()
    M.decho("Run pause reported.")
  end)
end

function M.endRun()
  if not M._hasToken() then return M.decho("endRun skipped (no token)") end
  -- Flush any final-wave monsters before closing the run.
  M._flushMonsters()
  M._enqueue("/run_end", {}, function()
    M.echo("<green>Run ended.")
  end)
  -- Reset locally right away; the run is over regardless of the response.
  M.run.active = false
  M._resetRun()
end

-- ---------------------------------------------------------------------------
-- Per-ripple reporting
-- ---------------------------------------------------------------------------

-- The API errors if ripple < current and no-ops if ==, so guard locally too.
function M.setRipple(n)
  n = tonumber(n)
  -- WHOLE NUMBERS ONLY (review, v4.7.322): the schema's `ripple` is an integer, and `mnem ripple
  -- 2.5` went straight through to a 422. The trigger path (`\d+`) could never send one.
  if not n or n ~= math.floor(n) then return end
  if not M._hasToken() then return end
  if M.run.ripple and n <= M.run.ripple then
    return M.decho("Ripple " .. n .. " <= current " .. tostring(M.run.ripple) .. ", skipping")
  end
  M._enqueue("/ripple_level", { ripple = n }, function()
    M.run.ripple = n
    M.decho("Ripple -> " .. n)
  end)
end

function M.reportMonsters(str)
  if not M._hasToken() then return end
  if type(str) ~= "string" or str == "" then return end
  M._enqueue("/monsters", { monsters = str })
end

function M.reportBoss(name)
  if not M._hasToken() then return end
  if type(name) ~= "string" or name == "" then return end
  M._enqueue("/boss", { boss = name })
end

-- list: array of { name = <string>, description = <string> }
function M.reportEffects(list)
  if not M._hasToken() then return end
  if type(list) ~= "table" or #list == 0 then return end
  M._enqueue("/effects", { effects = list })
end

-- WHO WE WERE WHEN THE BOONS WERE OFFERED (v4.7.220).
--
-- `class` and `race` are optional strings on BoonsOfferedRequest -- verified against the live
-- schema at http://104.128.56.238:8000/openapi.json rather than assumed from the field names.
-- They are what makes the offer data answerable: "does Bard see Songstep more often" is not a
-- question you can ask of a pile of undifferentiated offers.
--
-- CLASS IS NORMALISED, race is not. "Earth Lord" and "Earth Lady" are the same class wearing a
-- gender suffix, and leaving them distinct would split every per-class count in half for no
-- reason -- so the basher's existing normalisation is reused verbatim, which also means the
-- values match what the rest of this system already calls a class. Race is passed through as
-- GMCP reports it: there is no equivalent known distortion, and normalising data I cannot
-- verify against the game's own vocabulary would corrupt it more quietly than leaving it raw.
--
-- Omitted, never guessed. Both fields are optional server-side, so a missing or empty GMCP
-- read sends no key at all rather than "unknown" -- a literal "unknown" would show up in the
-- queries as a cohort, which is worse than a smaller honest sample.
function M._charInfo()
  local st = gmcp and gmcp.Char and gmcp.Char.Status
  if type(st) ~= "table" then return nil, nil end
  local class, race = st.class, st.race
  if type(class) == "string" then
    class = class:gsub("^%s+", ""):gsub("%s+$", "")
    if class ~= "" then
      local ok, norm = pcall(function()
        return class:title():gsub(" Lady", ""):gsub(" Lord", "")
      end)
      -- string.title is a Mudlet extension; if it is ever missing, the raw value still beats
      -- dropping the field.
      if ok and type(norm) == "string" and norm ~= "" then class = norm end
    end
  end
  if type(race) == "string" then race = race:gsub("^%s+", ""):gsub("%s+$", "") end
  if class == "" then class = nil end
  if race == "" then race = nil end
  return (type(class) == "string") and class or nil, (type(race) == "string") and race or nil
end

-- WHAT THE SCHEMA TAKES THAT THE OFFER SCREEN DOES NOT PRINT (v4.7.298).
--
-- `BoonInfo` had eight fields (nine since the tracker added `combo_boon`; see below). The offer screen supplies two -- name and description -- and we
-- were sending only those. The other six were not missing data: we HOLD them, in the local
-- catalogue (`M.history.boonLibrary`), which learns rarity from the BOONS list and
-- description/quote/category/unlocked-by/conflicts from `mnem boonfill` and the per-screen
-- trickle. They were simply never joined up.
--
-- THIS IS NOT A REVIVAL OF THE CONTEMPLATE CHAIN, and the distinction is the whole design.
-- v4.7.279 removed live enrichment because it sent a `BOON CONTEMPLATE` per boon, raced the next
-- ripple's captures for the single `_capturing` slot, and on a lost race stalled and silently
-- dropped the ENTIRE report. Every one of those hazards belongs to the FETCH, not to the fields.
-- A local table read cannot stall, cannot race, and cannot drop the post -- so the enrichment
-- rides the post that was already going out, and the reasons the chain was removed still stand.
--
-- FILL, NEVER OVERWRITE: the offer screen is authoritative for the description (it is the
-- wrap-joined text the player actually read); the catalogue only supplies what the screen did not.
-- Returns a COPY, because the caller's list is also what goes to local history and seeds
-- `run.lastOffered` -- a reporting concern must not mutate either.
local BOON_FIELDS = { "description", "quote", "rarity", "category" }

function M._enrichOffer(list)
  local out = {}
  for i, b in ipairs(list) do
    local rec = {}
    for k, v in pairs(b) do rec[k] = v end
    local known = M.boonInfo and M.boonInfo(rec.name)
    if type(known) == "table" then
      for _, f in ipairs(BOON_FIELDS) do
        if (rec[f] == nil or rec[f] == "") and type(known[f]) == "string" and known[f] ~= "" then
          rec[f] = known[f]
        end
      end
      -- Names differ across the boundary: the catalogue keeps Lua-side camelCase (matching its
      -- existing `maxEchoes`), the API takes snake_case. Mapped here, at the one place the two
      -- vocabularies meet.
      if (rec.unlocked_by == nil or rec.unlocked_by == "")
        and type(known.unlockedBy) == "string" and known.unlockedBy ~= "" then
        rec.unlocked_by = known.unlockedBy
      end
      -- ...and from the LIST when the string never made it (v4.7.328). `unlockedBy` is promoted
      -- through META_VALUE_MAX (60 chars), which a four-name combo recipe runs past -- so the
      -- tracker was sent nothing at all for exactly the longest recipes. `unlocksFrom` has no cap.
      if (rec.unlocked_by == nil or rec.unlocked_by == "")
        and type(known.unlocksFrom) == "table" and #known.unlocksFrom > 0 then
        rec.unlocked_by = table.concat(known.unlocksFrom, ", ")
      end
      if rec.num_echoes_possible == nil and tonumber(known.maxEchoes) then
        rec.num_echoes_possible = math.floor(tonumber(known.maxEchoes))
      end
      -- Only when non-empty. An empty Lua table has no array/object distinction, so yajl may
      -- encode `{}` where the schema wants `[]` -- and "we know of no conflicts" is what
      -- omitting the key already says.
      if rec.conflicts_with == nil and type(known.conflictsWith) == "table"
        and #known.conflictsWith > 0 then
        local cw = {}
        for j, name in ipairs(known.conflictsWith) do cw[j] = name end
        rec.conflicts_with = cw
      end
      -- THE NINTH FIELD (v4.7.322): `combo_boon`, a boolean the tracker added to BoonInfo. Sent
      -- when the catalogue knows EITHER answer; omitted when it knows neither -- the server
      -- defaults to false, and an unknown posted as false would be a guess that looks like data.
      if rec.combo_boon == nil and type(known.comboBoon) == "boolean" then
        rec.combo_boon = known.comboBoon
      end
    end
    out[i] = rec
  end
  return out
end

-- list: array of { name, description?, quote?, rarity?, category?, unlocked_by?,
--                  conflicts_with?, num_echoes_possible?, combo_boon? }
--
-- `rerolls` is the count SNAPSHOTTED when this screen was captured (see `_offerAfterRipple`).
-- It is a parameter rather than a live read because the POST is deferred, and a claim landing
-- inside that window resets the chain -- reading it here would report 0 for the screen that was
-- actually the Nth reroll. Falls back to the live count for a direct call (a manual `mnem`
-- command, or a test).
function M.reportBoonsOffered(list, rerolls)
  if not M._hasToken() then return end
  if type(list) ~= "table" or #list == 0 then return end
  local class, race = M._charInfo()
  -- An INTEGER, always sent, unlike class/race. Those are omitted when GMCP cannot be read
  -- because a guessed value would become its own cohort in the queries; a reroll count of 0 is
  -- not an unknown -- it is the positive observation that no reroll happened on this screen.
  if rerolls == nil and M._rerollCount then rerolls = M._rerollCount() end
  rerolls = math.floor(tonumber(rerolls) or 0)
  M._enqueue("/boons_offered", {
    offered = M._enrichOffer(list),
    class = class,
    race = race,
    reroll_count = rerolls,
  })
end

-- names: string or array of strings
function M.reportBoonsSelected(names)
  if not M._hasToken() then return end
  if type(names) == "string" then names = { names } end
  if type(names) ~= "table" or #names == 0 then return end
  M._enqueue("/boons_selected", { selected = names })
end

-- A BOON WE WERE GIVEN, NOT ONE WE CHOSE (v4.7.330, the tracker's author: "added a boons_received
-- endpoint. If you can, use this instead of boons_offered endpoint to send the combo boons that
-- are granted").
--
-- The endpoint is `/boon_received` (singular, verified against the live OpenAPI schema on
-- 2026-09-21) and it takes ONE `BoonInfo` -- the same shape an offer sends, so it goes through
-- `_enrichOffer` and carries everything the catalogue knows: description, quote, rarity, category,
-- `unlocked_by` (the recipe), `conflicts_with`, `num_echoes_possible` and `combo_boon`.
--
-- This replaces the `/boons_selected` post v4.7.328 made for a granted boon: a combo reward is
-- never offered and never chosen, so reporting it as a SELECTION said something that did not
-- happen. The tracker now has a name for the event.
function M.reportBoonReceived(name)
  if not M._hasToken() then return end
  if type(name) ~= "string" or name == "" then return end
  local enriched = M._enrichOffer({ { name = name } })
  local boon = enriched and enriched[1]
  if type(boon) ~= "table" then return end
  local class, race = M._charInfo()
  M._enqueue("/boon_received", { boon = boon, class = class, race = race })
end

function M.reportDeath(killer)
  if not M._hasToken() then return end
  M._enqueue("/death", { killer = (type(killer) == "string" and killer ~= "") and killer or "unknown" })
end

-- ---------------------------------------------------------------------------
-- Resume on load (~6s after boot, mirroring ataxia.updater's approach)
-- ---------------------------------------------------------------------------

if M._loadHandler then killAnonymousEventHandler(M._loadHandler) end
M._loadHandler = registerAnonymousEventHandler("sysLoadEvent", function()
  tempTimer(6, function()
    if ataxia.mnemosyne._auto() then ataxia.mnemosyne.runExists() end
  end)
end)
