--[[mudlet
type: trigger
name: ASSAULT
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Runie
- DWB
- Dual Blunt
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
- pattern: ^Whirling both of your weapons above your head, you unleash a vicious assault at the (.+) of (\w+).$
  type: 1
]]--

local limb = matches[2]
local tar = matches[3]

if isTargeted(tar) then
  -- Initialize if needed
  if not lb[tar] then lb[tar] = { hits = {} } end
  if not lb[tar].hits then lb[tar].hits = {} end
  lb[tar].hits[limb] = lb[tar].hits[limb] or 0

  -- Assault raises damage level (+100%)
  lb[tar].hits[limb] = lb[tar].hits[limb] + 100

  -- Track damage/mangle affs based on new damage level
  local limbNoSpace = limb:gsub(" ", "")
  if lb[tar].hits[limb] >= 200 then
    if limb == "head" then
      tarAffed("concussion")
    elseif limb == "torso" then
      tarAffed("serioustrauma")
    else
      tarAffed("mangled" .. limbNoSpace)
    end
  elseif lb[tar].hits[limb] >= 100 then
    if limb == "head" then
      tarAffed("damagedhead")
    elseif limb == "torso" then
      tarAffed("mildtrauma")
    else
      tarAffed("damaged" .. limbNoSpace)
    end
  end

  -- Torso assault: adds cracked ribs
  if limb == "torso" then
    if not ataxiaTemp.fractures then
      ataxiaTemp.fractures = { skullfractures = 0, wristfractures = 0, torntendons = 0, crackedribs = 0 }
    end
    ataxiaTemp.fractures.crackedribs = (ataxiaTemp.fractures.crackedribs or 0) + 3
  end
end
