# Mystor (Shikudo) vs Agathon (Infernal, two scimitars): won with KAI CHOKE

> Source: `kb/raw/logs/2026-10-11_mystor_shikudo-vs-infernal-dwc_win_vNTjvghY.txt` (Mystor's own log; how to read his client's output: `kb/raw/logs/README.md`). Every line number below is a line of that file.
> Written 2026-10-11 from a line-by-line reading: one agent per ~800-line chunk, merged by a further agent that checked doubtful claims against the log. Confidence: LOG for what the lines show; the readers' own "likely" and "guess" marks are kept. Not yet independently re-verified.

# Fight report: Mystor (Shikudo) vs Agathon (Infernal DSL), 2026-10-11, log s_vNTjvghY

**How this was written.** I merged the 11 chunk reports and checked doubtful or conflicting claims against `log.txt` with targeted greps:
- the lock and Telepathy timeline
- rooms
- the rebounding cycle
- infestation ticks
- counts of DSL outcomes
- the limb state in the two four-limb windows
- the kill lines

I also checked the "NEW" marks against the knowledge base and ran a few code greps. Line numbers refer to `log.txt`. "Model" means the target-affliction list that Mystor's own system prints. It is a hint, not game evidence.

## Fight

- **Who.**
  - **Mystor** is a Monk on Shikudo. He fights with "a twisted oaken staff", which needs both hands. For his Telepathy rounds he swaps it for "a Shield of Absorption". He has 6265 health and 5839 mana.
  - **Khovroth Agathon, Wolf of Baelgrim** (line 35) has 7281 health by ASSESS.
- **The opponent is an Infernal (Knight) with the DSL spec. This is confirmed.**
  - He wields "a Scimitar of Eagles in each hand" (35), ids `scimitar388622` and `scimitar314077`, and sends `dsl Mystor <limb> <item> <item>`.
  - He uses TYRANNY (123, 208-210), SUMMON INFESTATION (254-256), DEATHAURA ticks (295), the Hellforge investments TORMENT (577) and TORTURE (6045) in a DSL venom slot, QUASH (7006) and VIVISECT (2946-2948).
  - The likely Agony passive shows at 609-610.
  - All of these are Oppression abilities in `kb/classes/infernal.md:157-228`.
  - He also sends MASTERY, and draws `shield685283` for QUASH (6999-7005).
  - EPITOMISE (4113) is not in `infernal.md`, so where it comes from is unknown.
- **Result: Mystor won with two KAI CHOKEs.**
  - The first choke took Agathon from 3063 to 847 health (8923 to 8963).
  - The second (9020-9021) was followed by "Agathon collapses to the ground, his life snuffed out like a candle." and "You have slain Agathon." (9028-9029).
- **Duration.**
  - The log runs 10:37:57-10:42:51, 4 min 54 s.
  - First contact was 10:38:10 (35) and the first strike 10:38:31 (185), so the fighting lasted about 4 min 20 s.
  - Mystor never fell below 73% health (`H:4588|73%`, 1393).
  - Agathon's last landed attack was at 10:41:38 (7400), 73 s before he died.
- **Where.** The Colosseum Diabolus arena.
  - Mystor entered with SAY INVIDIA at the mirror in Corroded meadow (19, 24-31).
  - The rooms were Portal tower (32), Fallen passageway (71), Webbed passage (76) and Collapsed passage (134).
  - **Webbed passage**, 171-5935 (10:38:30-10:40:58). He left it once, to Fallen passageway at 4265-4409.
  - **Fallen passageway**, 5981-7769 (10:41:05-10:41:48).
  - **Portal tower**, 7785 to the kill.
  - The fight ended in "Colosseum Diabolus staging grounds" (9036).

## How it went

1. **Lock and Sapience before contact (10:37:57-10:38:31, lines 1-176).**
   - MIND PRINT and MIND SAPIENCE were refused: "You require a mindlock to perform that ability." (9-11, 44-46, 81-83).
   - Mystor went through the mirror (24-31). In Portal tower, gravehands already in the room threw him off balance for 1.0 s (40-41). Agathon was there (35) with rebounding already up (60).
   - The lock started at 10:38:10 (51). Delve lines followed at 10:38:14, :18 and :22 (93, 96, 99). The lock finished after the :22 prompt (102), about 12-16 s in all, while both men changed rooms.
   - MIND PRINT and MIND SAPIENCE then went through on Agathon in another room (109-112).
   - Sapience showed his out-of-sight TYRANNY in Collapsed passage (123).
2. **Oak, kata 1-12 (10:38:31-10:38:39, 177-411), in Webbed passage.** Four rounds of nervestrike + risingkick head + ruku/kuro.
   - Agathon ate magnesium after every nervestrike (201, 240, 300, 366) and touched the tree (205).
   - He cast TYRANNY in the room (209-210). Mystor was **not** proned: "You are not fallen or kneeling." (222).
   - He summoned INFESTATION (256), which dropped his own rebounding (255). He took one DEATHAURA tick (295).
   - His DSL alias did nothing while he was paralysed (328-362). It landed only after his magnesium (374-384).
3. **Gaital, kata 1-12 (10:38:39-10:38:48, 412-711).** Flashheel right every round, plus ruku, kuro or jinzuku.
   - Agathon applied mending to his legs after each flashheel (435, 472, 550). He sent DSL xentio/curare, torment/curare (healthleech, 577) and euphorbia/curare.
   - The first infestation tick came at 541. The likely Agony fired at 609-610 (506 unblockable damage plus "sanguine mist").
   - A fumbled flashheel (640) still counted toward the kata.
4. **Rain, kata 0-15 (10:38:48-10:39:10, 712-1545).**
   - WIELD SHIELD plus MIND DISRUPT (723), then four frontkick/kuro/ruku combos and three more DISRUPTs (1027, 1305, 1419). Each disrupt was cured with CONCENTRATE within a second (732, 1035, 1327, 1429).
   - DSL epteth/epseth broke Mystor's left arm and left leg (774, 779).
   - Mystor parried 6 DSL blows (1257-1528). His kai rose from 45% to 100%.
5. **Oak, then Gaital (10:39:10-10:39:30, 1546-2388).**
   - Oak to kata 12 (1909). Gaital to kata 12 (2264).
   - Ruku torso sloughed Agathon's fangbarrier (2020). He reapplied quicksilver (2053).
   - Needle crushed his throat, and he applied mending to his head (2263, 2322-2323).
   - DSL epteth/epteth broke both of Mystor's arms (2366, 2371).
   - Agathon was back to 100% by 2398.
6. **Rain with broken arms, Telepathy (10:39:30-10:39:48, 2389-3210).**
   - WIELD SHIELD was refused with the right arm broken (2394). MIND IMPATIENCE went out (2397). Kick-less and light combos took the kata to 9 (2718).
   - From 2820 he held the shield and used Telepathy only: IMPATIENCE x3 and PARALYSE x3. The shield absorbed DSL blows (2866, 3029).
   - **VIVISECT failed**: "Agathon reaches out for your chest but his hand stops short of it." (2946-2948). Only Mystor's left leg was damaged.
   - The lock was lost at 3099 (10:39:46, cause unseen). The relock started with the mindprint line (3110-3111).
   - **MIND PARALYSE twice with no completed lock** (3144, 3209). Agathon ate magnesium after the first (3168).
7. **Rain, kata 9-14 (10:39:48-10:40:06, 3211-4083).**
   - The lock finished at 3242 and Sapience was recast at 3264.
   - The broken right arm (3345) stopped WIELD STAFF, so the combo was refused three times (3386-3424).
   - Then PARALYSE on every equilibrium (6x, 3624-3912) and IMPATIENCE x2 (3503, 3564). Agathon ate magnesium within about 1 s each time. His DSL landed only right after a magnesium (3684, 3830).
8. **The chase (10:40:06-10:40:30, 4084-4840).**
   - Rain 14 to Oak (4088). Ruku torso sloughed the fangbarrier again (4096).
   - Agathon tumbled north (4106 to 4188) and raised EPITOMISE (4113).
   - Gravehands threw Mystor off balance three times (4163, 4183, 4207).
   - Mystor followed (4265). Agathon walked back (4312) and touched his shield out of sight (4404, through Sapience).
   - Mystor's combo bounced off the shield (4424). SHATTER, a parried risingkick and a light nervestrike followed (4443-4449).
   - Gaital from 4524. Two combos were refused because both of Mystor's legs were crippled (4663, 4674). The lock was lost at 4760.
