--[[mudlet
type: trigger
name: Gag Round Alias
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
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
- pattern: 'Alias "lveq" will now execute: '
  type: 2
- pattern: 'Alias "lvbal" will now execute: '
  type: 2
- pattern: 'Alias "lveqbal" will now execute: '
  type: 2
- pattern: 'Alias "lvclass" will now execute: '
  type: 2
- pattern: 'Alias "lvfree" will now execute: '
  type: 2
- pattern: 'Alias "lvfreestand" will now execute: '
  type: 2
- pattern: 'Alias "lvfull" will now execute: '
  type: 2
]]--

-- The game's echo of each round rewrite (`setalias lvfree a/b/c`, ataxia/003). The names are the ones
-- in ataxia_ROUND_TYPES, one by one, so a test alias such as `lvprobe` still shows.
--
-- A plain `deleteLine()`, NOT `deleteFull()`, for the reason trigger 056 gives. `deleteFull` also
-- deletes the next line if it is a prompt, and here that prompt can belong to the round. All 371 echoes
-- of the `pk` alias in kb/raw/logs have a prompt right after them, but it can close other output too:
--   Your lungs have recovered enough to smoke another mineral or plant.   (3ys7NuHA row 1975)
--   Alias "pk" will now execute: "stand/wield staff/..."                  (row 1976)
--   H:5991|85% M:2935|85% E:100% ...                                      (row 1977)
-- `deleteFull` would hide that prompt. This keeps it. The cost is one more prompt on the screen for
-- each rewrite. Those logs draw 12.5 prompts per rewrite anyway (4,643 prompts, 371 echoes).
deleteLine()
