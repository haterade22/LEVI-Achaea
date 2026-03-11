if isTargeted(matches[2]) then
  tarAffed("hypothermia")
  -- Hypothermia implies all prior freeze-chain affs
  tarAffed("frozen")
  tarAffed("shivering")
  tarAffed("nocaloric")
  -- Update magi offense state
  magi = magi or {}
  magi.offense = magi.offense or {}
  magi.offense.state = magi.offense.state or {}
  magi.offense.state.hypothermia = true
end
