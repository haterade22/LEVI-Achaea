--[[mudlet
type: trigger
name: Freeze
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes K-S
- Occultist
- Various Salve Lines
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
- pattern: Rays of cold blue light lash out from the Wheel of Chaos, irradiating the location.
  type: 3
- pattern: ^You create a tendril of icy blue light that lashes out at (\w+) and wraps around (\w+) aura.$
  type: 1
]]--

if (line:find("Wheel") and table.contains(ataxia.playersHere, target)) or isTargeted(matches[2]) then
  for _, stage in pairs( {"nocaloric", "shivering", "freezing"}) do
    if not haveAff(stage) then
      tarAffed(stage)
      if applyAffV3 then applyAffV3(stage) end
      break
    end
  end
end