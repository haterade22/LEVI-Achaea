--[[mudlet
type: trigger
name: Expunge (Psion)
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Remove Afflictions
- Groups
- Passive/Active
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'no'
  isPerlSlashGOption: 'no'
  isColorizerTrigger: 'no'
  isFilterTrigger: 'no'
  isSoundTrigger: 'no'
  isColorTrigger: 'no'
  isColorTriggerFg: 'no'
  isColorTriggerBg: 'no'
triggerType: 0
conditonLineDelta: 0
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^A slight tightening of the eyes is the only sign (\w+) makes that \w+ has made a great effort of will\.$
  type: 1
]]--

local name = matches[2]
local class = (ataxiaNDB_getClass(name) or "Unknown")

if isTargeted(matches[2]) and class == "Psion" then
  erAff("confusion")
  -- V2 integration: Expunge cures confusion + impatience/mental aff
  if removeAffV2 then removeAffV2("confusion") end
  if removeAffV3 then removeAffV3("confusion") end
  if haveAff("impatience") then
    erAff("impatience")
    if removeAffV2 then removeAffV2("impatience") end
    if removeAffV3 then removeAffV3("impatience") end
  else
  	local eAffs = {"stuttering", "stupidity", "recklessness", "hallucinations", "epilepsy", "confusion", "dizziness", "vertigo", "anorexia",
		"masochism", "agoraphobia", "claustrophobia", "dementia", "generosity", "loneliness", "lovers", "pacified", "paranoia", "shyness", "stuttering",}
    for _, aff in pairs(eAffs) do
      if haveAff(aff) then
        erAff(aff)
        if removeAffV2 then removeAffV2(aff) end
        if removeAffV3 then removeAffV3(aff) end
        break
      end
    end
  end
	selectString(line,1)
	fg("NavajoWhite")
	resetFormat()
	targetIshere = true
end
