if isTargeted(matches[3]) then
	paAff(matches[4])
  tarAffed(matches[4])
elseif isTargeted(matches[4]) then
  paAff(matches[3])
  tarAffed(matches[3])
  tarAffed(matches[5])
end

if isTargeted(matches[2]) then
tarAffed(matches[3])
tarAffed(matches[4])
end

if isTargeted(matches[2]) then
tarAffed(matches[3])
tarAffed(matches[4])
end

if isTargeted(matches[3]) then
tarAffed(matches[4])
tarAffed(matches[5])
tarAffed(matches[6])
tarAffed(matches[7])
end


if isTargeted(matches[3]) then
tarAffed(matches[4])
tarAffed(matches[5])
tarAffed(matches[6])
tarAffed(matches[7])
end
