# Mystor (Shikudo) vs Agathon (Shaman): lost, truelocked

> Source: `kb/raw/logs/2026-10-11_mystor_shikudo-vs-shaman_loss_t54WWU6b.txt` (Mystor's own log; how to read his client's output: `kb/raw/logs/README.md`). Every line number below is a line of that file.
> Written 2026-10-11 from a line-by-line reading: one agent per ~800-line chunk, merged by a further agent that checked doubtful claims against the log. Confidence: LOG for what the lines show; the readers' own "likely" and "guess" marks are kept. Not yet independently re-verified.

## Fight

- **Logger: Mystor**, a Shikudo monk. He is in Rain form at kata 0 on all 781 prompts.
- **Opponent: Agathon, a Shaman. This is confirmed.** Every ability seen belongs to the Shaman's Curses or Spiritlore skills (kb/classes/shaman.md):
  - **Curses:**
    - CURSE: 87 landed, shown by the logger as `Agathon: Curse -> You`. The only ungagged curse line is "Agathon points an imperious finger at you." (31).
    - CURSE BREACH: 11, first at 1308.
    - JINX: 26, first at 160.
    - SWIFTCURSE: likely; 3 "weaves his fingers" lines at 632, 1810 and 2409.
    - TZANTZA: likely; one chant at 3628.
  - **Spiritlore:** INVOKE RELAPSE (Syvis, 5, first at 97), INVOKE BLOODLET (Teraile, 5, first at 221), INVOKE COAGULATION (Aspar, 5, first at 350).
  - JINX, the invokes, SWIFTCURSE and TZANTZA are Shaman-only (shaman.md:26-30, 92, 108, 119-120). Apostate shares only BREACH (apostate.md:63).
  - He used no Vodun: the word "doll" never appears in the log.
- **Build ("spec").** A Shaman has no weapon spec. Agathon fought with Curses and Spiritlore, with Syvis, Teraile and Aspar bound. He was very likely **Teraile-attuned**, whose attunement reads "Curses will inflict bleeding" (shaman.md:28): every landed curse added 40 bleeding and every jinx 80 (36, 165, 2587).
- **Weapons and items:**
  - One scimitar, drawn only for the kill (3715) and used for BEHEAD (3718-3790).
  - "an enamel bubble pipe", smoked for rebounding (39, 449).
  - "an oaken vial" (1067).
  - The GUIDE's table has Agathon as an Infernal with scimitars in the logs just before this one (FceAmb0o, ends 10:28:04) and just after (vNTjvghY, starts 10:37:57). He most likely changed class for this spar; the change itself is not in this log.
- **Result: Mystor LOST.**
  - Truelocked from 10:33:42: `[true]` is on every prompt from 3302 to 3739.
  - Beheaded at 10:35:20 (3789-3791), at 85% health with 680 bleeding (3739).
- **Duration.** The log runs 10:28:44-10:35:20 (6 min 36 s). Agathon entered the room at 10:29:03 (23), which leaves 6 min 17 s to the death. That includes a 2-minute pause (10:30:47-10:32:45, lines 1730-1766) in which Mystor coached him.
- **Where.** An arena entered through a mirror ("You are moved by an iron-rimmed mirror.", 14). The arena room is "Corroded meadow." (15). The loser is put in "The spectator stands of the Colosseum Diabolus." (3802).
- **What kind of fight: a lock spar, not a duel. Mystor never attacked.**
  - There is no strike line. The only `You:` logger lines are the Mindlock (6) and two Kai Transmutes (3564, 3712).
  - His only typed commands: `mind cease` (19), `diag` x4 (525, 691, 3308, 3566), `say` x13 (1718-1757, 2073, 3734), `nod` (3314) and `smile` (3699).
  - His says teach Agathon to time the seal against Mystor's eating balance (1718-1757, 2073).
  - Everything else is his curing system ("Zax") and server-side curing.
  - So this log is evidence about a Shaman's lock and about curing against it. It says nothing about Shikudo offense.

## How it went

Each time is the prompt row after the line (1-second resolution).

1. **Setup, 10:28:44 (1-22).**
   - Target and ENEMY are set (1-2).
   - His lock alias sends `pt starting mind lock on Agathon`, refused because he is in no party (5, 9), and starts MIND LOCK while Agathon is not in the room (6).
   - The mirror moves him into the arena (12-17).
   - He types `mind cease` (19-20).
2. **Paralysis pressure, 10:29:03-10:29:19 (23-324).**
   - Agathon steps through the mirror with rebounding up (23, 30) and curses in his first second (31).
   - Paralysis is cursed again within 1-2 s of each magnesium Mystor eats. One paralysis curse carries a RELAPSE (97, which fires at 147).
   - Haemophilia + BLOODLET (218-222) takes the bleed from 0 to 293.
   - Jinxes: paralysis + weariness (160) and paralysis + impatience (243).
   - Magnesium is always eaten first, so haemophilia waits 11 s (217 to 451) while the bleed reaches 513.
3. **Seal 1, 10:29:19-21 (325-401).**
   - Asthma (327), then anorexia + COAGULATION slickness (346-353), on top of haemophilia, impatience and weariness. Zax's prompt shows `[h]` (354).
   - His tree had just come back (339). The escape: tree for slickness (359), epidermal (363), quicksilver (369), aurum (cured weariness, 378), FITNESS (cured asthma, 384). He is out in about 2 s.
4. **Pressure, 10:29:22-10:29:57 (402-1083).**
   - Curses and jinxes about 1.2 s apart. A SWIFTCURSE weave at 632, a second relapse (672, firing at 729) and a third bloodlet (762).
   - Impatience is left up for 19 s (246 to 641).
   - Kai reaches 100% at 1016 (10:29:53).
5. **Seal 2, 10:29:57-58 (1084-1181).**
   - Asthma is cursed (1094) and Zax raises it to priority 1 (1101).
   - The aurum that cures it (1116-1119) arrives in the same packet as anorexia + COAGULATION slickness (1120-1127).
   - With asthma gone he smokes realgar (1139), applies epidermal (1143) and applies quicksilver (1147).
   - Mystor later: "You hit me with ano sli right as I cured asthma" (1718).
