--[[mudlet
type: trigger
name: Battlerage Global Cooldown
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Basher
- Bashing
- Basher Lines
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
- pattern: You must wait a short time before you can use a battlerage ability again.
  type: 3
]]--

-- The global ~1s battlerage cooldown is active -- a queued BR ability was just rejected.
-- Record it (reload-safe TIMESTAMP, never a stuck flag) so the rotation stops queuing a BR
-- until it clears, instead of wasting the cycle. Also catches a BR fired outside the rotation
-- (e.g. a shielded shin-shatter from the class bash) that the rotation didn't arm itself.
ataxiaTemp = ataxiaTemp or {}
ataxiaTemp.brGlobalReadyAt = getEpoch() + 1

-- A REJECTED battlerage did not land, so replaying the held pick is exactly wrong:
-- the rebuild loop would re-queue it and get rejected again, burning cycle after
-- cycle (live log 2026-07-30 -- two back-to-back rejects while the Runewarden etch
-- pick sat in its 3s replay window). Drop the in-flight hold on every owned rotation
-- and let the next round re-decide, now gated by the timestamp above. The send-side
-- cooldown stamp deliberately stays: it self-heals on its own timer, and clearing it
-- here would let a rejected ability be retried instantly forever.
for _, k in ipairs({"rwBrPending", "dwBrPending", "psionBrPending", "gdragonBrPending"}) do
    ataxiaTemp[k] = nil
end
