--[[mudlet
type: trigger
name: Masochism
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Third Person
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
- pattern: ^The face of (\w+) contorts in horrified revulsion.$
  type: 1
- pattern: ^(\w+) smiles as \w+ rams her fist into \w+ jaw.$
  type: 1
]]--

if isTargeted(matches[2]) then
	tarAffed("masochism")
end

if gmcp.Char.Status.class == "Apostate" then
  if bloodworm() == true then
    killTimer(tostring(wormTimer))
    wormTimer = tempTimer(7.5, [[wormtick()]])
   
  end
end




function wormtick()
  if bloodworm() == true then
    if tAffs.masochism and not tAffs.deafness then
      tarAffed("dizziness")
    else
      killTimer(tostring(wormTimer))
	    wormTimer = tempTimer(7.5, [[wormtick()]])
    end
  end
end