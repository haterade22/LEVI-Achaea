--[[mudlet
type: trigger
name: GMCP Oceans
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- ZulahGUI - Saonji Edit
- zGUI Redux
- Wilderness Map
- GMCP Map Catchers
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'yes'
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
- pattern: return gmcp.Room and gmcp.Room.Info and gmcp.Room.Info.environment=='Vessel'
  type: 4
- pattern: return gmcp.Room and gmcp.Room.Info and gmcp.Room.Info.num==-2
  type: 4
]]--
-- ZGUI MAY NOT EXIST (v4.7.264). `zgui` is the LEGACY ZulahGUI namespace, created by a group
-- inline script ("ZulahGUI - Saonji Edit" > "zGUI Redux"). These wilderness-map triggers are
-- always active and indexed it unguarded, so whenever that group is off -- or its script has not
-- run yet -- every room change threw:
--     [ERROR:] object:<GMCP Rooms> function:<Trigger475>
--       <[string "Trigger: GMCP Rooms"]:1: attempt to index global 'zgui' (a nil value)>
--
-- Same family as the v4.7.261 orphaned calls, and invisible to the same gates -- but NOT catchable
-- by tools/check_orphans.py, which only sees CALLS to globals defined by inactive SCRIPTS. This is
-- a table INDEX, and the definition lives in a group's inline script rather than a script file.
-- Guarded rather than disabled: the feature is real and works for anyone running that GUI.

if not (zgui and zgui.map) then return end
if zgui.map.current ~= "Ocean" then
  zgui.map[zgui.map.current]:hide()
end
zgui.map.current = "Ocean"
zgui.map["Ocean"]:show() 