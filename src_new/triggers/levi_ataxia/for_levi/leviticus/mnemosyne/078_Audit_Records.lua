--[[mudlet
type: trigger
name: Mnemosyne Audit Records
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
- pattern: ^Audit records:
  type: 1
]]--

-- The AUDIT block header. Arms the capture on the OUTPUT rather than on our own send, so a manual
-- AUDIT typed by the user is captured identically -- and so that a wrong send on our side fails
-- visibly (nothing arrives) instead of silently producing no baseline.
--
-- One line of adapter, exactly like trigger 063: the parse stays in the script where the test
-- suite can see it. A guard inside a trigger is a guard the tests cannot reach (v4.7.260).
if ataxia.mnemosyne and ataxia.mnemosyne._auditCapture then
  ataxia.mnemosyne._auditCapture()
end
