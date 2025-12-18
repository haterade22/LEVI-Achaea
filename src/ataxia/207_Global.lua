-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > Leviticus > Global Script > Global

-- this should be in login
tparrying = tparrying or "head"
ltarget = ltarget or "torso"
envenom1 = envenom1 or nil
taffenvenom1 = taffenvenom1 or nil
preport1 = preport1 or ""
envenom2 = evenom2 or nil
taffenvenom2 = taffenvenom2 or nil
omount = omount or ""
engaged = engaged or false
need_raze = false
need_bisect = false
if not php then php = 100 end
if not pm then pm = 100 end
partyrelay = partyrelay or true
if tAffs.rebounding or tAffs.shield then
need_raze = true
  else
need_raze = false
  end
need_dwcempower = true
need_falcon = true
inc_imp = false
timpale = false
rtiwaz = false