# Mystor (Shikudo) vs Agathon (Infernal, two scimitars): won with KAI CHOKE

> Source: `kb/raw/logs/2026-10-11_mystor_shikudo-vs-infernal-dwc_win_FceAmb0o.txt` (Mystor's own log; how to read his client's output: `kb/raw/logs/README.md`). Every line number below is a line of that file.
> Written 2026-10-11 from a line-by-line reading: one agent per ~800-line chunk, merged by a further agent that checked doubtful claims against the log. Confidence: LOG for what the lines show; the readers' own "likely" and "guess" marks are kept. Not yet independently re-verified.

## Fight

- **Logger:** Mystor, a Shikudo monk. He fights with a twisted oaken staff and swaps in a Shield of Absorption for his non-combo rounds (928-929, 993-994). He has 6265 health and 5839 mana (log rows 2-4).
- **Opponent:** Khovroth Agathon, Wolf of Baelgrim: "He wields a Scimitar of Eagles in each hand." (2402-2403). He is an **Infernal, dual cutting (DSL), with two Scimitars of Eagles**, and has 7281 health (349). The class is confirmed by:
  - his own commands through Sapience: `wield scimitar388622 scimitar314077` / `dsl Mystor <limb> <venom> <venom>` every round (2217-2225);
  - the Hellforge investment TORMENT placed in a DSL venom slot (`dsl Mystor left leg torment curare`, 1258);
  - DEATHAURA: 26 ticks of 547 magical;
  - VIVISECT, tried 5 times (2116, 2439, 2577, 2690, 4717);
  - TYRANNY (2357), which left gravehands in the room (2402, 3317, 5960);
  - the "sanguine mist" line after his healthleech drained Mystor (1302), right after which Mystor's system printed "Assuming Agathon's class is infernal." (1303).
  - He also used FITNESS (46 sends), EPITOMISE, ENGAGE and TUMBLE.
- **Result:** Mystor won with "You have slain Agathon." (6467, 10:28:04). The finish was three KAI CHOKEs on a truelocked, confused and disrupted target. "Defeated, Agathon is cast out of the Arena." follows (6469).
- **Duration:** the log runs 10:23:22-10:28:04 (4 min 42 s). From Agathon's opener (280, 10:24:47) to the kill is 3 min 17 s.
- **Where:** the Colosseum Diabolus arena (the woods).
  - Agathon entered through the ornate mirror in Corroded meadow (251), coming from the Parapet atop the Tower of the Daegger (147).
  - First contact was in Dryad's gibbet (280-281). The fight later moved to Dismal bracken (2235, 5968).
  - After the fight Mystor is in the Colosseum Diabolus staging grounds (6474).

## How it went

