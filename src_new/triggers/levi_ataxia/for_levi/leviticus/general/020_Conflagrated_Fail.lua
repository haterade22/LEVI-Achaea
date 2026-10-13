--[[mudlet
type: trigger
name: Conflagrated Fail
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Mage
- General
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
- pattern: ^You bend your will upon (\w+), attempting to rouse a conflagration to consume \w+, but to no avail\.$
  type: 1
]]--

-- Only a failure at our target says anything about our target's burns (v4.7.420). Conflagrate
-- lands on a target with "two or more stacks of the ablaze affliction"
-- (kb/raw/wiki/Elementalism.wiki:230), so a failure means the target it names had fewer; but a
-- failure at anyone else used to zero the count tracked on `target`. 019, the landed conflagrate,
-- checks the name the same way.
if matches[2] ~= target then return end

tburns = 0
magi.offense.state.burns = 0
magi.offense.state.conflagrated = false
magi.offense.debugEcho("Conflagrate FAILED - burns reset")