-- Shikudo uses staves; Tekura uses bare fists/kicks.
-- Staff attacks contain weapon references in the line text.
-- Once identified as Shikudo, never downgrade to Monk (kicks are shared).
local attacker = matches[2]
if line:find("whips") or line:find("staff") or line:find("thrust")
   or line:find("kata") or line:find("sweeps") then
  classDetect.setAttackerClass(attacker, "Shikudo")
elseif classDetect.state.attackerName
   and classDetect.state.attackerName:lower() == attacker:lower()
   and classDetect.state.attackerClass == "Shikudo" then
  -- Already identified as Shikudo — kick is just part of their toolkit
  classDetect.resetCombatTimeout()
else
  classDetect.setAttackerClass(attacker, "Monk")
end
