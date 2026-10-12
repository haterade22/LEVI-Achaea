--[[mudlet
type: trigger
name: Ekanelia Success
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes K-S
- Serpent
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
- pattern: ^You sense the weakness in (\w+) as your (\w+) takes hold\.$
  type: 1
]]--

if isTargeted(matches[2]) then
    serpent.impulseSuccess = true
    -- Track monkshood ekanelia (impatience) delivery for relapse locking
    if matches[3] == "monkshood" then
        serpent.state.impatienceDelivered = true
        -- This line is the confirmation canAttemptImpatience()'s 2.5 s guard counts from
        -- (002_Serpent_Offense.lua, IMPATIENCE COOLDOWN). Nothing called the stamp before.
        if stampImpatienceCooldown then stampImpatienceCooldown() end
    elseif matches[3] == "scytherus" then
        serpent.state.camusDelivered = true
    end
    -- What the reaction GAVE, on the tracker. Only the reaction's result: the venom's own
    -- affliction comes from the bite line (009_Bite), so it is not in the map. Without this,
    -- haveAff("impatience") stayed false after our own monkshood reaction and the offense
    -- kept sending it.
    local results = serpent.EKANELIA_RESULTS and serpent.EKANELIA_RESULTS[matches[3]]
    if results then tarAffed(unpack(results)) end
    Algedonic.Echo("<green>EKANELIA SUCCESS<white> (" .. matches[3] .. ")")
end