9. **Rain; INVESTIGATE, THROW, kata timeout (10:40:30-10:41:03, 4841-5967).**
   - Lock at 4861 and Sapience at 4939. INVESTIGATE read Agathon's right arm at 0.0% (5167).
   - **All four of Mystor's limbs were out at 5425-5447**: prompt `[RL2, ra1, LA2, ll1]`. Agathon sent `assess` and `pt` (5424, 5434), not VIVISECT.
   - MIND PARALYSE (5483). DSL curare/gecko gave paralysis and slickness, and stripped Mystor's fangbarrier (5538-5548).
   - MIND DISRUPT (5621) was concentrated away (5647).
   - A damaged left arm refused the staff three times (5821-5846).
   - MIND THROW north (5881) shattered the lock: "Agathon jerks violently north." (5882-5883). Mystor relocked onto him in the next room (5892-5927) and cast Sapience across rooms (5960).
   - The kata chain lapsed: "You can no longer maintain your deadly kata." (5967).
10. **Rain again; the second four-limb window (10:41:03-10:41:26, 5968-6860).**
    - The combo bounced off a second shield, raised out of sight (5996). SHATTER (6014).
    - DSL torture/curare (6045, 6130). Nausea beat Mystor's parry (6314, 6320).
    - **All four limbs were out at 6394-6450**: `[ra1, la1, LL2, rl1]`. Agathon smoked malachite (6398). Then MIND PARALYSE (6427) stopped him. His curing mended all four limbs by 6595.
    - PARALYSE, IMPATIENCE and DISRUPT (6494, 6575, 6610). Rain reached kata 15 (6789).
11. **Oak; QUASH (10:41:26-10:41:36, 6861-7332).**
    - Light nervestrikes took Oak to kata 12.
    - Agathon switched to a QUASH alias (6999-7005): 1084 cold damage each time (7006-7007, 7278-7279).
12. **Gaital; his offense ends (10:41:36-10:41:42, 7333-7557).**
    - His last landed DSL was torture/curare (7394-7404).
    - Mystor's flashheel left + ruku right + ruku left (7455-7465) left the model at LL2/LA2/RA2.
    - Nine DSL sends then printed nothing (7468-7536). His last DSL send was 7533. He never attacked again.
    - He applied restoration, sipped and ate ferrum, raised epitomise (7545) and tumbled southwest (7575 to 7698).
13. **Maelstrom, Oak, Willow (10:41:42-10:42:09, 7558-8115).**
    - MIND IMPATIENCE x4 in Maelstrom.
    - The lock was lost as he tumbled out (7690). Mystor relocked into the next room (7710-7775), chased him to Portal tower (7770-7785) and ran three Maelstrom combos to kata 12 (7796-7900).
    - Oak with a light nervestrike (7924). That paralysis was never cured with magnesium.
    - Willow: flashheel/hiraku/hiru. Agathon FOCUSED, then ate plumbum (7993/7996, 8043/8044).
    - Flashheel and sweep took Willow to kata 12 (8085-8090).
14. **The finish (10:42:09-10:42:51, 8116-9039).**
    - Rain with Sapience recast (8120), then Oak, where "Vacancy fills the eyes of Agathon." appeared (8291).
    - The lock was lost at 8409. **IMPATIENCE (8454) and DISRUPT (8506) went through without a lock.** Then "Your concentration is interrupted and the mindlock fails." (8507). Relock at 8531.
    - Rain: MIND CONFUSE was refused 9 times for balance before it went through (8692-8742).
    - Oak: the Vacancy line again (8795). IMPATIENCE, PARALYSE and DISRUPT (8848, 8889, 8921).
    - Agathon only typed `fitness` (61 times), `diagnose` and `allies`.
    - KAI CHOKE (8961) took him from 42% to 11.6%. The second KAI CHOKE (9021) killed him (9028-9029). The arena lines follow (9031-9039).

## The opponent

### Rotation, as Sapience shows it

**Attack alias**, sent as one block:

```
stand / wield scimitar388622 scimitar314077 / wipe scimitar314077 / dsl Mystor <limb> <item1> <item2> / assess Mystor
```

After DSLs that landed, he also sent `pt Mystor: <aff> <aff> <aff> <aff>`, naming each landed item twice (e.g. 405, 3311). He sent nothing after fully parried ones.

**How the DSL sends turned out** (log grep):

| Outcome | Count |
|---|---|
| DSL sends | 122 |
| DSLs executed (128 blows) | 64 |
| Blows that did damage | 91 |
| Blows absorbed by Mystor's shield | 5 |
| Blows Mystor parried | 24 |
| Blows that missed | 8 |

- The other sends went out while he was paralysed or had broken arms, and printed nothing.
- **Limbs hit** (blows that reached Mystor, misses excluded): left leg 63, right leg 34, left arm 23, **right arm 0**.
- **Item pairs** (sends): epteth epseth 27, xentio curare 24, torture curare 23, torment curare 12, epseth epteth 11, epseth epseth 11, curare gecko 7, euphorbia curare 4, epteth epteth 3.
- **Order over the fight:**
  - curare pairs (xentio, torment, euphorbia) from 10:38:38 to about 10:39:30;
  - epteth/epseth limb-break pairs from about 10:39:30 to 10:41:16, with curare+gecko at 3026 and 5537;
  - torture+curare from 10:41:07 until his offense ended at 10:41:38.

**Other commands:**
- `tyranny` (123, 208)
- `summon infestation` x5 (243-292). Only 254 produced the summon line.
- `engage Mystor` (446)
- `vivisect Mystor` (2946), the only one
- `smoke malachite` x16
- `touch tree`
- `touch shield` (4404, and 8 times at 8315-8358 with no visible result)
- `touch cloak` (4302)
- `epitomise` (4112, 7544, 7581)
- `tumble n` (4105, after `tws n` at 4075), `tumble sw` (7574). A later `tumble n` (7541) printed nothing.
- The QUASH alias `stand/stand/mastery/sheathe scimitar388622/draw shield685283/quash Mystor` (from 6999). Two of his QUASH sends landed (7006, 7278).
- `restore` x2 (7660, 7686, no visible result)
- `fitness` x61 (all at the end)
- `diagnose`, `allies`, `L`, `concentrate`, `focus mind`
- outr/eat of minerals; `sip health`; `apply mending|restoration to <legs|arms|head>`; `apply quicksilver`

### Venoms, investments and abilities, with their lines

| Item / ability | What it did to Mystor | Line |
|---|---|---|
| curare | paralysis | "A prickly stinging overcomes your body, fading away into numbness." (384) |
| xentio | clumsiness | 379 |
| euphorbia | nausea. While Mystor was nauseous, his parry failed (6314, 6320) | 663 |
| gecko | slickness; stripped Mystor's fangbarrier | 3036-3037 |
| epteth | broke an arm, **left first**, whichever limb the DSL aimed at (a right-leg DSL broke the left arm: 769-774, 6313-6319) | 774 |
| epseth | broke a leg, left first. Nothing visible when both legs were already out (6386-6387) | 779 |
| TORMENT (Hellforge, in a venom slot) | healthleech; its own line replaces the database line | 577 |
| TORTURE (Hellforge, in a venom slot) | haemophilia | 6045 |
| DSL blows | 284-400 physical cutting each, +9 bleeding per damaging blow. A limb past 100% went straight to level 2 (2865, 5320, 6235) | 377 |
| DEATHAURA | 547 magical, about every 14 s, 18 ticks | 295-296 |
| INFESTATION | One affliction every ~9 s, first tick 9 s after the summon, never one Mystor already had. 22 ticks: weariness 6, asthma 4, confusion 4, lethargy 3, clumsiness 2, nausea 2, darkshade 1 | 256, 541 |
| TYRANNY | Gravehands rise. The grasp costs 1.0 s of balance (7 grasps). Mystor was not proned, although the wiki says tyranny prones non-Mhaldorians | 209-210, 40 |
| Agony (likely) | 506 unblockable plus the mist line, both times right after a TORMENT healthleech | 609-610, 1201-1202 |
| QUASH | 1084 cold (wiki: 4.00 s eq, strips a magical shield) | 7006-7007, 7278-7279 |
| VIVISECT | failed (one limb out) | 2948 |

### Curing order

This is what he did first, judging by his own commands.

1. **Paralysis: magnesium** at the first eat balance, every time (201, 240, 300, 366, 1621, 3633-3898, 5528, 6549, 7268), usually within 0.5-1.5 s. He cured it ahead of asthma (6902, 6976) and ahead of impatience (3633-3898).
   - Exception: the light nervestrike at 7924. He ate ferrum instead (7938, 7969) and never cured it.