| # | Clock | Lines | Form, kata | What happened |
|---|---|---|---|---|
| 1 | 10:23:22-10:24:45 | 1-263 | Oak 0 | **Search.** The server target is set (1). Mystor typed `mind lock` 24 times while Agathon was outside the area. The only answer was the system's "Target Not Present" banner, 8 times (6-239); no game reply is visible. MIND SENSE (146-147, 10:24:20) found him on the Parapet, and "You may seek out another mind." came about 4 s later (150). Agathon came through the mirror into Mystor's room (251; Mindnet 252), then left north (257). |
| 2 | 10:24:45-10:24:49 | 264-335 | Oak 0 | **Lock and opener.** MIND LOCK started with Agathon one room away, "speeded by the mindprint" (266-267). Agathon charged in from the adjacent room: 2220 physical cutting (35% of Mystor's health), prone, bleeding 73 and a stun of about 1 s (280-306). The lock finished while Mystor lay prone and stunned (296). SSC stood him up, clotted, sipped and ate potash (309-319). MIND PRINT (329). First DEATHAURA tick (332). |
| 3 | 10:24:50-10:25:00 | 336-653 | Oak 3->12 | Four rounds of nervestrike + risingkick head + ruku/kuro, with KAI BOOST in round 3 (480). Agathon used DSL with xentio/curare and torment/curare on the left leg and left arm: clumsiness, paralysis, healthleech (392-401, 526-535, 685-694). ENGAGE (362). His rebounding came up (463) and was dropped by his own DSL (525); he re-smoked (540). |
| 4 | 10:25:00-10:25:09 | 654-922 | Gaital 3->12 | Transition at Oak 12 (654-658). Mystor, clumsy, fumbled a flashheel (660). His flashheels broke Agathon's legs (736, 794, 869), and Agathon salved his legs each time (749, 804, 880). Mystor's left-arm parry stopped a DSL aimed at that arm (755-757). |
| 5 | 10:25:09-10:25:20 | 923-1412 | Rain 0->15 | Transition + shield + MIND SAPIENCE in a round with no combo (923-934). From 942 Sapience shows Agathon's commands. Frontkick opens every combo. MIND IMPATIENCE (1150) was cured with plumbum about 1 s later (1235). Torment's healthleech (1258-1263) was followed by 506 unblockable and the sanguine mist (1301-1302). |
| 6 | 10:25:20-10:25:31 | 1413-1833 | Rain->Oak at 15, Oak 3->12 | Agathon switched to epteth/epseth. Both of Mystor's arms "shrivel" (1441, 1446) and were mended one limb per application (1451-1508). Agathon parried five of Mystor's strikes, all aimed at his torso, the risingkick torso among them (1497, 1499, 1770-1775). |
| 7 | 10:25:31-10:25:42 | 1834-2226 | Gaital 3->12, Rain 3 | Limb breaks again. Mystor's left leg went past 100% and was damaged (2030-2032); restoration fixed it about 4 s after it was applied (2128->2273). **First VIVISECT refused** (2115-2117, 10:25:39). Gaital->Rain at 12: frontkick, hiru on the prone target, kuro (2143-2155). MIND THROW was refused 12 times for lack of balance (2159-2208). |
| 8 | 10:25:42-10:25:53 | 2227-2404 | Rain 3 | **MIND THROW NE.** The lock shattered and Agathon landed in Dismal bracken (2233-2236). Mystor re-locked him across rooms (2248-2311) and recast Sapience (2319). Agathon diagnosed and cast TYRANNY (2341-2357). Two of Mystor's rounds fired into empty rooms (2379-2398). Mystor walked into Dismal bracken (2401-2404). |
| 9 | 10:25:54-10:26:13 | 2405-2963 | Rain 3->12 | Mystor's first combo bounced off Agathon's shield (2415); SHATTER broke it (2430). VIVISECT refused three times (2441, 2578, 2691). A curare+gecko DSL gave paralysis and slickness and stripped Mystor's fangbarrier (2491-2502). Telepathy behind the Shield of Absorption: IMPATIENCE (2608) and PARALYSE x7 (2636-2944). One paralyse left seven of Agathon's DSL sends silent until he ate magnesium (2848-2898). |
| 10 | 10:26:13-10:26:31 | 2964-3509 | Rain 12, Oak 3->12, Gaital 3->12 | Frontkick prone + ruku + kuro (2971-2976). Rain->Oak (3072): risingkick to the head of the prone target, livestrike, and ruku torso, which stripped his fangbarrier (3084). Prone with broken limbs, Agathon could not stand until he mended his legs (3131, about 5 s). EPITOMISE (3055-3311). Ten of his quicksilver applications failed until his arms were mended (3132-3273). He tumbled SW (3247), and Mystor was already in Dryad's gibbet when he arrived (3345-3351). Gravehands threw Mystor off balance (3317). The lock was lost (3322) and re-made (3333-3385). Oak->Gaital at 12 (3362). His shield tattoo (3397) was shattered (3411). |
| 11 | 10:26:35-10:26:58 | 3574-4606 | Rain 0->15, Oak 3->9 | Sapience again (3582). IMPATIENCE while Mystor himself was paralysed (3705), and again at 3827. Epteth broke Mystor's left arm while he held the shield, and he could not re-wield the staff for three rounds (3742, 3776-3808). Rain->Oak at 15 (4353). Three Oak rounds opening with nervestrike light (4359, 4432, 4547), plus livestrike light for asthma (4437) and ruku torso for slickness, which stripped his sileris (4552-4553). |
| 12 | 10:26:58-10:27:05 | 4607-4862 | Willow 3 | **First lock.** Oak->Willow at 9: flashheel, hiraku light, hiru light. Agathon then had asthma, slickness and anorexia (the system marks it "(S)", 4622). MIND IMPATIENCE (4698), a VIVISECT refused (4717-4719), MIND PARALYSE (4745) and MIND CONFUSE (4794) followed. Agathon typed FITNESS 22 times. It worked at 10:27:05 (4834), and in the same second he smoked realgar, applied epidermal and ate magnesium (4846-4850). |
| 13 | 10:27:05-10:27:30 | 4863-5716 | Willow 3->12, Rain 3->15, Oak 3->12 | Flashheels with light head strikes, then frontkick rounds; Agathon's lowest health was 52.55% (5179). A prone hiru produced "Agathon looks about bemusedly." (5428). Rain->Oak at 15 (5473). "Vacancy fills the eyes of Agathon." printed after livestrike twice (5485, 5585). He touched his shield tattoo while paralysed (5515); it was shattered (5539). |
| 14 | 10:27:30-10:27:50 | 5717-6242 | Gaital 3->6, Maelstrom 3->12, Oak 3->6, Willow 3 | Ruku torso stripped his quicksilver (5727). Ruku right and ruku left took both of his arms to 100% in Mystor's model (5794-5796, 10:27:32); after this, none of Agathon's 21 DSL sends printed anything. He tumbled NE (5873) and EPITOMISEd (5880). Mystor was already waiting in Dismal bracken (5959) when he tumbled in (5968). IMPATIENCE x2 (5945, 5982); only the first was cured, with plumbum (5954). FITNESS worked once more (6082), then realgar (6089). Oak put asthma and slickness back on (6133-6135), then weariness and paralysis (6170-6172). Willow hiraku + hiru (6239-6241) completed a **truelock with weariness**. |
| 15 | 10:27:52-10:28:04 | 6309-6477 | Willow 3 | **The kill.** MIND CONFUSE (6317), then MIND DISRUPT (6366), then KAI CHOKE x3 (6399, 6424, 6444). ASSESS read 87.3% -> 53.4% -> 24.5% -> 3.4% (6368-6446). Agathon typed `say nice` and `say nice you got me` (6385, 6405); Mystor saw no say line. The fight ends with "You have slain Agathon." (6467). |

## The opponent

**Rotation as Sapience shows it** (from 942). He sends one burst per balance, about every 2 s:
`stand` / `wield scimitar388622 scimitar314077` / `wipe scimitar314077` / `dsl Mystor <limb> <venom1> <venom2>` / `assess Mystor` (2217-2225).
- After a DSL that landed he sends `pt Mystor: <v1> <v1> <v2> <v2>` (1085, 1280, 2055).
- STAND while standing, WIELD, OUTR, a WIPE of a clean blade, and ASSESS all print nothing on Mystor's screen.
- Venom 1 rides blade 1 and venom 2 rides blade 2 (1029-1038, 1258-1267, 1436-1446).
- He aimed at Mystor's left leg or left arm almost every time. He hit the right leg only at 2653, 3654, 3858, 4128 and 4302.

**DSL venom pairs, with the lines that show them:**
- xentio + curare (clumsiness, paralysis): 392-401, 1029, 1163, 2755, 2906, 3600, 3960, 4029.
- torment + curare (healthleech, paralysis): 526-535, 685-694, 1258, 3654.
- An unseen first venom gave nausea at 812-816 (before Sapience). Euphorbia is the nausea venom; that is a guess.
- curare + gecko (paralysis, slickness): 2491, 2653.
- epteth and epseth, in every combination, for VIVISECT: from 10:25:20 (1368-2220), and again from 10:26:39 to the end (3737-6298).

**Abilities and their lines:**
- **Opener** (280-284): "Agathon charges in, sword flashing at the ready." / "You writhe and scream as he drives the cruel blade deep into your side."
  - It did 2220 cutting, left Mystor prone and bleeding 73, and stunned him for about 1 s (303, 306).
  - It came from the adjacent room, and Sapience was not up yet.
  - The best fit is Weaponmastery **LUNGE** (kb abilities: "When starting from an adjacent location, you may lunge at a target... You must be wielding a sword", 3.00 s balance). The wiki text names neither the prone nor the stun, so this is a guess.
- **DSL:** the game's hit line is gagged; the system shows "Agathon: Dsl <limb> -> You". 100 blades reached Mystor's screen, about 50 DSLs:
  - 66 did damage, 25 were parried, 7 missed and 2 were absorbed by Mystor's shield.
  - Each blade that did damage left 9 bleeding.
- **Epteth** breaks an arm ("You watch, in horror, as your left arm shrivels up and becomes useless.", 1441). **Epseth** breaks a leg ("You stumble as your left leg shrivels into a useless appendage.", 1803).
  - The LEFT limb breaks first, then the right, whatever limb the DSL aims at. At 1521-1531 he aimed at the leg and both arms broke. At 3858-3869 he aimed at the right leg and the left leg broke first.
  - The limb damage still goes to the aimed limb (+6.9% per blade in Mystor's model). Past 100% that limb is damaged: "Your left leg is greatly damaged from the beating." (2032).
- **TORMENT** healthleech: "You feel your strength begin to leech away at the touch of the profane weapon." (529, 1262, 3658). It prints instead of the database's "Your health begins to drain away."
- **DEATHAURA:** "You feel sickened and weak by the aura of death emanating from Agathon." + "You take 547 magical, damage." every 7 s while in his room. 26 ticks, all 547 (14,222 in total).
- **Healthleech drain, then probably Agony:** "You take 506 unblockable, damage." + "The sanguine mist surrounding Agathon billows and writhes exultantly." (1301-1302, 3723-3724). It came only while Mystor carried torment's healthleech.
- **VIVISECT x5**, each answered by "Agathon reaches out for your chest but his hand stops short of it." (2117, 2441, 2578, 2691, 4719). Mystor never had four broken limbs.
- **TYRANNY** (2357): "Hands of rotting flesh and white bone push up from the ground." in the room (2402, still there at 5960, 108 s later). Once, "The hands of the grave grasp at your ankles and throw you off balance." (3317), for about 1 s.
- **ENGAGE:** "Agathon moves in to engage you." (362).
- **EPITOMISE:** starts with "Agathon moves with the grace of the wind, his stance the epitome of perfection beneath the flurry of blows." (3055, 5880) and ends with "Agathon no longer moves with such sublime alacrity." (3311, 6040), 8-9 s later. Sending it again while it was up printed nothing (3096, 3253).
- **TUMBLE:** 3247->3351 (SW) and 5873->5968 (NE), about 5-6 s each.
- **Wipe:** "Agathon carefully wipes all the venoms off of a Scimitar of Eagles." printed 13 times. Each was after a DSL with a parried or missed blade (810 after 755-757; 1943 after 1885-1889); other wipes were silent.

**His curing order** (Sapience plus his third-person lines):
1. **Paralysis:** magnesium at his next eat, usually 0-2 s (356, 387, 506, 610, 1606, 1727, 2646, 4408, 4484, 4588). Two exceptions:
   - After the nervestrike at 5479 he focused, sipped and touched his shield first (5509-5519, about 2 s).
   - After the one at 5544 he ate ferrum (5559) and aurum (5608) before magnesium (5660, about 5 s).
2. **Broken legs:** a leg salve within about 1 s of every flashheel (749, 804, 880, 1851, 1932, 2010, 2103, 3428, 3458, 3513, 4908, 5776, 6091). Restoration for damaged legs (2986, 4961, 5830).
3. **Slickness:** magnesium before his leg salve (3422->3428), or realgar once asthma was gone (4846, 6089).
4. **Kelp group** (aurum, usually after `outr aurum`): his most frequent eat.
5. **Impatience** (plumbum):
   - About 1 s after 1150 (1235), 3705 (3801) and 5945 (5954).
   - About 3 s after 3827 (3973).
   - 19 s after 3117 (3592).
   - Never for 5982.
6. **FOCUS MIND** right after hiru or hiraku (1335, 2165, 4189, 4290, 4624, 4922, 4992, 5108, 5436, 5509).
7. **Addiction and lethargy** (ferrum) last: jinzuku at 875 was cured only 12 s later (1308); other ferrum eats at 5559, 6019, 6072.
8. **Tree** every 14-16 s (359, 779, 1298, 1879, 2481, 2932, 3782, 4418, 4963, 5521).
9. **Rebounding** re-smoked right after his own attack drops it (525->540, 1164->1180, 5303->5322).
10. **Health** sipped at about 74-82%, often with potash (598+?, 1337+1340, 5191+5193, 5735+5737).
11. When prone he cures first and stands after (3931->3954).
12. When locked: FITNESS spam, 46 sends with 2 successes (4834, 6082). The first success was followed in one second by realgar -> epidermal -> magnesium -> quicksilver -> sip mana -> potash (4834-4857).

He never salved his arms after 10:27:32, and never writhed or clotted where Mystor could see it.

**His defences:**
- **Rebounding** (`smoke malachite`): up 12 times, 8-9 s after the smoke (1180->1559, 4319->4657). It went down 13 times, every time just as he attacked (a DSL, or even a refused VIVISECT: 2440, 4718). It never stopped one of Mystor's strikes.
- **Quicksilver fangbarrier:** "...applies a quicksilver droplet to himself." is followed 10-11 s later by "A supple metallic shell of quicksilver has formed around Agathon." (3273->3487, 4852->5245). Ruku torso's slickness stripped it three times (3084, 4553, 5727).
- **Shield tattoo:** already up at 2415, then raised at 3397 and 5515. A later touch (5601) printed nothing.
- **Cloak tattoo** (4410).
- **EPITOMISE**, whose effect is not visible here.
- **Parry:** he parried 6 of Mystor's strikes, all aimed at his torso (1497, 1499, 1770, 1773, 1775, 5541).

**His kill route against Mystor:** VIVISECT, after epteth and epseth break all four limbs. His first attempt (2116) came right after his party report claimed four limb venoms (2055). Mystor's SSC mended every break within about 1 s, one limb per application, using the tree for the second limb (1451-1508, 5689-5701), so every VIVISECT was refused. In between, the pressure was DSL damage, deathaura and bleeding. The curare + gecko pair (2491) may have been a venomlock attempt; that is a guess.

## Mystor's offense

**Forms and kata** (the game's kata line):
- Oak 12 -> Gaital 12 -> Rain 15 -> Oak 12 -> Gaital 12 -> Rain 3.
- Throw interlude, then Rain 5->12 -> Oak 12 -> Gaital 12 -> Rain 15 -> Oak 9 -> Willow 12 -> Rain 15 -> Oak 12 -> Gaital 6 -> Maelstrom 12 -> Oak 6 -> Willow 3, to the end.
- Every transition was sent as `transition to <form> form` inside the round's command before the combo (654, 1834, 3072, 4353, 4607, 5053, 5473, 5717, 5852, 6124, 6230), or in a round with no combo (923, 3574). Each went through.

**Combos per form** (the [Zax] command line). A combo has 2 or 3 strikes, at most one of them a kick. `light` gives the affliction without limb damage.

| Form | Combos | Lines | Purpose |
|---|---|---|---|
| Oak | nervestrike [light] + risingkick head/torso + ruku arm / ruku torso / kuro / livestrike [light]; SHATTER first when he is shielded | 338, 1576, 3164, 3282, 4353, 4427, 4542, 5473, 5534, 5576, 6124, 6162 | paralysis, asthma, slickness (which strips his sileris), torso damage (model 116% -> 251%) |
| Gaital | flashheel + kuro / ruku arm / ruku torso / jinzuku; ruku light once the arm model passed about 90% | 654, 731, 865, 1834, 1916, 3362, 3406, 5717, 5786 | broken leg every time it landed, weariness, clumsiness, addiction |
| Rain | frontkick (prone) + kuro / ruku arm / hiru; kickless pairs kuro light + ruku light (2411), shatter + kuro light (2425), kuro + ruku light (2460, 2557) | 989-1401, 2143, 2964, 3897-4262, 5053-5419 | prone, weariness or lethargy, clumsiness or healthleech, confusion from the prone hiru (once) |
| Willow | flashheel + hiraku light + hiru light; flashheel + hiru light x2 | 4607, 4868, 4931, 4976, 6230 | anorexia, stuttering, dizziness, with no head damage |
| Maelstrom | risingkick torso + jinzuku light / ruku torso / ruku light | 5852, 5902, 5995, 6056 | torso damage, addiction, slickness, clumsiness |

**Telepathy:** every MIND affliction was cast while locked, and with the Shield of Absorption in hand (929, 2605, 3580, 4695, 5942, 6314).

| Ability | Count | Form | Lock | Lines |
|---|---|---|---|---|
| MIND SENSE | 1 | Oak | none (target outside the area) | 146-150 |
| MIND LOCK | 3 that worked | Oak, Rain, Oak | sped up by a held mindprint | 266->296, 2248->2311, 3333->3385 |
| MIND PRINT | 1 | Oak | locked | 329 |
| MIND SAPIENCE | 3 | Rain | locked | 931, 2319, 3582 |
| MIND IMPATIENCE | 8 | Rain, Oak, Willow, Maelstrom | locked | 1150, 2608, 3117, 3705, 3827, 4698, 5945, 5982 |
| MIND PARALYSE | 8 | Rain x7, Willow | locked | 2636-2944, 4745 |
| MIND THROW NE | 1 | Rain | locked; the throw shatters the lock | 2233-2236 |
| MIND CONFUSE | 2 | Willow | locked | 4794, 6317 |
| MIND DISRUPT | 1 | Willow | locked | 6366 |

The lock was lost three times: shattered by the throw (2234), for no visible reason at 10:26:25 (3322), and at the kill (6462).

**Kai:**
- **KAI BOOST** (480): kai went 15% -> 4% across the round (467 -> 491) and no equilibrium was spent. Afterwards each incoming DSL gave +10 kai instead of +5.
- **TRANSMUTE**, sent by SSC 8 times (553, 638, 859, 1313, 1570, 2536, 3891, 4065): mana into health 1:1, with no cost in kai, balance or equilibrium.
- **KAI CHOKE x3** to finish (6399, 6424, 6444).

**Shields and rebounding:**
- SHATTER three times, each the first strike after a shield went up (2430, 3411, 5539).
- Mystor never had to deal with Agathon's rebounding. For example, 12 strikes landed while it was up from 2956 to 3462.

**How the kill was set up:**
- **First lock attempt:**
  1. A nervestrike light every Oak round kept Agathon's eat balance busy with magnesium (4359-4588), so the asthma from livestrike light stayed on him.
  2. Ruku torso added slickness (4552).
  3. The Willow hiraku added anorexia, giving a softlock at 10:26:58 (4622).
  4. IMPATIENCE, PARALYSE and CONFUSE followed (4698-4794).
  - He escaped at 10:27:05 because FITNESS went through (4834).
- **Second attempt:**
  1. Asthma and slickness put straight back on after his FITNESS and realgar (6124-6136).
  2. Kuro for weariness, and nervestrike light (6162-6172).
  3. Hiraku and hiru (6230-6241): truelock plus weariness. FITNESS then failed 7 times (6322-6381).
  4. MIND CONFUSE and MIND DISRUPT: he cannot CONCENTRATE back his equilibrium. He never tried CONCENTRATE after the disrupt; his only try was much earlier (5694).
  5. Three KAI CHOKEs took him from 87% to 3% in about 9 s. He was dead 1 s later (6467).

## Timings

| What | Value | Form / note | Lines |
|---|---|---|---|
| Combo with a kick (balance spent) | 2.1 s | Oak, Gaital, Rain, Maelstrom; the figure prints after the kick | 345, 661, 997, 1495, 5859 |
| Combo with a kick | 1.9 s | Willow | 4614, 4876, 6237 |
| Combo with no kick | no balance figure printed; arm balances back about 2 s later | Rain | 2453-2458 |
| Fumbled flashheel combo | 2.1 s, still a kata action | Oak->Gaital | 659-666 |
| Combo bounced off a magical shield | no balance; 1.44 s of equilibrium | Rain | 2415-2418 |
| MIND SAPIENCE (eq) | 2.89 s (recovered in 2.93-3.0) | Rain; the wiki says 4.00 | 932, 2320, 3583 |
| MIND IMPATIENCE (eq) | 1.07 s in Rain; 1.27 s in Oak, Willow and Maelstrom | wiki 1.50 | 1148, 3115, 4696, 5943 |
| MIND PARALYSE (eq) | 1.44 s in Rain; 1.70 s in Willow | wiki 2.00 | 2634, 4743 |
| MIND CONFUSE / DISRUPT (eq) | 1.70 / 3.40 s | Willow; wiki 2.00 / 4.00 | 4792, 6315, 6367 |
| MIND THROW (eq) | 2.16 s; it also needs balance | Rain; wiki 3.00 | 2230 |
| DIAGNOSE (eq) | 0.72 s | Rain; AB 1.00 | 2354 |
| KAI CHOKE (eq) | 3.40 s (recovered in 3.34-3.42) | Willow; wiki 4.00 | 6400, 6425, 6445 |
| Rule that fits every reading | Rain about 0.72 x the wiki; every other form about 0.85 x | | |
| KAI BOOST, TRANSMUTE, MIND LOCK, PRINT, SENSE | no equilibrium spent | | 491, 554, 268, 330, 148 |
| MIND LOCK with a held mindprint | about 2.5-3 s to finish | | 266->296, 2248->2311, 3333->3385 |
| MIND SENSE until "You may seek out another mind." | about 4 s | | 146->150 |
| Eat (herb/mineral) | 1.44-1.61 s | | 436, 1111, 4104 |
| Salve: mending / restoration | 0.81-1.06 s / 3.97-4.04 s | | 1479, 2276, 4896 |
| Sip | 4.29-4.49 s | | 427, 1650, 5887 |
| Moss / potash | 5.87-6.01 s | | 502, 1347 |
| Tree | 13.91-14.05 s | | 845, 4180, 6037 |
| Restoration on a damaged leg, applied to cured | about 4 s; the leg is then still broken and needs mending | | 2128->2273->2283 |
| Kai gain | +5 per incoming DSL, +10 after KAI BOOST, parried DSLs included; none from deathaura, ENGAGE or Mystor's own strikes | | 286, 402, 536, 908 |
| Kai decay | -5 about every 30 s | | 1125, 2321, 3060, 4021, 5275, 6106 |
| Opener stun / prone | about 1 s / about 2 s | | 303-306, 283->311 |
| Agathon: DSL cadence | about 2.0-2.2 s when free to act | | 392-694, 4302 |
| Agathon: deathaura | every 7 s | | 26 ticks |
| Agathon: malachite to rebounding up | 8-9 s | Our trigger curing_bals/009 assumes 8.0 s | 1180->1559, 4319->4657 |
| Agathon: quicksilver to shell formed | 10-11 s | | 3273->3487, 4852->5245 |
| Agathon: tree to tree | 14-16 s | | 359->779, 4963->5521 |
| Agathon: standing after a frontkick | 1-2 s; about 5 s with a broken leg (he mends first) | | 3954, 5079-5128 |
| Agathon: EPITOMISE / tumble | 8-9 s / 5-6 s | | 3055->3311, 5873->5968 |

**DSL damage per blade:**

| Damage | Hits | When |
|---|---|---|
| 370 | 4 | Mystor in Willow |
| 356 | 13 | Rain, staff |
| 353 | 14 | Oak |
| 342 | 2 | Gaital |
| 334 | 12 | Rain, Shield of Absorption wielded |
| 284 | 8 | Rain, Agathon weary (model) |
| 281 | 4 | Oak, Agathon weary |
| 273 | 9 | Gaital, Agathon weary |

The weary values are 0.80 x the others in every form.

## Game lines

**Marks:**
- **NEW:** not in any curated kb page (anything under `kb/` except `kb/raw/`).
- **NEW (raw):** only in `kb/raw` evidence.
- **known:** already curated.
- **NEW?:** the chunk reader's mark, not rechecked.

**Not listed (system lines, not game text):**
- prompts, `[Zax]:`, `[Curing]:`, the `[... Recov/Spent]` timings, `You: ...`, `Agathon: Dsl ...`, `My <limb>`, ASSESS bars, banners, `--> Agathon:`;
- every `pt ...` line, including **`pt Intercepted ...`**, which is Mystor's own outgoing relay (19 relays; all 99 of his pt sends were refused with "You are not the member of any party."). This corrects GUIDE.md.

**Hidden by the logger** (gagged, so still not captured): Mystor's strike and damage lines, the form lines, the Telepathy success lines, the transmute line, the ASSESS line, Agathon's DSL hit lines, and the lock start, finish and lost lines.

**Our attacks and effects**

| Line | Text | Mark |
|---|---|---|
| 342 | Horror overcomes the face of Agathon as his body locks in paralysis. | **NEW** (nervestrike, light ones included; 13 of 13) |
| 344 | Your foot catches Agathon under the chin, snapping his head back. | known |
| 3171 | Your foot drives into the solar plexus of Agathon. | known |
| 347 | The staff cracks across the right thigh of Agathon. | known |
| 381 | The staff connects to the left arm with a resounding crack, the limb flopping uselessly. | known |
| 3083 | Agathon staggers as the staff cracks across his ribs, sweat breaking out upon his forehead. | known |
| 3081 | The breath of Agathon leaves him in an explosive gasp as the end of the staff smashes home. | known |
| 736 | You feel the satisfying crunch of bone under the impact of your heel. | known |
| 875 | The end of the staff drives viciously into the kidneys of Agathon. | known |
| 996 | The instep of your foot smashes into the left underarm of Agathon, throwing him from his feet and sending him spinning to the ground. | known |
| 1329 | The staff connects to the side of Agathon's head with a resounding crack. | known |
| 4616 | The staff smashes into the face of Agathon with a sickening crunch. | known |
| 2430 | The end of your staff smashes the magical shield surrounding Agathon in an explosion of translucent shards. | known |
| 660 | You fumble your strike, the attack going wide. | known |
| 2415 | A dizzying beam of energy strikes you as your attack rebounds off of Agathon's shield. | NEW |
| 3084 | The protective coating covering the skin of Agathon sloughs off. | NEW (raw) |
| 5428 | Agathon looks about bemusedly. | NEW (hiru on a prone target) |
| 5485 | Vacancy fills the eyes of Agathon. | NEW |
| 1497 | Agathon parries the attack with a deft manoeuvre. | known |

**Kata, form, limb balance and wield**

| Line | Text | Mark |
|---|---|---|
| 348 | You are now maintaining a kata chain of 3 actions. | known (the `[Oak]: ` prefix is the system's) |
| 367 | You have recovered balance on your legs. | NEW (raw) |
| 368 | You have recovered balance on your right arm. | NEW (raw) |
| 369 | You have recovered balance on your left arm. | NEW (raw) |
| 3343 | You have recovered balance on all limbs. | NEW (raw) |
| 986 | You have recovered equilibrium. | NEW (raw) |
| 928 | You cease to wield a twisted oaken staff. | NEW |
| 929 | You start to wield a Shield of Absorption in your right hand. | NEW |
| 993 | You cease wielding a Shield of Absorption in your right hand. | NEW |
| 994 | You start to wield a twisted oaken staff in your hands. | NEW |
| 3776 | You must have both hands available to wield a two-handed item. | NEW |
| 3777 | You may not carry out a combination utilising Shikudo strikes without the required staff. | NEW |

**Kai**

| Line | Text | Mark |
|---|---|---|
| 480 | You gather up and expend your Kai energy to enhance your sensitivity to its energies. | NEW |
| 6444 | Agathon gasps and stumbles as an unseen force crushes the life breath out of him. | NEW (in code: highlighting/063) |
| 288 | You will no longer use kaido transmute. | NEW |
| 322 | You will now use kaido transmute when you can. | NEW? |

**Telepathy and alerts**

| Line | Text | Mark |
|---|---|---|
| 147 | You seek out the mind of Agathon and an image of Parapet atop the Tower of the Daegger appears in your mind. | known (the trailing "(8195) (Coloseum Diabolus)" is probably the mapper's) |
| 150 | You may seek out another mind. | NEW |
| 267 | Your mindlock is speeded by the mindprint you hold. | NEW |
| 2255 | You must cease your current lock attempt before trying another. | NEW |
| 2159 | You must regain balance first. | NEW |
| 2234 | Your mindlock with Agathon shatters! | NEW |
| 2235 | Agathon jerks violently northeast. | NEW |
| 2240 | You require a mindlock to perform that ability. | NEW |
| 252 | Mindnet: Agathon has entered the area. | NEW |
| 6470 | Mindnet: Agathon has left the area. | NEW |
| 281 | Alertness: Agathon has entered Dryad's gibbet at your location. | NEW |
| 2236 | Alertness: Agathon has entered Dismal bracken, to the northeast. | NEW |

**Opponent attacks and effects**

| Line | Text | Mark |
|---|---|---|
| 280 | Agathon charges in, sword flashing at the ready. | NEW |
| 282 | You writhe and scream as he drives the cruel blade deep into your side. | NEW |
| 284 | You take 2220 physical cutting, damage. | NEW (this damage-line format is in no kb page) |
| 332 | You feel sickened and weak by the aura of death emanating from Agathon. | NEW |
| 333 | You take 547 magical, damage. | NEW |
| 755 | Agathon misses you with a Scimitar of Eagles. | known |
| 362 | Agathon moves in to engage you. | NEW (raw) |
| 810 | Agathon carefully wipes all the venoms off of a Scimitar of Eagles. | NEW |
| 2117 | Agathon reaches out for your chest but his hand stops short of it. | NEW |
| 1301 | You take 506 unblockable, damage. | NEW |
| 1302 | The sanguine mist surrounding Agathon billows and writhes exultantly. | NEW |
| 3317 | The hands of the grave grasp at your ankles and throw you off balance. | NEW |
| 2402 | Hands of rotting flesh and white bone push up from the ground. | NEW (in code: highlighting/007) |
| 2402-2403 | Khovroth Agathon, Wolf of Baelgrim is here. He wields a Scimitar of Eagles in each hand. | NEW? |
| 3608 | Your shield completely absorbs the damage. | known |

**Afflictions landing on Mystor**

| Line | Text | Mark |
|---|---|---|
| 283 | You have been afflicted with prone. | NEW (73 times; see Unclear) |
| 396 | You gasp as your fine-tuned reflexes disappear into a haze of confusion. | known |
| 401 | A prickly stinging overcomes your body, fading away into numbness. | known |
| 529 | You feel your strength begin to leech away at the touch of the profane weapon. | NEW |
| 816 | A sense of extreme nausea washes over you. | known |
| 2501 | The protective covering coating your skin sloughs off. | NEW (raw) |
| 2502 | You notice that your sweat glands have begun to rapidly secrete a foul, oily substance. | known |
| 1441 | You watch, in horror, as your left arm shrivels up and becomes useless. | NEW |
| 1803 | You stumble as your left leg shrivels into a useless appendage. | NEW |
| 2032 | Your left leg is greatly damaged from the beating. | known |
| 292 | You take 73 raw, damage. | NEW |
| 293 | You bleed 73 health. | NEW (raw) |
| 303 | You are too stunned to be able to do anything. | NEW |
| 306 | You are no longer stunned. | known |
| 2084 | Both of your legs must be free and unhindered to do that. | NEW |
| 3698 | You are paralysed and are unable to drop anything. | NEW |
| 3699 | Paralysed as you are, your body is not able to pick up anything. | NEW |
| 3701 | You are paralysed and unable to do that. | NEW |

**Mystor's cures**

| Line | Text | Mark |
|---|---|---|
| 311 | You stand up. | known |
| 313 | You clot your wounds 4 times. | NEW |
| 413 | You exert superior mental control and your wounds clot before your eyes. | NEW (in code: 709) |
| 315 | You take a drink from an amethyst vial. | NEW |
| 316 | The elixir heals and soothes you. | known |
| 597 | Your mind feels stronger and more alert. | NEW (raw) |
| 318 | You eat a potash crystal. | NEW |
| 319 | You feel your health and mana replenished. | NEW (raw) |
| 409 | You eat a magnesium chip. | NEW |
| 410 | Your muscles unlock; you are no longer paralysed. | known |
| 411 | You have cured the paralysis affliction. | NEW (72 times; see Unclear) |
| 421 | You touch the tree of life tattoo. | NEW (raw) |
| 422 | Thank Maya, the Great Mother! Your clumsiness has been cured. | known (database template) |
| 515 | You eat an aurum flake. | NEW (raw) |
| 608 | Your aching, pain-wracked body is soothed and calmed. | known |
| 851 | Your stomach becalms itself. | known |
| 2509 | Your glands cease their oily secretion. | known |
| 1452 | You take out some salve and quickly rub it on your arms. | NEW (raw) |
| 1453 | The bones in your left arm mend. | known |
| 2273 | Your left leg feels stronger and healthier. | known |
| 2555 | You apply a quicksilver droplet to yourself. | NEW? |
| 2818 | The quicksilver hardens into a supple metallic shell. | NEW (raw) |
| 340 | You will now attempt to parry attacks to your torso. | NEW (raw) |
| 757 | You parry the attack with a deft manoeuvre. | NEW (raw) |
| 435 | You may eat another plant or mineral. | NEW (raw) |
| 1478 | You may apply another salve to yourself. | NEW (raw) |
| 426 | You may drink another health or mana elixir. | NEW (raw) |
| 502 | You may eat another bit of irid moss or potash. | NEW (raw) |
| 844 | You may utilise the tree tattoo again. | NEW (raw) |

**The opponent's cure and defence lines (third person)**

| Line | Text | Mark |
|---|---|---|
| 356 | Agathon eats a magnesium chip. | NEW (raw) |
| 439 | Agathon eats an aurum flake. | known |
| 1235 | Agathon eats a plumbum flake. | NEW |
| 1308 | Agathon eats a ferrum flake. | NEW (raw) |
| 1340 | Agathon eats a potash crystal. | NEW (raw) |
| 598 | Agathon takes a drink from an oaken vial. | NEW (prints for sip health and sip mana alike) |
| 749 | Agathon takes some salve from a vial and rubs it on his legs. | NEW (raw) (mending and restoration print the same line) |
| 3154 | Agathon takes some salve from a vial and rubs it on his arms. | NEW (mending and restoration print the same line) |
| 4848 | Agathon takes some salve from a vial and rubs it on his body. | NEW (raw) (epidermal 4847, restoration 5614) |
| 3273 | Agathon applies a quicksilver droplet to himself. | NEW (raw) |
| 3487 | A supple metallic shell of quicksilver has formed around Agathon. | NEW (raw) |
| 359 | Agathon touches a tree of life tattoo. | NEW (raw) |
| 4410 | Agathon touches a cloak tattoo. | NEW (raw) |
| 3397 | A nearly invisible magical shield forms around Agathon. | known |
| 540 | Agathon takes a long drag off an enamel bubble pipe. | NEW (smoke malachite) |
| 1181 | A great gurgling sound is heard as Agathon takes a long drag from an enamel bubble pipe. A series of shining bubbles erupt from the bowl of his pipe. | NEW (smoke malachite) |
| 1343 | The bubbles spewn from an enamel bubble pipe burst. *POP*  *POP*   *POP* | NEW |
| 4846 | Agathon takes a long drag off his pipe. | NEW (raw) (smoke realgar) |
| 463 | You suddenly perceive the vague outline of an aura of rebounding around Agathon. | NEW (raw) |
| 525 | Agathon's aura of weapons rebounding disappears. | NEW (raw) |
| 1335 | A look of extreme focus crosses the face of Agathon. | known |
| 4834 | Agathon draws a deep, measured breath. | known |
| 1020 | Agathon stands up. | NEW (raw) |
| 3055 | Agathon moves with the grace of the wind, his stance the epitome of perfection beneath the flurry of blows. | NEW (in code: 703) |
| 3311 | Agathon no longer moves with such sublime alacrity. | NEW |
| 3247 | Agathon begins to tumble towards the southwest. | NEW (raw) |
| 3351 | Agathon tumbles in from the northeast. | NEW |
| 2622 | Agathon peers about himself dubiously. | NEW |
| 1090 | Comprehension flashes across Agathon's face. | NEW |

**Arena, death and other**

| Line | Text | Mark |
|---|---|---|
| 1 | Your target is now: Agathon (an adventurer) | NEW (raw) |
| 251 | The face of Agathon appears in the mirror, warping as he steps through it. | NEW |
| 257 | Agathon leaves to the north. | NEW (raw) |
| 71 | Now now, don't be so hasty! | NEW |
| 81 | There is no exit in that direction. | NEW (raw) |
| 337 | You have no sanity. | NEW (every round; see Unclear) |
| 372 | You hold no "bomb". | NEW |
| 339 | You are not fallen or kneeling. | NEW |
| 270 | You are not the member of any party. | NEW |
| 3809 | You may not assess someone again so soon after doing so previously. | NEW |
| 6450 | Your mouth turns up as your face breaks into a smile. | NEW |
| 6467 | You have slain Agathon. | NEW (raw) |
| 6468 | With the completion of your adventure, you feel your renown grow to new heights! (You gain 150 Renown.) | NEW? |
| 6469 | Defeated, Agathon is cast out of the Arena. | NEW (raw) |
| 6472 | You have been victorious and leave the Arena in triumph! | NEW (raw) |
| 6477 | The Arena is once again open for combat. | NEW |

## Answers to the open questions

1. **Telepathy without a lock.**
   - MIND SENSE worked without a lock, on a target outside the arena area. It spent no equilibrium and is usable again about 4 s later (146-150).
   - MIND THROW was refused without a lock ("You require a mindlock to perform that ability.", 2240, 2261), but Agathon was in another room at the time, so this fits Mystor's rule (lock needed out of room).
   - Every in-room MIND affliction (IMPATIENCE x8, PARALYSE x8, CONFUSE x2, DISRUPT x1), plus SAPIENCE x3 and THROW, went out while locked. **Mystor's claim that a lock is needed only out of room is neither confirmed nor refuted.**
   - New facts about the lock and the abilities:
     - MIND LOCK starts on a target one room away (264-296) and on a target thrown into another room (2248-2311). It takes about 2.5-3 s with a mindprint.
     - A second MIND LOCK during an attempt is refused (2255, 3367).
     - MIND THROW needs balance as well as the lock. It was refused 12 times, even after the left arm's balance had come back (2205, 2208). It costs 2.16 s of equilibrium and 100 mana, and it breaks the lock (2234).
     - Sapience stops when the lock is lost and has to be cast again (no `-->` lines from 2234 to 2341, or from 3322 to 3590).
     - Sapience shows commands from another room (5964).
2. **Blackout.**
   - There is no MIND BLACKOUT and no "blackout" text anywhere in the log.
   - New: "Vacancy fills the eyes of Agathon." printed twice, after livestrike in an Oak combo that had a risingkick to the torso earlier (5480-5485, 5581-5585). Both times his torso was 150-159% in Mystor's model. Mystor's system then marks the target BLCK for 4 s (5490), and Agathon sent DIAGNOSE six times after the second one (5596-5604).
   - This may be the same event as log 2's "[AFF]: Blackout", which kb/combat/shikudo.md places in an Oak round with nervestrike and livestrike and blames on MIND BLACKOUT. Unproven.
3. **Kata limits and stumbles.**
   - No stumble, rhythm, "kata of at least" or ADOPT line (0 hits for each).
   - Highest kata: Rain 15 (three times: 1412, 4273, 5431); Oak, Gaital, Willow and Maelstrom 12.
   - Transitions went through at 6 (5852, 6230), 9 (4607), 12 and 15.
   - MIND and KAI rounds add no kata (Willow stayed at 3 through confuse, disrupt and three chokes, 6242-6447; Maelstrom 6 -> 7 across two impatience rounds, 5913-6002).
   - The chain did not decay over 12-14 s without strikes.
   - A fumbled kick (666), parried strikes (1500, 1776) and SHATTER (2433) all count.
   - The system's "Kata is N" tag can be one behind the game's line (5544 vs 5545).
4. **Kai Surge / Choke cost.**
   - SURGE was not used.
   - KAI CHOKE on an adventurer costs 10 kai (95->85->75->65%, ending at 6447) and 3.40 s of equilibrium in Willow.
   - The three chokes took 2469, 2105 and 1533 health by ASSESS, net of his regeneration. His torso was 234-251% in Mystor's model.
   - KAI BOOST: 15% -> 4%, no equilibrium.
5. **Dawnkick's epilepsy line.** There was no dawnkick in this fight (0 hits). Still open.
6. **Light, parried and absorbed strikes.**
   - **Light strikes** print their effect line but no damage line; the system's line then shows no limb %. This held for nervestrike light (3286-3287), livestrike light, hiraku light, hiru light, kuro light and ruku light.
   - **Parried strikes** print "Agathon parries the attack with a deft manoeuvre." with no effect line, still cost 2.1 s of balance and still count as kata. A kick can be parried (1770, 5541).
   - **Fumbled:** "You fumble your strike, the attack going wide." on a flashheel while Mystor was clumsy (660).
   - **Absorbed:** none of Mystor's strikes. Mystor's own Shield of Absorption fully absorbed 2 DSL blades ("Your shield completely absorbs the damage.", 3608, 3867), and **the venom still landed** (paralysis 3609, broken right leg 3868), with no bleeding from that blade. This confirms the absorbed-blow half of CONFLICTS #6, from the defender's side.
   - **Shielded target:** the whole combo prints only the beam line, costs 1.44 s of equilibrium and no balance, and adds no kata (2415-2418).
7. **Prone extras.**
   - Hiru on a prone target gave confusion once in five: "Agathon looks about bemusedly." (5428). The other four printed nothing extra (1329, 2152, 4174, 4272). This settles the hiru half of CONFLICTS #4: confusion is a chance.
   - Risingkick to the head of a prone target printed only its usual line, with no stun line (3078).
   - No hiraku hit a prone target (4616, 4939, 4984 and 6239 were all on a standing target).
8. **Shields and rebounding.**
   - SHATTER, as the first strike of the next combo, broke each shield (2430, 3411, 5539) and counts as a kata action.
   - Agathon's rebounding never reflected a staff strike or a kick. For example, the aura stood from 2956 to 3462 while 12 of Mystor's strikes landed.
   - Rebounding drops on its owner's own attack, 13 of 13 times, a refused VIVISECT included.
   - Ruku torso's slickness strips a formed quicksilver shell (3084, 4553, 5727). Gecko's slickness stripped Mystor's own (2501).

## Lessons for our package

**For our Shikudo offense** (docs/plans/shikudo-offense-review-2026-10-11.md):
1. **Record nervestrike from its effect line.** "Horror overcomes the face of <T> as his body locks in paralysis." followed every nervestrike, 13 of 13, the 7 light ones included.
   - No trigger matches it: 420_Paralysis matches "...'s face as \w+ body stiffens into paralysis."
   - Add it to the gated effect-line group. That closes the nervestrike half of CONFLICTS #6.
   - Correct kb/combat/shikudo.md:85 ("none on the attacker's side") and :296.
   - Ruku to the arm still names no target (381); only the gated window can attribute it.
2. **The kill template that worked:**
   - livestrike for asthma, ruku torso for slickness, hiraku for anorexia, nervestrike for paralysis and MIND IMPATIENCE;
   - plus **kuro's weariness**: FITNESS broke the first lock when weariness was low (4834) and failed 7 times once kuro had just landed (6170, 6322-6381);
   - then MIND CONFUSE + MIND DISRUPT, then KAI CHOKE (10 kai, 3.4 s of equilibrium each).
   - A nervestrike light every Oak round kept his eat balance on magnesium, which is why the livestrike asthma stuck (4359-4622).
3. **Against DSL knights, ruku both arms to 100%.** After 5794-5796 none of his 21 DSL sends printed anything (likely the arms; see Unclear). Weariness also cut his blade damage by 20%.
4. **MIND THROW** needs balance and a lock, breaks the lock and ends Sapience. Re-lock (about 2.5 s with a held mindprint) and recast Sapience after it.
5. **Shield swap risk.** Swapping the staff out for the shield on Telepathy rounds is dangerous against epteth: a broken arm blocks re-wielding the two-handed staff, and three rounds were lost (3776-3808). SSC mended the leg before that arm (3752 before 3833).
   - Mend arms first when the staff is out of hand, or skip the swap.
6. **Plan Telepathy in Rain** (0.72 x equilibrium). A queued round waits for both balance and equilibrium, so a MIND round delays the next combo by its equilibrium (4865).
7. **Rebounding needs no handling for Shikudo.** A magical shield does: lead with SHATTER as soon as the shield line prints, or the round's equilibrium is lost to the beam (2415).
8. **Parry the limb the knight is aiming at.** All 25 of Mystor's parries came when his parry matched the aimed limb; Agathon aimed at the left leg or left arm almost always.
9. **The "Vacancy" line** is a candidate for blackout from the Oak combo. Keep it pending more evidence before recording it.

**For our defence against this class:**
1. **Epteth and epseth** break the left limb first, then the right, whatever the aim. Each is cured by one mending application (salve balance 0.8-1.0 s) or by the tree.
   - .claude/classes/infernal.md is wrong on both points (it says a single restoration cures it, and that it lands on the opposite limb).
   - The dossier also calls FITNESS passive; it is a typed command (46 sends).
2. **The VIVISECT refusal line** ("...reaches out for your chest but his hand stops short of it.") means he believes four limbs are down. Mending within 1 s, as Mystor's SSC did, beat all five attempts.
3. **Trigger 345_Broken_Legs_Block** says "one broken leg does not trip this". The line printed in the STAND slot with ONE broken or damaged leg 10 times out of 10 (2084, 3899, 4166, 4692...), and kicks still worked. 345 and swarm 009's legOut therefore misread it.
4. **highlighting/027_Parry_Success** matches only the PvE "You parry the assault to your <limb>...". The PvP "You parry the attack with a deft manoeuvre." appears only in slc/001_functions.lua:254 and in missLines (_groups.yaml:268), so ataxia_parrySuccess is never fed in PvP.
5. **703_Epitome** uses a 6 s timer, but EPITOMISE lasted 8-9 s, and no trigger matches the end line ("...no longer moves with such sublime alacrity.").
6. **The pipe triggers miss this opponent.** 215, 278 and curing_bals/009 use `takes a long drag off \w+ pipe`, which misses "off an enamel bubble pipe" and the "drag from" variant; only 390 catches them. The 8 s "rebounding coming up" timer (009) never arms against this player.
7. **DEATHAURA** ("sickened and weak by the aura of death", a flat 547 every 7 s) is a free Infernal identifier and a fixed number for the danger model; no trigger knows it. TORMENT's healthleech brings 506 unblockable and probably an Agony cure for him, so cure it fast.

**For tracking this class's cures:**
1. **Ambiguous third-person lines:**
   - the legs line for mending and restoration (2986 vs 3128);
   - the arms line for mending and restoration (3271 vs 3308);
   - the body line for epidermal and restoration (4847 vs 5614);
   - the oaken vial for sip health and sip mana (1336 vs 4853);
   - two pipe lines: "off his pipe" (realgar, 4846) and the enamel pipe in two wordings (malachite, 540 / 1181).
   - These should branch in V3, not resolve.
2. **Minerals:** magnesium = paralysis or slickness, aurum = the kelp group, plumbum = goldenseal, ferrum = ginseng, potash = moss. OUTR prints nothing.
3. **Silence:** paralysis stops his DSL with no line at all (1697-1722, 2848-2894). An attack from him is evidence he is not paralysed; silence is not evidence of anything.
4. **The wipe line** means his previous DSL left venom on a blade (a blade was parried or missed), so that venom did not land.
5. **The sanguine mist** (only after his healthleech drains) is probably a random cure on him; branch it, as Mystor's system did (1303).
6. **The FITNESS line** cures asthma. passive_active/007 also removes weariness on it, which holds only if weariness blocks FITNESS.

## Unclear or unverified

- **The kill blow.** No killing line is visible: the third choke left him at 249/7281 (6446), and he died 1 s later (6467). A healthleech tick is a guess.
- **"Vacancy fills the eyes of <T>."** Blackout, stun or something else? Its trigger condition is not settled.
- **Why 21 DSL sends printed nothing** at 10:27:32-33 and 10:27:42-43, when he was not paralysed in Mystor's model. Broken arms are the likely cause; lack of balance is not excluded.
- **Why FITNESS failed 44 of 46 times.** It worked 4 s after a VIVISECT (4717 -> 4834), which fits VIVISECT costing 4 s of balance (the dossier) rather than equilibrium (the wiki). That is a guess.
- **Whether the second MIND IMPATIENCE (5982) landed.** He never ate plumbum afterwards.
- **The lock loss at 3322 (10:26:25).** No cause is visible: the gravehands throw was in the same second (3317), and the 15-second break chance is the other candidate.
- **The opener ability.** LUNGE is a guess; the wiki does not explain the prone or the stun.
- **The unseen nausea venom** at 812.
- **Per-form DSL damage** (Willow 370, Rain 356, Oak 353, Gaital 342) and 334 with the shield wielded: correlations only. The 0.8 x factor matches weariness (database: weariness "decreases damage from cutting or blunt attacks").
- **Mana per MIND ability.** It cannot be split from the round:
  - IMPATIENCE, PARALYSE and DISRUPT rounds read -132, CONFUSE -199, SAPIENCE -399, combo rounds -66 (2418: -66 with only the bounced combo and the assess).
  - 66-mana drops also occur with no action (4721).
  - The only clean readings: CLOT -40, MIND THROW -100, lock finish -30.
- **EPITOMISE's effect and skill.** It is not in the Weaponmastery, Oppression or Malignity lists we have.
- **The quicksilver failures.** His 10 failed applications (3132-3204) are probably due to broken arms, since the first application after mending his arms worked (3270-3273). His application at 5778 never printed a shell line, and five more at 6092-6119 printed nothing.
- **"You have been afflicted with <aff>." / "You have cured the <aff> affliction."** These are game text per GUIDE.md, but they are absent from both raw logs from other clients, so probably a per-player game option. The same doubt applies to the "You take N <type>, damage." format, while our trigger 351 expects "Health lost: N (type).".
- **"You have no sanity."** prints every round before the [Zax] line; the command is unknown.
- **'You hold no "bomb".'** is probably a DROP: while paralysed it became "unable to drop anything" (3698). Two GET-type commands are silent normally (3699-3700).
- **The [Zax] round line does not prove what ran.** In round 1 it read "parry left arm/mind lock .../ruku left", but the game parried the torso (340) and struck kuro right (346-347). Whether it echoes an alias definition or the queued command is unknown.
- **"Doubleaff"** (system tag). In this log every kuro at kata 12+ (579, 1409, 2976, 4270, 5430, 5640) and every ruku to the arm at kata 11+ (1411, 2092, 2974, 3508, 4172, 5364, 6066) carries it. Kuro at kata 11 never does (873, 1327, 2090, 3506, 5362), nor does any of the 52 kuro/arm-ruku strikes at kata 10 or less. No game line shows the second affliction.
- **Unexplained prompt changes:** +200h/-100m ticks about every 6 s (probably Kaido regeneration), +313h ticks with kai dips to 95%, and Agathon's +364 health with no sip.
- **Unknown prompt fields:** `(n)`, `[CDBK]`, `[30.31]`.
- **The paralysis priority toggles** 25/5 by Mystor's system.
- **Whether "Alertness:" and "Mindnet:" lines** are the game's own format or the logger's.
- **Head damage to Agathon** read half of what the same strikes did to Claes in log 1 (nervestrike +6.1% vs 12.3%, risingkick +4.2% vs 8.4%). A chunk reader saw the same figures in two of the game's damage lines in log LcJC-rJ5 (737, 740); not rechecked here.
