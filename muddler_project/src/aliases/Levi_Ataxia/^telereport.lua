if teleannounce == "activated" then
	teleannounce = "deactivated" 
	cecho("\n<brown>Your telepathy will no longer be announced to your party.")
else
	teleannounce = "activated"
	cecho("\n<dark_sea_green>Your telepathy will be announced to your party.")
end