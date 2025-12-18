-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Ataxia-DownloadThis > Ataxia > Combat > Offensive Things > Twohander Fractures

function twohanded_increaseFracture(what, count)
  if not ataxiaTemp.fractures then return end
  
  ataxiaTemp.fractures[what] = ataxiaTemp.fractures[what] + count 
  if ataxiaTemp.fractures[what] >= 7 then ataxiaTemp.fractures[what] = 7 end
  
  twohanded_displayFracture(what)
end

function twohanded_decreaseFracture(what)
  if not ataxiaTemp.fractures then return end
  
  ataxiaTemp.fractures[what] = ataxiaTemp.fractures[what] -1 
  if ataxiaTemp.fractures[what] < 0 then ataxiaTemp.fractures[what] = 0 end
  
  twohanded_displayFracture(what)
end

function twohanded_resetFractures()
  ataxiaTemp.fractures = {
    skullfractures = 0,
    wristfractures = 0,
    torntendons = 0,
    crackedribs = 0,
  }
  twohanded_headHit()
  twohanded_torsoHit()
  twohanded_armsHit()
  twohanded_legsHit()
end

function twohanded_displayFracture(what)
  local tc = ataxiaTemp.fractures[what]
  local cstring = ""
  
  if tc < 2 then
    cstring = "<SeaGreen>"
  elseif tc < 4 then
    cstring = "<yellow>"
  elseif tc < 6 then
    cstring = "<orange>"
  else
    cstring = "<red>"
  end
  
  if what == "crackedribs" then
    cstring = cstring.."CR "
  elseif what == "torntendons" then
    cstring = cstring.."TT "
  elseif what == "wristfractures" then
    cstring = cstring.."WF "
  else
    cstring = cstring.."SF "
  end
  cstring = cstring..tc.."<NavajoWhite>| "
  
  cinsertText(cstring)
end