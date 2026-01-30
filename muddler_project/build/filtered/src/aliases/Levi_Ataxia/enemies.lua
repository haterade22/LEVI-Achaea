for token in matches[2]:gmatch("%w+") do 
		sendAll("unenemy "..token, "enemy "..token)
	end