6. **First cursewards, 10:30:00-10:30:43 (1182-1717).**
   - CURSEWARD (1184) holds three curses (1289, 1298, 1304) and is breached (1308).
   - Addiction + nausea jinxes (1449, 1486); relapse 3 (1554, firing at 1597); paralysis + asthma jinx (1630).
   - CURSEWARD again (1641), which holds two curses (1682, 1709); FITNESS (1688).
7. **Coaching pause, 10:30:43-10:32:45 (1718-1766).** Twelve says (1718-1757). One curse goes into the ward (1761). Kai decays from 100 to 60.
8. **Resumed, 10:32:45-10:33:03 (1767-2075).**
   - BREACH (1768).
   - A stupidity jinx and three stupidity curses (1779-1855) use up focus twice, a plumbum and the tree (1796-1861).
   - SWIFTCURSE (1810); relapse 4 (1900, firing at 1949); then haemophilia, weariness, impatience and asthma.
   - Zax sets asthma to priority 1 (2071). Mystor says: "You should track enemy eat and not attempt seal if it lines up within .2 of eat" (2073).
9. **Seal 3, 10:33:04 (2076-2145).**
   - The aurum cures weariness (2085); anorexia + COAGULATION slickness lands (2090-2101); `[h]` (2102).
   - The escape: FITNESS (2105), realgar (2116), epidermal (2120), quicksilver (2124), then the tree for impatience the moment it returns (2140). He is out within the second.
10. **Build-up, 10:33:05-10:33:38 (2146-2834).**
    - A weariness jinx. A queued FITNESS is refused for weariness (2171).
    - Addiction + BLOODLET (2196); addiction + nausea jinx (2233); a recklessness prediction (2283); SWIFTCURSE (2409).
    - Relapse 5 is wasted on a paralysis already cursed back (2518, firing at 2555).
    - CURSEWARD (2614) is breached 2 s later (2656).
    - **FITNESS is spent on asthma at 10:33:31 (2681) and the tree on haemophilia at 10:33:33 (2741).**
    - Jinx impatience + asthma (2815, 10:33:36). The aurum at 10:33:38 (2832) cures weariness, not asthma.
11. **Seal 4 and the truelock, 10:33:39-42 (2835-3302).**
    - FITNESS is re-sent on every prompt into its cooldown, from 2837.
    - Anorexia + COAGULATION slickness lands about 1 s after the aurum, before eating balance returns (2888-2898; eating balance back at 3006). `[h]` from 2899.
    - CURSE WEARINESS (3244) lands one second before FITNESS comes off cooldown (3293), so every FITNESS is refused for weariness (3253-3290).
    - JINX paralysis + haemophilia (3296-3299): `[true]` (3302, 10:33:42).
12. **Locked, 10:33:42-10:35:09 (3303-3714).** Nothing is cured for 98 s.
    - Curseward race: 9 raises and 8 breaches (3305-3672).
    - Jinx asthma + stupidity (3379); coagulation re-applied (3407-3411); jinx dizziness + epilepsy (3452).
    - A ward raised at 10:34:00 holds five curses until 10:34:47 (3477-3597, breach at 3619).
    - Epilepsy fits from 3536; TRANSMUTE (3563); `diag` (3566-3581).
    - A chant, most likely TZANTZA, starts after a breach and stops within a second (3628-3635).
    - Bleeding reaches 680 and ticks every 5-6 s; health stays between 77% and 100%.
13. **The kill, 10:35:09-10:35:20 (3715-3806).**
    - Scimitar drawn (3715). BEHEAD swing (3718, 10:35:10). "bear down" (3732, about 10:35:15).
    - Decapitation (3789-3790), "You have been slain by Agathon." (3791), thrown out of the arena (3800).

## The opponent

### Rotation (inferred: there is no Sapience in this log)

The word "Sapience" never appears in the log, so his typed commands are not visible. The commands below are inferred from the logger's labels and the game lines that follow them, written with the wiki syntax from kb/classes/shaman.md.

| Command (inferred) | Count | What Mystor sees | Lines |
|---|---|---|---|
| CURSE Mystor `<curse>` | 61 landed, plus 12 into the ward | Logger `Agathon: Curse -> You`, the affliction, "A dull ache builds behind your eyes.", +40 bleed, +3 kai. Into a ward: only "...but your curseward holds." | 31, 1289 |
| JINX `<c1> <c2>` Mystor (2.30 s balance, wiki) | 26 (25 landed, 1 into the ward) | Logger `Agathon: Jinx -> You`, both afflictions in the order sent, one ache, +80 bleed, +4 kai | 160, 3421 |
| CURSE Mystor PARALYSE INVOKE RELAPSE PARALYSIS (Syvis, 2.20 s balance) | 5 | Paralysis, `Invoke Relapse`, then the "Horror overcomes you..." line 1-3 s after the first cure | 97, 672, 1554, 1900, 2518 |
| CURSE + INVOKE BLOODLET (Teraile; the combined syntax is not shown) | 5 | On a haemophiliac: about +255 bleed (0 to 293 at 222; 0 to 295 at 763). Otherwise: haemophilia | 221, 491, 762, 2196, 2787 |
| CURSE Mystor ANOREXIA INVOKE COAGULATION SLICKNESS (Aspar) | 5 | Anorexia + slickness, which strips the fangbarrier; net -100 bleed | 350, 1124, 2098, 2895, 3410 |
| CURSE Mystor BREACH (1.00 s balance, 90 mana) | 11 | "Your curseward has been breached!", the curse label and the ache, +40 bleed | 1308, 1768, 2656, 3322-3666 |
| SWIFTCURSE, bare (2.50 s equilibrium; speeds up the next ten curses) | 3 | "Agathon weaves his fingers together skilfully.", then curses about 1 s apart (1810-2095) | 632, 1810, 2409 |
| CURSE Mystor TZANTZA (3.00 s balance) | 1 | The chant plus the ache; he stops within about 1 s | 3628, 3635 |
| SMOKE pipe | 23 | 17 "takes a long drag off an enamel bubble pipe", 6 "A great gurgling sound..." | 39, 449 |
| SIP | 3 | "Agathon takes a drink from an oaken vial." | 1067, 2725, 3520 |
| Draw scimitar, BEHEAD Mystor | 1 | Draw, swing, bear down, decapitation | 3715-3790 |

The 87 logger curse lines are 61 plain curses (including 31 and 3332), 15 curses carrying an invoke and 11 breaches.

