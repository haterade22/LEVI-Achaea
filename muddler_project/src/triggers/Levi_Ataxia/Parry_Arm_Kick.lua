-- multimatches[1][2] = "left" or "right" from first pattern
local arm = multimatches[1][2]

if arm == "left" then
  tpla = true
  tpra = false
else
  tpra = true
  tpla = false
end

tpll = false
tph = false
tpto = false
tprl = false

-- Set frontkick parry flag for Rain form combo switching
if ataxia.vitals.form == "Rain" then
  ataxiaTemp.frontkickWasParried = true
end
