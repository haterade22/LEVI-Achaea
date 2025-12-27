--[[mudlet
type: timer
name: NIGHTMARE AFFLICTION
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- leviticus
- APO
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTimer: 'no'
  isOffsetTimer: 'no'
time: '00:00:08.500'
command: ''
packageName: ''
]]--



if gmcp.Char.Status.class == "Apostate" and demon() == "nightmare" and tAffs.dementia and tAffs.hypersomnia then



tarAffed("hellsight")

disableTimer("NIGHTMARE AFFLICTION")
enableTimer("NIGHTMARE AFFLICTION")

end



