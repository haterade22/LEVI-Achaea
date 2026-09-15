--[[mudlet
type: trigger
name: Mnemosyne Death Stare Kill
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
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
- pattern: freezes for a moment before dying. Instantly.
  type: 0
]]--

-- Death Stare LANDED. Captured live 2026-09-15:
--
--   "A stout footsoldier freezes for a moment before dying. Instantly."
--   "Damage dealt: 27803 (unblockable)."
--
-- The tail is matched as a substring so the variable mob name in front of it never matters. This
-- line prints only with the boon, so it is self-proving: `ataxiaBasher_deathStareConfirm`
-- (basher/001) re-latches the flag, marks the ripple's one charge SPENT and releases the
-- in-flight replay. Counting the charge from the kill rather than the send is what lets a send
-- the server ate retry instead of forfeiting the ripple. `chartreuse` bold is the attack-landed
-- colour (Arc, Thunderclap, Spirit Rend, Flourish).
selectString(line, 1)
fg("chartreuse")
setBold(true)
deselect()
resetFormat()

if ataxiaBasher_deathStareConfirm then
  ataxiaBasher_deathStareConfirm()
end
