local name = matches[2]
local class = (ataxiaNDB_getClass(name) or "Unknown")

if isTargeted(matches[2]) and class == "Psion" then
  erAff("confusion")
  -- V2 integration: Expunge cures confusion + impatience/mental aff
  if removeAffV2 then removeAffV2("confusion") end
  if haveAff("impatience") then
    erAff("impatience")
    if removeAffV2 then removeAffV2("impatience") end
  else
  	local eAffs = {"stuttering", "stupidity", "recklessness", "hallucinations", "epilepsy", "confusion", "dizziness", "vertigo", "anorexia",
		"masochism", "agoraphobia", "claustrophobia", "dementia", "generosity", "loneliness", "lovers", "pacified", "paranoia", "shyness", "stuttering",}
    for _, aff in pairs(eAffs) do
      if haveAff(aff) then
        erAff(aff)
        if removeAffV2 then removeAffV2(aff) end
        break
      end
    end
  end
	selectString(line,1)
	fg("NavajoWhite")
	resetFormat()
	targetIshere = true
end
