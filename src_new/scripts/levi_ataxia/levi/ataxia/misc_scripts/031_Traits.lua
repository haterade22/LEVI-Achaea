--[[mudlet
type: script
name: Traits
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- Misc Scripts
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

-- OUR TRAITS, from TRAIT LIST KNOWN (v4.7.456). The user (2026-10-27): "We shouldn't be using assess
-- or contemplate unless we have the trait Health Inspector or Mind Warden. We can do Trait List
-- Known". Without HEALTH INSPECTOR an ASSESS costs balance, and without MIND WARDEN a CONTEMPLATE
-- costs it too; the group log of that day has an ASSESS where a combo should have been.
--
-- The game's list, as the user pasted it (one row per trait, the racial one first):
--   ----------------------------------------------------------------------
--   Racial:   Child of Ceylon
--   Level 20: Nimble
--   ...
--   Level 100: Clean freak
--   ----------------------------------------------------------------------
-- Trigger 792 reads the `Racial:` row: it starts a fresh list and opens a short window. Trigger 793
-- reads each `Level N:` row, only inside that window, so a "Level 20:" row of any other output is
-- never taken for a trait. The list is SAVED (ataxia.settings.traits), so one reading lasts; login
-- asks for it only while none is saved, and the `traits` alias reads it again.
--
-- An UNKNOWN list answers "no" for every trait: the user's rule is to assess only WITH the trait.

ataxia = ataxia or {}
ataxia.settings = ataxia.settings or {}
ataxiaTemp = ataxiaTemp or {}

local WINDOW = 3 -- seconds after the Racial row in which Level rows are read

local function norm(s)
  return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", ""):lower())
end

-- true / false; false when the list was never read.
function ataxia_hasTrait(name)
  local t = ataxia.settings.traits
  local list = type(t) == "table" and t.list
  if type(list) ~= "table" then return false end
  return list[norm(name)] == true
end

function ataxia_traitsKnown()
  local t = ataxia.settings.traits
  return type(t) == "table" and type(t.list) == "table"
end

-- ASSESS is free only with Health Inspector, CONTEMPLATE only with Mind Warden.
function ataxia_assessFree() return ataxia_hasTrait("health inspector") end
function ataxia_contemplateFree() return ataxia_hasTrait("mind warden") end

-- Trigger 792: "Racial:   Child of Ceylon".
function ataxia_traitRacial(name)
  ataxiaTemp.traitRead = { at = (getEpoch and getEpoch()) or 0, list = {} }
  ataxiaTemp.traitRead.list[norm(name)] = true
  -- Saved now, and again with each Level row: the rows arrive in one burst with no end marker
  -- we can rely on (the closing dashes are the same as the opening ones).
  ataxia_traitCommit()
end

-- Trigger 793: "Level 20: Nimble". Ignored outside the window a Racial row opens.
function ataxia_traitLevel(name)
  local r = ataxiaTemp.traitRead
  local nowT = (getEpoch and getEpoch()) or 0
  if type(r) ~= "table" or nowT - (r.at or 0) > WINDOW then return end
  r.list[norm(name)] = true
  ataxia_traitCommit()
end

function ataxia_traitCommit()
  local r = ataxiaTemp.traitRead
  if type(r) ~= "table" then return end
  local had = ataxia_assessFree() and "y" or "n"
  local list = {}
  for k, v in pairs(r.list) do list[k] = v end
  ataxia.settings.traits = { list = list, at = r.at }
  if ataxia_saveSettings then ataxia_saveSettings(false) end
  -- One line when the answer for ASSESS changes, so the user sees what the offenses will do.
  local now = ataxia_assessFree() and "y" or "n"
  if now ~= had or not r.said then
    r.said = true
    if tempTimer then
      tempTimer(0.5, function() ataxia_traitReport() end)
    end
  end
end

-- What the offenses do with the traits we have.
function ataxia_traitReport()
  if not ataxiaEcho then return end
  if not ataxia_traitsKnown() then
    ataxiaEcho("Traits not read yet: ASSESS and CONTEMPLATE stay off. Read them: traits")
    return
  end
  ataxiaEcho("Traits: ASSESS " .. (ataxia_assessFree() and "<green>free (Health Inspector)"
      or "<red>costs balance -- not sent") .. "<reset>, CONTEMPLATE "
    .. (ataxia_contemplateFree() and "<green>free (Mind Warden)" or "<red>costs balance -- not sent")
    .. "<reset>.")
end

-- The `traits` alias: read the list again (bare), or show what is saved (`traits show`).
function ataxia_traitCommand(arg)
  if arg == "show" then return ataxia_traitReport() end
  send("trait list known", false)
end

-- Login (login/001): ask once, while nothing is saved.
function ataxia_traitLogin()
  if ataxia_traitsKnown() then return end
  if tempTimer then
    tempTimer(18, function() send("trait list known", false) end)
  end
end

-- ---------------------------------------------------------------------------------------------
-- The per-hit limb call to the party (limb/004: "Hit Sadey left arm for 9.2%."), v4.7.456.
-- ataxia.settings.relayLimbHits: true / false, set by `relaylimbs on|off`. Unset, it is OFF for a
-- Monk (a Shikudo combo sent three a round, and nothing in a group reads a monk's limb numbers)
-- and ON for every other class, as it always was. It sits here, beside the other "what the package
-- says and sends for you" switch, rather than in a file of its own.
-- ---------------------------------------------------------------------------------------------
function ataxia_relayLimbHits()
  local s = ataxia.settings.relayLimbHits
  if s ~= nil then return s and true or false end
  return not (ataxia_isClass and ataxia_isClass("monk"))
end

function ataxia_relayLimbsCommand(arg)
  if arg == "on" then
    ataxia.settings.relayLimbHits = true
  elseif arg == "off" then
    ataxia.settings.relayLimbHits = false
  end
  if (arg == "on" or arg == "off") and ataxia_saveSettings then ataxia_saveSettings(false) end
  if ataxiaEcho then
    ataxiaEcho("Party limb-hit calls: " .. (ataxia_relayLimbHits() and "<green>ON" or "<red>OFF")
      .. "<reset>" .. (ataxia.settings.relayLimbHits == nil and " (the default for this class)" or "")
      .. ". Change it: relaylimbs on | relaylimbs off")
  end
end

-- ---------------------------------------------------------------------------------------------
-- THE TRAIT GATE FOR EVERY CLASS (v4.7.456). The user: "We should implement all classes for the
-- assess and contemplate trait gate." About 70 files build ASSESS or CONTEMPLATE into their rounds
-- as literal text ("...;assess " .. target .. ";contemplate " .. target), so the gate sits where
-- every command leaves the package: `send` is wrapped once, and the wrapper removes each command
-- of the form `assess <word>` or `contemplate <word>` whose trait we lack. `sendAll` and the
-- `[[send(...)]]` strings of tempTimer call the global `send`, so they pass through it too.
--
--   "queue addclear free wield x;combo T a b c;assess T"  -> "queue addclear free wield x;combo T a b c"
--   "queue addclear free assess T;combo T a b c"          -> "queue addclear free combo T a b c"
--   "assess T"                                            -> nothing is sent
--
-- Only a WHOLE command of two words is removed, so "boon contemplate <name>" (Mnemosyne, no trait
-- needed) and any longer command are untouched. Commands are split on our separator
-- (ataxia.settings.separator) and on ";", the one many offenses write literally. A command typed
-- in the input line never passes through `send`, and the `assess` alias (004_ASSESS) sends with
-- `ataxia_rawSend`, so asking by hand still works.
-- ---------------------------------------------------------------------------------------------

local function gated(segment)
  local verb = segment:lower():match("^%s*(%a+)%s+%S+%s*$")
  if verb == "assess" then return not ataxia_assessFree() end
  if verb == "contemplate" then return not ataxia_contemplateFree() end
  return false
end

-- Split `s` on any of `seps` (longest first). Returns { { sep = <the separator before>, text } }.
local function split(s, seps)
  local out, pos, sepBefore = {}, 1, ""
  while true do
    local at, len
    for _, sp in ipairs(seps) do
      local i = s:find(sp, pos, true)
      if i and (not at or i < at or (i == at and #sp > len)) then at, len = i, #sp end
    end
    if not at then
      out[#out + 1] = { sep = sepBefore, text = s:sub(pos) }
      return out
    end
    out[#out + 1] = { sep = sepBefore, text = s:sub(pos, at - 1) }
    sepBefore = s:sub(at, at + len - 1)
    pos = at + len
  end
end

-- The command with its gated parts removed; "" when nothing is left.
function ataxia_traitFilter(cmd)
  if type(cmd) ~= "string" then return cmd end
  local low = cmd:lower()
  if not (low:find("assess", 1, true) or low:find("contemplate", 1, true)) then return cmd end
  local prefix, rest = cmd:match("^(%s*[Qq][Uu][Ee][Uu][Ee]%s+%a+%s+%a+%s+)(.*)$")
  if not prefix then prefix, rest = "", cmd end
  local sep = (ataxia.settings and ataxia.settings.separator) or ";"
  local seps = { sep }
  if sep ~= ";" then seps[2] = ";" end
  table.sort(seps, function(a, b) return #a > #b end)
  local kept, dropped = {}, false
  for _, part in ipairs(split(rest, seps)) do
    if gated(part.text) then
      dropped = true
    else
      kept[#kept + 1] = part
    end
  end
  if not dropped then return cmd end
  local out = {}
  for i, part in ipairs(kept) do
    out[#out + 1] = (i > 1 and part.sep or "") .. part.text
  end
  local body = table.concat(out)
  if body:match("^%s*$") then return "" end
  if not ataxiaTemp.traitGateSaid and ataxiaEcho then
    ataxiaTemp.traitGateSaid = true
    ataxiaEcho("ASSESS / CONTEMPLATE left out of our rounds: no Health Inspector / Mind Warden trait "
      .. "(traits show). Once a session.")
  end
  return prefix .. body
end

-- The wrapper. `ataxia_rawSend` keeps Mudlet's own send across reloads (a SYSUPDATE re-runs this
-- file; wrapping the wrapper would only filter twice, but the original must never be lost).
if type(send) == "function" and not ataxia_sendWrapped then
  ataxia_rawSend = send
  send = function(cmd, ...)
    local out = ataxia_traitFilter(cmd)
    if out == "" then return true end
    return ataxia_rawSend(out, ...)
  end
  ataxia_sendWrapped = true
end
