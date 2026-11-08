--[[mudlet
type: trigger
name: Ash
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Remove Afflictions
- Herbs
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
conditonLineDelta: 1
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^(\w+) eats (some prickly ash bark|a stannum flake).$
  type: 1
]]--

if matches[2] == target then
    if anorexiaFailsafe then
        tAffs[lastFocus] = true
        ataxiaEcho("Backtracked anorexia being cured with last focus.")
        anorexiaFailsafe = nil
        lastFocus = nil
    end
    -- One eat is one cure. With our crescendo up, the eat is charged to it: from 2 or more the game
    -- takes it down to 1 ("The building crescendo about you is greatly diminished."), from 1 it ends it
    -- ("... abruptly falls silent."), kb/raw/logs/2026-11-01_nikita_depthswalker-vs-bard_win_kAQnlFAW.txt
    -- :250 (2 -> 1), :428 (4 -> 1), :864 (6 -> 1), :1722 (1 -> 0). That is measured only with no other
    -- ash affliction up (kAQnlFAW, L8LSw7xD). With confusion, hallucinations, paranoia, dementia or
    -- hypersomnia up as well, which one the eat takes is unknown (kb/mechanics/foundations.md #6), and
    -- crescendo first is an assumption (curingTable.ash lists it last). V3 does not hold crescendo (it is a
    -- count in tAffs), so its ash cure then took a SECOND ash affliction for the same eat (2026-11-08
    -- deep review, F45). Now the eat is charged to crescendo alone, with what targetAteWrapper does
    -- besides the cure: the eat proves no anorexia, and the target's herb balance starts.
    local cres = tAffs.crescendo
    if cres == true then cres = 1 end
    cres = tonumber(cres)
    if cres and cres > 0 then
      erAff("anorexia")
      if cres >= 2 then
        tAffs.crescendo = 1
      else
        erAff("crescendo")
      end
      if startCureBalanceV3 then startCureBalanceV3("herb") end
    else
      targetAteWrapper("ash")
    end
if passiveFailsafe then restorePassiveCure() end
    tBals.plant = false
  if tBals.timers.plant then killTimer(tBals.timers.plant) end
    if tAffs.mercury then
        erAff("mercury")
        tBals.timers.plant = tempTimer(1.9, [[tBals.plant = true; tBals.timers.plant = nil]])
    else
        tBals.timers.plant = tempTimer(1.3, [[tBals.plant = true; tBals.timers.plant = nil]])
    end
    targetIshere = true
end
