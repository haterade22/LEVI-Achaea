--[[mudlet
type: trigger
name: Hypersomnia
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes A-J
- Apostate
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
- pattern: ^(\w+) suddenly appears tired all of a sudden.$
  type: 1
]]--

if isTargeted(matches[2]) then
  tarAffed("hypersomnia")
end
if gmcp.Char.Status.class == "Apostate" then
  if demon() == "nightmare" then
    killTimer(tostring(nmTimer))
    nmTimer = tempTimer(8.5, [[nighttick()]])
    killTimer(tostring(mareTimer))
    mareTimer = tempTimer(6.5, [[maretickthing()]])
  end
end




function nighttick()
  if demon() == "nightmare" then
    if tAffs.dementia and tAffs.hypersomnia then
      tarAffed("hellsight")
    else
      killTimer(tostring(nmTimer))
	    nmTimer = tempTimer(8.5, [[nighttick()]])
    end
  end
end

function maretickthing()
  if demon() == "nightmare" then
    if not tAffs.dementia and tAffs.hypersomnia and tAffs.asthma and tAffs.impatience then
      maretick = true
    else
    maretick = false
      killTimer(tostring(mareTimer))
	    mareTimer = tempTimer(6.5, [[maretickthing()]])
    end
  end
end