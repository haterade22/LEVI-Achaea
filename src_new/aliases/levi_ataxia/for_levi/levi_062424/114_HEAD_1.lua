--[[mudlet
type: alias
name: HEAD
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- LeviticusREG
- Leviticus
- Knight
- RUNIE
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^ihe$
command: ''
packageName: ''
]]--

targetlimb = "head"
if tAffs.nausea
 then
 

infernalpriosprep()

elseif ataxiaTemp.parriedLimb == "torso" and not tAffs.nausea then
infernalpriosbasic()
ataxia_boxEcho("THEY ARE PARRYING THAT LIMB --- YOU IDIOT", "lightblue")

else

infernalpriosprep()


end
