--[[mudlet
type: script
name: Depthswalker Setup
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- System-related
- Class Things
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

-- DEPTHSWALKER ONE-TIME BUFFS (`dw setup`, v4.7.144).
--
-- Terminus words are almost all ONE-TIME defences: intone once and they persist. (The
-- exceptions are the ones with a "Works against" field -- Laiad/Hailad target denizens
-- and are repeatable actions, not defences.) So raising them is a setup chore, not
-- something the bashing rotation should re-assert on a timer.
--
-- All intoned words share ONE word balance (`ataxiaTables.depthswalker.wordBal`, set by
-- trigger depthswalker/009 and cleared by 010), so they cannot be sent as a batch. This
-- queues the list and sends the next word each time the word balance RETURNS -- the
-- game's own line drives the chain, so it self-paces at exactly the right rate.

ataxiaTables = ataxiaTables or {}

-- Order matters only in that the denizen-facing buffs come first, so a partial run
-- (interrupted by combat) still lands the ones that matter for bashing.
ataxiaDW_SETUP_WORDS = {
  { word = "trusad",   cmd = "intone trusad",          note = "crit chance vs denizens" },
  { word = "tsuura",   cmd = "intone tsuura",          note = "less damage from denizens" },
  { word = "mainaas",  cmd = "intone mainaas",         note = "skin resists cutting/blunt" },
  { word = "mainaad",  cmd = "intone mainaad scythe",  note = "scythe cutting edge (+damage)" },
  { word = "balateth", cmd = "intone balateth scythe", note = "scythe speed" },
  { word = "tah'maal", cmd = "intone tah'maal",        note = "cloak fire resist + rebirth" },
  { word = "ukhia",    cmd = "intone ukhia",           note = "clot without willpower" },
  { word = "qamad",    cmd = "intone qamad",           note = "deeper meditation regen" },
  { word = "dalem",    cmd = "intone dalem",           note = "+5 phylactery shadows" },
  -- Deliberately NOT here: KAIL raises a prismatic barrier, which stops US attacking
  -- too, so it is an emergency command rather than a standing buff. LAIAD/HAILAD are
  -- denizen-targeted actions ("Works against"), not defences. TOOROS damages the caster.
}

function ataxia_dwSetup(force)
  local dw = ataxiaTables.depthswalker
  if not dw then ataxiaEcho("Depthswalker tables not loaded."); return end
  dw.pendingWords = {}
  local known, skipped = dw.abilities, {}
  for _, entry in ipairs(ataxiaDW_SETUP_WORDS) do
    -- `known` is populated by the AB TERMINUS scrape; when it hasn't run we fail OPEN
    -- and try everything (a word we lack just refuses harmlessly).
    local haveIt = (not known) or known[entry.word] == true
    -- Already-standing defences are skipped unless forced.
    local defUp = entry.def and ataxia.defences and ataxia.defences[entry.def]
    if haveIt and not (defUp and not force) then
      dw.pendingWords[#dw.pendingWords + 1] = entry
    elseif not haveIt then
      skipped[#skipped + 1] = entry.word
    end
  end
  if #dw.pendingWords == 0 then
    ataxiaEcho("Nothing to intone -- no known Terminus buff words.")
    return
  end
  ataxiaEcho("Intoning "..#dw.pendingWords.." Terminus buff(s); one per word balance.")
  if #skipped > 0 then
    ataxiaEcho("<DimGrey>Not researched: "..table.concat(skipped, ", "))
  end
  ataxia_dwIntoneNext()
end

-- Sends the next queued word if the word balance is free. Called by `dw setup` to start
-- the chain and by trigger depthswalker/010 every time the balance comes back.
function ataxia_dwIntoneNext()
  local dw = ataxiaTables.depthswalker
  if not dw or not dw.pendingWords or #dw.pendingWords == 0 then return end
  if dw.wordBal == false then return end
  local entry = table.remove(dw.pendingWords, 1)
  send(entry.cmd, false)
  ataxiaEcho("<DimGrey>"..entry.cmd.."<reset> -- "..entry.note
    .." <DimGrey>("..#dw.pendingWords.." left)")
end

function ataxia_dwSetupStop()
  local dw = ataxiaTables.depthswalker
  if dw then dw.pendingWords = {} end
  ataxiaEcho("Terminus buff queue cleared.")
end