**The order he worked in:**
1. **Attack, then smoke.** Each of his attacks drops his own rebounding; the drop prints just before the attack line (24 drops; e.g. 30-31, 3627-3628). He re-smokes within about a second, and the aura returns 8-9 s later (23 smokes, 23 auras).
2. **Tax and pressure.**
   - Paralysis is cursed again within 1-2 s of each magnesium (805 then 849, 865 then 881).
   - Haemophilia stops clotting; BLOODLET on a haemophiliac adds a burst of bleeding.
   - Impatience blocks FOCUS and weariness blocks FITNESS. Asthma comes by curse or jinx.
3. **The seal.** CURSE ANOREXIA INVOKE COAGULATION SLICKNESS, sent once asthma and impatience were up. Four attempts: 350, 1124, 2098 and 2895. The last landed about 1 s after Mystor's eat.
4. **The close.** CURSE WEARINESS just before FITNESS returned (3244, ready line at 3293), then JINX PARALYSE HAEMOPHILIA (3296). Paralysis also blocks the tree.
5. **The hold.**
   - He BREACHes each curseward 0-2 s after it rises (3305-3428). The exception is the ward that held 47 s (3472-3619).
   - He stacks Tzantza-valid mental afflictions: stupidity (3381), then dizziness and epilepsy (3453-3456).
   - He tries TZANTZA (3628).
6. **The kill.** Draw scimitar, BEHEAD (3715-3790).

### Curses, invokes and their lines

- **Curses seen,** by the affliction they gave: paralysis, haemophilia, impatience, weariness, asthma, anorexia, stupidity, dizziness (2435) and addiction (2190).
  - Jinx pairs added nausea, paired with addiction (1449, 1486, 2233; by elimination the VOMITING curse), and epilepsy, paired with dizziness (3452).
  - There were no venoms.
- **"A dull ache builds behind your eyes."** prints once per landed curse, breach, jinx or chant: 113 = 87 curses + 25 landed jinxes + 1 chant. It never prints after a curse the ward held, after the jinx the ward stopped (3421) or after a relapse.
- **A curse on an affliction Mystor already had** prints only that affliction's own message. There is no "You have been afflicted with" line and no GMCP Add (822, 1604, 2585, 3300).
- **BLOODLET's haemophilia** prints no "You sense a subtle change deep within." (492, 2197, 2788).
- **COAGULATION** lowered the bleeding by exactly 100 every time (493 to 393, 360 to 260, 320 to 220, 120 to 20, 500 to 400; prompts 354, 1128, 2102, 2899, 3412). The game accepted it at 120 bleeding.

### Curing order

Not observable: Mystor never gave him an affliction. Everything he did for himself was 23 pipe smokes and 3 sips. No eat, apply, tree or focus line of his appears.

### Defences

- **Rebounding from the pipe.**
  - He arrived with it up (30).
  - Smoke to aura took 8-9 s every time (e.g. 39 then 208, 2521 then 2666).
  - Every attack he made dropped it, even a curse the ward held (1760-1761, 3476-3477) and the chant (3627).
  - So in practice it was up only in the gaps between his attacks. Mystor never tested it.
- No shield, curseward or anything else appears.
- Two third-person lines of unknown nature: "Agathon peers about himself dubiously." (3508) and "Comprehension flashes across Agathon's face." (3607).

### Kill route against Mystor

- **The lock.** An affliction truelock (asthma, anorexia, slickness, impatience and paralysis; prompt 3302):
  - weariness switches off FITNESS (3253-3290);
  - paralysis, or the tree's cooldown, takes away the tree.
- **The kill: BEHEAD with a scimitar,** about 10 s from swing to death (3718-3791). The word "prone" appears nowhere in the log, so a paralysed, truelocked, non-prone target was enough.
- **Bleeding was pressure, not the kill.** It did 10,260 raw damage in the last 98 s, but health never fell below 77% (3705).
- **The probable TZANTZA at four valid afflictions did not kill** (3628-3635). The wiki says six valid afflictions kill instantly (shaman.md:160).

## Mystor's offense

- **Forms and kata.** Rain for the whole log. Kata 0 on all 781 prompts. No combo, form change, transition, ADOPT, stumble or rhythm line.
- **Combos per form.** None.
- **Telepathy:**
  - MIND LOCK was started by his alias at 10:28:44 while Agathon was not in the room (6; the game line is gagged and the logger prints `You: Mindlock (start) -> Agathon`). The alias's party tell failed: he was in no party (5, 9).
  - The attempt was still running after the mirror moved him: `mind cease` drew "You cease attempting to initiate a mindlock." (19-20).
  - MINDNET was up ("Mindnet: Agathon has entered the area.", 24; removed at death).
  - He sent no other MIND ability, with or without a lock.
- **Kai:**
  - Mystor was in **Kai Trance**: `-Def: kaitrance` is in the death packet (3761).
  - Kai came only from Agathon's landed attacks:
    - +3 per curse, breach or chant; +4 per jinx;
    - nothing for a curse the ward held, a relapse or a bleed tick (36, 165, 1311, 1762, 1952, 3630);
    - 0 to 100 in about 50 s (10:29:03 to 10:29:53, line 1016).
  - It fell 10 points about every 30 s (282, 886, 1731, 3353, 3735).
  - He used no ability that spends kai. **KAI TRANSMUTE x2:** "[Curing]: TRANSMUTE 501", then the logger's `You: Kai Transmute -> Yourself` (3563-3565, 3711-3713). Each gave +501 health for -501 mana with kai unchanged, used no balance or equilibrium, and worked while he was paralysed and anorexic.
  - "[Curing]: TRANSMUTE 814" drew "The idea of putting something in your stomach sickens you." and did nothing (3707-3708).
- **Shields and rebounding:**
  - No shield tattoo, no SHATTER, and no rebounding of his own (none among the 35 defences removed at death, 3741-3788).
  - **CURSEWARD x12**, each costing 2.89 s of equilibrium and 166 mana. Between them they held 12 curses and 1 jinx and were breached 11 times. One re-send was refused (1233).
  - Fangbarrier: stripped by each new slickness (352, 1126, 2100, 2897) and rebuilt with quicksilver 8-10 s later (369, 1147, 2124). It was not rebuilt after the last strip, because slickness blocks applying.
