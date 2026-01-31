if callguard then
  tempTimer(10, [[ cecho("\n<red> - guard arriving in 20 seconds -")]])
  tempTimer(20, [[ cecho("\n<orange> - guard arriving in 10 seconds -")]])
  tempTimer(25, [[ cecho("\n<yellow> - guard arriving in 5 seconds -")]])
  tempTimer(30, [[ cecho("\n<green> - guard should have arrived! -")]])
end
callguard = nil