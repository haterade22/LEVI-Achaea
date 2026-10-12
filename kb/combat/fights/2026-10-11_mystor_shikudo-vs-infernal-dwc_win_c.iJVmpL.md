# Mystor (Shikudo) vs Agathon (Infernal, two scimitars): won with MIND SCYTHE

> Source: `kb/raw/logs/2026-10-11_mystor_shikudo-vs-infernal-dwc_win_c.iJVmpL.txt` (Mystor's own log; how to read his client's output: `kb/raw/logs/README.md`). Every line number below is a line of that file.
> Written 2026-10-11 from a line-by-line reading: one agent per ~800-line chunk, merged by a further agent that checked doubtful claims against the log. Confidence: LOG for what the lines show; the readers' own "likely" and "guess" marks are kept. Not yet independently re-verified.

## Fight

- **Who.** Mystor, the logger, is a Shikudo monk. He fights with a twisted oaken staff and swaps it for a Shield of Absorption on Telepathy rounds (1595-1596, 1669-1670). His opponent is "Khovroth Agathon, Wolf of Baelgrim" (210).
- **Opponent class: Infernal (the first read is confirmed).** Every Infernal signature appears in his own commands (seen through MIND SAPIENCE) or in the game's lines:
  - `dsl` with two scimitars (271 onwards);
  - the Hellforge investments TORMENT, TORTURE and EXPLOIT (275, 527, 760);
  - `vivisect Mystor` (3241-3242);
  - INFESTATION maggots (448);
  - a daemonic hyena (209, 227);
  - gravehands already up in his room (210);
  - the "sanguine mist" line after a healthleech drain (817-818), which is likely Agony.
- **Spec and weapons.** Dual-wield cutting (DSL).
  - Two Scimitars of Eagles, `scimitar388622` and `scimitar314077` ("He wields a Scimitar of Eagles in each hand.", 210), worn in "a scabbard embellished with a gold eagle" (2932).
  - He also carries "an archaic, Mhaldorian battleaxe" (system line 2857). He swaps to it only for UNDERCUT (2852-2858) and back afterwards (2929-2934).
- **Result.** Mystor won with MIND SCYTHE at 11:53:25 (system line 4232; "You have slain Agathon." 4239). One second earlier Agathon was at full health, 7716/7716 (4199).
- **Duration.**
  - The log runs 11:49:35-11:53:25.
  - The mind lock started at 11:51:05 (102).
  - The first blow was at 11:51:27 (222) and the kill at 11:53:25, so about 2 minutes of fighting.
- **Where.** The Colosseum Diabolus arena, forest rooms at night (48). The fight was in Ruined copse (207-214), and the win ended in the staging grounds (4246).
- **Maximum health.** Agathon 7716 (224). Mystor 6265 (prompt after 3977).

## How it went

1. **Before contact, 11:49:35-11:51:26 (1-197).** Mystor is in Rain at kata 0, and his kai decays from 20 to 5 (2, 28, 34, 89).
   - Twelve `mind print|mind sapience` sends are refused with "You require a mindlock to perform that ability." (9-97). Agathon was outside the area at the time.
   - Mindnet and Alertness report Agathon arriving at 11:50:59-11:51:03 (88, 91).
   - MIND LOCK starts at 11:51:05 (102). A second MIND LOCK is refused (105). A progress line prints at 131, and the lock finishes around 11:51:13 (134): about 8 s, with no balance or equilibrium spent. Mystor walked four rooms out and back while it built (111-187).
   - MIND PRINT and MIND SAPIENCE follow (141-144). From 150 on, Agathon's typed commands print as `--> Agathon: ...` (454 such lines in the log).
2. **Rain 1, 11:51:27-45 (198-986), kata 0 to 15.**
   - The first combo rebounds off Agathon's shield tattoo (222, 1.44 s of equilibrium). SHATTER + frontkick + kuro then breaks the shield (244-251).
   - Agathon sends a DSL every 1.5-3 s (271, 322, 416, 519, 612, 689, 751).
   - Each time Mystor is paralysed, his alias swaps the combo for MIND DISRUPT (351, 470). Agathon CONCENTRATEs in the same second both times (357-358, 482-483).
   - TORTURE gives haemophilia (527-528), and clotting stops from there.
   - The Rain kata reaches 12 (783) and then 15 (910).
   - Aconite + EXPLOIT leave Mystor with stupidity, paranoia and weariness (751-762), and stupidity misfires follow (774-775, 825, 884, 899-900, 922, 936).
   - Slike + gecko give anorexia and slickness and strip his fangbarrier (863-874).
   - The first 506 unblockable drain and mist line come at 817-818.
   - A larkspur + curare DSL to the leg Mystor was parrying is parried on both blows (972-976).
3. **Oak 1, 11:51:45-53 (987-1270), kata 1 to 12.**
   - Mystor transitions at Rain kata 15 inside the alias (987).
   - Each nervestrike prints "Horror overcomes the face of Agathon as his body locks in paralysis." (993, 1131, 1219), and Agathon eats magnesium 1-2 s later (1013, 1187, 1254).
   - Mystor breaks his own softlock in one second: FOCUS, aurum, realgar, quicksilver, then a sip (1023-1045).
   - Ruku to the torso strips Agathon's fangbarrier (1078), and he re-applies quicksilver (1117).
   - While Agathon is paralysed his DSL round prints nothing (1165-1169), but his FITNESS works (1173). It is the only one of his 54 fitness sends that does.
   - He raises his shield tattoo (1258).
4. **Gaital 1, 11:51:53-12:02 (1271-1589), kata 1 to 12.**
   - The transition and SHATTER land in the same second as Agathon's new shield (1271-1277).
   - Mystor lands four flashheel-right combos. Each time Agathon applies mending to his legs within about 1 s (1289, 1326, 1418, 1515).
   - Agathon's DSLs now do 283 per blow (1349-1541). Mystor's kai reaches 100% (1358).
5. **Rain 2, 11:52:02-20 (1590-2189), kata 0 to 15.**
   - Mystor transitions at Gaital kata 12 into a Telepathy round: shield in hand, MIND DISRUPT (1590-1599). Agathon CONCENTRATEs (1607-1608).
   - The lock breaks at 11:52:03 (1631) with Agathon still in the room. Mystor's system re-sends MIND LOCK at once (1630, 1645), the game prints "Your mindlock is speeded by the mindprint you hold." (1646), and the lock is back by 11:52:06 (1715).
   - There are no `-->` lines from 1612 to 1745. The Sapience feed returns only when MIND SAPIENCE is cast again (1741).
   - A shield at 1652 is shattered at 1672. The next shield (1813) makes a combo sent without SHATTER rebound (1827); it is shattered at 1855.
   - Agathon lands torment + curare twice on the left leg (1889, 1977), and Mystor parries a third DSL (2060-2064).
   - A frontkick followed by hiru prints "Agathon looks about bemusedly." (2085).
   - The 506 drain and mist come again (2162-2163).
6. **Oak 2, 11:52:20-28 (2190-2448), kata 1 to 12.**
   - Transition at Rain kata 15 (2190), then three nervestrikes (2196, 2268, 2343).
   - After the first nervestrike, Agathon's `touch shield` still raises a shield (2227-2228) before he eats magnesium (2231-2232). Mystor shatters it (2263).
   - Risingkick to the torso + livestrike + ruku to the torso (2381-2388) give asthma and slickness and strip his fangbarrier. Agathon answers on five balances in one second (2394-2403). His lowest health of the fight is 71.27% (2390).
