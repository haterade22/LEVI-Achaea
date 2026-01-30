--[[mudlet
type: trigger
name: Logout initiated
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
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
- pattern: You grow still and begin to silently pray for preservation of your soul while you are out of the land.
  type: 3
]]--

--systemDefup("none")

send("get 50 ink from palette;inr all")

if ataxia_isClass("runewarden") or ataxia_isClass("infernal") or ataxia_isClass("paladin") then
	send("falcon sanctuary")
  send("hyena sanctuary")
elseif ataxia_isClass("unnamable") then
  send("hound sanctuary")
end
send("inr all")

--if shaman then shaman.save() end

ataxiaTemp.keepout = {}
ataxiaTemp.qqtimer = tempTimer(30, [[ataxiaTemp.qqtimer = nil; populate_keepOut(); ataxia_precacheQueue()]])

raiseEvent("logging out")