- **His curing in numbers:**
  - 84 eats: magnesium 42, ferrum 23, aurum 10, plumbum 9.
  - 11 tree touches; 4 FITNESS cures (plus 144 refusals); 5 FOCUS.
  - 4 epidermal, 2 realgar, 3 quicksilver; 59 CLOTs; 6 mana sips; 5 DIAGNOSEs.
- **Why he lost.** He did not fight, so he could only lose if his curing failed. That curing broke seals 1-3 (10:29:20, 10:29:58, 10:33:04). Its rules:
  - magnesium for paralysis always comes first;
  - asthma goes to priority 1 the moment it lands (336, 1101, 2071, 2823);
  - FITNESS is used for asthma when he is not weary;
  - the tree is used when it is ready.

  Seal 4 worked because three escapes were gone at the same moment:
  - FITNESS had been used at 10:33:31 (2681) and was cooling down until 10:33:41 (3293);
  - the tree had been spent on haemophilia at 10:33:33 (2741) and was back only at 10:33:47 (3361);
  - the aurum at 10:33:38 (2832) took weariness instead of asthma, and the seal landed about 1 s later, inside his 1.59 s eating window (2888-2898; eating balance back at 3006).

  Weariness then landed one second before FITNESS returned (3244), and paralysis took the tree (3296).

  The paralysis-first order had already let him park haemophilia for 11 s twice (217 to 451, 955 to 1169) and impatience for 15-19 s (246 to 641, 2481 to 2773).

## Timings

Only Rain form was used, so there is no per-form comparison. `[.. Recov]` figures are the logger's measurements; `[.. Spent]` figures are constant for each ability.

| What | Measured | Lines | Note |
|---|---|---|---|
| Eating balance (magnesium, ferrum, aurum, plumbum) | 1.38-1.64 s, mean about 1.50 s | 62, 830, 1611, 2415 | The same for every mineral |
| Tree tattoo | 13.93-14.01 s (11 readings) | 340, 1223, 1727, 2445, 3362 | |
| Salve (epidermal) | 0.81-0.93 s | 396, 944, 2131 | Quicksilver went on in the same second each time (363/369, 1143/1147, 2120/2124) |
| Smoke (realgar) | 1.43 s, 1.47 s | 1159, 2150 | |
| Sip (mana elixir) | 4.37-4.50 s | 536, 920, 2406, 2796 | |
| FOCUS | 2.36-2.48 s; about 166 mana | 1814, 2492, 2425 | |
| FITNESS | 2.8 s of balance (x4; wiki 3.00 s); balance back in 2.65-2.73 s | 385, 1722, 2682, 2749 | |
| FITNESS cooldown | 9-10 s | 384 to 580, 1688 to 1735, 2105 to 2291, 2681 to 3293 | Weariness blocks it |
| CURSEWARD | 2.89 s of equilibrium (x12); back in 2.71-2.95 s; 166 mana | 1185, 1232, 2615, 2680, 3306 | |
| DIAGNOSE | 0.72 s of equilibrium (x5; AB 1380 says 1.00 s); back in 0.56-0.74 s | 259, 1091, 3581 | Rain = x0.72 for equilibrium |
| Epilepsy fit | 1.8 s of balance (x6, one with no fit line at 3721); back in 1.71-1.79 s | 3537, 3541 | First fit about 28 s after the affliction (3456 then 3536) |
| Quicksilver to fangbarrier | 8-10 s | 369 to 568, 1147 to 1282, 2124 to 2321 | |
| Bleed tick | every 5-6 s, the whole current bleed as raw damage | 171, 280, 2638, 3283 | Does not shrink under haemophilia |
| CLOT | 1 clot per 20 bleeding, 40 mana per clot | 45, 455, 1676, 2652 | The wiki's Kaido Clotting says 60 mana |
| Kai | +3 per curse, +4 per jinx; -10 about every 30 s | 36-790, 1016, 3353 | Kai Trance |
| Opponent's attack rate | mean 1.2-1.4 s; several pairs within one second | 31-785, 819-1175, 2435-2892 | Faster than one 2.20 s balance allows, so swiftcurses are mixed in |
| Opponent's rebounding | aura 8-9 s after the smoke, 23 of 23 | 39 to 208, 2521 to 2666 | |
| Opponent's relapse | 1-3 s after the first cure | 113 to 147, 681 to 729, 1567 to 1597, 1916 to 1949, 2534 to 2555 | |
| Opponent's invoke reuse (upper bounds) | relapse 28 s, bloodlet 13 s, coagulation 14 s | 97/672; 221/491/762; 2895/3410 | |
| Opponent's seal against the eat | same packet as the aurum (1116-1127); about 1 s after it (2832, then 2888) | 1124, 2895 | |
| Truelock to BEHEAD | 88 s; the behead itself about 5 s + 5 s | 3302, 3718, 3732, 3789 | |

The Rain figures fit a 0.72 equilibrium factor: DIAGNOSE costs 0.72 s against an AB value of 1.00 s. CURSEWARD's 2.89 s would then imply a 4.00 s base. That is an inference: CURSEWARD's own base cost is not in the KB. FITNESS's 2.8 s against the wiki's 3.00 s fits neither 0.72 nor 0.85, so either the Rain reduction applies to equilibrium only or the wiki figure is off. This is unverified.

## Game lines

All lines are verbatim. **KB:** `known` = already in a curated kb/ page; `raw` = only in kb/raw evidence files; `NEW` = nowhere in kb/; `n/c` = not checked.

Two reading notes:
- The logger prints `[Zax]` GMCP notices before the game text of the same packet.
- The logger's `Agathon: Curse -> You` sits after "You have been afflicted with..." (32-33). Do not read game order from logger lines.

### Our attacks and effects

None. Mystor made no attack in this log.

### Opponent attacks and effects

