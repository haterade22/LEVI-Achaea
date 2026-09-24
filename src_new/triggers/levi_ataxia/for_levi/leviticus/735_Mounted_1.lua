--[[mudlet
type: trigger
name: Mounted
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
- pattern: ^You easily vault onto the back of (.+).$
  type: 1
- pattern: ^You climb up on (.+).$
  type: 1
]]--

if ataxia.settings.autogallop and not mmp.settings.gallop then
	mmp.settings:setOption("gallop", true)
end

-- ...and jumps become MOUNTJUMPs (v4.7.345). From the saddle the game refuses a leap outright,
-- and in a Mnemosyne escape that refusal is a silent no-op. basher/013 owns the belief.
if ataxiaBasher_mountedSet then ataxiaBasher_mountedSet(true, "vaulted on") end