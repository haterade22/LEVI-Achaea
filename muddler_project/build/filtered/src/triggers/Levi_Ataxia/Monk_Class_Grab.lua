-- Shikudo uses staves; Tekura uses bare fists/kicks
-- Staff attacks contain weapon references in the line text
if line:find("whips") or line:find("staff") or line:find("thrust")
   or line:find("kata") or line:find("sweeps") then
  classDetect.setAttackerClass(matches[2], "Shikudo")
else
  classDetect.setAttackerClass(matches[2], "Monk")
end
