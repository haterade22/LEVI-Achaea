-- We just died. Fire death handler immediately to stop the basher
-- before the next prompt can dispatch another attack.
-- ataxiaBasher_onDeath() is idempotent — safe to call from both
-- "You have been slain" and "Your starburst tattoo flares".
ataxiaBasher_onDeath()
