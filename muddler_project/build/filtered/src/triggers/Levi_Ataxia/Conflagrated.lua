if target == matches[2] then
    tarAffed("conflagration")
    magi.offense.state.conflagrated = true
    if magi.offense.state.burns < 2 then magi.offense.state.burns = 2 end
    tburns = magi.offense.state.burns
    magi.offense.ptRelay(target .. ": Conflagrated! (burns:" .. magi.offense.state.burns .. ")")
  end

tfirelash = false