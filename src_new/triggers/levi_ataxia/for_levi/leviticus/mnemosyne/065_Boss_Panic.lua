--[[mudlet
type: trigger
name: Boss Panic
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
- pattern: ^(.+) flails in panic\.$
  type: 1
]]--

-- "Lyaeus, the travelling bard flails in panic." (captured live 2026-08-11)
--
-- The tell that a denizen is about to LEAVE. It carries the proper name, which the departure
-- line does not -- that one calls the same creature "a satyri bard" -- so this is the half that
-- identifies who ran, and trigger 066 is the half that says where.
--
-- Latches only; the follow decision belongs to M.onDenizenFled. onDenizenPanic self-guards on
-- being in the tower and on the name matching the ripple's Objective boss, so a panicking
-- ordinary denizen sets nothing.
if ataxia and ataxia.mnemosyne and ataxia.mnemosyne.onDenizenPanic then
	ataxia.mnemosyne.onDenizenPanic(matches[2])
end

selectString(line, 1)
setBold(true)
fg("gold")
deselect()
resetFormat()
