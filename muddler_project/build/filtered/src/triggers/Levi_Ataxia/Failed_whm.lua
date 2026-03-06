local whm = {"dementia", "stupidity", "confusion", "hypersomnia", "paranoia", "hallucinations", "impatience", "addiction", "agoraphobia", "lovers", "loneliness", "recklessness", "masochism"}

selectString(line,1)
fg("black")
bg("orange")
deselect()
resetFormat()

for _, aff in pairs(whm) do
  erAff(aff)
  if removeAffV3 then removeAffV3(aff) end
end