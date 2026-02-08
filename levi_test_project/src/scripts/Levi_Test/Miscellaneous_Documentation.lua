--[[
  For the sake of reducing questions, this script is going to contain variables and functions that aren't tied to anything specific.
  
  ataxia_getPing()                    - Returns an average latency from your past 30-odd seconds, can use it to setup accurate timers etc.
                                        tempTimer(10+ataxia_getPing(), \[\[stuff\]\]) for example. Minus the \s
]]