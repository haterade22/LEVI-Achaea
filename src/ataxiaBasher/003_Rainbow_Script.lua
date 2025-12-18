-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Ataxia-DownloadThis > Basher > zData > zData > Rainbow Script

-- Take in a string to rainbow-ify, optionally rainbow type and frequency for type 1
-- str   : string to rainbow-ify
-- type  : type of rainbow-ification
--         0 - single cycle of colours, default option
--         1 - multiple cycles determined by frequency, possible less than a full cycle
--         2 - Old, ugly, technically rainbowed thing
-- freq  : color frequency of rainbow in degrees, 0 to 360, default 15
--         higher freqs produce much shorter cycles of color, lower freqs longer cycles
--         freq of 1 is solid color
-- Return: returns a string suitable for plugging into hecho, colored in the rainbow
--         style chosen
function rainbow(str, type, freq)
	-- default settings, set to default if out-of-bounds
	type = type or 0
	if type > 2 or type < 0 then type = 0 end

	freq = freq or 15

	if freq < 0 or freq > 360 then freq = 15 end

	local product = ""
	local phase = 2 * math.pi / 3

	local rand = betterRand()


	if type == 0 then -- Non-repeating rainbow
		freq = 2*math.pi / #str
		for i = 1, #str do
			if string.sub(str, i, i) == " " then
				product = product..string.sub(str, i, i)
			else
				r = math.sin(freq*i + phase + rand*10) * 127 + 128
				g = math.sin(freq*i + 0 + rand*10) * 127 + 128
				b = math.sin(freq*i + 2*phase + rand*10) * 127 + 128
				r = string.format("%x", r)
				g = string.format("%x", g)
				b = string.format("%x", b)

				if #r < 2 then r = "0"..r end
				if #g < 2 then g = "0"..g end
				if #b < 2 then b = "0"..b end
				product = product.."|c"..r..g..b..string.sub(str, i, i)
			end
		end
	elseif type == 1 then -- Repeating rainbow

		freq = freq * math.pi / 180
		for i = 1, #str do
			--if string.sub(str, i, i) == " " then
			--	product = product..string.sub(str, i, i)
			--else
				r = math.sin(freq*i + phase + rand*10) * 127 + 128
				g = math.sin(freq*i + 0 + rand*10) * 127 + 128
				b = math.sin(freq*i + 2*phase + rand*10) * 127 + 128
				r = string.format("%x", r)
				g = string.format("%x", g)
				b = string.format("%x", b)

				if #r < 2 then r = "0"..r end
				if #g < 2 then g = "0"..g end
				if #b < 2 then b = "0"..b end
				product = product.."|c"..r..g..b..string.sub(str, i, i)
			--end
		end
	elseif type == 2 then -- Old, uglier rainbow
		local colours = { "|cFF0000", "|cFF6600", "|cFFEE00", "|c00FF00", "|c0099FF", "|c4400FF", "|c9900FF" }
		local pass = math.random(7)

		for char in str:gmatch"." do
			--if char == " " then
			--	product = product .. char
			--else
				product = product .. colours[pass] .. char
				if pass == #colours then pass = 1 end
					pass = pass + 1
			--end
		end
	end
	return product.."|r"
end
 
function betterRand()
	randomtable = {}
	for i = 1, 97 do
		randomtable[i] = math.random()
	end
	local x = math.random()
	local i = 1 + math.floor(97*x)
	x, randomtable[i] = randomtable[i], x
	return x
end