2. **Slickness: magnesium, before any salve** (2047-2050, 7350-7353).
3. **Limbs, on the salve balance:**
   - mending to the legs 1-2 s after each flashheel (435, 472, 550, 2049, 2171, 2302, 4549, 4607, 7352, 7385);
   - mending to the head for a crushed throat (2322);
   - restoration, then mending, for level-2 limbs (4022, 4169, 4714, 7482);
   - two RESTOREs with nothing visible (7660, 7686).
4. **Impatience: plumbum within about 1 s** whenever paralysis was not up (2834, 2920, 3327, 3540, 6626, 7615, 7638, 7664, 8386).
5. **Disrupted: CONCENTRATE within about 1 s**, 8 of 9 times (732, 1035, 1327, 1429, 5647, 6106, 6619, 8525).
6. **Kelp group** (clumsiness, weariness, healthleech, asthma): aurum, his most frequent eat.
7. **Ginseng group** (addiction, lethargy): ferrum, late. The first was at 4646, then on every eat from 10:41:53 while jinzuku kept hitting.
8. **Anorexia and dizziness: FOCUS**, then plumbum (2609, 4860, 7993/7996, 8043/8044, 8104, 8164).
9. **Tree** about every 13-15 s when several afflictions were up.
10. **Prone:** he stood about 1 s later, after his first eat. His last "stands up." was at 6810.
11. **Rebounding:** he smoked malachite straight after his own attack dropped it.
12. **Fangbarrier:** quicksilver right after a slough.
13. **Health:** sip health plus potash at about 75-83%.
14. **Escape when crippled:** tumble plus epitomise (10:40:08 and 10:41:42-48), and touch shield.

From about 10:42:24 he had anorexia (hiraku), asthma and slickness (livestrike, ruku torso), impatience, paralysis and disrupted, and he stopped curing. His last eat was 8435, his last sip 8462 and his last concentrate 8525. After that he typed only fitness, diagnose and allies.

### Defences

- **Rebounding** came from `smoke malachite` and was perceived 8-9 s later. There were 16 cycles.
  - **All 17 drops followed his own offensive command**: dsl x14, summon infestation (255), vivisect (2947), quash (7277).
  - Nothing Mystor did stripped it.
- **Fangbarrier** came from quicksilver and formed 10 s after it was applied (2053 to 2457).
  - Mystor's ruku torso (slickness) sloughed it 3 times (2020, 4096, 7339).
- **Shield tattoo.** Two were shattered (4443, 6014). Both were raised out of Mystor's sight.
- **EPITOMISE** was raised twice. The first lasted 8 s (4113 to 4304).
- **Other:** deathaura (always on), a glass lily dropped at the start (68), a cloak tattoo (4303), CONCENTRATE, and three parries of Mystor's strikes (4445, 6959, 6962).

### Kill route against Mystor

- His route was **withering limbs for VIVISECT**: 52 of his 122 DSL sends carried epteth/epseth.
- On top of that he used curare paralysis on most curare pairs, and damage from DSL, deathaura and quash.
- He tried VIVISECT once, too early (2946-2948, only a damaged left leg).
- He then missed both moments when all four of Mystor's limbs were out:
  - 5425-5447, ~10:40:44: he sent assess and pt;
  - 6394-6450, ~10:41:16: he smoked malachite, then MIND PARALYSE stopped him.
- In both windows some limbs had been damaged by blows rather than "shrivelled" by a venom. Whether VIVISECT ("all four of his or her limbs are withered", `infernal.md:223`) counts those is unknown.
- He never got Mystor below 73%.

## Mystor's offense

### Forms and kata

**Transitions** were always sent as `transition to <form> form` ahead of the combo in the same round. The combo then counted from 1 in the new form. None were refused, and there was no stumble or rhythm line.

| Line | From form (kata) | To form |
|---|---|---|
| 422 | Oak 12 | Gaital |
| 719 | Gaital 12 | Rain |
| 1550 | Rain 15 | Oak |
| 2014 | Oak 12 | Gaital |
| 2393 | Gaital 12 | Rain |
| 4088 | Rain 14 | Oak |
| 4524 | Oak 12 | Gaital |
| 4845 | Gaital 12 | Rain |
| 6861 | Rain 15 | Oak |
| 7333 | Oak 12 | Gaital |
| 7558 | Gaital 9 | Maelstrom |
| 7922 | Maelstrom 12 | Oak |
| 7980 | Oak 6 | Willow |
| 8116 | Willow 12 | Rain |
| 8285 | Rain 6 | Oak |
| 8448 | Oak 6 | Willow |
| 8589 | Willow 6 | Rain |
| 8789 | Rain 6 | Oak |

- **Highest kata:** Oak, Gaital, Maelstrom and Willow 12 each; Rain 15.
- **What counts toward the kata:**
  - every sent strike counts: fumbled strikes (640, 842, 2200), parried strikes (4445, 6959-6962) and SHATTER (4443) all count;
  - a combo that bounces off a shield adds nothing (4424, 5996);
  - a refused combo adds nothing and spends no balance (3386-3424, 4663, 6378).
- Mystor's system's own appended "Kata is N" undercounted parried, fumbled and SHATTER strikes (2203-2206, 4448-4449, 6964-6965).
- **The chain survives** Telepathy rounds, weapon swaps and room changes:
  - Rain 9 from 10:39:37 to 10:39:53 (2718 to 3448);
  - Maelstrom 3 to 4 across a chase (7565 to 7801).
- **It times out after about 19-20 s without a strike.** The last strike was at 5376 (10:40:43), and "You can no longer maintain your deadly kata." printed at 5967 (10:41:02-03). Refused combos did not refresh it.

### Combos per form (command strings as his system sent them)

**Oak**
- `nervestrike risingkick head ruku <arm>` (150, 180, 220, 266, 1546)
- `nervestrike risingkick head kuro left` (309)
- `nervestrike risingkick head livestrike` (1675)
- `nervestrike light risingkick torso livestrike[ light]` (1898, 6857, 7132)
- `risingkick torso livestrike ruku torso` (4084, and light at 8281)
- `nervestrike light risingkick torso ruku torso` (4134)
- `shatter risingkick torso nervestrike light` (4438)
- `risingkick torso ruku torso nervestrike light` (6954)
- `nervestrike light risingkick torso kuro [light] right` (7234, 7918, 8390)
- `risingkick torso livestrike light kuro left` (7950)
- `risingkick head livestrike light ruku torso` (8785)

**Gaital**
- `flashheel right ruku right ruku right` (418)
- `flashheel right kuro right jinzuku` (456)
- `flashheel right ruku left ruku left` (522)
- `flashheel right kuro left ruku right` (635)
- `flashheel right ruku torso kuro left|jinzuku|ruku left|needle` (2010, 2116, 2195, 2253)
- `flashheel left kuro light right ruku light right` (4520)
- `flashheel left kuro left jinzuku light` (4591)
- `flashheel right ruku torso ruku light right|jinzuku light` (7329, 7368)
- `flashheel left ruku right ruku left` (7455), which ended his offense

**Rain**
- `frontkick <side> kuro <side> ruku <side>` (835, 1126, 1219, 4001, 5067, 8180, 8234)
- `frontkick right ruku right ruku right` (928, 5251)
- `frontkick right ruku right kuro right` (1485, 5366)
- `frontkick left hiru light kuro right` (4841)
- `frontkick right kuro light right ruku light right` (8631, 8673)
- **kick-less two-strike combos:** `  ruku light right hiru` (2545), `  kuro left ruku light right` (2632, 3438), `  hiru kuro left` (2710). These print no `[Bal Spent]`, and only the two arm balances come back.

**Maelstrom**
- `risingkick torso jinzuku light ruku torso|ruku light right` (7554, 7796, 7840, 7890)

**Willow**
- `flashheel right sweep hiru light` (8081)
- `flashheel right|left hiraku light hiru light` (7976, 8024, 8053, 8473, 8543)

**Light strikes** (kuro, ruku, hiru, hiraku, jinzuku, nervestrike, livestrike) were used so as not to break a limb already prepped.

### Telepathy

