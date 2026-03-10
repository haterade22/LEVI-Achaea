-- Gate: only when playing Magi
if gmcp.Char.Status.class ~= "Magi" then return end
-- Don't react to our own callouts
if matches[2] == gmcp.Char.Name then return end

local tgt = matches[3]

if matches[1]:lower():find("unblind") then
  send("queue addclearfull freestand cast transfix " .. tgt)
else
  -- Staffcast call or Transfixed call
  send("queue addclearfull freestand staffcast horripilation at " .. tgt)
end
