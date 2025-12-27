--[[mudlet
type: trigger
name: Nairat
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Affs Post Queue - Gated
- Classes K-S
- Knight
- Other Stuff
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'no'
  isPerlSlashGOption: 'no'
  isColorizerTrigger: 'no'
  isFilterTrigger: 'no'
  isSoundTrigger: 'no'
  isColorTrigger: 'no'
  isColorTriggerFg: 'no'
  isColorTriggerBg: 'no'
triggerType: 0
conditonLineDelta: 0
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: Cold blue flames wreathe your runeblade, emanating an icy, penetrating chill.
  type: 3
]]--

if not ataxiaTemp.ignoreShield then
	local nairat = {"nocaloric", "shivering", "frozen"}
	local count = 0
	for _, aff in pairs(nairat) do
		if count == 2 then
			break
		else
			if not haveAff(aff) then
				tAffs[aff] = true
				count = count + 1
			end
		end
	end
	selectString(line, 1)
	if haveAff("frozen") then
		fg("blue")
	else
		fg("a_blue")
	end
	deselect()
end
ataxiaTemp.ignoreShield = nil