--[[mudlet
type: script
name: Shikudo Extras
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- Combat
- Offensive Things
- Monk
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

-- A PROBABLE STUMBLE (evidence for kb/CONFLICTS.md #8; nothing reads it to decide). A stumble
-- "resets your kata chain but also puts you completely out of your current form and back into the
-- basic Shikudo form (Tykonos)" (Shikudo.wiki:116), and no stumble line has ever been captured. So
-- a move into Tykonos is recorded and flagged, for the user to keep the line that caused it, when
--   * we sent nothing that asks for Tykonos in the last FORM_SEND_WINDOW seconds
--     (ataxiaTemp.shikFormSendAt, stamped by monk/004's send watcher), and
--   * a chain was alive: its last line (ataxiaTemp.kataAt, trigger 164) is under CHAIN_LIVE
--     seconds old. A chain lapses about 17-20 s after the last strike (vNTjvghY:5967), and a
--     stumble needs one. This also keeps out a form restored from disk -- ataxia.vitals is saved,
--     so the first prompt after a restart compares the live form with an old one -- and a respawn.
--   * nothing has ended that chain since its last line, in an earlier round than this one: not
--     the lapse line (165 stamps ataxiaTemp.kataLapseAt; the form is kept, vNTjvghY:5968), and
--     not a form change (a transition resets the chain, :116; ataxiaTemp.shikFormChangeAt). A
--     lapse line in the SAME round as the drop is not counted: no stumble line has been seen, and
--     a stumble may print it. The one stumble this misses is on the combo after a round that sent
--     its transition BEFORE its combo: that round's chain line (3) prints just before the form
--     change. The wiki makes a stumble at 3 most unlikely (the chance grows with the chain).
-- The kata itself is no guide: the basher zeroes ataxia.vitals.kata whenever it queues a
-- transition at its cap (basher/002:2614-2623), so it reads 0 on exactly the combo a stumble is
-- likeliest on.
local FORM_SEND_WINDOW = 6
local CHAIN_LIVE = 30
local SAME_ROUND = 1

-- true when `endAt` (the lapse line, or the form change before this one) came after the chain's
-- last line, in an earlier round than `now`.
local function chainEndedAt(endAt, chainAt, now)
  return endAt ~= nil and endAt >= chainAt and now - endAt > SAME_ROUND
end

local function shikudo_formChanged(v)
  -- "Transitioning will reset your kata chain" (Shikudo.wiki:116), and Kata "is absent from
  -- charstats until a chain starts" (basher/002), so without this the old form's chain would be
  -- read in the new one until the next strike.
  local held = v.kata
  v.kata = 0
  ataxiaTemp = ataxiaTemp or {}
  local now = getEpoch()
  -- Every change ends the chain; the recorder below reads the one BEFORE this.
  local changedAt = ataxiaTemp.shikFormChangeAt
  ataxiaTemp.shikFormChangeAt = now
  if v.form:lower() ~= "tykonos" then return end
  local sentAt, chainAt = ataxiaTemp.shikFormSendAt, ataxiaTemp.kataAt
  if sentAt and now - sentAt <= FORM_SEND_WINDOW then return end
  if not chainAt or now - chainAt > CHAIN_LIVE then return end
  if chainEndedAt(ataxiaTemp.kataLapseAt, chainAt, now) or chainEndedAt(changedAt, chainAt, now) then
    return
  end
  local kata = ataxiaTemp.kataLast
  ataxiaTemp.shikudoStumbles = ataxiaTemp.shikudoStumbles or {}
  table.insert(ataxiaTemp.shikudoStumbles, { from = v.oldform, kata = kata, at = now, held = held })
  ataxiaEcho("<yellow>[Shikudo] probable STUMBLE from " .. tostring(v.oldform) .. " at kata "
    .. tostring(kata or held or "?") .. " -- keep the line above<reset>")
end

-- shikudo_checkForms(changed): print the forms we can flow to. `changed` is true only from the
-- vitals update's form-change branch (update_stuff/004); then the kata is reset and a move into
-- Tykonos is checked for a stumble. Without it (the first sighting of a form) it only prints.
function shikudo_checkForms(changed)
  -- v4.7.382: the vitals update calls this while it is still reading the Form charstat, before
  -- Kata has been parsed, so on the first prompt kata is nil and `k > 5` threw.
  if not ataxia.vitals.form then return end
  local v = ataxia.vitals
  if changed and v.oldform and v.oldform ~= v.form then shikudo_formChanged(v) end
  local k = ataxia.vitals.kata or 0
  local f = ataxia.vitals.form:lower()
  local nextForm = {
    tykonos = {"Willow"},
    willow = {"Rain"},
    rain = {"Tykonos", "Oak"},
    oak = {"Willow", "Gaital"},
    gaital = {"Rain", "Maelstrom"},
    maelstrom = {"Oak"},
  }
  if k > 5 or k == 0 then
    if not nextForm[f] then return end
    cecho("\n<orange>[<green>"..ataxia.vitals.form.."<orange>]: <NavajoWhite>"..table.concat(nextForm[f], " -- ").."")
  end
end