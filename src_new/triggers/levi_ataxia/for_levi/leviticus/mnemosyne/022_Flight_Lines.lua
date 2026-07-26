--[[mudlet
type: trigger
name: Mnemosyne Flight Lines
hierarchy:
- Levi_Ataxia
- Ataxia
- Mnemosyne
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
- pattern: ^The ring of shining metal carries you up into the skies\.
  type: 1
- pattern: ^You land easily, back on the ground again\.
  type: 1
]]--

-- Confirmed flight state for the swarm module's recovery hover (009): the escape's
-- FLY can be eaten by afflictions (razer stupidity replaced queued commands in the
-- Pinnacle death), so S.flying stays optimistic until the up-line lands here. The
-- land line clears it so a forced/incidental landing re-triggers the hover's re-send.
local S = ataxia.mnemosyne and ataxia.mnemosyne.swarm
if not S then return end
if string.find(line, "carries you up into the skies", 1, true) then
  if S.onFlightUp then S.onFlightUp() end
elseif S.onFlightDown then
  S.onFlightDown()
end
