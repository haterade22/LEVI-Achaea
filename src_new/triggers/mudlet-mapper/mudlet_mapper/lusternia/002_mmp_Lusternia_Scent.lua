--[[mudlet
type: trigger
name: mmp Lusternia Scent
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- Lusternia
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
conditonLineDelta: 99
mStayOpen: 100
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: You scent at the air, your skilled nose picking up the faint traces of others in the surrounding area.
  type: 3
- pattern: You snort and snuffle at the air, sensing through a ridiculous pig nose upon your face the faint traces of others
    in the surrounding area.
  type: 3
- pattern: A pert little nose takes in a delicate whiff of your surroundings, sensing the faint traces of others in the nearby
    area.
  type: 3
- pattern: You tilt back your head and inhale deeply through your nose, the whiskers of a wolf's snout upon your face twitching
    as you sense the faint traces of others in the surrounding area.
  type: 3
- pattern: You flutter your nose at the air, sensing through a cute little rabbit nose upon your face the faint traces of
    others in the surrounding area.
  type: 3
- pattern: You sniff disdainfully at the air with a snobby snoot, wrinkling your nose as you sense the faint traces of others
    in the nearby area.
  type: 3
- pattern: Your snout twitches and trembles at the air, sensing through a striped badger nose upon your face the faint traces
    of others in the surrounding area.
  type: 3
- pattern: You twitch your snout and scent the air, sensing through a scaled fink nose upon your face the faint traces of
    others in the surrounding area.
  type: 3
]]--

mmp.tempscent = {}
mmp.pdb_lastupdate = {}