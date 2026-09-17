--[[mudlet
type: script
name: Sense Keepers (Monk/Blademaster)
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- System-related
- Deffing
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--[[
    ============================================================================
    MONK / BLADEMASTER SELF-SENSE KEEPERS -- DEAF and BLIND
    ============================================================================

    AB Deaf (Kaido 875): `DEAF`, works on SELF -- "This simply allows you to enter
    a short TRANCE and deafen yourself." A trance RESOLVES OVER TIME. The command
    costs no balance or equilibrium that we track, so nothing about the act of
    sending it makes the next send wait.

    WHY THIS EXISTS (v4.7.315, live log 12:58:32):

      You stare straight ahead and concentrate on a distant focal point.   x6
      The world about you falls silent as the deafness trance sinks upon you.

    SIX attempts inside 0.15s for one trance. The keeper lived in the prompt
    trigger and its only guard was `incomingdeafness`, a flag set by the trigger
    that matches the game's ATTEMPT ECHO -- so the guard could not close until our
    command had reached the server and its echo had come back. Every prompt inside
    that round trip re-sent. **A guard fed by the game's reply cannot hold off the
    sends that happen before the reply arrives**: the hold has to be stamped at
    SEND time, which is the only moment we know something is in flight. This is the
    `shin augment` lesson (v4.7.270, refused five times in 0.45s) in a second
    place, and the general rule is one this package keeps relearning -- a command
    that does not wait on a balance we track will re-fire on every rebuild unless
    something client-side holds it.

    STAMPED IN BOTH PLACES, DELIBERATELY. `ataxia_senseKeepTick` stamps when WE
    send, which closes the round-trip window. Triggers 762/763 stamp again when the
    attempt echo arrives, which covers a DEAF or BLIND the user typed themselves --
    the game's echo proves an attempt is in flight no matter who started it, and
    without that a manual cast would be answered by a duplicate from the keeper.

    GMCP OWNS WHETHER THE DEFENCE IS UP; WE ONLY OWN WHETHER ONE IS IN FLIGHT.
    `ataxia.defences` is fed by Char.Defences Add/Remove/List (deffing/001), and
    the live log proves both edges for deafness: "Your hearing is suddenly
    restored." cleared it, which is why the keeper fired at all. The previous code
    also wrote `ataxia.defences.deafness = true` from the ATTEMPT line -- optimism
    the v4.7.280 rule forbids, because an INTERRUPTED trance would leave us
    believing in a defence GMCP never confirmed and will therefore never Remove:
    a keeper that can never fire again. The attempt line now stamps the hold and
    nothing else, so a lost trance costs one hold period, never the defence.

    THE HOLD CANNOT LIVELOCK. It is a timestamp compared against a window, not a
    flag waiting on a confirmation (v4.7.167), and a MISSING stamp reads READY
    (the v4.7.192 rule) -- so the failure direction is one early re-send rather
    than a keeper that is silently off forever. That also fixes a real
    latent bug in the old code: `incomingdeafness` was never initialised, and
    `nil == false` is FALSE in Lua, so on a fresh session the deaf keeper did
    nothing at all until the first manual DEAF happened to set the flag.
]]--

ataxia = ataxia or {}
ataxiaTemp = ataxiaTemp or {}

-- Matches the 6s the old `tempTimer(6, ...)` intended. It only ever needs to outlast
-- one round trip plus the trance; it is not a duration for the defence itself.
-- MEASURED, not inherited (v4.7.317). A live BLIND capture 2026-09-17 brackets the trance:
--
--   You close your eyes for a moment.                                      13:59:29.740 prompt
--   ... GO!, wade status ...                                               13:59:32.925 prompt
--   You open your eyes once more, and the world about you is darkness.     13:59:35.679 prompt
--
-- The landed line falls BETWEEN the 32.925 and 35.679 prompts, so attempt -> landing is
-- **3.2s at minimum and 5.9s at most** -- one sample, and one that spans a GO! into a ripple,
-- so treat the top of that range as soft. Either way the old 6 was inherited from
-- `tempTimer(6, ...)` and sat right on the boundary: a trance at the slow end would have drawn a
-- duplicate at almost exactly the moment it landed. 10 clears the whole observed range.
--
-- Raising it costs nothing now, because the LANDED line releases the hold (see
-- ataxia_senseLanded). Before that existed, a long hold was a straight trade against masking an
-- opponent's strip; now the hold only has to cover the in-flight window and the game tells us
-- when that ends -- the v4.7.271 rule, stop predicting and listen.
ataxia_SENSE_HOLD = math.max(1, tonumber(ataxia_SENSE_HOLD) or 10)

-- After the trance lands, GMCP still has to report the defence. Collapse the hold to this
-- instead of clearing it outright: clearing would let the very next prompt re-send if the
-- Char.Defences Add has not arrived yet.
ataxia_SENSE_LANDED_GRACE = 1.5

-- def   = the key in `ataxia.defences` (GMCP's own name, lowercased)
-- cmd   = what we send to raise it
-- stamp = where the in-flight hold lives on ataxiaTemp
ataxia_SENSE_KEEPERS = {
  { def = "deafness",  cmd = "deaf",  stamp = "deafAttemptAt" },
  { def = "blindness", cmd = "blind", stamp = "blindAttemptAt" },
}

local function senseNow()
  return (getEpoch and getEpoch()) or os.time()
end

-- Only these two classes self-apply these senses as defences.
function ataxia_senseKeepClass()
  local c = gmcp and gmcp.Char and gmcp.Char.Status and gmcp.Char.Status.class
  return c == "Monk" or c == "Blademaster"
end

-- Pure decision, so the suite can see it: should `k` be (re)sent right now?
-- A guard inside a trigger is a guard the test suite cannot see (v4.7.260).
-- PER-SENSE OPT-OUT (v4.7.316). Defaults ON for both, so this changes nothing by itself --
-- it exists because BLIND had never executed in the history of this package before v4.7.315
-- and is now enforced on every Monk/Blademaster prompt, in PvP, open-world bashing and the
-- Mnemosyne tower alike. `ataxia.denizensHere` is fed from GMCP `Char.Items` for the ROOM,
-- i.e. from what the character PERCEIVES, and there is a direct precedent for that going
-- empty when perception changes: v4.7.125, "airborne gmcp Char.Items reflects the SKY so
-- denizensHere is empty". If blindness does the same on the ground then `_roomHasDenizens`
-- reads clear, the explorer walks out of occupied rooms and target selection finds nothing --
-- silently. UNVERIFIED either way; this is the switch to reach for if the basher goes blind
-- in the other sense. Config lives on `ataxia` (persisted) because it IS config; the in-flight
-- stamps stay on `ataxiaTemp` (v4.7.192).
function ataxia_senseKeepEnabled(def)
  local s = ataxia.settings and ataxia.settings.senseKeep
  if not s then return true end
  return s[def] ~= false
end

function ataxia_senseKeepNeeded(k)
  if not k or not k.def then return false end
  if not ataxia_senseKeepEnabled(k.def) then return false end
  if ataxia.defences and ataxia.defences[k.def] then return false end -- already up, per GMCP
  local at = tonumber(ataxiaTemp and ataxiaTemp[k.stamp])
  if not at then return true end -- missing stamp reads READY
  local since = senseNow() - at
  -- `since >= 0` guards a future-dated stamp (the v4.7.245 tumble-settle rule): a stamp
  -- ahead of the clock must not disable the keeper permanently.
  if since >= 0 and since < ataxia_SENSE_HOLD then return false end
  return true
end

-- The game's attempt echo (triggers 762/763), or our own send below. Either proves
-- an attempt is in flight; neither proves it landed.
function ataxia_senseAttemptSeen(def)
  ataxiaTemp = ataxiaTemp or {}
  for _, k in ipairs(ataxia_SENSE_KEEPERS) do
    if k.def == def then ataxiaTemp[k.stamp] = senseNow() return end
  end
end

-- The trance RESOLVED (triggers 772/773). This is the game's own word that the in-flight window
-- is over, so the long hold above no longer has to be served out: an opponent stripping the
-- defence a second later is answered immediately rather than up to `ataxia_SENSE_HOLD` later.
--
-- It collapses the hold to a short grace rather than clearing it, because GMCP's Char.Defences
-- Add may not have arrived yet and a cleared stamp would let the next prompt re-send into a
-- defence that is already up. It never writes `ataxia.defences` -- the landing is the game's
-- word that the ACTION finished, GMCP remains the only authority on the STATE (v4.7.280).
function ataxia_senseLanded(def)
  ataxiaTemp = ataxiaTemp or {}
  for _, k in ipairs(ataxia_SENSE_KEEPERS) do
    if k.def == def then
      local back = ataxia_SENSE_HOLD - ataxia_SENSE_LANDED_GRACE
      if back < 0 then back = 0 end
      ataxiaTemp[k.stamp] = senseNow() - back
      return
    end
  end
end

-- REFUSED: "You are already deaf." (triggers 774/775). A refusal is a FREE STATE PROBE -- the
-- reasoning that got the Fury refusal ("You're already raged with fury!") and the shin-augment
-- already-channelling line wired. It tells us two things: no trance started, and the defence IS up.
--
-- It takes the FULL hold, not the landed line's grace. The landing collapses the hold because we
-- want a strip answered fast and GMCP is about to confirm; a refusal means our picture is already
-- wrong somewhere, and backing off properly is the right response to that.
--
-- IT STILL DOES NOT WRITE `ataxia.defences`, even though the game just stated the state -- and this
-- is the one place that rule is genuinely tempting. If GMCP disagrees with the game here, then GMCP
-- is not tracking this defence; and if it is not tracking it, it will never Remove it either. So a
-- write would be a belief nothing can ever clear -- the exact v4.7.280 livelock, arrived at from
-- the opposite direction. Instead we WARN, once, and let the hold re-probe every
-- `ataxia_SENSE_HOLD`: noisy at worst, never permanently wrong.
function ataxia_senseRefused(def)
  ataxiaTemp = ataxiaTemp or {}
  for _, k in ipairs(ataxia_SENSE_KEEPERS) do
    if k.def == def then
      ataxiaTemp[k.stamp] = senseNow()
      -- The game says the defence is up and GMCP does not. Say so once -- a warning after every
      -- refusal is one the user learns to ignore (the boon-claim rule, v4.7.278).
      if not (ataxia.defences and ataxia.defences[def]) then
        local seen = "senseDisagree_" .. def
        if not ataxiaTemp[seen] then
          ataxiaTemp[seen] = true
          if ataxiaEcho then
            ataxiaEcho("<indian_red>" .. def .. "<reset>: the game says we already have it but GMCP does not list it -- "
              .. "the keeper will re-probe every " .. ataxia_SENSE_HOLD .. "s. Not correcting the state from a refusal.")
          end
        end
      end
      return
    end
  end
end

-- Called once per prompt. Sends at most one command per sense per hold window.
function ataxia_senseKeepTick()
  if not ataxia_senseKeepClass() then return end
  ataxiaTemp = ataxiaTemp or {}
  for _, k in ipairs(ataxia_SENSE_KEEPERS) do
    if ataxia_senseKeepNeeded(k) then
      ataxiaTemp[k.stamp] = senseNow() -- stamp BEFORE the send; see the header
      send(k.cmd, false) -- quiet: a keeper firing every few seconds should not echo (CLAUDE.md)
    end
  end
end
