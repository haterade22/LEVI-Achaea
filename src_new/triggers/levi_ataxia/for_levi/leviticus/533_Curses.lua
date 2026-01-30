--[[mudlet
type: trigger
name: Curses
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes K-S
- Shaman
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
- pattern: ^You point an imperious finger at (\w+), bringing the curse of (\w+) down upon \w+.$
  type: 1
]]--

if isTargeted(matches[2]) then
	ataxiaTemp.curse = curseConvert(matches[3])
	
	if ataxiaTemp.curse ~= "breach" and ataxiaTemp.curse ~= "bleed" then
		tarAffed(ataxiaTemp.curse)
    if partyrelay and not ataxia.afflictions.aeon then  send("pt "..target..": "..ataxiaTemp.curse) end
	else
		tAffs.curseward = false
	end
	
	if haveAff("curseward") then erAff("curseward") end
	if ataxiaTemp.curse ~= "breach" and not ataxiaTemp.swiftcurse and not tzantzacurse and tAffs.haemophilia then
		send("Discern "..target)
	elseif beepBoop and beepBoop.enabled then
    send("Discern "..target)
	end
	targetIshere = true
	tAffs.bleed = tAffs.bleed or 0
   if not tAffs.haemophilia then
  tAffs.bleed = 0
  end
  if shaman.spiritisbound("teraile") then
    if tAffs.haemophilia then
    tAffs.bleed = tAffs.bleed + 40
    cecho(" <white>[<red>"..tAffs.bleed.."<white>]")
  end
  end
  ataxiaTemp.swiftcurse = false
	
	
end