if ataxiaTemp.learning and not sentLearn then
	send("learn 20 "..ataxiaTemp.learning.." from "..ataxiaTemp.learnFrom,false)
	sentLearn = tempTimer(0.5, [[sentLearn = nil]])
end
