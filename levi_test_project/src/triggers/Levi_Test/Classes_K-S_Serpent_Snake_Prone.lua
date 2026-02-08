if isTargeted(matches[2]) then
incommingsnakeprone = false
tempTimer(2,[[cecho("\n<a_darkcyan>(<a_darkmagenta>LEVI<a_darkcyan>): Snake Prone in 6 seconds")]])
tempTimer(4,[[cecho("\n<a_darkcyan>(<a_darkmagenta>LEVI<a_darkcyan>): Snake Prone in 4 seconds")]])
tempTimer(6,[[cecho("\n<a_darkcyan>(<a_darkmagenta>LEVI<a_darkcyan>): Snake Prone in 2 seconds")]])
tempTimer(7,[[cecho("\n<a_darkcyan>(<a_darkmagenta>LEVI<white>): Snake Prone in 1.2 seconds")]])
tempTimer(7.5,[[incommingsnakeprone = true]])

end