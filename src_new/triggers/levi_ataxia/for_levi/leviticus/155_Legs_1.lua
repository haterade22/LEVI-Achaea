--[[mudlet
type: trigger
name: Legs
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- INFERNAL
- Fractures
- Decrease Fracture Count
- Devastate
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
- pattern: ^Bracing your feet, you launch a devastating (slash)? at the legs of (\w+), delivering a glancing blow.$
  type: 1
- pattern: ^You whip .+ in a vicious arc, hewing savagely into the legs of (\w+).$
  type: 1
- pattern: ^Adjusting your footing, you unleash a horrific slash at the legs of (\w+), cleaving flesh and shattering bone
    in a savage display of your supremacy.$
  type: 1
- pattern: ^Drawing back a .+, you deliver a single, crippling blow to the legs of (\w+), manglingbone and meat in a bloody
    spray\.$
  type: 1
]]--

if isTargeted(matches[2]) then

  if ataxiaTemp.fractures.torntendons >= 6 then
    tarAffed("mangledleftleg", "mangledrightleg", "prone")
    if applyAffV3 then applyAffV3("mangledleftleg"); applyAffV3("mangledrightleg"); applyAffV3("prone") end
  elseif ataxiaTemp.fractures.torntendons >= 4 then
    tarAffed("damagedleftleg", "damagedrightleg", "prone")
    if applyAffV3 then applyAffV3("damagedleftleg"); applyAffV3("damagedrightleg"); applyAffV3("prone") end
  else
    tarAffed("brokenleftleg", "brokenrightleg", "prone")
    if applyAffV3 then applyAffV3("brokenleftleg"); applyAffV3("brokenrightleg"); applyAffV3("prone") end
  end
  
  ataxiaTemp.fractures.torntendons = 0
  twohanded_legsHit()  
end