| Line | First (count) | KB | Note |
|---|---|---|---|
| `Agathon points an imperious finger at you.` | 31 (1) | NEW | The only ungagged curse line. Our determine_class/003 expects `..., bringing the curse of \w+ down upon you.` |
| `Agathon points an imperious finger at you, but your curseward holds.` | 1289 (12) | NEW | Curse stopped by the curseward: no affliction, bleed, ache or kai |
| `Your curseward has been breached!` | 1308 (11) | NEW | CURSE BREACH. GMCP `-Def curseward` comes first. Counts as a landed curse |
| `A dull ache builds behind your eyes.` | 35 (113) | NEW | Once per landed curse, breach, jinx or chant. Teraile attunement likely |
| `Horror overcomes you as you realise that the curse of paralysis has manifested upon you once again.` | 147 (5) | NEW | The Syvis relapse firing |
| `Agathon weaves his fingers together skilfully.` | 632 (3) | NEW | Likely bare SWIFTCURSE |
| `Agathon's eyes flutter and close as he begins to rock back and forth, chanting ominously under his breath.` | 3628 (1) | NEW | Likely TZANTZA |
| `Agathon ceases his chanting, a frustrated expression crossing his face.` | 3635 (1) | NEW | About 1 s after the chant began; no kill |
| `A grim, ominous scimitar rings out brightly as Agathon rapidly draws it from a scabbard embellished with a gold eagle.` | 3715 (1) | NEW | About 1 s before BEHEAD |
| `Agathon raises his scimitar over his head and begins to swing it in a wide circle, gaining speed as he goes.` | 3718 (1) | NEW | BEHEAD stage 1; two of our triggers match it |
| `Agathon begins to bear down on you with his whirling scimitar.` | 3732 (1) | NEW | BEHEAD stage 2, about 5 s later |
| `You take <N> raw, damage.` | 171 (31) | NEW | Bleed tick; N = the whole current bleed |
| `You bleed <N> health.` | 172 (31) | raw | Follows each tick |

### Afflictions landing on Mystor

| Line | First (count) | KB | Note |
|---|---|---|---|
| `You have been afflicted with <affliction>.` | 32 (119) | NEW | Paralysis 43, haemophilia 20, weariness 12, impatience 9, stupidity 8, asthma 8, anorexia 5, slickness 4, addiction 4, nausea 3, dizziness 2, epilepsy 1. Not printed when the affliction is already present |
| `A prickly stinging overcomes your body, fading away into numbness.` | 34 | known | paralysis |
| `You sense a subtle change deep within.` | 76 | known | haemophilia; never for BLOODLET's haemophilia |
| `Your limbs grow heavy and you groan feebly.` | 163 | known | weariness |
| `You shuffle your feet noisily, suddenly bored.` | 247 | known | impatience |
| `You feel a tightening sensation grow in your lungs.` | 329 | known | asthma |
| `The idea of eating or drinking is repulsive to you.` | 348 | known | anorexia |
| `The protective covering coating your skin sloughs off.` | 352 (4) | raw | Fangbarrier lost with every new slickness |
| `You notice that your sweat glands have begun to rapidly secrete a foul, oily substance.` | 353 | known | slickness |
| `You feel a terrible hunger grow within you.` | 1451 | known | addiction |
| `A sense of extreme nausea washes over you.` | 1453 | known | nausea |
| `Hmmmm. Why must everything be so difficult to figure out?` | 1781 | known | stupidity |
| `Your mind swims as dizziness overtakes you.` | 2436 | known | dizziness |
| `Your nerves feel suddenly jangled.` | 3456 | known | epilepsy |
| `Your limbs begin to jerk and shake uncontrollably, and you begin to foam at the mouth.` | 3536 (5) | NEW | Epilepsy fit; 1.8 s of balance |
| `You waggle your eyebrows comically.` | 1790 | NEW | Stupidity turned an EAT MAGNESIUM into an emote; re-sent at once |
| `You pick your nose absently.` | 2341 | NEW | The same thing happening to EAT MAGNESIUM |
| `You blink.` | 3404 | NEW | Not typed; likely stupidity |
| `You pull down your pants and moon the world.` | 3468 | NEW | Not typed; likely a CURSEWARD send lost to stupidity |
| `You get down on one knee and serenade the world.` | 3485 (2) | NEW | Not typed; likely stupidity |
| `You nod your head emphatically.` | 3645 | NEW | Not typed here; at 3315 it answers a typed `nod` |
| `You twitch spasmodically.` | 3650 | NEW | Not typed; stupidity or epilepsy |
| `You are:` | 251 (5) | NEW | DIAGNOSE header |
| `blind.` / `deaf.` | 252 / 253 | n/c | Kept defences |
| `wearied in body.` | 254 | known | |
| `afflicted by haemophilia.` | 255 | known | |
| `paralysed.` / `impatient.` | 256 / 257 | n/c | |
| `bleeding for <N> health.` | 258 | NEW | Equals the prompt's Bl |
| `afflicted by horrible asthma.` | 531 | known | |
| `anorexic.` | 3573 | known | |
| `extremely oily.` | 3574 | known | slickness |
| `unnaturally stupid.` | 3577 | known | |
| `overcome by dizziness.` | 3578 | known | |
| `suffering from epilepsy.` | 3579 | known | |

### Mystor's cures, cure balances and his own defences

