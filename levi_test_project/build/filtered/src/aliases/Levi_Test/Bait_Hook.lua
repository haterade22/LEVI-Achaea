if not ataxia.fishing then
	ataxiaEcho("Fishing variables do not exist. Use afish init to fix this.")
else
	if ataxia.fishing.type == "deepsea" then
		send("get "..ataxia.fishing.bait.." from tank")
	else
		send("get "..ataxia.fishing.bait.." from bucket")
	end
	send("bait hook with "..ataxia.fishing.bait)
end