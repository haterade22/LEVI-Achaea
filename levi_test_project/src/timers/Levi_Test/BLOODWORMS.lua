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