7. **Gaital 2, 11:52:28-40 (2449-2823), kata 1 to 12.**
   - Transition plus SHATTER on a fresh shield (2449-2455).
   - Flashheels (2457, 2538) and two dawnkick combos at 2.8 s each (2593, 2681). Agathon FOCUSes 2-3 s after each dawnkick (2667-2668, 2758-2759).
   - His DSLs switch between Mystor's legs: three land (2496, 2629, 2768) and two are parried (2572-2576, 2716-2720). Mystor's own model puts his right leg at 96.6% (2775).
   - The hyena tears away Mystor's mindcloak (2798-2799).
8. **Rain 3, the turning point, 11:52:40-53:00 (2824-3451).**
   - As Mystor transitions (2824), Agathon sheathes both scimitars, wields the battleaxe and UNDERCUTs Mystor's right leg: 730 damage, the leg at level 2, Mystor prone (2852-2866).
   - Agathon draws the scimitars and DSLs the right arm with epseth + epteth (2929-2948). At 11:52:42 Mystor is prone with all four limbs afflicted: `[PR, RL2, la1, RA2, ll1]` (2950).
   - Agathon then sends assess, a party report and an aurum. He sends no VIVISECT.
   - Mystor's Kaido RESTORE at 11:52:43 mends the two withered limbs and refuses the two damaged ones (2973-2979). It costs 7.22 s of equilibrium (2980).
   - Salves fix the rest (3009-3149). Mystor stands only when his equilibrium returns, at 11:52:50 (3183-3186).
   - Meanwhile Agathon sends 20 bare `stand`s (3001-3155). He re-withers the left arm the moment the right arm is mended (3159-3167), and Mystor uses the tree on it (3172).
   - Agathon then tries VIVISECT with nothing withered (3241-3242).
   - Mystor alternates light-kuro combos with MIND IMPATIENCE (3289-3297, 3397-3405). Agathon eats plumbum within about 1 s each time (3365, 3436). Mystor's shield absorbs one DSL blow (3330).
9. **Oak 3, 11:53:01-12 (3452-3861), kata 1 to 12.**
   - Transition at Rain kata 10 (3452), then a risingkick to the torso in every combo, livestrike, ruku to the torso (fangbarrier stripped, 3464) and two light nervestrikes (3514, 3685).
   - Agathon: one DSL parried (3484-3488), one blow missed (3563), then torment + curare lands (3624-3632) with the 506 drain and mist (3636-3637).
   - He is paralysed from 11:53:07.8 (3685) until he eats magnesium at 11:53:13 (3898). In between he sends 13 torture + curare rounds, and none of them prints anything.
   - "Vacancy fills the eyes of Agathon." prints after a light livestrike (3785).
10. **Gaital 3 and the scythe, 11:53:12-25 (3862-4249).**
    - Transition at Oak kata 12, then sweep + flashheel left (3862-3871).
    - Needle + spinkick + kuro (3966-3977):
      - the needle crushes his throat;
      - the spinkick hits the prone head for +15%, taking it to 100% ("You feel something give way under your blow.", 3973; model `H3`, 3981);
      - the kuro takes his right leg to 100%.
    - Agathon is now at 78.37%. He spends his salve balance on his legs (mending 4033, restoration 4078, mending 4176), tries to tumble out (4036, 4126, 4159-4160) and uses EPITOMISE (4040).
    - Mystor transitions to Rain at kata 5 with the shield in hand. He casts MIND IMPATIENCE (4056-4065), IMPATIENCE again (4094), BATTER (4113) and IMPATIENCE once more (4198).
    - Agathon answers with plumbum (4082, 4137, 4178) and FOCUS (4180). He applies restoration to his head only at 11:53:25 (4207).
    - MIND SCYTHE (4231-4232) kills him: "You have slain Agathon." (4239), then "Defeated, Agathon is cast out of the Arena." (4241).

## The opponent

### Rotation (his commands as Sapience shows them)

His attack round, sent every time he had balance:
```
stand
wield scimitar388622 scimitar314077
wipe scimitar314077
dsl Mystor <limb> <venom1|investment> <venom2>
assess Mystor
```
After each round he sends `pt Mystor: <what landed>` to his party (440, 1948, 2960). Late in the fight he stopped naming a limb: `dsl Mystor prefarar curare` (3562) and `dsl Mystor torment curare` (3624).

His finisher (2852-2935), then `dsl Mystor right arm epteth` (3159) and `vivisect Mystor` (3241):
```
sheathe scimitar<id>      x2
wield battleaxe<id>
undercut Mystor right leg
unwield left
draw scimitar<id>         x2
dsl Mystor right arm epseth epteth
```

| Lines | Command | Result on Mystor |
|---|---|---|
| 271, 322, 612 | `dsl Mystor <right leg/right arm> torment curare` | 367 + 367; healthleech (torment line) + paralysis |
| 416 | `dsl Mystor right leg euphorbia curare` | 367 + 367; nausea + paralysis |
| 519 | `dsl Mystor right arm curare torture` | 367 + 367; curare on an already-paralysed Mystor printed only the sting line (523); haemophilia (527-528) |
| 689 | `dsl Mystor right arm kalmia euphorbia` | 295 + 295; asthma + nausea |
| 751 | `dsl Mystor right leg aconite exploit` | 367 + 367; stupidity, then paranoia + weariness |
| 863 | `dsl Mystor right arm slike gecko` | 367 + 367; anorexia + slickness, fangbarrier stripped |
| 972, 2060, 2572, 2716, 3484 | DSLs to the limb Mystor was parrying | both blows parried every time (974/976, 2062/2064, 2574/2576, 2718/2720, 3486/3488) |
| 1168, 3526, 3705-3847 (13 sends) | DSLs sent while paralysed | nothing printed |
| 1346, 1436, 1533 | `dsl Mystor right arm torment curare` / `euphorbia curare` | 283 + 283; healthleech or nausea, plus paralysis |
| 1889, 1977, 2139 | `dsl Mystor <left/right> leg torment curare` | 367 + 367; healthleech + paralysis |
| 2496 / 2629, 2768 | `dsl Mystor <leg> torment curare` | 283 + 283 / 352 + 352; healthleech + paralysis |
| 2858 | `undercut Mystor right leg` (battleaxe) | 730; right leg broken to level 2; prone |
| 2935 | `dsl Mystor right arm epseth epteth` | 367 + 367; right arm to level 2; LEFT leg and LEFT arm withered |
| 3159, 3322 | `dsl Mystor right arm epteth` | left arm withered (blow 1); 3322's second blow absorbed by Mystor's shield (3330) |
| 3241 | `vivisect Mystor` | "...his hand stops short of it." (Mystor had no limb afflicted) |
| 3562 | `dsl Mystor prefarar curare` | blow 1 missed (3563); blow 2 365 + paralysis |
| 3624 | `dsl Mystor torment curare` | 365 + 365; healthleech + paralysis; then the 506 drain and the mist (3636-3637) |

The first-named venom always lands on the first blow and the second on the second. Investments can ride either blow: torment on blow 1, torture and exploit on blow 2 (1889-1899, 519-528, 751-762).

### Venoms, investments, abilities and their lines