| Line | First (count) | KB | Note |
|---|---|---|---|
| `You eat a magnesium chip.` | 41 (42) | NEW | paralysis |
| `Your muscles unlock; you are no longer paralysed.` | 42 | known | |
| `You have cured the <affliction> affliction.` | 43 (105) | NEW | After every herb, salve, tree or focus cure; never after FITNESS |
| `You eat a ferrum flake.` | 191 (23) | raw | haemophilia, nausea, addiction |
| `Your blood regains its ability to clot.` | 86 | known | |
| `Your stomach becalms itself.` | 1460 | known | |
| `Your terrible addiction seems to wane.` | 1476 | known | |
| `You eat an aurum flake.` | 378 (10) | raw | asthma or weariness |
| `Your limbs strengthen and you feel stronger.` | 379 | known | |
| `Your bronchial tubes open up and your asthma is cured.` | 546 | known | |
| `You eat a plumbum flake.` | 641 (9) | NEW | impatience, stupidity, dizziness |
| `You are patient once again.` | 642 | known | |
| `You aren't such a complete idiot anymore.` | 1797 | known | |
| `You are no longer dizzy.` | 2505 | known | |
| `You focus your mind intently on curing your mental maladies.` | 1796 (5) | raw | FOCUS |
| `You touch the tree of life tattoo.` | 85 (11) | raw | |
| `Your glands cease their oily secretion.` | 360 | known | |
| `You take out some salve and quickly rub it on your body.` | 363 (4) | raw | Epidermal |
| `Food is no longer repulsive to you.` | 364 | known | |
| `You take a long drag of realgar off your pipe.` | 1139 (2) | raw | |
| `You inhale deeply, purging yourself of your asthmatic condition.` | 384 (4) | NEW | FITNESS; trigger curing_bals/006 matches it |
| `You clot your wounds <N> times.` | 45 (59) | NEW | |
| `You take a drink from an amethyst vial.` | 457 (6) | NEW | SIP MANA |
| `Your mind feels stronger and more alert.` | 458 (6) | raw | |
| `You apply a quicksilver droplet to yourself.` | 369 (3) | raw | Fangbarrier |
| `The quicksilver hardens into a supple metallic shell.` | 568 (3) | raw | Fangbarrier up |
| `You already have curseward up.` | 1233 | NEW | A refused re-send |
| `You have added the RECKLESSNESS affliction to your predicted afflictions list.` | 2283 | NEW | CURING PREDICT |
| `You are predicting that you have the recklessness afflictions.` | 2286 (5) | NEW | |
| `You are not predicting that you have any afflictions at present.` | 2427 | NEW | Right after a FOCUS |
| `You may eat another plant or mineral.` | 62 | raw | |
| `You may apply another salve to yourself.` | 395 (4) | raw | |
| `Your lungs have recovered enough to smoke another mineral or plant.` | 1158 (2) | raw | |
| `You may drink another health or mana elixir.` | 535 (6) | raw | |
| `You may utilise the tree tattoo again.` | 339 (11) | raw | |
| `Your mind is able to focus once again.` | 1813 (5) | raw | |
| `You have recovered equilibrium.` | 266 (17) | raw | |
| `You have recovered balance on all limbs.` | 433 (10) | raw | |
| `You may purge your lungs once again.` | 580 (4) | NEW | FITNESS ready; curing_bals/007 |
| `You may not purge your lungs again as of this time.` | 1723 (130) | NEW | FITNESS on cooldown; curing_bals/008 |
| `Your body is too weary to perform such a feat.` | 435 (14) | NEW | FITNESS blocked by weariness; no trigger of ours matches it |
| `You must regain equilibrium first.` | 3312 | NEW | A typed `diag` while CURSEWARD's equilibrium was spent |
| `The idea of putting something in your stomach sickens you.` | 3708 | NEW | Anorexia refusal after "[Curing]: TRANSMUTE 814" |

### The opponent's cure and defence lines (third person)

| Line | First (count) | KB | Note |
|---|---|---|---|
| `Agathon's aura of weapons rebounding disappears.` | 30 (24) | raw | Prints just before each of his attacks; triggers 225/400 match it |
| `You suddenly perceive the vague outline of an aura of rebounding around Agathon.` | 208 (23) | raw | 8-9 s after a smoke |
| `Agathon takes a long drag off an enamel bubble pipe.` | 449 (17) | NEW | Only 390_Smoked matches it |
| `A great gurgling sound is heard as Agathon takes a long drag from an enamel bubble pipe. A series of shining bubbles erupt from the bowl of his pipe.` | 39 (6) | NEW | The same pipe's other wording |
| `The bubbles spewn from an enamel bubble pipe burst. *POP*  *POP*   *POP*` | 104 (6) | NEW | Flavour, 2-3 s after each gurgling smoke |
| `Agathon takes a drink from an oaken vial.` | 1067 (3) | NEW | |
| `Agathon peers about himself dubiously.` | 3508 | NEW | Meaning unknown |
| `Comprehension flashes across Agathon's face.` | 3607 | NEW | Meaning unknown |

### Telepathy

| Line | First (count) | KB | Note |
|---|---|---|---|
| `You are not the member of any party.` | 9 | NEW | Reply to the lock alias's `pt` |
| `You cease attempting to initiate a mindlock.` | 20 | NEW | MIND CEASE |
| `Mindnet: Agathon has entered the area.` | 24 | NEW | |

### Kata and form

None.

### Kai

No game line is visible. TRANSMUTE's line is gagged, and kai gain and decay print nothing.

### Arena, death and world

| Line | First | KB | Note |
|---|---|---|---|
| `Your target is now: Agathon (an adventurer)` | 1 | raw | |
| `Agathon is now one of your enemies.` | 2 | NEW | |
| `Tendrils of blackness spew forth from the surface of the mirror, pulling you beneath its sheen surface. Pain pierces your mind. Just as you succumb to the terror, you awake, and you find yourself within a forbidding forest.` | 12-13 | NEW | Arena entry |
| `You are moved by an iron-rimmed mirror.` | 14 | NEW | |
| `Corroded meadow.` | 15 | NEW | |
| `The stars twinkle in the clear night sky. An ornate mirror stands here, its silver face reflecting cold light.` | 16 | NEW | |
| `You see exits leading north, east, south, and west.` | 17 | NEW | Generic |
| `The face of Agathon appears in the mirror, warping as he steps through it.` | 23 | NEW | |
| `Alertness: Agathon has entered Corroded meadow at your location.` | 25 | NEW | |
| `A roar of triumph bursts from Agathon and with horrified realization, you watch as he brings his whirling scimitar towards your neck, severing your head from your body. The last thing you see before death is your own crumpling body, neck spitting blood like a fountain.` | 3789-3790 | NEW | BEHEAD kill |
| `You have been slain by Agathon.` | 3791 | NEW | Our trigger 407 |
| `You have been defeated and are thrown out of the Arena.` | 3800 | NEW | |
| `The spectator stands of the Colosseum Diabolus. (indoors)` | 3802 | NEW | |
| `A noxious, red-hued fog overwhelms the area with a thick, palpable vapour. A runic totem is planted solidly in the ground. A stalwart basalt pedestal bears a gleaming bronze plaque aloft, declaring the Champion of Baelgrim. A vicious death adder is here, hood flared in warning. Domina Saibel Aristata is here. Her features are obscured by a mask of lifevision. She wields a serrated dirk of cold steel in her left hand and a sable heater shield lined with broken arrowheads in her right.` | 3803-3805 | NEW | |
| `You see a single exit leading south.` | 3806 | NEW | |
| `It is now the 2nd of Daedalan, 1014 years after the fall of the Seleucarian Empire.` | 3327 | known | |
| `Talo has been slain in The Collosea en Duir by Miriew Le'Yuet, Brother from another Boulder.` | 2245 | NEW | Another fight |
| `A shade of magic has destroyed Zargoth with the wonders of the arcane.` | 3424 | NEW | Unrelated |
| `A shade of might has destroyed Vissa in a deadly display of brute force.` | 3463 | NEW | Also 3492 (Zargoth) |
| `You tilt your head to one side, rub your chin, and thoughtfully declare "Hrm."` | 1295 | NEW | Emote |
| `"Heh heh heh," Agathon chuckles.` | 3691 | NEW | |
| `Your mouth turns up as your face breaks into a smile.` | 3700 | NEW | Typed `smile` |

