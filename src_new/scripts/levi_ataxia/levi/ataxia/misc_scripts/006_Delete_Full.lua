--[[mudlet
type: script
name: Delete Full
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- Misc Scripts
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

function deleteFull()
 	--if deletingPrompt then killTrigger( deletingPrompt ) end
 	--deletingPrompt = tempLineTrigger(1,1,[[if not isPrompt() then 
  	--	noPromptEcho = false
  --		deletingPrompt = nil
-- 	end]])
 	deleteLine()
 	noPromptEcho = true
	
		tempLineTrigger(1,1,[[if isPrompt() then
			deleteLine()
		end
		noPromptEcho = false
	]])
end