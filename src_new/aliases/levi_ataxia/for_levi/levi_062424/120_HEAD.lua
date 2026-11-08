--[[mudlet
type: alias
name: HEAD
hierarchy:
- Levi_Ataxia
- Classes
- Knight
- RUNIE
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^ihe$
command: ''
packageName: ''
]]--
-- No revision of this repo defines infernalpriosprep() or infernalpriosbasic(); guarded, because this
-- alias only threw (the parry warning below still runs).

targetlimb = "head"
if tAffs.nausea
 then
 

if infernalpriosprep then infernalpriosprep() end

elseif ataxiaTemp.parriedLimb == "torso" and not tAffs.nausea then
if infernalpriosbasic then infernalpriosbasic() end
ataxia_boxEcho("THEY ARE PARRYING THAT LIMB --- YOU IDIOT", "lightblue")

else

if infernalpriosprep then infernalpriosprep() end


end
