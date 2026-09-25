--[[mudlet
type: trigger
name: Transcendence Full
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Class Stuff
- Psion
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
- pattern: 'You have achieved transcendence: your body and mind operate as one.'
  type: 3
- pattern: Your body and mind are in perfect harmony; transcendence is yours.
  type: 3
]]--

local was = tonumber(ataxiaTemp.transcendence) or 0
ataxiaTemp.transcendence = 100

-- The round already queued was built BEFORE this line, so it has no free shatter in it; without
-- this it fired as a plain deathblow and the shatter came a round late (v4.7.352, user: "Seems
-- like we are behind one attack on the transcendance, maybe a clearqueue is needed when we are
-- at full"). Only on the change: "...transcendence is yours." repeats on every weave at 100.
if was < 100 and ataxiaBasher_requeueNow then ataxiaBasher_requeueNow("transcendence full") end

if ataxiaBasher.enabled and not ataxiaBasher.manual then
	deleteFull()
end