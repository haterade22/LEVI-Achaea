--[[mudlet
type: trigger
name: Start Shikudo
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- MONK 1
- Monk
attributes:
  isActive: 'no'
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
mStayOpen: 100
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: '[System]: Running queued eqbal command:'
  type: 2
- pattern: You tap out the contents of your pipe.
  type: 3
- pattern: ^You fill your pipe with (.*).$
  type: 1
- pattern: You hold no "malachite".
  type: 3
- pattern: ^You glance over (\w+) and see that (his|her) health is at (.*).$
  type: 1
]]--

monk.shikudo.start()
monk.shikudo.combo_affs = {}
monk.shikudo.parrying = {}