| Source | What Mystor saw | Lines |
|---|---|---|
| DSL itself | game line gagged; system prints `Agathon: Dsl <limb> -> You`, then `You take N physical cutting, damage.` per blow | 272-279 |
| curare / euphorbia / kalmia / aconite / slike / gecko | the affliction's standard line: paralysis 281, nausea 421, asthma 694, stupidity 756, anorexia 868, slickness 874 (with the fangbarrier strip at 873) | |
| epseth / epteth | `You stumble as your left leg shrivels into a useless appendage.` / `You watch, in horror, as your left arm shrivels up and becomes useless.` | 2943, 2948, 3164, 3327 |
| TORMENT / TORTURE / EXPLOIT | their own lines replace the affliction's standard line | 275, 527, 760 |
| UNDERCUT | `As pain lances up your leg from the grievous wound, <T> drives you clean off your feet.` | 2865 |
| INFESTATION | 13 maggot ticks, each giving one affliction: asthma x3, lethargy x3, darkshade x2, weariness x2, nausea, confusion, clumsiness | 448 ... 4145 |
| daemonic hyena | 29 attacks, both attack lines, 121-221 physical cutting or blunt plus bleeding; strips one defence (vitality, consciousness, mindcloak, mindseye, alertness) | 227 ... 4211; 1687, 2288, 2799, 3232, 4212 |
| healthleech drain + Agony (likely) | `You take 506 unblockable, damage.` while Mystor carried his healthleech; the mist line follows 3 of the 4 drains | 394, 817-818, 2162-2163, 3636-3637 |

### Curing order (all typed commands seen in Sapience; minerals only)

1. **Disrupted:** CONCENTRATE first, in the same second, every time (357-358, 482-483, 1607-1608).
2. **Impatience:** plumbum within about 1 s, ahead of weariness, lethargy, clumsiness and healthleech (3363-3365, 3435-3436, 4081-4082; after BATTER, 4137 and 4178).
3. **Paralysis:** magnesium 1-2 s after each nervestrike (1013, 1187, 1254, 2232, 2280, 2364, 3546). Two exceptions:
   - he touched his shield before eating (2227-2231);
   - once he ate two aurums first (3730, 3837) and stayed paralysed about 5 s (3685 to 3898).
4. **Prone:** stand about 2 s later, usually after one eat or sip (257, 604, 681, 854, 966, 1753, 1881, 1969, 2054, 2130). He never stood after the sweep at 3868.
5. **Kelp group (weariness, clumsiness, healthleech, asthma):** aurum on nearly every eat balance. The tree on cooldown, about every 14 s (586, 1201, 1660, 2154, 2616, 3219, 3576, 4044).
6. **Lethargy:** ferrum, rarely and late (3270-3271, 3029-3031, 4028-4029). It sat on him for 10 s or more at a time.
7. **Slickness:** magnesium if his eat balance was free (1114, 3492-3493), smoke realgar if not (1176-1177, 2396-2397). He re-applies quicksilver right after a fangbarrier strip (1117, 2399, 3494-3495).
8. **Asthma:** aurum (2394, 3470). FITNESS is typed (54 sends, 3 of them misspelt `fitenss`) and showed a success line only once (1173).
9. **Limbs:** mending to the legs within about 1 s of every flashheel (1289, 1326, 1418, 1515, 2467, 2552). Restoration for a leg at 100% (3944-3945, 4077-4078). Legs before head: restoration to the head only at 4206-4207.
10. **Mental afflictions:** FOCUS for epilepsy after dawnkick (2668, 2759), for confusion after hiru (2093), for stupidity after spinkick (3989), and after BATTER (4180).
11. **Health:** sips at 71-86% (822, 1088, 1330, 1548, 2095, 2401, 2620, 3473, 3840, 3996), with potash beside a sip (1333, 2097, 2403, 3475).

### Defences

- **Shield tattoo:** up on arrival, then raised again 5 times (1258, 1652, 1813, 2228, 2416). All six were shattered.
- **Fangbarrier (quicksilver):** stripped three times by ruku to the torso (1078, 2388, 3464). The shell forms about 10 s after each application.
- **Gravehands** were already in his room (210).
- **EPITOMISE** (4040); its effect is unknown.
- He tried to TUMBLE out at the end (4160).
- No rebounding aura was seen all fight.

### Kill route against Mystor

