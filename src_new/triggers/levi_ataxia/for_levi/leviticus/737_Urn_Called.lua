--[[mudlet
type: trigger
name: Urn Called
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Misc Triggers
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
- pattern: ^As you rub one hand over a petite ceramic urn, the air in front of you warps and changes as (.+) coalesces.$
  type: 1
]]--

if ataxia.mountid ~= "urn/"..ataxiaTemp.me then
  ataxia.mountid = "urn/"..ataxiaTemp.me
  ataxiaEcho("Mount id has been updated to urn/"..ataxiaTemp.me..".")
end
  if not dontMount then
    send("curing mount "..ataxia.mountid,false)
  else
    send("queue addclear free order "..ataxia.mountid.." follow me")
  end
  
dontMount = nil