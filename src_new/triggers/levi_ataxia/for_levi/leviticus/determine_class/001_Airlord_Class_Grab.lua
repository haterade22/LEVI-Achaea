--[[mudlet
type: trigger
name: Airlord Class Grab
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Curing Stuff
- Priority Management
- Determine Class
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
- pattern: ^As the dark intent of (\w+) falls upon you, you feel the air surrounding you begin to thrum with tension\.$
  type: 1
- pattern: ^(\w+) studies you intently, the howling winds that surround \w+ stilling for a moment\.$
  type: 1
- pattern: ^(\w+) clenches a hand into a fist, a sudden force locking closed about your throat and constricting your airflow\.$
  type: 1
- pattern: ^(\w+) casts a hand out in your direction, an icy zephyr descending upon you to tear your fortitude away\.$
  type: 1
- pattern: ^A howling wind sweeps over you, its terrible power scouring flesh from bone and leaving your face a bloody ruin
    by the will of (\w+)\.$
  type: 1
]]--

if matches[2] == target then
ataxiaNDB.players[target].class = "Airlord"
end
