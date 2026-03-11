local tgt = matches[2]
if not tgt or tgt ~= target then return end

magi.offense = magi.offense or {}
magi.offense.state = magi.offense.state or {}
magi.offense.state.scintillaSpark = true

-- Scintilla spark lasts ~4s before igniting or fading
if magi.offense.state.scintillaTimer then
  killTimer(magi.offense.state.scintillaTimer)
end
magi.offense.state.scintillaTimer = tempTimer(4, [[
  magi.offense = magi.offense or {}
  magi.offense.state = magi.offense.state or {}
  magi.offense.state.scintillaSpark = false
  magi.offense.state.scintillaTimer = nil
]])

if magi.offense.ptRelay then
  magi.offense.ptRelay(target .. ": Scintilla spark (4s)")
end
if magi.offense.debugEcho then
  magi.offense.debugEcho("Scintilla spark → 4s timer")
end
