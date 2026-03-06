deleteLine()
cecho("\n<red>[|] [|] [|] <orange>BLADETWIST <red>[|] <orange>BLADETWIST <red>[|] <orange>BLADETWIST <red>[|] [|] [|]")
cecho("\n<red>[|] [|] [|] <orange>BLADETWIST <red>[|] <orange>BLADETWIST <red>[|] <orange>BLADETWIST <red>[|] [|] [|]")

-- BM Brokenstar phase engine callback (increment count on actual fire, not button spam)
if blademaster and blademaster.onBladetwistSuccess then blademaster.onBladetwistSuccess() end