**Logger stand-ins for gagged game lines (not game text):**
- `Agathon: Curse -> You` (87), `Agathon: Jinx -> You` (26).
- `Agathon: Invoke Relapse/Bloodlet/Coagulation -> You` (5 each).
- `You: Mindlock (start) -> Agathon` (6), `You: Curseward` (12), `You: Kai Transmute -> Yourself` (2).

## Answers to the open questions

- **Telepathy without a lock.** Not tested: no MIND ability was used in the room. What the log does show:
  - MIND LOCK can be started on a target who is not in the room (6; Agathon arrives at 23).
  - The attempt survives an arena-mirror transfer and is stopped by MIND CEASE (12-20).
  - MINDNET reports the arrival (24).
- **Blackout.** None, on either side.
- **Kata limits and stumbles.** No data: there were no strikes, and kata was 0 on all 781 prompts.
- **Kai Surge / Kai Choke cost.** Neither was used. What was measured:
  - KAI TRANSMUTE costs no kai (3565, 3713).
  - In Kai Trance, kai comes from the enemy's landed attacks (+3 per curse, +4 per jinx) and decays 10 about every 30 s. Against curse pressure it reached 100 within 50 s (1016).
- **Dawnkick's epilepsy line.** No dawnkick was used. The victim-side epilepsy lines, from a Shaman jinx:
  - afflicted: "Your nerves feel suddenly jangled." (3456);
  - fit: "Your limbs begin to jerk and shake uncontrollably, and you begin to foam at the mouth." (3536, x5), 1.8 s of balance each;
  - the first fit came about 28 s after the affliction.

  Whether dawnkick's delayed epilepsy prints the same lines is untested.
- **Light, parried and absorbed strikes.** None.
- **Prone extras for hiru, hiraku and risingkick.** None. No strikes were made, and nobody was ever prone ("prone" never appears in the log).
- **Shields and rebounding:**
  - Neither side used a magical shield or SHATTER.
  - Agathon's rebounding comes up 8-9 s after each pipe smoke and drops at each of his own offensive acts, including curses the ward held, the chant and breaches (24 drops, 23 auras).
  - Mystor's defences were the curseward (12 raises, 11 breaches) and the fangbarrier (stripped by slickness, back 8-10 s after quicksilver).

## Lessons for our package

### For our Shikudo offense

- **The Shaman's rebounding is down whenever he acts.** Each attack strips it, and it comes back only 8-9 s after his next smoke (24 drops, 23 cycles). Staff strikes straight after his curse or jinx land without rebounding.
- **Kai is cheap against a Shaman.** In Kai Trance the enemy's attacks pay for kai abilities: 0 to 100 in 50 s (36 to 1016). It decays 10 per 30 s, so it is better spent than banked.
- **Rain makes equilibrium cheap.** DIAGNOSE cost 0.72 s against an AB value of 1.00 s (259). MIND abilities and CURSEWARD are cheaper in Rain. FITNESS's balance cost did not follow the same factor (385).
- This log carries no combo, kata or Telepathy data for the Shikudo rework.

### For our defence against this opponent class

- **Weariness is the Monk's lock key.**
  - It refuses FITNESS with "Your body is too weary to perform such a feat.", and the game checks it before the cooldown (3244-3293).
  - Cure weariness before it pairs with asthma.
  - When both are up, the server's aurum is unpredictable: it cured weariness at 379, 2086 and 2833, and asthma at 546, 1118 and 1214.
- **Save the tree and FITNESS while asthma and impatience are up.** The lock landed 8 s after FITNESS and 6 s after the tree had been spent on haemophilia (2681, 2741, 2895).
- **The seal arrives inside the eating window.** It came in the same packet as an aurum (1116-1127) or about 1 s after one (2832 to 2888). Mystor's own advice is to track the enemy's eat timing (2073).
- **A paralysis-first order lets a Shaman tax every eat.** Paralysis was cursed back within 1-2 s of each magnesium (805 to 849, 865 to 881). Haemophilia waited 11 s and impatience up to 19 s.
- **Curseward is a speed bump:**
  - BREACH removed it 0-2 s after it went up, 11 times out of 12.
  - The 12 raises cost about 2,000 mana.
  - It does stop the bleed and kai riders; a held curse adds nothing (1762).
- **Every curse also bleeds.**
  - With Teraile, each curse is +40 bleed (+80 per jinx), unclottable under haemophilia.
  - Clotting costs 40 mana per 20 bleed: 3,400 mana in the first 38 s alone (lines 1-800).
  - Bleeding never threatened the kill: 31 ticks, health always at least 77%.
- **Relapse brings paralysis back.** It returns 1-3 s after the first cure. The "Horror overcomes you..." line could pre-queue a second magnesium; no trigger of ours reads it.
- **Watch the Tzantza count.** Six valid afflictions kill instantly (shaman.md:160). He tried at four: epilepsy, dizziness, impatience and stupidity (prompt 3622).
- **BEHEAD needs no prone.** A paralysed, truelocked, non-prone victim died to it in about 10 s. The draw line (3715) is the earliest tell.
- **Paralysis does not stop equilibrium actions.** CURSEWARD (3305-3672), DIAGNOSE (3566-3581) and KAI TRANSMUTE (3563, 3711) all worked while paralysed.
- **Trigger gaps:**
  - 215_Rebounding_Smoked, 278_Lost_Asthma and curing_bals/009_Ataxia_Rebounding use `takes a long drag off \w+ pipe` (one word before "pipe"). None of them can match this opponent's 23 smokes, in either wording. 390_Smoked catches both: its patterns are at 390_Smoked.lua:35 and :37, the latter `^(\w+) takes a .+ pipe.$`.
  - 009's 8 s timer value matches the measured 8-9 s; only its pattern needs widening.
  - determine_class/003 did not fire on anything in this log.
  - Nothing matches: the breach line, the curseward-holds line, the relapse line, the dull ache, the weave, the chant and its end, or "too weary".
  - curing_bals/006-008 track FITNESS's use, readiness and cooldown refusal (`ataxiaTemp.activeCureUsed`), but nothing handles the weariness refusal.
  - Mystor's client re-sent FITNESS up to 67 times a second (2837-3241). Our 008 cooldown flag exists to prevent exactly that loop.
