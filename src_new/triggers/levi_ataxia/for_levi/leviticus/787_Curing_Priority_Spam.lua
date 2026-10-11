--[[mudlet
type: trigger
name: Curing Priority Spam Refused
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
- pattern: You have exceeded the spam threshold for curing priority
  type: 2
]]--

-- "You have exceeded the spam threshold for curing priority. Please see Announce #5450 for
-- details." -- the server DROPPED a `curing priority` write (more than 5 a second). Seen live
-- 2026-10-11, seven times, after the v4.7.397 login re-send. Nothing parsed it, so the table was
-- recorded as sent with writes missing. ataxia/001 forgets the recorded send and retries once.
if ataxia_prioSpamRejected then ataxia_prioSpamRejected() end
