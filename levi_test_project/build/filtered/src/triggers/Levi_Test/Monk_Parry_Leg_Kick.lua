-- multimatches[1][2] = "left" or "right" from first pattern
local leg = multimatches[1][2]

if leg == "left" then
  tpll = true
  tprl = false
else
  tprl = true
  tpll = false
end

tpla = false
tph = false
tpto = false
tpra = false

-- Set flashheel parry flag for Willow form combo switching
if ataxia.vitals.form == "Willow" then
  ataxiaTemp.flashheelWasParried = true
end

-- Also set for Gaital form (which uses flashheel too)
if ataxia.vitals.form == "Gaital" then
  ataxiaTemp.flashheelWasParried = true
end