| Ability | Uses | Forms | Locked? | Effect seen |
|---|---|---|---|---|
| MIND LOCK | 7 starts, 6 finished | all | n/a | see below |
| MIND PRINT | 1 (109) | Oak | locked (102) | later locks: "Your mindlock is speeded by the mindprint you hold." |
| MIND SAPIENCE | 6 (111, 3264, 4939, 5960, 8120, 8593) | Oak once, then Rain | always | Sapience output stopped at every lost lock and needed a recast (e.g. last `-->` line 7686, next 8128 after the 8120 recast) |
| MIND DISRUPT | 9 (723 … 8921) | Rain, Willow, Oak | locked, except 8506 | 8 of 9 cured by concentrate within about 1 s; only the last stuck |
| MIND IMPATIENCE | 14 (2397 … 8848) | Rain, Maelstrom, Oak, Willow | locked, except 8454 | plumbum within about 1 s when he was not paralysed |
| MIND PARALYSE | 15 (2972 … 8889) | Rain, Oak | locked, except 3144 and 3209 | magnesium within about 1 s (3168 after the lockless 3144) |
| MIND CONFUSE | 1 (8742) | Rain | locked | refused 9x "You must regain balance first." while off balance (8692-8732) |
| MIND THROW north | 1 (5881) | Rain | locked | "Your mindlock with Agathon shatters!" and "Agathon jerks violently north." |

**Lock timeline:**

| Lock | Held from | Until | Length | How it ended |
|---|---|---|---|---|
| 1 | 102 (~10:38:26) | 3099 (10:39:46) | ~80 s | lost, cause unseen |
| 2 | 3242 | 4760 (10:40:29) | 40 s | lost, cause unseen |
| 3 | 4861 | 5882 | 24 s | ended by MIND THROW |
| 4 | 5927 | 7690 | 50 s | lost as Agathon tumbled out |
| 5 | 7775 | 8409 | 31 s | lost, cause unseen |
| 6 | 8531 | 9023 | 22 s | lost at the kill |

- Every relock started with the mindprint line and finished in 2-3 s. The first lock, with no mindprint, took about 12-16 s.
- Three relocks were started on a target in another room (5892, 7710, and 51 indirectly), some while Mystor was off equilibrium (5886).
- A MIND LOCK sent during an attempt is refused 16 times: "You must cease your current lock attempt before trying another." The attempt carries on.
- **Telepathy and parry worked while Mystor was paralysed** (1412-1420).
- **They also worked with all four of his limbs broken** (6427).

### Kai

- **KAI TRANSMUTE** ran 11 times, from his curing (`[Curing]: TRANSMUTE <n>`).
  - Each was exactly n health for n mana, with no kai and no balance or equilibrium spent (708-710, 1212-1214, 3551-3553).
  - One time (1119-1121) mana fell by 567 for 501 health, probably a drain landing on the same prompt.
- **KAI CHOKE** ran twice at the end: K went from 90% to 80% and it took 3.40 s of equilibrium in Oak (8940-8964).
- **Kai gain:** +10% for each DSL Mystor took, parried ones included. He gained nothing from deathaura, infestation or Agony (chunk 2: 851-1376).
- **Kai decay:** -5% roughly every 30 s when no gain masked it (10:38:45, 10:39:15, 10:40:15, 10:40:45, 10:41:15, 10:41:46, 10:42:15, ~10:42:48).
- No SURGE or CRIPPLE in this fight.

### Shields and rebounding

- **Shikudo strikes landed through Agathon's aura of rebounding** in at least 8 combos inside an "up" window: 928-938, 1679-1685, 2257-2263, 4285-4291, 4442-4448, 4847-4853, 5255-5261 and 6782-6788. None printed a rebound.
- The **shield tattoo** stopped whole combos:
  - "A dizzying beam of energy strikes you as your attack rebounds off of Agathon's shield." (4424, 5996);
  - no strike line and no kata;
  - 1.70 s of equilibrium in Oak and 1.44 s in Rain; balance kept.
- **SHATTER in the first combo slot** broke the shield, and the rest of the combo landed (4443, 6014).
- Sapience showed `touch shield` (4404) twenty lines before the first bounce.
- **Mystor's own Shield of Absorption** absorbed 5 DSL blows (2866, 3029, 3344, 3692, 6651). It stops damage and bleeding only: the venom and the limb damage still landed.

### How the kill was set up

1. **Attrition until 10:41:38.** Agathon out-healed Mystor's offense (100% at 2398, 96% at 5623). MIND PARALYSE on every equilibrium rationed his DSLs to the moment right after each magnesium.
2. **His offense was shut off.** The Gaital round flashheel left + ruku right arm + ruku left arm (7455-7465) left both his arms and a leg broken in the model. His DSL never fired again (9 silent sends, 7468-7536). Restoration and RESTORE did not visibly fix it.
3. **He was locked down.**
   - hiraku: anorexia (7985, 8484, 8553);
   - livestrike and ruku torso: asthma and slickness;
   - kuro: weariness;
   - MIND IMPATIENCE, PARALYSE, DISRUPT and CONFUSE;
   - prone from sweep and frontkick, with no stand line after 6810.
   He last ate at 8435, last sipped at 8462 and last concentrated at 8525.
4. **He was ground down, then choked.**
   - His health went from 90% (8510) to 42% (8849) in about 20 s.
   - Risingkick torso had kept the torso in the model past 200%. The wiki gives KAI CHOKE more damage against a damaged or mangled torso; no game line confirms the torso state.
   - The first choke did 2216 damage (3063 to 847) and the second killed him.

## Timings

**Balance (Mystor):**

| Action | Oak | Gaital | Rain | Maelstrom | Willow |
|---|---|---|---|---|---|
| Three-strike combo with a kick | 2.1 s (188) | 2.1 (425) | 2.1 (934) | 2.1 (7561) | **1.9** (7983) |
| Fumbled or parried kick | 2.1 parried (4446) | 2.1 fumbled (2201) | 2.1 fumbled (843) | | |
| Kick-less two-strike combo | | | no `[Bal Spent]`; arms back ~2 s (3492-3493) | | |

- INVESTIGATE: 2.3 s, recovered in 2.27 s (5168, 5249).
- Gravehands grasp: 1.0 s, recovered in 0.88-1.0 s (41, 4164, 5795).

**Equilibrium (Mystor).** About 0.85 of the wiki outside Rain and 0.72 in Rain, as in the KB's first-pass table (`shikudo.md`):

| Ability (wiki) | Rain | Oak | Willow | Maelstrom |
|---|---|---|---|---|
| MIND IMPATIENCE (1.50) | 1.07 (2395) | 1.27 (8345) | 1.27 (8452) | 1.27 (7604) |
| MIND PARALYSE (2.00) | 1.44 (2970) | 1.70 (8887) | | |
| MIND CONFUSE (2.00) | 1.44 (8740) | | | |
| MIND DISRUPT (4.00) | 2.89 (724) | 3.40 (8922) | 3.40 (8509) | |
| MIND SAPIENCE (4.00) | 2.89 (3265) | 3.40 with PRINT (112) | | |
| MIND THROW (3.00) | 2.17 recovered (5918) | | | |
| KAI CHOKE (4.00) | | 3.40 (8962) | | |
| Combo bounced off a shield | 1.44 (5997) | 1.70 (4425) | | |

**Mind lock:**
- First lock, no mindprint: about 12-16 s, with a delve line every 4 s (93-102).
- With a mindprint: 2-3 s (3110 to 3242, 4775 to 4861, 5892 to 5927, 7710 to 7775, 8520 to 8531).

