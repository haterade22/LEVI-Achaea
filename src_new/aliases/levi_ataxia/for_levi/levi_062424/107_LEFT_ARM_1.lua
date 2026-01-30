--[[mudlet
type: alias
name: LEFT ARM
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
regex: ^ila$
command: ''
packageName: ''
]]--

targetlimb = "left arm"
if tAffs.nausea
 then
 

infernalpriosprep()

elseif ataxiaTemp.parriedLimb == "left arm" and not tAffs.nausea then
infernalpriosbasic()
ataxia_boxEcho("THEY ARE PARRYING THAT LIMB --- YOU IDIOT", "lightblue")

else

infernalpriosprep()


end
