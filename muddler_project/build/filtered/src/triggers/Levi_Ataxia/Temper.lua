local colours = {sanguine = "a_darkred", melancholic = "DeepSkyBlue", phlegmatic = "a_darkmagenta", choleric = "a_brown"}
local humour = matches[3]

selectString(matches[3], 1)
fg(colours[humour])
resetFormat()

tAffs[humour] = tAffs[humour] or 0
tAffs[humour] = tAffs[humour] + 1