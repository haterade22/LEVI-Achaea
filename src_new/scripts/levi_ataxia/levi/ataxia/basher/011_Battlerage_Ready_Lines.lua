--[[mudlet
type: script
name: Battlerage Ready Lines
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Basher
- Bashing
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

-------------------------------------------------------------------------------
--            AUTHORITATIVE BATTLERAGE COOLDOWN FEED (v4.7.167)              --
--                                                                           --
--  The game tells us, by name, the exact moment each battlerage ability     --
--  comes off cooldown:                                                      --
--                                                                           --
--    "You can use Collide again."                                           --
--    "Your Collide ability could be used again but you lack the necessary   --
--     Rage."                                                                --
--                                                                           --
--  The second form is the same event seen through an empty rage bar -- the  --
--  cooldown expired, we just cannot pay for it yet. Both mean READY NOW.    --
--                                                                           --
--  Until now every owned rotation GUESSED at this: a send-side epoch stamp  --
--  plus a hardcoded `cd` constant per ability (GDRAGON_BR/PSION_BR/DW_BR/   --
--  RW_BR in basher/002). That guess is wrong in both directions --          --
--    * too SLOW when the real cooldown is shortened (boons, gear, stat      --
--      reductions), so the ability idles after it was actually available;   --
--    * too FAST when a stamped pick never executed (the queue was cleared,  --
--      the round was refused for broken arms, the target died), so the      --
--      rotation believes an ability is spent that never fired.              --
--                                                                           --
--  These lines settle it from the server. They are class-agnostic: the      --
--  verb is captured from the line, lower-cased, and cleared in whichever    --
--  rotation table owns it. An unknown verb is simply ignored.               --
--                                                                           --
--  Live evidence (2026-07-30 Runewarden log): Collide, Bulwark, Etch and    --
--  Cullingblade all announced themselves this way, repeatedly, while the    --
--  rotation was rage-starved -- ~10 free cooldown facts in three minutes,   --
--  every one of them discarded.                                            --
--                                                                           --
--  NOTE the pre-existing gag (006_GAG) hides the CHAOSGATE forms of these   --
--  lines specifically; the generic forms are unclaimed, so this costs no    --
--  existing behaviour.                                                     --
-------------------------------------------------------------------------------

ataxiaTemp = ataxiaTemp or {}

-- verb (lower-case, as the game prints it) -> the epoch table + key that the owning
-- rotation reads. Clearing the stamp is what "ready" means to those loops: they test
-- `(now - stamp) >= cd`, so a nil stamp is unconditionally ready.
--
-- Culling reap is deliberately ABSENT: it is gated on `ataxiaTemp.bladeCooldown`,
-- a flag owned by the culling trigger, not by these tables.
local BR_READY_MAP = {
  -- Runewarden (RW_BR)
  bulwark   = { "rwBrAt", "bulwark" },
  etch      = { "rwBrAt", "etch" },
  onslaught = { "rwBrAt", "onslaught" },
  collide   = { "rwBrAt", "collide" },
  -- Golden Dragon (GDRAGON_BR)
  deaden    = { "gdragonBrAt", "deaden" },
  psidaze   = { "gdragonBrAt", "psidaze" },
  psiblast  = { "gdragonBrAt", "psiblast" },
  overwhelm = { "gdragonBrAt", "overwhelm" },
  -- Psion (PSION_BR)
  regrowth   = { "psionBrAt", "regrowth" },
  devastate  = { "psionBrAt", "devastate" },
  whirlwind  = { "psionBrAt", "whirlwind" },
  barbedblade = { "psionBrAt", "barbedblade" },
  -- Depthswalker (DW_BR)
  erasure   = { "dwBrAt", "erasure" },
  curse     = { "dwBrAt", "curse" },
  boinad    = { "dwBrAt", "boinad" },
  lash      = { "dwBrAt", "lash" },
}

-- The shared trigger-driven timers used by the classes that do NOT own a rotation
-- (330/331/332 set these). A ready-line for one of those slots clears it too.
local BR_SHARED = {
  cullingblade = "culling", -- handled specially below
}

--- Mark a battlerage ability as off cooldown, from the game's own ready line.
-- `verb` is whatever the line named ("Collide", "Cullingblade", ...).
function ataxiaBasher_brReady(verb)
  if type(verb) ~= "string" then return end
  local key = verb:lower():gsub("[^%a]", "")
  if key == "" then return end

  -- Culling blade has its own flag rather than a rotation stamp.
  if BR_SHARED[key] == "culling" then
    ataxiaTemp.bladeCooldown = nil
    return "culling"
  end

  local entry = BR_READY_MAP[key]
  if not entry then return nil end
  local tbl, field = entry[1], entry[2]
  if ataxiaTemp[tbl] then ataxiaTemp[tbl][field] = nil end

  -- A ready ability is by definition not the one still in flight: if the pending
  -- replay is holding this very verb, release it so the next round re-decides
  -- instead of replaying a pick whose cooldown the game just reset.
  for _, p in ipairs({"rwBrPending", "dwBrPending", "psionBrPending", "gdragonBrPending"}) do
    local pend = ataxiaTemp[p]
    if pend and pend.verb == field then ataxiaTemp[p] = nil end
  end

  return field
end
