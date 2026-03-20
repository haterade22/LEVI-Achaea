--[[mudlet
type: trigger
name: Applied Head
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Remove Afflictions
- Groups
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
- pattern: ^(\w+) takes some salve from a vial and rubs it on \w+ head.$
  type: 1
]]--

if isTargeted(matches[2]) then
    if passiveFailsafe then restorePassiveCure() end
    erAff("slickness")

    -- ==== CRUSHEDTHROAT TRACKING ====
    local now = os.clock()
    if ataxiaTemp.crushedCheck.pending then
        if now - ataxiaTemp.crushedCheck.lastApply < 1.2 then
            -- confirmed mending, cure crushedthroat
            if haveAff("crushedthroat") then
                erAff("crushedthroat")
            end
            -- cancel pending timer
            if ataxiaTemp.crushedCheck.timer then killTimer(ataxiaTemp.crushedCheck.timer) end
            ataxiaTemp.crushedCheck.pending = false
            ataxiaTemp.crushedCheck.timer = nil
            target_salveBal(1.1)
        end
    end

    -- record this head apply as pending
    ataxiaTemp.crushedCheck.pending = true
    ataxiaTemp.crushedCheck.lastApply = now
    if ataxiaTemp.crushedCheck.timer then killTimer(ataxiaTemp.crushedCheck.timer) end
    ataxiaTemp.crushedCheck.timer = tempTimer(1.5, function()
        ataxiaTemp.crushedCheck.pending = false
        ataxiaTemp.crushedCheck.timer = nil
    end)

    -- ==== HEAD BREAK HANDLING ====
    local salvetimer = false
    if tLimbs.H >= 100 and tLimbs.H < 200 then
        -- lvl 2 break
        tempTimer(4, function()
            target_resetLimb("head")
            erAff("mangledhead")
            ataxia_boxEcho("they cured Head Damage (lvl 2)", "DodgerBlue")
        end)
        salvetimer = 4
    elseif tLimbs.H >= 200 then
        -- lvl 3 break
        tempTimer(4, function()
            tLimbs.H = 100
            erAff("mangledhead")
            ataxia_boxEcho("they cured Head Damage (lvl 3 -> lvl 2)", "DodgerBlue")
        end)
        salvetimer = 4
    end

    if salvetimer then
        target_salveBal(salvetimer)
    end

    erAff("bloodfire")
    targetIshere = true
end