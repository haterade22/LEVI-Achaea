--[[mudlet
type: trigger
name: Mnemosyne Rimewrought
hierarchy:
- Levi_Ataxia
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
- pattern: '^Rimewrought:\s+Perpetual ice coats your body'
  type: 1
]]--

-- Ongoing-effect line in the Mnemosyne status screen (live 2026-09-24):
--   Rimewrought:   Perpetual ice coats your body, rendering tattoos ineffective, and denizens
--                  cause additional freezing on their attacks.
-- Every tattoo we send is inert while it is up, so `onRimewroughtSeen()` latches the affix (the
-- spend sites gate on `ataxiaBasher_tattoosDead()`) and turns the game's tree curing off, since
-- the tree is a tattoo too. Idempotent and gated on being in a run; onRunEnd puts curing back.
if ataxia and ataxia.mnemosyne and ataxia.mnemosyne.onRimewroughtSeen then
  ataxia.mnemosyne.onRimewroughtSeen()
end