**Cure balances (Mystor's measured recovery):**

| Balance | Recovery |
|---|---|
| Eat | 1.39-1.67 s (~1.5) |
| Mending salve | 0.80-1.05 s |
| Restoration salve | 3.95-4.02 s (the cure and the balance arrive together) |
| Sip | 4.29-4.52 s |
| Tree | 13.89-14.14 s |
| Moss / potash | 5.82-6.11 s |
| Focus | 2.42-2.52 s |

Mana: CLOT cost 40 (e.g. 5663 to 5623) and FOCUS 166 (2337).

**Opponent:**
- Smoke malachite to rebounding: 8-9 s, every cycle.
- Quicksilver to fangbarrier: 10 s.
- DSL cadence: about 2-2.4 s.
- Deathaura: about 14 s. Infestation: about 9 s.
- Tumble: 4.5-5.5 s.
- Magnesium after paralysis: 0.5-1.5 s. Concentrate after disrupt: under 1 s.
- Tree: about every 13-15 s.
- Epitomise: up for 8 s.
- Wiki costs: tyranny 3.00 s of balance, quash and vivisect 4.00 s of equilibrium, infestation 3.00 s of equilibrium.

## Game lines

**How the NEW mark was decided:**
- **NEW**: a fixed-string search for a distinctive fragment found nothing in the curated KB (`kb/` outside `kb/raw` and `kb/inbox`). Markdown line-wraps can hide a match, so I also read the first-pass notes on these fights (`shikudo.md:256-343`).
- **NEW\***: not searched by me. The chunk readers found it in none of `shikudo.md`, `infernal.md` or `database.md`.
- **–**: already in the KB.

**These are system lines, not game text, and are left out:** `You: …`, `[Zax]: …`, `Agathon: Dsl …`, `My <Limb>…`, `--> Agathon: …`, `pt …` (including `pt Intercepted …`, see the Unclear section), `Room: …`, banners, `Reset Agathon`, `-Agathon`, `(1) person here: …`. The game's own lines for Mystor's strikes, Telepathy successes, lock start/finish/loss and TRANSMUTE are gagged, so this log does not capture them.

### Our attacks and effects

| Line | First (count) | New | Meaning |
|---|---|---|---|
| `Horror overcomes the face of Agathon as his body locks in paralysis.` | 185 (17) | – (shikudo.md:306; but the strike table at shikudo.md:85 still says "none on the attacker's side") | nervestrike, light ones too; paralysis landed |
| `Your foot catches Agathon under the chin, snapping his head back.` | 187 | – | risingkick head |
| `Your foot drives into the solar plexus of Agathon.` | 1905 | – | risingkick torso |
| `The breath of Agathon leaves him in an explosive gasp as the end of the staff smashes home.` | 1685 (8) | – | livestrike |
| `The staff connects to the left arm with a resounding crack, the limb flopping uselessly.` | 190 | – | ruku to an arm (also right); names no target; light ones print it too |
| `Agathon staggers as the staff cracks across his ribs, sweat breaking out upon his forehead.` | 2019 | – | ruku torso (slickness) |
| `The staff cracks across the left thigh of Agathon.` | 319 | – | kuro (also right) |
| `The end of the staff drives viciously into the kidneys of Agathon.` | 466 | – | jinzuku |
| `You feel the satisfying crunch of bone under the impact of your heel.` | 424 | – | flashheel |
| `The end of the staff smashes into the exposed throat of Agathon, crushing cartilage.` | 2263 | – | needle |
| `The instep of your foot smashes into the right underarm of Agathon, throwing him from his feet and sending him spinning to the ground.` | 933 | – | frontkick (also left); prints even on a target already prone |
| `The staff connects to the side of Agathon's head with a resounding crack.` | 2552 | – | hiru |
| `The staff smashes into the face of Agathon with a sickening crunch.` | 7985 | – | hiraku |
| `The staff sweeps the legs out from under Agathon, sending him sprawling.` | 8089 | – | sweep |
| `The end of your staff smashes the magical shield surrounding Agathon in an explosion of translucent shards.` | 4443 (2) | – | SHATTER |
| `The protective coating covering the skin of Agathon sloughs off.` | 2020 (3) | NEW | his fangbarrier stripped, straight after ruku torso |
| `Vacancy fills the eyes of Agathon.` | 8291 (2) | NEW | unknown; see the Unclear section |
| `You fumble your strike, the attack going wide.` | 640 (3) | – | fumble while clumsy |
| `Agathon parries the attack with a deft manoeuvre.` | 4445 (3) | – | our strike parried |
| `A dizzying beam of energy strikes you as your attack rebounds off of Agathon's shield.` | 4424 (2) | NEW (our triggers 167/275/336 already match it) | whole combo stopped by his shield |
| `You carefully study the right arm of Agathon, noting that it appears to be 0.0% of the way to breaking.` | 5167 | NEW | INVESTIGATE |
| `You are now maintaining a kata chain of 3 actions.` | 191 | – | kata count |
| `You can no longer maintain your deadly kata.` | 5967 | NEW | kata timeout (~19-20 s with no strike) |

### Opponent attacks and effects

| Line | First (count) | New | Meaning |
|---|---|---|---|
| `Agathon raises a Scimitar of Eagles above his head, necromantic energy flickering wildly about the weapon. Then he drives it down into the ground at his feet in a muted flash.` | 209 | NEW | TYRANNY |
| `Grisly skeletal hands thrust upwards from beneath the earth, clawing at the living.` | 210 | NEW | gravehands rise |
| `Hands of rotting flesh and white bone push up from the ground.` | 34 | NEW | room description: gravehands present (Portal tower, Webbed and Collapsed passages) |
| `The hands of the grave grasp at your ankles and throw you off balance.` | 40 (7) | NEW | 1.0 s of balance |
| `Agathon utters a low chant and hundreds of sickly white maggots dig their way out of the earth, squirming over one another to spread out across the ground in a putrid mass.` | 256 | NEW | SUMMON INFESTATION |
| `You recoil in horror as countless maggots squirm over your flesh, burrowing into your pores.` | 541 (22) | NEW | infestation tick |
| `You feel sickened and weak by the aura of death emanating from Agathon.` | 295 (18) | – | DEATHAURA tick |
| `You take 547 magical, damage.` | 296 (18) | – | deathaura damage |
| `You take 300 physical cutting, damage.` | 377 (91) | NEW | one DSL blow (284-400) |
| `You take 506 unblockable, damage.` | 609 (2) | NEW\* | while he had healthleech on Mystor (likely Agony) |
| `The sanguine mist surrounding Agathon billows and writhes exultantly.` | 610 (2) | NEW | likely Agony curing him |
| `Agathon moves in to engage you.` | 447 | NEW | ENGAGE |
| `Agathon misses you with a Scimitar of Eagles.` | 966 (8) | – (form in runewarden-snb.md:38) | one DSL blade missed |
| `Agathon reaches out for your chest but his hand stops short of it.` | 2948 | NEW | VIVISECT failed |
| `Agathon wreathes his hand in black lightning, delivering a savage backhand to your face that sends the profane energy ripping through your body.` | 7006 (2) | NEW | QUASH |
| `You take 1084 cold, damage.` | 7007 (2) | NEW\* | quash damage |
| `Agathon bats your weak attempt to defend against his attack aside.` | 6314 (2) | NEW | Mystor's parry beaten (he was nauseous) |
| `Agathon carefully wipes all the venoms off of a Scimitar of Eagles.` | 1362 (8) | – | prints only when a parried DSL left venom on the blade |
| `With a sibilant 'shhhiiiinnngggt!', Agathon smoothly sheathes a Scimitar of Eagles.` | 7003 | NEW | sheathes for QUASH |
| `Agathon silently draws a Scimitar of Eagles from a scabbard embellished with a gold eagle.` | 7391 | NEW | rewields it |
| `Agathon begins to tumble towards the north.` | 4106 (2) | NEW | tumble start (also southwest) |
| `Agathon tumbles out to the north.` | 4188 (2) | NEW | tumble end, 4.5-5.5 s later |
| `Agathon leaves to the north.` | 139 | NEW\* | walk (also south, 4312) |
| `Agathon releases his grip upon a clouded glass lily, allowing it to fall to the ground, where it crumbles into dust.` | 68 | NEW | glass lily |

### Afflictions landing on Mystor

| Line | First (count) | New | Meaning |
|---|---|---|---|
| `You have been afflicted with clumsiness.` | 378 | NEW | generic line before each affliction's own (origin: see the Unclear section) |
| `You gasp as your fine-tuned reflexes disappear into a haze of confusion.` | 379 | – | clumsiness |
| `A prickly stinging overcomes your body, fading away into numbness.` | 384 | – | paralysis |
| `Your limbs grow heavy and you groan feebly.` | 543 | – | weariness |
| `A sense of extreme nausea washes over you.` | 663 | – | nausea |
| `You feel a tightening sensation grow in your lungs.` | 912 | – | asthma |
| `You feel your energy robbed from you as lethargy overtakes you.` | 1289 | – | lethargy |
| `Your head spins as your mind is drowned in chaos and confusion.` | 2329 | – | confusion |
| `You feel your allergy to the sun going into temporary remission.` | 8374 | NEW | printed before darkshade's line; meaning unknown |
| `Your vision is flooded with light, and your face suddenly reddens.` | 8375 | – | darkshade |
| `You feel your strength begin to leech away at the touch of the profane weapon.` | 577 (2) | NEW | TORMENT healthleech (replaces the database line) |
| `Your very blood rebels against the profane touch of a Scimitar of Eagles.` | 6045 (5) | NEW | TORTURE haemophilia |
| `You watch, in horror, as your left arm shrivels up and becomes useless.` | 774 | NEW | epteth arm break (also right) |
| `You stumble as your left leg shrivels into a useless appendage.` | 779 | NEW | epseth leg break (also right) |
| `Your left leg is greatly damaged from the beating.` | 2865 | – | limb past 100%, level 2 |
| `The protective covering coating your skin sloughs off.` | 3036 (2) | NEW | gecko slickness stripped his fangbarrier |
| `You notice that your sweat glands have begun to rapidly secrete a foul, oily substance.` | 3037 | – | slickness |
| `You take 9 raw, damage.` | 3041 | NEW\* | bleed tick |
| `You bleed 9 health.` | 3042 | – | bleed tick |
| `Your shield completely absorbs the damage.` | 2866 (5) | – | Shield of Absorption; venom still lands |
| `You parry the attack with a deft manoeuvre.` | 1257 (24) | NEW | Mystor parried a DSL blow (no limb named) |

### Mystor's cures

| Line | First | New | Meaning |
|---|---|---|---|
| `You eat a magnesium chip.` | 390 | NEW | paralysis, slickness |
| `Your muscles unlock; you are no longer paralysed.` | 391 | – | |
| `You have cured the paralysis affliction.` | 392 | NEW | generic confirmation after each cure |
| `You exert superior mental control and your wounds clot before your eyes.` | 394 | NEW | CLOT, 40 mana |
| `You touch the tree of life tattoo.` | 400 | NEW (the KB quotes only "You touch the tree...") | tree |
| `Thank Maya, the Great Mother! Your clumsiness has been cured.` | 401 | – (database template) | clumsiness cured |
| `You eat an aurum flake.` | 566 | NEW | kelp group |
| `Your limbs strengthen and you feel stronger.` | 567 | – | weariness cured |
| `Your aching, pain-wracked body is soothed and calmed.` | 757 | – | healthleech cured |
| `You eat a ferrum flake.` | 813 | NEW | ginseng group |
| `Your stomach becalms itself.` | 814 | – | nausea cured |
| `You eat a potash crystal.` | 729 | NEW | moss |
| `You feel your health and mana replenished.` | 730 | NEW | potash effect |
| `Your bronchial tubes open up and your asthma is cured.` | 1266 | – | |
| `The lethargy evaporates, leaving you full of energy.` | 1469 | – | |
| `Your blood regains its ability to clot.` | 6070 | – | haemophilia cured (tree, ferrum) |
| `Your glands cease their oily secretion.` | 3048 | – | slickness cured |
| `No longer will the sunlight harm you.` | 8383 | – | darkshade cured |
| `You focus your mind intently on curing your mental maladies.` | 2334 | NEW | FOCUS, 166 mana |
| `The confusion lifts from your mind and it is clear once again.` | 2335 | – | |
| `You take out some salve and quickly rub it on your legs.` | 785 | NEW | mending or restoration (also arms) |
| `The bones in your left leg mend.` | 786 | – | one limb per application |
| `Your left leg feels stronger and healthier.` | 3085 | – | restoration, ~4 s after applying |
| `You take a drink from an amethyst vial.` | 590 | NEW | his own vial (health or mana) |
| `The elixir heals and soothes you.` | 591 | – | |
| `Your mind feels stronger and more alert.` | 1065 | NEW | mana elixir |
| `You apply a quicksilver droplet to yourself.` | 3133 | NEW | fangbarrier |
| `The quicksilver hardens into a supple metallic shell.` | 3605 | NEW | fangbarrier up, ~10 s later |

### The opponent's cure and defence lines (third person)

| Line | First (count) | New | Meaning |
|---|---|---|---|
| `Agathon eats a magnesium chip.` | 201 | NEW | paralysis or slickness |
| `Agathon eats an aurum flake.` | 248 | – (shikudo.md:200 form) | kelp group |
| `Agathon eats a plumbum flake.` | 2607 | NEW | impatience |
| `Agathon eats a ferrum flake.` | 4646 | NEW | addiction or lethargy |
| `Agathon eats a potash crystal.` | 288 | NEW | moss |
| `Agathon touches a tree of life tattoo.` | 205 | NEW | tree |
| `Agathon touches a cloak tattoo.` | 4303 | NEW | cloak |
| `Agathon takes a long drag off an enamel bubble pipe.` | 283 (15) | NEW | smoke malachite (rebounding) |
| `A great gurgling sound is heard as Agathon takes a long drag from an enamel bubble pipe. A series of shining bubbles erupt from the bowl of his pipe.` | 2958 | NEW | the same smoke, a cosmetic variant |
| `The bubbles spewn from an enamel bubble pipe burst. *POP*  *POP*   *POP*` | 3017 | NEW | cosmetic |
| `Agathon takes a drink from an oaken vial.` | 285 | NEW | sip health |
| `Agathon takes some salve from a vial and rubs it on his legs.` | 435 | NEW | mending or restoration, salve unnamed (also arms 4023, head 2323) |
| `Agathon applies a quicksilver droplet to himself.` | 2053 | NEW | fangbarrier |
| `A supple metallic shell of quicksilver has formed around Agathon.` | 2457 | NEW | his fangbarrier up |
| `Agathon's eyes lose their focus suddenly.` | 732 (8) | NEW | CONCENTRATE (cures disrupted) |
| `A look of extreme focus crosses the face of Agathon.` | 2609 | – (runewarden-snb.md:47) | FOCUS |
| `Agathon stands up.` | 957 | NEW | stood from prone (last at 6810) |
| `You suddenly perceive the vague outline of an aura of rebounding around Agathon.` | 60 (16) | NEW (trigger 430 matches it) | rebounding up |
| `Agathon's aura of weapons rebounding disappears.` | 255 (17) | – (shikudo.md:316) | his own attack dropped it |
| `Agathon moves with the grace of the wind, his stance the epitome of perfection beneath the flurry of blows.` | 4113 (2) | NEW | EPITOMISE |
| `Agathon no longer moves with such sublime alacrity.` | 4304 | NEW | epitomise ends |
| `Agathon ceases to favour his head.` | 8717 | NEW | unknown |

### Telepathy

| Line | First (count) | New | Meaning |
|---|---|---|---|
| `You require a mindlock to perform that ability.` | 9 (8) | NEW | PRINT/SAPIENCE before the lock; THROW to the next room |
| `You must cease your current lock attempt before trying another.` | 54 (16) | NEW | MIND LOCK during an attempt |
| `You continue to delve deeper and deeper into the mind of Agathon.` | 93 (4) | NEW | lock in progress, every 4 s |
| `Your mindlock is speeded by the mindprint you hold.` | 3111 (6) | NEW | lock with a held mindprint |
| `Your mindlock with Agathon shatters!` | 5882 | NEW | MIND THROW ended the lock |
| `Agathon jerks violently north.` | 5883 | NEW | MIND THROW effect |
| `Your concentration is interrupted and the mindlock fails.` | 8507 | NEW | attempt failed right after our MIND DISRUPT |
| `You must regain balance first.` | 8692 (9) | NEW\* | MIND CONFUSE off balance |
| `You must regain equilibrium first.` | 8749 (2) | NEW\* | |
| `Mindnet: Agathon has left the area.` | 9032 | NEW | mindnet, on his expulsion |
| `Alertness: Agathon has entered Collapsed passage, to the south.` | 119 | NEW | ALERTNESS |

### Kata, form and weapon refusals

| Line | First (count) | New | Meaning |
|---|---|---|---|
| `You must have both hands available to wield a two-handed item.` | 3386 (6) | NEW | staff with one broken or damaged arm |
| `You may not carry out a combination utilising Shikudo strikes without the required staff.` | 3387 (6) | NEW | combo refused, no balance spent |
| `Both of your legs are shriveled and thus you cannot carry out that action.` | 4663 (3) | NEW | kick combo with both legs out |
| `You cannot do that because both of your arms must be whole and unbound.` | 6406 | NEW | both arms out: combo and wield refused, Telepathy not |
| `Both of your legs must be free and unhindered to do that.` | 2895 | NEW (trigger 345 reads it) | STAND with even one crippled leg (4698, 5368) |
| `You have no free hands to wield a Shield of Absorption.` | 2394 (2) | NEW | shield with the right arm broken |
| `You cease to wield a twisted oaken staff.` | 720 | NEW\* | swap to the shield |
| `You start to wield a Shield of Absorption in your right hand.` | 721 | NEW\* | |
| `You cease wielding a Shield of Absorption in your right hand.` | 839 | NEW\* | swap back |
| `You start to wield a twisted oaken staff in your hands.` | 840 | NEW\* | |

### Kai

| Line | First (count) | New | Meaning |
|---|---|---|---|
| `Agathon gasps and stumbles as an unseen force crushes the life breath out of him.` | 8961 (2) | – (shikudo.md:309) | KAI CHOKE |

### Arena and death

| Line | First | New | Meaning |
|---|---|---|---|
| `As you utter the command, the air about the mirror begins to shimmer.` | 26 | NEW\* | SAY INVIDIA at the mirror |
| `Tendrils of blackness spew forth from the surface of the mirror, pulling you beneath its sheen surface. Pain pierces your mind. Just as you succumb to the terror, you awake, and you find yourself within a smooth tower.` | 29 | NEW\* | into the arena |
| `You are moved by an iron-rimmed mirror.` | 31 | NEW\* | |
| `Agathon collapses to the ground, his life snuffed out like a candle.` | 9028 | – | death |
| `You have slain Agathon.` | 9029 | NEW\* | |
| `Defeated, Agathon is cast out of the Arena.` | 9031 | NEW | |
| `You have been victorious and leave the Arena in triumph!` | 9034 | NEW | (asterisk rows at 9033 and 9035) |
| `The Arena is once again open for combat.` | 9039 | NEW | |
| `Tralden has bled out, slain by the might of Arduous Anzerloi Ar'kena in The Gauntlet.` | 129 | NEW\* | a different fight |
| `Austere has been burned from within by the scouring flames of Austere Diaboli, Master-at-Arms.` | 8098 | NEW\* | a different fight |
| `A manifested nightmare engulfs Austere within its shifting form, and moments later a new face appears amongst the countless features crowding its surface.` | 8576 | NEW\* | a different fight |

### Balances, rooms and other game lines

| Line | First | New | Meaning |
|---|---|---|---|
| `You have recovered balance on your legs.` | 216 | NEW | after a combo; also `…on your right arm.` and `…on your left arm.` |
| `You have recovered balance on all limbs.` | 63 | NEW | after a gravehands grasp or INVESTIGATE |
| `You have recovered equilibrium.` | 132 | NEW\* | |
| `You may eat another plant or mineral.` | 442 | NEW | |
| `You may apply another salve to yourself.` | 821 | NEW | |
| `You may drink another health or mana elixir.` | 746 | NEW | |
| `You may utilise the tree tattoo again.` | 915 | NEW | |
| `You may eat another bit of irid moss or potash.` | 995 | – | |
| `Your mind is able to focus once again.` | 2466 | NEW | |
| `You will now attempt to parry attacks to your torso.` | 153 | NEW\* | PARRY each round |
| `You are not fallen or kneeling.` | 152 | NEW\* | hidden STAND while standing |
| `You have no sanity.` | 149 | NEW | reply to an unseen per-round command |
| `You hold no "bomb".` | 151 | NEW\* | reply to an unseen per-round command (a DROP) |
| `You are paralysed and are unable to drop anything.` | 1413 | NEW\* | |
| `Paralysed as you are, your body is not able to pick up anything.` | 1414 | NEW\* | two hidden GETs |
| `You are paralysed and unable to do that.` | 1416 | NEW\* | STAND while paralysed |
| `You are not the member of any party.` | 57 | NEW | every `pt` his system sends |
| `You may not assess someone again so soon after doing so previously.` | 3400 | NEW | ASSESS cooldown, about 1-2 s |
| `There is no exit in that direction.` | 4271 | NEW\* | |
| `I'm sorry, I don't know what "mnind" does.` | 5567 | NEW\* | typo for MIND THROW |
| `I cannot fathom the meaning of "mnind".` | 5584 | NEW\* | |
| `Your target is now: Agathon (an adventurer)` | 1 | NEW\* | origin unclear |
| `Portal tower. (indoors)` | 32 | NEW\* | also Corroded meadow (19), Fallen passageway (71), Webbed passage (76), Collapsed passage (134) |
| `A runic totem is planted solidly in the ground.` | 33 | NEW\* | in every arena room |
| `Khovroth Agathon, Wolf of Baelgrim is here. He wields a Scimitar of Eagles in each hand.` | 35 | NEW\* | |
| `Colosseum Diabolus staging grounds. (indoors)` | 9036 | NEW\* | |
| `You have earned 100 renown for being an active position holder in your organizations.` | 3408 | NEW\* | unrelated; also the renown line at 3409 |
| `Samhirket has been recycled by Seasone the Industrious, ready to be used in the next potion.` | 7828 | NEW\* | unrelated |

## Answers to the open questions

- **Telepathy without a lock.** In the same room, the (\*) abilities did not need a completed lock.
  - MIND PARALYSE went out at 3144 and 3209, during the attempt between the loss at 3099 and the finish at 3242. Agathon ate magnesium at 3168.
  - MIND IMPATIENCE (8454) and MIND DISRUPT (8506) went out between the loss at 8409 and the finish at 8531. The disrupt was cured by concentrate (8525).
  - What does need a lock:
    - MIND PRINT and SAPIENCE, refused even 1 s into an attempt (81-83);
    - MIND THROW with the target next door (5896, 5906);
    - Sapience's output, which stopped at every loss.
  - This is consistent with the players' rule (`monk.md:276`). MIND BLACKOUT, the subject of CONFLICTS #7, was not used, so it remains untested.
- **Blackout.** Mystor sent no MIND BLACKOUT.
  - "Vacancy fills the eyes of Agathon." (8291, 8795) is the only candidate. Mystor's system marks the target BLCK for exactly 4 s after it, which is blackout's duration.
  - It printed after the only two livestrikes that hit a prone Agathon: he was prone from frontkicks at 8239 and 8678, Sapience showed no `stand`, and the last "stands up." was at 6810.
  - It never printed after the six livestrikes on a standing target (1685, 1908, 4093, 6868, 7142, 7958). It also did not print after a risingkick torso on the prone target with no livestrike (8399).
  - What causes it is unproven.
- **Kata limits and stumbles.**
  - Highest 12 in Oak, Gaital, Maelstrom and Willow; 15 in Rain. That fits our code's 12 per form, and Rain's 24 cap was never reached.
  - Transitions at kata 6, 9, 12, 14 and 15 were all accepted. There was no stumble or "rhythm" line.
  - New: the idle timeout, about 19-20 s, "You can no longer maintain your deadly kata." (5967). This bears on CONFLICTS #8.
- **Kai SURGE and CHOKE cost.**
  - SURGE was not used.
  - CHOKE cost 10 kai (90% to 80%, 8940-8964) and 3.40 s of equilibrium in Oak.
  - Mana: the prompt fell about 99 against the wiki's 50, but Sapience's drain could be mixed in.
  - Damage: 2216 at 42% health.
- **Dawnkick's epilepsy line.** No dawnkick in this fight.
- **Light, parried and absorbed strikes.**
  - **Light** strikes print the normal effect line and no damage line; the system shows no % for them. They still afflict: a light nervestrike was followed by his magnesium (1903 to 1963), and a light hiru by his focus (4851 to 4860).
  - **Parried** strikes (3) print the strike, then "Agathon parries the attack with a deft manoeuvre.", and no effect line. They still count toward the kata and still spend the 2.1 s of balance (4446).
  - **Fumbled** strikes (3) count and cost balance.
  - **Absorbed:** no Shikudo strike was absorbed in this fight. The 5 absorbs were Mystor's shield against DSL blows.
  - Anomaly: the `hiru light` after `sweep` printed nothing at all, yet it counted (8081-8090).
- **Prone extras.**
  - Light hiraku and hiru on a prone Agathon (8483-8486, 8552-8555) printed no stun or confusion line. The wiki promises a stun from hiraku and possible confusion from hiru on a prone target.
  - Risingkick to the head (8790) and torso (8286, 8398) on a prone target printed only their usual lines, apart from the Vacancy line above.
- **Shields and rebounding.**
  - Rebounding never stopped a Shikudo strike, in 8 or more combos. It dropped only on his own attacks (17 of 17).
  - The shield tattoo stopped a whole combo at an equilibrium cost (1.70 s in Oak, 1.44 s in Rain).
  - SHATTER in the first combo slot broke the shield, and the rest of the combo landed (4443, 6014).
  - QUASH would strip a magical shield (wiki), but Mystor had none.

## Lessons for our package

### For our Shikudo offense

1. **Paralysis confirmation.** Add a trigger for `^Horror overcomes the face of (\w+) as (?:his|her) body locks in paralysis\.$`. It printed after all 17 nervestrikes, light ones included, and it is the only confirmation of a light nervestrike (CONFLICTS #6). Two things to fix alongside it:
   - `420_Paralysis.lua:35` expects "…'s face as … body stiffens into paralysis.", so nothing matches this line today;
   - `shikudo.md:85` still says "none on the attacker's side".
2. **Do not break rebounding for Shikudo strikes; break the shield.**
   - Rebounding never stopped a strike in this fight.
   - Lead with SHATTER whenever a shield may be up. Sapience showed `touch shield` 20 lines before the bounce (4404 to 4424), and a bounce costs the whole combo plus 1.4-1.7 s of equilibrium.
3. **The staff/shield swap strands the monk.**
   - With one arm broken or damaged, WIELD STAFF fails ("You must have both hands available…"), and the combo then fails too. Six rounds were lost this way (3386-3424, 5821-5846).
   - Keep the staff in hand when an arm is at risk, or mend first.
   - Do not send kick combos while both legs are crippled (4663, 4674, 6378).
   - With both arms out, fall back to Telepathy: MIND PARALYSE still went out (6427).
4. **Kata model.**
   - Count every strike in the sent combo: parried, fumbled and SHATTER included.
   - Count nothing for a bounced or refused combo.
   - Drop the chain after about 19 s with no strike, and on "You can no longer maintain your deadly kata.".
5. **Paralysis and disrupt against an Infernal.**
   - MIND PARALYSE on every Rain equilibrium (1.44 s) forced a magnesium each time, and rationed his DSLs.
   - MIND DISRUPT was nearly wasted: 8 of 9 were concentrated away within about 1 s.
6. **The kill that worked.**
   1. Both of his arms and a leg (7455-7465) end his DSL.
   2. Stack anorexia, asthma, slickness, impatience, paralysis and weariness until he cannot cure.
   3. Mangle the torso with risingkick torso.
   4. KAI CHOKE from about 42%.
7. **ASSESS has a cooldown of about 1-2 s.** An alias that assesses every Telepathy round gets refused (3400, 4675, 5835, 6412).

### For our defence against an Infernal DSL

1. **Parry the limb he actually hits.**
   - When Mystor's parry matched the DSL limb, both blows were stopped every time (12 DSLs).
   - His rotating parry matched only 12 of 64.
   - Agathon's blows went to the left leg 63 times, the right leg 34, the left arm 23 and the right arm never.
2. **Nausea beats parry** ("…bats your weak attempt…", 6314, 6320). Cure euphorbia's nausea early against a DSL.
3. **Venom breaks print "shrivels" lines, not "breaks with a loud crack".**
   - Our SLC level-1 break trigger `038_Limb_Broken_L1.lua:34` matches only the "loud crack" line, so it never sees a venom break.
   - Epteth and epseth choose the left limb first, whatever limb the DSL aims at.
4. **Watch for the four-limb VIVISECT window.** Twice it lasted only 1-2 s because one salve application mends one limb (~0.9 s). Keep restoration and mending moving, and treat "Agathon reaches out for your chest but his hand stops short of it." as a VIVISECT attempt.
5. **Healthleech from TORMENT feeds Agony** (506 unblockable, then the mist line, and he is cured of something). Cure that healthleech quickly.
6. **INFESTATION is a room effect.**
   - No ticks hit Mystor while he was in other rooms from 10:40:58 to 10:41:50.
   - Leaving the room stops it.
   - No trigger reads the maggot line, the deathaura line or the mist line.
7. **"Both of your legs must be free and unhindered to do that." does not mean both legs are out.** It printed with a single crippled leg (4698 with rl1, 5368 with RL2). Trigger `345_Broken_Legs_Block` and `S._legsOut()` treat it as both legs broken.

### For our tracking of this class's cures

1. **"<T>'s eyes lose their focus suddenly." is CONCENTRATE.** It cures `disrupted` and nothing else.
   - No trigger reads it.
   - `telepathy_tekura/007_Disrupt.lua:44` clears `disrupted` on a flat `tempTimer(10, …)`.
   - Add `erAff("disrupted")` on this line, and never treat it as a full cure: Mystor's own tracker wiped its whole model on it (8527).
2. **"<T>'s aura of weapons rebounding disappears." meant his own attack every time (17 of 17).**
   - `225_Rebounding_Down.lua:44` also calls `erAff("shield")`, which would wrongly clear a shield that is still up.
   - Rebounding returns 8-9 s after the pipe line. But `215_Rebounding_Smoked` (`^(\w+) takes a long drag off (\w+) pipe\.$`) allows one word before "pipe", so it cannot match "…off an enamel bubble pipe.". Its 7.5 s timer also only sets a DWB flag.
3. **The third-person salve line names the place, not the salve** ("…rubs it on his legs/arms/head"). Branch between mending and restoration; head means a crushed throat or other head cure.
4. **Mineral meanings:**
   - magnesium = paralysis, or slickness after a ruku torso;
   - plumbum = impatience;
   - ferrum = addiction or lethargy;
   - aurum = the kelp group.
5. **The wipe line means venom is still on his blade.** It printed only after fully parried DSLs: 8 of 12. The other 4 had a Hellforge investment as the first item.
6. **The slough line means slickness landed and fangbarrier is gone.** A quicksilver application should follow. Two of our triggers read the line with different meanings (`424_Got_slickness`, `706_Flayed_Sileris`).
7. **The Agony mist means one unknown affliction was cured.** Treat it as a random-cure branch.
8. **"Agathon misses you with a Scimitar of Eagles." (8 times) is not read.** `416_Clumsiness_1` matches only `misses you with \w+ dirk by a hair`. Whether these misses come from clumsiness is unproven.
9. **The SLC parry feed misses PvP parries.** `highlighting/027_Parry_Success.lua:34` matches only the PvE "You parry the assault to your <limb>…" line. `slc/001_functions.lua:254` and `ataxiaTables.missLines` (`_groups.yaml:268`) do contain the PvP wording.

## Unclear or unverified

- **"Vacancy fills the eyes of Agathon."** (8291, 8795). Blackout or stun, and from livestrike or from risingkick on a prone target? Unproven (see the Answers).
- **"`[Curing]: <ACTION>`" origin.** GUIDE.md calls it Mystor's system. Against that, our own trigger `curing_bals/002_Tree_Touch.lua` matches "[Curing]", and HELP 13.7.8 lists `CURING CLOTAT` (line 56) and `CURING KAIDOTRANSMUTE` (line 65), which match "CLOT 18" and "TRANSMUTE 814". It may be server-side curing's own line. Unresolved.
- **"`pt Intercepted Agathon (Party): …`" is not game text, contrary to GUIDE.md.** Each one draws exactly one "You are not the member of any party." (e.g. 891→898, 1643→1646). So it is Mystor's system relaying the message Sapience showed as `--> Agathon: pt Mystor: …`. One of Agathon's messages was not relayed (2313, 6844), for an unknown reason.
- **Format questions.** "You have been afflicted with X.", "You have cured the X affliction." and "You take N <type>, damage." use internal names and an odd comma. Our trigger 351 expects "Health lost: N (type).". GUIDE.md says these are game text; not proven.
- **Unexplained lines:**
  - "You have no sanity." and "You hold no "bomb"." answer commands Mystor's system hides. Paralysis turned them into one DROP and two GET refusals (1413-1415).
  - "You feel your allergy to the sun going into temporary remission." (8374).
  - "Agathon ceases to favour his head." (8717).
  - The fragment "on its own, will list all the possibilities."" (2756).
- **Tyranny and gravehands.**
  - Why TYRANNY did not prone Mystor (222). Mystor's city is unknown.
  - Why the gravehands grasped only sometimes: 7 grasps, none on many entries.
- **Infestation in Portal tower.** Ticks resumed there from 10:41:54 (7862) with no summon line seen; Sapience was down from 7690 to 8120. A second summon that nobody saw is a guess.
- **Lock losses.** No visible cause at 3099, 4760 or 8409. At 7690 the loss coincided with his tumble out, but at 4188 an earlier tumble did not break the lock.
- **His paralysis at 7924 was never cured with magnesium.** He ate ferrum instead, and a cause is not visible.
- **`touch shield` sent 8 times with no result** (8315-8358), while he was prone with both arms broken in the model.
- **His 61 FITNESS sends printed nothing.** The model had him weary, and weariness blocks FITNESS, but no game line shows it.
- **Would VIVISECT have worked** in the two four-limb windows? One or two limbs had been damaged by blows rather than "withered" by a venom.
- **EPITOMISE:** source and effect unknown. Mystor's full combos landed while it was up.
- **The "Doubleaff" tag.** Mystor's system tags ruku-to-arm strikes from kata 11 and kuro strikes from kata 12 (17 tags). Whether the game really gives both afflictions is not shown.
- **Mana per round:** combo rounds about -66, MIND rounds -132, Sapience -399. Which command costs what is not separable. Sapience may drain about 100 every 6 s.
- **Unexplained deltas:**
  - "+200h -100m" and "+313h" prompt changes with no line (possibly Kaido regeneration);
  - the kai dips of 5%;
  - Agathon's health gains with no visible heal (6289, 7630).
- **DSL damage drifted from 376 down to 284.** 353 and 284 while Mystor held the shield, against 376 and 303 with the staff, might be the shield's doing. This is a guess.
- **The prompt's "(n)" field** looks like the branch count of his tracker. "[30.31]" and "[CDBK]" are unknown.