1. DSL one leg up to about 97% (6.9% per blow in Mystor's own model, 2775).
2. Swap to the battleaxe and UNDERCUT: a level-2 leg and prone (2858-2866).
3. Swap back and DSL with epseth + epteth to wither the other limbs (2935-2950).
4. VIVISECT, which the wiki says needs all four limbs withered.

He reached the four-limb prone state at 11:52:42 (2950) but never sent VIVISECT before Mystor's RESTORE broke it (2973). Around this core he kept up pressure with curare paralysis, torment healthleech (feeding Agony), infestation and the hyena.

## Mystor's offense

**Round structure.** Each round is one alias:

`[unseen command -> "You have no sanity."] / [unseen -> 'You hold no "bomb".'] / stand / parry <limb> / [transition to <form> form] / [wield staff|shield] / combo <T> <a> <b> <c> OR mind <ability> <T> / assess <T>`

- When he is paralysed, the combo slot becomes a MIND ability (343-355, 462-474).
- Telepathy rounds wield the Shield of Absorption, and the next combo round re-wields the staff.

**Forms and kata.** The cycle ran Rain, Oak, Gaital, three times, and ended in Rain.

| Change | Kata at the change | Line |
|---|---|---|
| Rain to Oak | 15 | 987, 2190 |
| Rain to Oak | 10 | 3452 |
| Oak to Gaital | 12 | 1271, 2449, 3862 |
| Gaital to Rain | 12 | 1590, 2824 |
| Gaital to Rain | 5 | 4056 |

- Highest chain per form: Rain 15 (910, 2088), Oak 12, Gaital 12.
- No stumble or rhythm line, no refused transition, no ADOPT.
- Each transition was a separate command placed before the combo; the combo then counted from 1.

**Combos per form** (from the `[Zax]` command echoes):
- **Rain:**
  - `frontkick <side> kuro <side> ruku <side>` (561, 661, 772, 897, 1917, 2016)
  - `shatter frontkick <side> kuro left` (240, 1664, 1850)
  - `frontkick left hiru kuro left` (2076)
  - light two-strike combos: `kuro light right kuro light right` and `kuro light right ruku light right` (2824, 3192, 3250, 3345, 3418)
- **Oak:**
  - `nervestrike risingkick head ruku <side|torso>` (987, 1126, 1214, 2190)
  - `risingkick head livestrike ruku torso` (1067)
  - `shatter risingkick head nervestrike` (2258)
  - `nervestrike risingkick head kuro right` (2338)
  - `risingkick torso livestrike ruku torso` (2377, 3452)
  - `risingkick torso ruku torso nervestrike light` (3504)
  - `nervestrike light risingkick torso livestrike light` (3680)
  - `risingkick torso livestrike light kuro light right` (3776)
- **Gaital:**
  - `shatter flashheel right kuro left` (1271, 2449)
  - `flashheel right` with kuro/ruku pairs (1310, 1402, 1491)
  - `flashheel left kuro light right ruku light right` (2533)
  - `dawnkick kuro light right ruku light right` x2 (2588, 2676)
  - `sweep flashheel left` (3862)
  - `needle spinkick kuro right` (3966)

Damage to Agathon per combo (from ASSESS) was 420-1,141: 252, 573, 673, 1080, 3978.

**Telepathy.** Every MIND attack went out under a lock, which held from 134 to 1631 and from 1715 to 4234. Without a lock, only the pre-fight refusals exist.
- MIND LOCK: 102-134, re-locked at 1645-1715.
- MIND PRINT: 141.
- MIND SAPIENCE: 143 and again at 1741 after the lock was re-made.
- MIND DISRUPT x3 (351, 470, 1598): each one was CONCENTRATEd off within the second. Two of them were cast while Mystor was paralysed.
- MIND IMPATIENCE x5 (3297, 3405, 4065, 4094, 4198).
- MIND BATTER x1 (4113).
- MIND SCYTHE x1 (4232).
- MIND CLOAK ON, used only as a defence after the hyena stripped it (2804-2805).

**Kai.** No kai attack was used: no SURGE, CHOKE, CRIPPLE or ENFEEBLE.
- Kai was at 90% from 979 (11:51:45), at 100% from 1358, and only dipped by the 5% decay ticks until the end.
- Kaido abilities used:
  - TRANSMUTE x4 through the game's own curing (752, 752, 800, 940 at 336, 455, 767, 890): mana into health 1:1, no kai, no balance or equilibrium;
  - CLOT (40 mana each);
  - RESTORE once (2973);
  - CONSCIOUSNESS ON (2305).

**Shields and rebounding.** Six shields and six SHATTERs (245, 1277, 1672, 1855, 2263, 2455).
- The two combos sent without SHATTER into a fresh shield rebounded whole (222, 1827): nothing landed, the kata did not grow, and it cost 1.44 s of equilibrium.
- SHATTER inside a combo counts as a kata action and the rest of the combo still lands (245-251, 1277-1283).

**How the kill was set up (the "scythe fork").**
1. Sweep makes him prone; flashheel takes his left leg (3862-3871, 11:53:12).
2. Needle crushes his throat, spinkick hits the prone head (+15% to 100%; model `H3`), kuro takes the right leg (3966-3977).
3. Agathon puts his salves on his legs and leaves the head until 4207.
4. Mystor goes to Rain at the minimum kata of 5. He keeps impatience on at 1.07 s each and adds BATTER (stupidity, epilepsy, dizziness), faster than Agathon's plumbum + plumbum + focus can clear them.
5. MIND SCYTHE kills at full health, 13 s after the sweep (3868 to 4239).
   - The wiki's condition is a mangled head plus two of stupidity, impatience, dizziness, epilepsy and confusion (kb/classes/monk.md:371).
   - The head level itself shows only in Mystor's model.

## Timings

| What | Value | Form | Lines |
|---|---|---|---|
| Combo with frontkick, risingkick, flashheel or sweep | 2.1 s balance (28 of 32 readings) | Rain, Oak, Gaital alike | 248, 905, 996, 1280, 2199, 3459, 3871 |
| Shatter + frontkick + kuro sent with WIELD STAFF in the same alias | 2.3 s (the only other reading in that group) | Rain | 1664-1675 |
| Dawnkick combo | 2.8 s; "all limbs" back after 2.82 s | Gaital | 2593, 2681, 2786-2787 |
| Needle + spinkick (prone head) + kuro | 3.7 s | Gaital | 3974, 4053 |
| Combo with no kick (light strikes only) | no balance reading; only the arms report back | Rain | 2912-2913 |
| Combo rebounding off a shield | 1.44 s of EQUILIBRIUM, balance kept; back in 1.36-1.38 s | Rain | 223, 237-238, 1828, 1847-1848 |
| MIND SAPIENCE | 2.89 s eq (wiki 4.00) | Rain | 144, 160, 1742, 1819 |
| MIND DISRUPT | 2.89 s eq (wiki 4.00) | Rain | 352, 471, 1599, 1662 |
| MIND IMPATIENCE | 1.07 s eq x5 (wiki 1.50); back in 1.00-1.26 s | Rain | 3295, 3403, 4063, 4092, 4196 |
| MIND BATTER | 2.70 s eq (wiki 4.00); back in 2.77 s | Rain | 4111, 4190 |
| MIND SCYTHE | 2.89 s eq (wiki 4.00) | Rain | 4231 |
| TOUCH MINDSEYE | 2.55 s eq | Oak | 3613, 3678 |
| Kaido RESTORE with four limbs afflicted | 7.22 s eq (wiki base 3.00), about -266 mana | Rain | 2980-2981, 3184 |
| MIND LOCK without / with a mindprint | about 8 s / about 2 s; no balance or eq | Rain | 102-134; 1645-1715 |
| Eating (herb or mineral) | 1.41-1.66 s | all | 313, 828, 1616, 2473, 3372, 4184 |
| Focus | 2.32-2.46 s | Rain, Oak | 943, 1019, 1109, 1873 |
| Smoke | 1.43 s | Oak | 1091-1092 |
| Sip | 4.28-4.47 s | all | 511, 723, 1007, 1193, 1626, 2793, 3826 |
| Moss / potash | 5.88-5.96 s | all | 645, 1052, 3085 |
| Tree | 13.87-14.02 s | all | 914, 1379, 1841, 2419, 3034, 3554, 4132 |
| Salve: mending | 0.95-0.97 s | Rain | 3059, 3212, 3375 |
| Salve: restoration | 4.02 s; the cure lands as the balance returns | Rain | 3009-3012, 3136-3139 |
| Kai | +10 per Agathon DSL, also when fully parried (979); -5 at about :02 and :32 each minute | all | 283, 338, 428 ... 1358; 392, 1580, 2567, 3496 |
| Agathon: DSL rounds | every 1.5-3 s | | 271-759 |
| Agathon: infestation tick | 9-10 s, 13 ticks | | 448 ... 4145 |
| Agathon: hyena | about 3 s, with pauses of 6-10 s (11:51:34-52:05, 11:52:11-21, 11:53:03-19); 29 attacks | | 227 ... 4211 |
| Agathon: tree | every 13-18 s, 8 touches | | 586 ... 4044 |
| Agathon: quicksilver to shell | about 10 s | | 1117 to 1465, 2399 to 2724, 3495 to 3888 |
| Agathon: CONCENTRATE after DISRUPT | same second | | 357-358, 482-483, 1607-1608 |
| Agathon: magnesium after nervestrike | 1-2 s (once about 5 s) | | 1013, 1187, 1254, 2232, 2280, 2364; 3685 to 3898 |
| Agathon: mending after flashheel | about 1 s | | 1289, 1326, 1418, 1515, 2467, 2552 |
| Agathon: shield again after a SHATTER | 6 s at the quickest | | 1672 to 1813 |
| Mystor prone after the undercut | about 10 s, held by RESTORE's equilibrium | Rain | 2866 to 3186 |

## Game lines

The KB column was checked by searching kb/ for each line's fixed text on 2026-10-11:
- **known**: a curated kb/ page has the line;
- **raw**: only kb/raw evidence files have it;
- **NEW**: it is nowhere in kb/.

System lines (`You: ...`, `[Zax]`, `[Curing]`, timers, `Agathon: Dsl ...`, `My <Limb>`, `pt ...`, banners) are left out.

**Our attacks and effects**

| Line | Game text | KB | Note |
|---|---|---|---|
| 245 | `The end of your staff smashes the magical shield surrounding <T> in an explosion of translucent shards.` | known | SHATTER, x6 |
| 222 | `A dizzying beam of energy strikes you as your attack rebounds off of <T>'s shield.` | NEW | whole combo rebounds, x2 (222, 1827) |
| 247 | `The instep of your foot smashes into the <left/right> underarm of <T>, throwing him from his feet and sending him spinning to the ground.` | known | frontkick, prone |
| 250 | `The staff cracks across the <left/right> thigh of <T>.` | known | kuro, light or full |
| 571 | `The staff connects to the <left/right> arm with a resounding crack, the limb flopping uselessly.` | known | ruku to the arm; names no target |
| 1077 | `<T> staggers as the staff cracks across his ribs, sweat breaking out upon his forehead.` | known | ruku to the torso |
| 1078 | `The protective coating covering the skin of <T> sloughs off.` | raw | right after ruku torso, only with a formed fangbarrier (1078, 2388, 3464) |
| 993 | `Horror overcomes the face of <T> as his body locks in paralysis.` | NEW | nervestrike, all 8 incl. light (3514, 3685) |
| 995 | `Your foot catches <T> under the chin, snapping his head back.` | known | risingkick head, x7, target always standing |
| 2382 | `Your foot drives into the solar plexus of <T>.` | known | risingkick torso, x5 |
| 1075 | `The breath of <T> leaves him in an explosive gasp as the end of the staff smashes home.` | known | livestrike |
| 1279 | `You feel the satisfying crunch of bone under the impact of your heel.` | known | flashheel |
| 2084 | `The staff connects to the side of <T>'s head with a resounding crack.` | known | hiru |
| 2085 | `<T> looks about bemusedly.` | NEW | after hiru on a target the same combo had just proned |
| 3868 | `The staff sweeps the legs out from under <T>, sending him sprawling.` | known | sweep |
| 3971 | `The end of the staff smashes into the exposed throat of <T>, crushing cartilage.` | known | needle |
| 3973 | `You feel something give way under your blow.` | NEW | spinkick to the prone head (head to 100% in the model) |
| 3785 | `Vacancy fills the eyes of <T>.` | NEW | after a light livestrike; meaning unknown |
| 251 | `You are now maintaining a kata chain of <N> actions.` | known | the `[Form]: ` prefix is the system's |

**Opponent attacks and effects**

| Line | Game text | KB | Note |
|---|---|---|---|
| 227 | `A daemonic hyena snarls as she hurls herself at you, raking her claws across your face.` | NEW | blunt or cutting damage |
| 932 | `A daemonic hyena lets loose a wooping cackle as it lunges at you, sinking its teeth into your flesh.` | NEW | "it", not "she" |
| 1687 | `Your <defence> defence is torn to tatters by her jaws.` | NEW | the hyena strips a defence |
| 448 | `You recoil in horror as countless maggots squirm over your flesh, burrowing into your pores.` | NEW | INFESTATION tick |
| 275 | `You feel your strength begin to leech away at the touch of the profane weapon.` | NEW | TORMENT: healthleech |
| 527 | `Your very blood rebels against the profane touch of <weapon>.` | NEW | TORTURE: haemophilia |
| 760 | `You feel the strength simply drain out of you, a mad sense of unease pervading your mind and setting your hands to trembling.` | NEW | EXPLOIT: paranoia + weariness |
| 2865 | `As pain lances up your leg from the grievous wound, <T> drives you clean off your feet.` | NEW | UNDERCUT |
| 2943 | `You stumble as your left leg shrivels into a useless appendage.` | NEW | epseth |
| 2948 | `You watch, in horror, as your left arm shrivels up and becomes useless.` | NEW | epteth (2948, 3164, 3327) |
| 3242 | `<T> reaches out for your chest but his hand stops short of it.` | NEW | failed VIVISECT |
| 3563 | `<T> misses you with a Scimitar of Eagles.` | known | |
| 1345 | `<T> carefully wipes all the venoms off of a Scimitar of Eagles.` | NEW | printed only 3 times (1345, 2138, 2767) |
| 2853 | `With a sibilant 'shhhiiiinnngggt!', <T> smoothly sheathes a Scimitar of Eagles.` | NEW | the swap to the battleaxe |
| 2932 | `A Scimitar of Eagles rings out brightly as <T> rapidly draws it from a scabbard embellished with a gold eagle.` | NEW | |
| 274 | `You take <N> physical cutting, damage.` | NEW | DSL 283-367 per blow, undercut 730, hyena 121-168 |
| 228 | `You take <N> physical blunt, damage.` | NEW | hyena 168-221 |
| 394 | `You take 506 unblockable, damage.` | NEW | x4, always while Mystor had healthleech |
| 629 | `You take <N> raw, damage.` | NEW | bleed tick |
| 630 | `You bleed <N> health.` | raw | |
| 209 | `A daemonic hyena awaits in savage readiness, golden eyes burning with a cold, cunning malevolence amidst the steady exhalation of crimson fog from slavering jaws.` | NEW | room |
| 210 | `Hands of rotting flesh and white bone push up from the ground.` | NEW | gravehands |
| 210 | `Khovroth Agathon, Wolf of Baelgrim is here. He wields a Scimitar of Eagles in each hand.` | NEW | |

**Afflictions landing on Mystor**

| Line | Game text | KB | Note |
|---|---|---|---|
| 276 | `You have been afflicted with <affliction>.` | NEW | every new affliction; origin unproven |
| 281 | `A prickly stinging overcomes your body, fading away into numbness.` | known | paralysis; also prints when already paralysed (523) |
| 421 | `A sense of extreme nausea washes over you.` | known | |
| 450 | `You feel a tightening sensation grow in your lungs.` | known | asthma |
| 756 | `Hmmmm. Why must everything be so difficult to figure out?` | known | stupidity |
| 2426 | `Your limbs grow heavy and you groan feebly.` | known | weariness (not printed for EXPLOIT's weariness, 762) |
| 1556 | `You feel your energy robbed from you as lethargy overtakes you.` | known | |
| 1799 | `Your head spins as your mind is drowned in chaos and confusion.` | known | |
| 2111 | `You gasp as your fine-tuned reflexes disappear into a haze of confusion.` | known | clumsiness |
| 868 | `The idea of eating or drinking is repulsive to you.` | known | anorexia |
| 873 | `The protective covering coating your skin sloughs off.` | raw | fangbarrier stripped by slickness |
| 874 | `You notice that your sweat glands have begun to rapidly secrete a foul, oily substance.` | known | slickness |
| 849 | `You feel your allergy to the sun going into temporary remission.` | NEW | before darkshade's line (849, 3068) |
| 850 | `Your vision is flooded with light, and your face suddenly reddens.` | known | darkshade |
| 2863 | `Your <limb> is greatly damaged from the beating.` | known | level 2 |
| 774 | `You grunt a bit and then let out a loud "OINK!"` | NEW | stupidity misfire |
| 775 | `You get down on one knee and serenade the world.` | NEW | stupidity misfire (775, 798, 884) |
| 922 | `You pick your nose absently.` | NEW | replaced a pt send |
| 825 | `"The voices! The voices! Get them out of my head!!" you moan, holding your head in pain.` | raw | while stupid |
| 899 | `Your tree of life tattoo glows faintly for a moment then fades, leaving you unchanged.` | NEW | only while stupid, during the tree cooldown; did not restart it |
| 900 | `Your mind is whirling with thoughts - you cannot settle down to sleep.` | NEW | while stupid |

**Mystor's cures and defences**

| Line | Game text | KB | Note |
|---|---|---|---|
| 287 | `You eat a magnesium chip.` | NEW | |
| 288 | `Your muscles unlock; you are no longer paralysed.` | known | |
| 289 | `You have cured the <affliction> affliction.` | NEW | after every cure line; origin unproven |
| 403 | `You eat an aurum flake.` | raw | |
| 598 | `You eat a ferrum flake.` | raw | |
| 433 | `You eat a potash crystal.` | NEW | |
| 434 | `You feel your health and mana replenished.` | raw | |
| 366 | `You take a drink from an amethyst vial.` | NEW | both elixirs |
| 367 | `Your mind feels stronger and more alert.` | raw | mana |
| 543 | `The elixir heals and soothes you.` | known | health |
| 299 | `You touch the tree of life tattoo.` | raw | cured healthleech (300) and a broken arm (3173) |
| 300 | `Your aching, pain-wracked body is soothed and calmed.` | known | healthleech cured |
| 789 | `You focus your mind intently on curing your mental maladies.` | raw | |
| 790 | `Aaaahhh. No one is out to get you after all.` | known | |
| 950 | `You aren't such a complete idiot anymore.` | known | |
| 1028 | `Food is no longer repulsive to you.` | known | |
| 1035 | `You take a long drag of realgar off your pipe.` | raw | |
| 1036 | `Your glands cease their oily secretion.` | known | |
| 1041 | `You apply a quicksilver droplet to yourself.` | raw | |
| 1337 | `The quicksilver hardens into a supple metallic shell.` | raw | 10 s after applying |
| 493 | `Your bronchial tubes open up and your asthma is cured.` | known | |
| 599 | `Your stomach becalms itself.` | known | |
| 837 | `Your blood regains its ability to clot.` | known | |
| 1102 | `No longer will the sunlight harm you.` | known | |
| 1152 | `Your limbs strengthen and you feel stronger.` | known | |
| 1700 | `The lethargy evaporates, leaving you full of energy.` | known | |
| 1805 | `The confusion lifts from your mind and it is clear once again.` | known | |
| 2117 | `Thank Maya, the Great Mother! Your clumsiness has been cured.` | known | |
| 2870 | `You take out some salve and quickly rub it on your <legs/arms>.` | raw | same for mending and restoration |
| 3009 | `Your <limb> feels stronger and healthier.` | known | restoration, about 4 s after applying |
| 2974 | `The bones in your <limb> mend.` | known | |
| 3186 | `You stand up.` | raw | |
| 2305 | `You will remain conscious at all times.` | NEW | CONSCIOUSNESS ON |
| 3612 | `Touching the mindseye tattoo, your senses are suddenly heightened.` | raw | |
| 201 | `You will now attempt to parry attacks to your <limb>.` | raw | |
| 974 | `You parry the attack with a deft manoeuvre.` | raw | x10 |
| 3330 | `Your shield completely absorbs the damage.` | known | Shield of Absorption (3330, 4213) |
| 1595 | `You cease to wield a twisted oaken staff.` | NEW | |
| 1596 | `You start to wield a Shield of Absorption in your right hand.` | raw | |
| 1669 | `You cease wielding a Shield of Absorption in your right hand.` | raw | |
| 1670 | `You start to wield a twisted oaken staff in your hands.` | raw | |

**The opponent's cure and defence lines (third person)**

| Line | Game text | KB | Note |
|---|---|---|---|
| 257 | `<T> stands up.` | raw | |
| 260 | `<T> eats an aurum flake.` | known | |
| 1013 | `<T> eats a magnesium chip.` | raw | |
| 3031 | `<T> eats a ferrum flake.` | raw | |
| 3365 | `<T> eats a plumbum flake.` | NEW | |
| 1333 | `<T> eats a potash crystal.` | raw | |
| 586 | `<T> touches a tree of life tattoo.` | raw | |
| 822 | `<T> takes a drink from an oaken vial.` | NEW | sip health |
| 358 | `<T>'s eyes lose their focus suddenly.` | raw | CONCENTRATE (3 of 3) |
| 2093 | `A look of extreme focus crosses the face of <T>.` | known | FOCUS |
| 1117 | `<T> applies a quicksilver droplet to himself.` | raw | |
| 1465 | `A supple metallic shell of quicksilver has formed around <T>.` | raw | |
| 1173 | `<T> draws a deep, measured breath.` | known | FITNESS, 1 success in 54 sends |
| 1177 | `<T> takes a long drag off his pipe.` | raw | realgar per Sapience |
| 1258 | `A nearly invisible magical shield forms around <T>.` | known | |
| 1289 | `<T> takes some salve from a vial and rubs it on his <legs/head>.` | raw | mending or restoration |
| 818 | `The sanguine mist surrounding <T> billows and writhes exultantly.` | NEW | likely Agony |
| 4040 | `<T> moves with the grace of the wind, his stance the epitome of perfection beneath the flurry of blows.` | NEW | EPITOMISE; only 1 of 4 sends printed |
| 4160 | `<T> begins to tumble towards the <dir>.` | raw | |

**Telepathy** (every MIND success line and the lock start/finish/lost lines are gagged)

| Line | Game text | KB | Note |
|---|---|---|---|
| 9 | `You require a mindlock to perform that ability.` | NEW | x12, target outside the area |
| 105 | `You must cease your current lock attempt before trying another.` | NEW | 105, 1668 |
| 131 | `You continue to delve deeper and deeper into the mind of <T>.` | NEW | lock progress |
| 1646 | `Your mindlock is speeded by the mindprint you hold.` | NEW | |
| 2805 | `You will now begin to concentrate on cloaking your telepathy.` | NEW | MIND CLOAK ON |

**Kata / form.** Only the kata-chain line (251, above). The form lines are gagged.

**Kai**

| Line | Game text | KB | Note |
|---|---|---|---|
| 232 | `You exert superior mental control and your wounds clot before your eyes.` | NEW | CLOT, 40 mana |
| 840 | `You clot your wounds <N> times.` | NEW | at bleed 22-72 |
| 2973 | `Energy wreathes itself about your body to heal your limbs.` | NEW | Kaido RESTORE, first person |
| 2978 | `Your <limb> is too damaged to cure in that manner.` | NEW | RESTORE refuses a level-2 limb |
| 2881 | `You will no longer use kaido transmute.` | NEW | game-curing setting |
| 3205 | `You will now use kaido transmute when you can.` | NEW | |

**Arena / death**

| Line | Game text | KB | Note |
|---|---|---|---|
| 4239 | `You have slain <T>.` | raw | no death line before it |
| 4241 | `Defeated, <T> is cast out of the Arena.` | raw | |
| 4244 | `You have been victorious and leave the Arena in triumph!` | raw | between asterisk rows 4243 and 4245 |
| 4246 | `Colosseum Diabolus staging grounds. (indoors)` | NEW | |
| 4249 | `The Arena is once again open for combat.` | NEW | |

**Other (balances, refusals, room)**

| Line | Game text | KB | Note |
|---|---|---|---|
| 310 | `You have recovered balance on your <legs/left arm/right arm>.` | raw | |
| 2673 | `You have recovered balance on all limbs.` | raw | only after the dawnkick and spinkick combos (2673, 2786, 4053) |
| 159 | `You have recovered equilibrium.` | raw | |
| 313 | `You may eat another plant or mineral.` | raw | |
| 511 | `You may drink another health or mana elixir.` | raw | |
| 645 | `You may eat another bit of irid moss or potash.` | raw | |
| 943 | `Your mind is able to focus once again.` | raw | |
| 914 | `You may utilise the tree tattoo again.` | raw | |
| 1091 | `Your lungs have recovered enough to smoke another mineral or plant.` | raw | |
| 3011 | `You may apply another salve to yourself.` | raw | |
| 344 | `You are paralysed and are unable to drop anything.` | NEW | |
| 345 | `Paralysed as you are, your body is not able to pick up anything.` | NEW | |
| 347 | `You are paralysed and unable to do that.` | NEW | |
| 349 | `Your state of paralysis prevents you from doing that.` | NEW | also TOUCH MINDSEYE (3592, 3596) |
| 468 | `You are paralysed and cannot do that.` | NEW | |
| 2902 | `You must regain balance first.` | NEW | RESTORE while off balance |
| 2983 | `You must regain equilibrium first.` | NEW | x9 |
| 200 | `You are not fallen or kneeling.` | NEW | |
| 199 | `You hold no "bomb".` | NEW | unseen alias command |
| 197 | `You have no sanity.` | NEW | unseen alias command |
| 108 | `You are not the member of any party.` | NEW | 59 replies to 59 pt sends |
| 192 | `Now now, don't be so hasty!` | NEW | moving too fast |
| 307 | `You turn quickly as a twig snaps behind you.` | NEW | cause unknown |
| 1 | `Your target is now: <T> (an adventurer)` | raw | |
| 19 | `The pain plaguing your <limb> subsides.` | NEW | |
| 48 | `The sky darkens with the onset of night.` | NEW | |
| 49 | `You see exits leading <directions>.` | raw | |
| 47-207 | Room names: Unhallowed pines, Tarry morass, Despoiled grove, Dryad's gibbet, Dismal bracken, Ruined copse | not checked | |

## Answers to the open questions

1. **Telepathy without a lock.** Not tested in the same room. Every MIND attack went out under a lock (134 to 1631, 1715 to 4234).
   - The only lock-less evidence is the 12 refusals "You require a mindlock to perform that ability." for MIND PRINT and MIND SAPIENCE while Agathon was outside the area (9-97).
   - SAPIENCE depends on the lock. Its feed stopped when the lock broke (no `-->` lines from 1612 to 1745) and came back only after a fresh MIND SAPIENCE (1741).
   - The wiki marks DISRUPT, IMPATIENCE and BATTER with the asterisk that means "no lock needed", but not SCYTHE or BLACKOUT (kb/classes/monk.md:282, 303, 305, 325-327). Whether SCYTHE needs a lock in the same room is still untested.
2. **Blackout.** No MIND BLACKOUT and no blackout line. The only candidate is "Vacancy fills the eyes of Agathon." (3785). After it, Mystor's system marked BLCK for about 4 s (3791-3937), and Agathon typed `diagnose` at 3938. That fits blackout but does not prove it.
3. **Kata limits and stumbles.**
   - Highest chains: Rain 15, Oak 12, Gaital 12 (910, 2088, 1225, 2686). No stumble, no rhythm line, no refused transition, no ADOPT.
   - Transitions went through at kata 5, 10, 12 and 15 (4049-4067, 3452, 1271, 987).
   - Telepathy rounds and staff/shield swaps neither add to the kata nor break it (3258 to 3428; [Rain]:0 through five MIND abilities, 4067-4214).
   - The kata held 8 s with no strike (251 to 572) and 10 s idle while Mystor was prone (2833 to 3197).
4. **Kai Surge / Choke cost.** No data: no kai attack was used. Kai was 90-100% from 11:51:45 (979) to the end. It came only from Agathon's DSLs (+10 each, also when fully parried, 979) and decayed 5 at about :02 and :32 each minute (392, 1580, 2567, 3496).
5. **Dawnkick's epilepsy line.** Not seen. Two dawnkicks (2588, 2676) printed no effect line, and no epilepsy line appears anywhere in the log. Agathon FOCUSed 2-3 s after each (2667-2668, 2758-2759). CONFLICTS #5 stays open.
6. **Light, parried and absorbed strikes.**
   - Light strikes print their effect line but no damage line, so the system line shows no limb %: kuro, ruku, nervestrike and livestrike all do this (2540-2543, 3254-3255, 3513-3514, 3689-3690).
   - None of Mystor's strikes was parried, fumbled or absorbed.
   - His only failed attacks were two whole combos rebounding off a fresh shield (222, 1827).
   - On his own side: "You parry the attack with a deft manoeuvre." once per blow (10 lines), and "Your shield completely absorbs the damage." (3330, 4213).
7. **Prone extras.**
   - Hiru on a target the same combo had just proned added "Agathon looks about bemusedly." (2080-2085); Agathon FOCUSed at once (2092-2093). It was the only frontkick-then-hiru combo in this log.
   - No hiraku was used.
   - All 7 risingkicks to the head hit a standing target, and none of them, nor the 5 to the torso, printed a stun line.
   - Spinkick on a prone target hit the head (+15%, 3972-3973), as the wiki says (kb/classes/monk.md:186).
8. **Shields and rebounding.** Agathon had a shield tattoo on arrival and raised five more (1258, 1652, 1813, 2228, 2416). All six were shattered (245, 1277, 1672, 1855, 2263, 2455). SHATTER in the first combo slot counts as a kata action and does not stop the rest. A combo sent without SHATTER into a fresh shield rebounds whole for 1.44 s of equilibrium. No rebounding aura was seen.

## Lessons for our package

**For our Shikudo offense**
- **Add a trigger for the nervestrike line.** Nervestrike prints "Horror overcomes the face of <T> as his body locks in paralysis." every time, light ones included (993, 1131, 1219, 2196, 2268, 2343, 3514, 3685). Our `src_new/triggers/levi_ataxia/for_levi/leviticus/420_Paralysis.lua:35` matches a different line ("...'s face as \w+ body stiffens into paralysis"), so this paralysis is never recorded. An effect-line trigger fixes it, and it corrects "none on the attacker's side" in kb/combat/shikudo.md and CONFLICTS #6.
- **SHATTER whenever a shield is up.** The combo needs a shield flag that puts SHATTER first. Six fresh shields came up in two minutes, and the two combos sent without SHATTER cost a whole round each (222, 1827).
- **Transitions.** A `transition to <form> form` placed before the combo in the same alias works from kata 5, costs no balance, and the combo then counts from 1. Use this alongside the inline form already noted in CLAUDE.md.
- **The scythe fork is a complete, proven route.** Sweep, then needle + spinkick (prone head), then Rain at kata 5, then IMPATIENCE (1.07 s of equilibrium) + BATTER (2.70 s), then SCYTHE (2.89 s). It killed from full health 13 s after the sweep (3868 to 4239). Nothing in the package implements it today, according to the chunk readers' check of docs/plans.
- **MIND DISRUPT was wasted against this player.** He concentrated within the same second all 3 times. `telepathy_tekura/007_Disrupt.lua:43-44` records `disrupted` and clears it on a fixed `tempTimer(10, ...)`, and nothing reads "<T>'s eyes lose their focus suddenly.". Add that line as the cure.
- **Kai went unspent.** Kai sat at 90-100% for the last 100 s. Kai attacks would have been free to use against this opponent.
- **"Doubleaff" is the logger's own tag.** In this log it appears on ruku to the arm from kata 10 and on kuro from kata 12, never below (671/1412/1927/2597 untagged at 9; 1499/2683 kuro untagged at 11). The game text is unchanged. Do not model a two-affliction kata effect until HELP or AB confirms it.

**For our defence against this class (Infernal, dual cutting)**
- **Parry the limb the DSLs are prepping.** Standing, every DSL aimed at the parried limb was parried on both blows (5 of 5). Prone, the parried arm took both blows twice (2935-2948, 3159-3167). He worked one side and switched legs after a parry (2496-2768).
- **Treat a leg near 90%+ as an undercut threat.** The sheathe line (2853) comes in the same second as the undercut, too late to react to. The real warning is the leg's damage (96.6% in Mystor's model at 2775).
- **RESTORE cost.** Against the four-limb setup, RESTORE stopped the vivisect (2973), but it cost 7.22 s of equilibrium, refused the level-2 limbs, and kept Mystor prone 5 s after his legs were mended (3019 to 3186).
- **The hyena strips defences.** It took vitality, consciousness, mindcloak, mindseye and alertness. Mindseye could not be re-touched while paralysed (3592, 3596).
  - `372_Hyena_Turned_On_Us.lua:35` matches the snarl line.
  - The bite reads "as it lunges at you", which `367_Infernal_Hyena_Maul_Cooldown.lua:33` ("as she lunges at") misses.
  - No trigger reads "torn to tatters".
- **Lines our triggers do not read.** Hellforge investments print their own line instead of the affliction's (275, 527, 760), but GMCP still adds the affliction, so curing is unaffected. No trigger exists for the investment lines, the maggots, the withering lines or the undercut.
- **Cure healthleech quickly against an Infernal.** Each drain was 506 unblockable, and 3 of the 4 fed what is likely Agony curing him (818, 2163, 3637).
- **Kuro may weaken his DSL** (a hypothesis, not proven). His DSL dropped to 295 per blow in the one clean case where he was weary (689-697).

**For our tracking of this class's cures**
- **Fangbarrier timing.** `442_Got_Sileris.lua:37` sets the target's fangbarrier on the application line, but the shell formed about 10 s later each time (1117 to 1465, 2399 to 2724, 3495 to 3888). Ruku to the torso only stripped a formed shell (1078 vs 1136).
- **The tree pool is too small.** `treeCurableAffsV3` (`affliction_tracking_core/008_V3_Integration.lua:264-270`) lacks healthleech and broken limbs, but the tree cured both (298-301, 3171-3174). The Infernal treed every ~14 s, so his tree cures are under-modelled.
- **No trigger for the mist line.** The likely Agony line "The sanguine mist surrounding <T> billows and writhes exultantly." should branch a random cure in V3.
- **Salve applications are ambiguous.** "rubs it on his legs" is the same line for mending and restoration (4033 vs 4078), which supports the v4.7.404 branching. Flashheel breaks were mended within about 1 s, 6 of 6.
- **FITNESS is a typed command**, not passive (54 sends, 1 success line at 1173). Only "<T> draws a deep, measured breath." proves asthma cured.
- **Predictable cure order:** concentrate first; plumbum for impatience first; magnesium for paralysis within 1-2 s; aurum on nearly every eat; ferrum (lethargy) rarely; legs before head; FOCUS for epilepsy, confusion and stupidity.
- **When the wipe line prints** (a hypothesis): a wipe printed only after a DSL that did not land (972, then 1345; 2060 then 2138; 2716 then 2767). The wipe after a parried torment + curare was silent (2572, then 2628). That fits "a parried blow leaves its venom, and scimitar314077 carries the first-named venom", but it is unproven.

## Unclear or unverified

- **"You have been afflicted with X." / "You have cured the X affliction."** The GUIDE calls them game text. They are absent from kb/ and the earlier logs, so they may be a configuration message.
- **The `--> <T>: <command>` format:** game or system is unknown.
- **"Mindnet: ..." and "Alertness: ..." (88, 91, 4242)** are probably the system's rewrites. Our triggers expect "<T> has entered the area." and "Your enhanced senses inform you that ...".
- **"Room: Infestation Down" (4240)** is probably a system line.
- **"You have no sanity." and 'You hold no "bomb".'** answer alias commands the `[Zax]` echo does not show.
- **The 506 drain and the mist (likely).** The 506 drain is most likely healthleech: 4 of 4 came with `hlch` on Mystor's prompt. The mist line is most likely Agony: it was missing only at 394, when Agathon's model was empty.
- **"Vacancy fills the eyes of <T>." (3785)** has an unknown meaning: blackout per Mystor's system, or a stun.
- **"You feel something give way under your blow." (3973)** is either spinkick's own line or the head reaching level 3. The head level shows only in the model (`H3`, 3981).
- **Agathon's unexplained health gains**, with no sip, eat or potash line and no command in Sapience:
  - 7296 to 7716 (252 to 353);
  - 6446 to 6664 across a combo (673 to 784);
  - 7296 to 7289 after a frontkick + kuro (1829 to 1862);
  - 7424 to 7716 (4114 to 4199).
- **DSL damage per blow varied:** 367 in Rain, 365 in Oak, 352 and 283 in Gaital, 295 once with him weary, 345 while Mystor held the shield. The ratios fit weariness = x0.8 (295/367, 283/352) and Gaital = x0.96, but the weariness states come from the model.
- **Actions that worked during paralysis.** TOUCH SHIELD (2227-2228) and FITNESS (1173) went through in nervestrike paralysis windows, while his DSLs failed silently and Mystor's own TOUCH MINDSEYE was refused (3592). Either some actions are allowed under paralysis or the paralysis had not taken hold.
- **The tumble at 4160** began while the model showed him prone. No "stands up" appears after 2130.
- **EPITOMISE's effect** is unknown. kb/ has it only as a defence name (kb/defences/README.md). Only 1 of 4 sends printed (4040, 4129, 4166, 4172).
- **The lock break at 11:52:03 (1631)** has no visible cause; the target was in the room, 50 s after the lock formed.
- **Kai gain:** +10 per DSL or +5 per blow cannot be told apart. The :02/:32 decay clock is inferred.
- **Mana attributions are guesses.** Observed: CLOT -40 (229 to 233); combo round -66; DISRUPT and IMPATIENCE rounds -132; BATTER round -399. The wiki's equilibrium ratio in Rain is about 0.72, and the 0.85 x 0.85 split is a guess. BATTER read 2.70 s against 2.89 s for the other 4.00-s abilities.
- **The one 2.3 s combo (1675)** was the only kick combo sent with WIELD STAFF in the same alias. The cause is unverified.
- **Mystor's system switches paralysis curing priority between 25 and 5** (374, 2548, 3699, 4019); why is not shown.
- **"You turn quickly as a twig snaps behind you." (307)** has an unknown cause.
- **The prompt fields `[CDBK]`, `[54.44]` and `(n)`** are unknown. `(n)` is probably the number of branches in the target model.
- **The "glows faintly" tree line (899)** did not restart the tree cooldown (914 is 13.94 s after the real touch at 299). `curing_bals/001_Treed_(fake_).lua:34` matches it; whether that trigger marks the tree used when it should not is untested.
- **The insomnia, deafness and blindness removals at the win (4218-4223)** are likely the arena exit.

**Corrections made while merging**
- **"pt Intercepted ..." is Mystor's own outgoing message, not the opponent's.** It is his client's party tell relaying what Sapience showed (Agathon's own `--> Agathon: pt Mystor: ...` line). Each one is answered "You are not the member of any party." (441 then 444). Under stupidity one was replaced by "You pick your nose absently." (919 then 922). The GUIDE (lines 62-63) and chunk 5 read it as the opponent's message, which is wrong.
- **Not every frontkick combo took 2.1 s.** The shatter + frontkick combo at 1675 took 2.3 s; chunk 3 listed it as 2.1 s.
- **The hyena attacks about every 3 s, not 7-9 s.** It made 29 attacks, about 3 s apart. The 7-9 s chunk 2 reported was one quiet stretch.
- **The 730 damage was the undercut (2864).** The torment + curare DSL at 3624 did 365 + 365.
- **TRANSMUTE was used 4 times** (chunk 1 counted 3; the fourth is at 890), and FITNESS was sent 54 times with 1 success.
- **Three lines marked NEW are already in kb/.** "A nearly invisible magical shield forms around <T>.", "A look of extreme focus crosses the face of <T>." and "<T> draws a deep, measured breath." are in curated kb/ pages.
- **The parried larkspur DSL did not break the wipe pattern.** The wipe after it (1167) came while Agathon was paralysed and printed nothing; the next wipe (1345) printed. Chunk 4 counted this case against the pattern.
- **"TOUCH SHIELD works while paralysed" is not established.** Chunk 3 rated it likely; it is downgraded to unresolved (see above).
