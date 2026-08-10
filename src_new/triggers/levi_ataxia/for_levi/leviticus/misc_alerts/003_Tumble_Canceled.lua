--[[mudlet
type: trigger
name: Tumble Canceled
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Misc Tracking
- Warnings
- Misc Alerts
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
- pattern: You cease your tumbling.
  type: 3
]]--

ataxia_boxEcho("OUR TUMBLE HAS BEEN CANCELED!", "black:yellow")
send("cq all")

-- TELL THE SWARM (v4.7.245). This trigger has printed its banner and flushed the queue for a
-- long time without ever telling the one system that depends on a tumble landing. So a
-- cancelled tumble was invisible: `ataxiaTemp.tumbleDir` stayed set until the TUMBLE_CONFIRM
-- fallback expired, and since v4.7.243 made that state a MOVEMENT LOCK, those were seconds in
-- which nothing could move at all.
--
-- Live log 2026-08-10: cancel at 11:40:41.115, retry at 11:40:45.938 -- four and a half
-- seconds at 14% HP in a burning room, waiting out a timer, while the line that said "this
-- failed" was already on screen. A fallback timer is for when the game says NOTHING.
--
-- Ordered AFTER the `cq all` above on purpose: that flush would otherwise wipe the retry we
-- are about to queue. onTumbleCanceled is inert outside Mnemosyne and when no tumble is being
-- tracked, so the manual/PvP uses of this line are unaffected.
if ataxia and ataxia.mnemosyne and ataxia.mnemosyne.swarm
   and ataxia.mnemosyne.swarm.onTumbleCanceled then
  ataxia.mnemosyne.swarm.onTumbleCanceled()
end