deleteLine()
cecho("\n<purple>[<white>TORSO<purple>]")

if evenom1 == "torment" and affstrack.score.healthleech>100 then
OppGainedAff("confusion")
elseif evenom1 == "torment" and affstrack.score.healthleech<50 then
OppGainedAff("healthleech")
elseif evenom1 == "exploit"  then
OppGainedAff("weariness")
OppGainedAff("paranoia")
end