- **Code assumptions this log contradicts:**
  - Our Shaman dossier gates COAGULATION on bleed of 200 or more (.claude/classes/shaman.md:63, 124). The game accepted it at 120 (2895-2899).
  - Our Serpent behead requires prone (serpent/002_Serpent_Offense.lua:1708-1714), which is stricter than what killed Mystor.

### For our tracking of this class's cures

- **His curing order is unobservable here.** Get a Sapience log, or a fight in which he is afflicted.
- **278_Lost_Asthma never fires on a multi-word pipe.** It treats "the target smoked" as proof he has no asthma. A Shaman with a decorated pipe will keep a stale asthma in our target model.
- **Model rebounding as down from his attack until 8-9 s after his next smoke.** The drop line (30) is the anchor.
- **The server's herb choice is not a fixed order:**
  - aurum on asthma + weariness cured each three times;
  - plumbum on the same two afflictions (dizziness + impatience) cured impatience at 2472 and dizziness at 2504, with no priority change printed in between.

  This contradicts kb/afflictions/README.md ("in the server's order"), which V3's cure-branching weights depend on. It is a candidate kb/CONFLICTS.md entry.
- **Victim-side re-curses are invisible to GMCP.** A re-cursed affliction prints only its own message, with no Add, so text-based counting would double-count (822, 1604, 2585, 3300). Keep GMCP authoritative.

## Unclear or unverified

- **The ache's source.** "A dull ache builds behind your eyes." most likely comes from the Teraile attunement. It prints once per jinx although a jinx bleeds twice (2586-2587).
- **The short curse line.** "Agathon points an imperious finger at you." is the short form. Our basher records our own swiftcurse attack as "You point an imperious finger at..." (highlighting/071 per CLAUDE.md), so the short form may be the SWIFTCURSE line rather than a plain CURSE line. The gagged curse lines cannot settle it. Mystor kept the blind and deaf defences (252-253), which might also change what he sees.
- **The weave.** "Agathon weaves his fingers together skilfully." as SWIFTCURSE: likely, not confirmed.
- **The chant.** It is most likely TZANTZA, but no ability name is shown. Why it stopped is not shown either: his pipe smoke (3632) came between the start and the end.
- **Two unidentified lines:** "Agathon peers about himself dubiously." (3508) and "Comprehension flashes across Agathon's face." (3607).
- **The silent curse at 3332:** a curse that added bleed but printed no affliction message, landing before the ward went up. It may have been a BREACH sent with no ward up.
- **The silent jinx at 3421:** the jinx into the ward printed nothing visible beyond the logger's label. The game's line for a blocked jinx is gagged.
- **Why the breaching paused.** Agathon did not breach for 47 s (3472-3619) after breaching within 0-2 s every time before.
- **Two lines may not be game text:** "You have been afflicted with..." and "You have cured the ... affliction." The GUIDE treats them as game text, but they are absent from both earlier raw logs. They may be a CONFIG option or Zax's.
- **The `[Curing]:` lines.** The GUIDE calls them the system's, but our trigger curing_bals/002 matches `[Curing]: TOUCH TREE` as game text. Their origin is unsettled.
- **The `[Bal Spent]` / `[Eq Spent]` figures.** They are constant per ability. Whether they re-print the game's own figures is unknown: the log contains no "Balance used" or "Equilibrium used" text.
- **Zax's priority writes:**
  - paralysis goes to 25 right after FITNESS or CURSEWARD spends balance or equilibrium, and back to 5 within 1-4 s (391/413, 1653/1663, 2691/2717, 3309/3318);
  - while it sat at 25, ferrum went first once (2700-2727);
  - asthma at priority 1 did not stop three aurums curing weariness;

  so whether, and when, these writes reach server-side curing is unproven.
- **Did FITNESS wait for equilibrium?** It fired only when equilibrium returned after a CURSEWARD (1686-1688, 2679-2681). That may be a game requirement or Zax's own rule.
- **TRANSMUTE 814.** Its refusal (3708) is unexplained.
- **Untyped prompt changes.**
  - The +200 health / -100 to -181 mana ticks (2074, 3493, 3716) may be boosted regeneration (regeneration and boostedregeneration were among his defences, 3751-3752).
  - The kai decay may be the Kai Trance drain.
- **Untyped DIAGNOSEs** at 251 and 1084 were sent by the system or a key.
- **Stale FITNESS refusals** at each balance recovery (435, 1723, 2171, 2750) were probably duplicate FITNESS commands waiting in a queue.
- **The CLOT cost** of 40 mana per clot is against the wiki's 60. It may be specific to this character.
- **Invoke cooldowns** (relapse 28 s, bloodlet 13 s, coagulation 14 s) are upper bounds from use, not measured cooldowns.
- **The curative refund** on leaving the arena (+47 magnesium and others, 3792-3798) may include earlier fights.
- **Not settled as game or system text:** the asterisk banners (3799, 3801), the `(indoors)` suffix (3802) and `[here - Agathon (1)]` (26).
- **What `[h]` means.** It shows at 354, 2102 and 2899-3294 with asthma, anorexia, slickness and impatience but no paralysis. `[true]` replaces it at 3302. It is most likely Zax's "hardlock" tag.
- **Agathon's class switch from Infernal** is inferred from the GUIDE's table, not seen in this log.

**Chunk-report claims corrected against the log:**
- **MIND LOCK start.** The `Mindlock (start)` line is 6, not 7 (chunk 4).
- **Coagulation count.** There were five, not four: 350, 1124, 2098, 2895 and 3410 (chunk 5).
- **390_Smoked.** It matches both pipe wordings, not only the gurgling one (chunk 5): its second pattern catches "takes a long drag off an enamel bubble pipe."
- **The `[h]` range** is 2899-3294, not 2899-2926 (chunk 1).
- **Counts.** The 113 aches reconcile exactly to 87 landed curse lines + 25 landed jinxes + 1 chant, which confirms that the jinx at 3421 was blocked. There were 130 cooldown refusals and 14 weariness refusals for FITNESS, and 31 bleed ticks.
