--[[mudlet
type: timer
name: BLOODWORMS
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- leviticus
- APO
attributes:
  isActive: 'no'
  isFolder: 'no'
  isTempTimer: 'no'
  isOffsetTimer: 'no'
time: '00:00:07.500'
command: ''
packageName: ''
]]--



if gmcp.Char.Status.class == "Apostate" and bloodworm() == true then

bloodwormaff = true

if bloodwormaff and not tAffs.deafness and not tAffs.masochism  then 

tarAffed("masochism")

elseif

bloodwormaff and tAffs.masochism and not tAffs.deafness and not tAffs.dizziness then

 tarAffed("dizziness")

end
end


if bloodworm() == true then
disableTimer("BLOODWORMS")
enableTimer("BLOODWORMS")
else
disableTimer("BLOODWORMS")
end



