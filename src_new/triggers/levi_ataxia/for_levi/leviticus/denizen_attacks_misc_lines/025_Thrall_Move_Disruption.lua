--[[mudlet
type: trigger
name: Thrall Move Disruption
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Basher
- Bashing
- Basher Lines
- Denizen Attacks / Misc Lines
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
- pattern: ^As the thrall draws near, it wildly grasps at your arms and legs, disrupting
    your focus\.$
  type: 1
- pattern: ^A mindless thrall hurls itself at you in a frenzy, disrupting your countermeasures\.$
  type: 1
]]--

-- THRALLS ACTIVELY STOP US LEAVING (v4.7.243, user: "It also seems thralls try and stop us
-- from leaving"). Both lines appeared in the caves-beneath-Kuthalebak death log and NEITHER
-- matched anything in the package -- the mechanic that was eating our escapes was invisible.
--
-- These come from the Necromantic affix ("Denizens may revive as mindless thralls"), which was
-- captured back in v4.7.196 and deliberately left unhandled pending observation. This is the
-- observation.
--
-- Deliberately does NOT re-send anything. With the v4.7.243 movement lock, a disruption landing
-- mid-tumble MUST wait for the lock to resolve -- a reflexive re-send here is exactly the
-- tumble-cancelling move the lock exists to prevent. Its job is to leave a timestamp so
-- S.onMoveFailed and _tumbleCheck can tell "disrupted, worth retrying" from "silently eaten",
-- and to put the cause in the next death log rather than nowhere.
ataxiaTemp = ataxiaTemp or {}
ataxiaTemp.moveDisruptedAt = (getEpoch and getEpoch()) or 0

if ataxia and ataxia.mnemosyne and ataxia.mnemosyne.swarm
   and ataxia.mnemosyne.swarm.state ~= "idle" then
  cecho("\n<indian_red>[Swarm]<reset>: a thrall is <indian_red>disrupting our escape<reset>.")
end

selectString(line, 1)
fg("indian_red") -- never the orange family: reserved for the user
deselect()
resetFormat()
