-- unnamed > For Levi > Levi_062424 > mudlet-mapper_24 > Mudlet Mapper > Utilities > Assorted small utilities

function mmp.comma_value(n) -- credit http://richard.warburton.it
	local left,num,right = string.match(n,'^([^%d]*%d)(%d*)(.-)$')
	return left..(num:reverse():gsub('(%d%d%d)','%1,'):reverse())..right
end