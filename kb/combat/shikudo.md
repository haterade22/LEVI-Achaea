---
topic: shikudo-combat
confidence: mixed (tagged per claim)
sources:
  - kb/raw/logs/2026-10-11_shikudo-vs-runewarden-snb_attacker.txt
  - kb/raw/logs/2026-10-11_runewarden-snb-vs-shikudo_defender.txt
  - kb/raw/wiki/Shikudo.wiki
  - kb/raw/wiki/Telepathy.wiki
  - kb/raw/wiki/Kaido.wiki
  - kb/raw/live/affliction_show/blackout.txt
  - the user and Mystor, in game, 2026-10-11 (Telepathy and the mind lock; blackout)
code:
  - src_new/triggers/levi_ataxia/for_levi/leviticus/563-587 (strike triggers, strike-start dedupe reset)
  - src_new/triggers/levi_ataxia/for_levi/leviticus/calls/ (effect-line triggers)
  - src_new/triggers/levi_ataxia/for_levi/leviticus/3rd_person_shikudo/ (effect-line triggers)
  - src_new/triggers/levi_ataxia/for_levi/leviticus/telepathy_tekura/
  - src_new/scripts/levi_ataxia/levi/levi_scripts/shikudo/006_CC_Shikudo_Dispatch.lua, 007_CC_Shikudo_Lock.lua
  - src_new/tests/test_shikudo_tracking.lua
last_verified: 2026-10-11
---

# Shikudo in combat

What a Shikudo monk's attacks look like on screen, from both sides, read from two real fights
(2026-10-11): a Shikudo killing a Runewarden by Dispatch (the monk's own log), and a Runewarden
killing a Shikudo (the Runewarden's log). This is what our tracking triggers have to match, and
what the offense has to plan around. Abilities themselves (syntax, forms, costs) are in
[classes/monk.md](../classes/monk.md); kill routes and locks in `.claude/classes/monk.md`.

Unless marked otherwise, every line below is **CONFIRMED (live)**: it appears in one of the two
logs. `<staff>` is the weapon's description ("a twisted oaken staff"), `<T>` the target,
`<M>` the monk as the victim sees him.

## How a combo works

- **Syntax:** `COMBO <target> <attack> [side|limb] <attack> [side|limb] <attack> [side|limb] [TRANSITION <form>]`.
  Seen: `combo Claes flashheel left kuro left kuro left`, `combo Claes nervestrike livestrike risingkick head`,
  `combo Claes frontkick left kuro left ruku right transition oak`, `combo Claes SHATTER flashheel right hiraku transition rain`.
- **The kick can go anywhere** in the combo (`nervestrike livestrike risingkick head` puts it last).
- **One kata action per attack:** "You are now maintaining a kata chain of 3 actions." after a
  three-attack combo, 6 after the next, and so on.
- **`light`:** `kuro light left`, `nervestrike light`. A light strike prints its strike line and
  its effect line but **no damage line**, i.e. it lands the affliction without limb damage. Use:
  keep afflicting through a limb without breaking it before the rest are ready.
- **Balance:** the "Balance used" line prints straight after the combo's KICK, once per combo, so
  only combos with a kick are measured: 2.1 s for 21 combos in Gaital, Rain and Oak, **1.9 s in
  Willow** (all three Willow combos, each with flashheel: the wiki's faster strikes and kicks,
  confirmed), and 2.8 s for the one Gaital combo with dawnkick. The four combos without a kick (two
  in Oak, two in Gaital) printed no reading. ADOPT took 4.1 s and a leap 1.0 s. Rain does not change
  balance.
- **Transitions:** `TRANSITION <form>` inline at the end of a combo works (the form's line prints
  right after the combo's kata line), and so does a separate `TRANSITION TO RAIN FORM`, which **cost
  no balance and went through while paralysed** (twice in log 1). **A kata of at least 5 is
  required:** "A kata of at least 5 must be performed in order to flow from the Willows Shaken by the
  Wind to another." (also seen for Gaital). A refused transition **keeps** the chain (kata 3 stayed
  3, and the next combo made 6). Seen: Gaital to Rain at kata 12 and 10, Rain to Oak at 6 and 18,
  Oak to Willow at 6, Willow to Rain at 9, Oak to Gaital at 13. A new form starts the kata again at
  0, and **every strike sent counts**: fumbled, parried, light and SHATTER alike.
- **ADOPT <form> FORM** reaches a form that is not on the current form's list, and **costs balance
  (4.1 s)**: "You clumsily transition from the form of Willows in Rain Storm into the form of Gaital."
  (the monk was clumsy at the time, so "clumsily" may come from the affliction). Others see: "<M>
  falters, his flowing motions becoming jerky for a moment as he abruptly transitions into a new
  series of kata."
- **How long a chain can run:** the wiki gives no number (Rain allows "twice the normal length",
  and Tykonos is exempt), and a stumble is a chance that grows the longer a chain runs. Log 1: Oak
  reached 13 and Rain 18 with no stumble. That rules out only a certain stumble at 12, which is how
  our code's comments put it (006: "Must transition before kata 12 stumble"); it does not rule out a
  12/24 limit. The stumble line has never been captured. Per the wiki a stumble resets the kata AND
  drops you into Tykonos.
- **ASSESS gives the target's health,** which Crescent needs (it requires 50% or less):
  "You glance over <T> and see that her health is at 4463/5460 [81%]." The monk in log 1 ran
  `assess` after every combo.

## The lines of each attack

Each strike prints up to three lines: the **strike line** (it carries the staff's name, so it is
long: up to 147 columns), the **damage line** (only when the blow does limb damage), and an
**effect line** when the affliction lands. Most attacks print a different strike line when they
are the **first** attack of a combo and when they **follow** another one.

| Attack | Strike line, first in the combo | Strike line, later in the combo | Effect line | Gives | Limb damage |
|---|---|---|---|---|---|
| kuro | Dropping into a lower stance, you sweep <staff> at the left thigh of <T>. | Falling back into a low crouch, you lash out with a swift strike at the left thigh of <T>. | The staff cracks across the left thigh of <T>. | weariness; lethargy if already weary | 8.4% leg |
| ruku | You whip <staff> at <T> in a controlled arc, bringing its length to crack against her torso. | You spin a full rotation, bringing <staff> around in a blur of motion to smash into the torso of <T>. (or "the right arm of <T>") | torso: <T> staggers as the staff cracks across her ribs, sweat breaking out upon her forehead. arm: The staff connects to the right arm with a resounding crack, the limb flopping uselessly. | torso: slickness. arm: clumsiness; healthleech if already clumsy | 8.4% |
| nervestrike | You whip <staff> at the side of <T>'s neck. | (not seen) | none on the attacker's side | paralysis | 12.3% head |
| livestrike | Lunging forward, you drive the end of <staff> viciously into the solar plexus of <T>. | Turning with the motion, you channel the momentum of your previous strike into a thrust at the solar plexus of <T> with <staff>. | The breath of <T> leaves her in an explosive gasp as the end of the staff smashes home. | asthma | 12.3% torso |
| hiru | Whirling <staff> in a tight arc, you bring the weapon around to crash into the side of the head of <T>. (ASSUMED: our trigger 575) | Snapping back into a ready stance, you whirl <staff> in a long sweep at the head of <T>. | The staff connects to the side of <T>'s head with a resounding crack. | dizziness; confusion too if prone (WIKI) | 8.6% head |
| hiraku | Stepping forward, you drive <staff> at the face of <T>. (ASSUMED: our trigger 178) | Bracing your back foot, you lunge forward with <staff> at the face of <T>. | The staff smashes into the face of <T> with a sickening crunch. | anorexia, stuttering; a stun too if prone (WIKI) | 8.6% head |
| needle | With pinpoint precision, you drive <staff> at the throat of <T>. (ASSUMED: our trigger 564) | Reversing your grip on <staff>, you drive the top of the weapon into the throat of <T>. | The end of the staff smashes into the exposed throat of <T>, crushing cartilage. | crushed throat (the windpipe Dispatch needs) | 13.4% head |
| jinzuku | Stepping to the side of <T>, you drive <staff> at her kidneys. (ASSUMED: our trigger 566) | You flow around <T>, <staff> lashing out in a swift strike at her kidneys. | The end of the staff drives viciously into the kidneys of <T>. | addiction | 8.4% torso |
| flashheel | Snapping your leg out to its full extent, you drive a heel into the left knee of <T>. | (same) | You feel the satisfying crunch of bone under the impact of your heel. | **breaks the leg** | 8.4% leg |
| frontkick | You lash out with a straight kick at the left shoulder of <T>. | (same) | The instep of your foot smashes into the left underarm of <T>, throwing her from her feet and sending her spinning to the ground. | prone | 8.4% arm |
| risingkick | You drive your foot up in a rising kick at the head of <T>. (or "the torso") | (same) | head: Your foot catches <T> under the chin, snapping her head back. torso: Your foot drives into the solar plexus of <T>. | a stun on a prone head or a torso with trauma (WIKI) | 8.4% |
| dawnkick | Springing off your back foot, the heel of your foot smashes into the temple of <T> with flawless precision. | (not seen) | epilepsy about 2 s later; that line was deleted by the logger's system, so it is still **wanted** | epilepsy | 8.9% head |
| sweep | Taking a firm hold of <staff> you whip it in a wide sweep at the legs of <T>. | | The staff sweeps the legs out from under <T>, sending her sprawling. | prone | none |
| SHATTER | Bracing your feet, you drive <staff> towards <T>. | | The end of your staff smashes the magical shield surrounding <T> in an explosion of translucent shards. | breaks the shield tattoo | none |

The damage line is always "As your blow lands with a crunch, you perceive that you have dealt
8.4% damage to <T>'s left leg." The limb damage per attack above is what one monk dealt one
Runewarden; it will vary with the monk and the target.

**Flashheel breaks the leg in one blow.** The 8.4% is the limb damage it does as well; the
Runewarden applied salve to her legs after every flashheel.

### How a strike can fail, and what that looks like

- **Parried:** the strike line prints, then "<T> parries the attack with a deft manoeuvre." No
  damage line, no effect line. **A strike line on its own does not prove a hit.**
- **Fumbled** (the monk is clumsy): the strike line, then "You fumble your strike, the attack going wide."
- **Absorbed:** against a Shield of Absorption the damage line can be missing while the effect
  line and the affliction still land. The victim sees "Your shield completely absorbs the damage."
- **Light** strikes print no damage line by design (above).

### What the victim sees (log 2)

| Attack | Line | Then |
|---|---|---|
| kuro, first | Dropping into a lower stance, <M> sweeps <staff> at your right thigh. | The staff cracks across your right thigh, the muscles suddenly becoming weak. |
| kuro, later | Dropping back into a low crouch, <M> whips <staff> at your right thigh. | (same) |
| nervestrike | <M> whips <staff> at the side of your neck. | Your body locks in paralysis as numbness overtakes your body below the neck. |
| livestrike, later | Bleeding off the momentum of his previous strike, <M> turns and brings <staff> around in a thrust at your solar plexus. | Your breath exits your lungs in an explosive gasp as the end of the staff smashes home. |
| hiru, first | <M> whips <staff> in a tight arc, sweeping it at your head. | Stars explode in front of your eyes as the staff cracks you across the side of the head. |
| hiraku | Bracing his back foot, <M> lunges forward with <staff> at your face. | The staff drives into your face, your jaw shattering under the blow. |
| flashheel | Snapping his leg out to its full extent, <M> drives a heel into your left knee. | You feel your knee crunch under the force of the kick, nausea and pain racking you. |
| frontkick | <M> lashes out with a straight kick at you. | Pain blossoms as the instep of <M>'s foot smashes into the vulnerable cluster of nerves beneath your left arm, sending you spinning to the ground. (prone; once also a broken left arm) |
| risingkick | <M> lashes out with a high kick at your torso. | The foot of <M> drives into your solar plexus. |
| damage | As <M>'s blow crunches into you, you perceive that he has dealt 9.2% damage to your right leg. | |

Our own limb counter reads that damage line through an unanchored `dealt N% damage to your
<limb>` temp trigger (`self_limb_tracking/002_Track_The_Damage.lua`), so it works whenever the
line fits on one row (log 2's 96-column wrap split it; this user's 119-124 does not).

## Forms

| Form | The monk sees | Others see |
|---|---|---|
| Rain | Dropping into a lower stance, you snap your weapon into an offensive position, tensing your muscles in preparation for the form of Willows in Rain Storm. | <M> drops into a lower stance, his weapon snapping up into an aggressive guard. |
| Oak | Rising onto the balls of your feet, you prepare to begin the deadly form of the Live Oak. | <M> rises onto the balls of his feet, a look of grim certainty overcoming his face. |
| Willow | Twirling your staff, you sink into the calm required for the form of Willows Shaken by the Wind. | <M> twirls his staff, a look of serene calm overcoming him. |
| Gaital | You let your eyes fall closed and instinct guide you as you flow into the form of Gaital. | The eyes of <M> fall closed, a look of tranquility coming over him. |

**What each form gives** (wiki, Shikudo): **Tykonos** diverts damage more easily, and a chain there
never stumbles. **Willow**: faster strikes and kicks (confirmed above). **Rain**: chains twice as
long, damage that grows with the chain, and **"your equilibrium recovery shall be significantly
increased"**, which is why monks do their Telepathy there. **Oak**: more damage. **Gaital**: strikes
slide through parries. **Maelstrom**: kai from damaging strikes inside a kai trance, and resistance
that grows with kai. **SHATTER** works in every form ("it can be performed in the flow of any one of
the forms").

## Telepathy

**A mind lock is needed only to reach a target outside your room, and for certain skills such as
Radiance and Sapience** (the user and Mystor, in game, 2026-10-11). Those two are lock skills by
nature (wiki): RADIANCE, the instant kill, builds up for a while and cannot be used on a target in
your room, and SAPIENCE shows you everything a locked target does. The user: most Telepathy needs
only the target in the room. The wiki agrees for its 15 abilities marked (*), all of which take a
target: impatience, paralyse, batter, confuse, stupidity, epilepsy, fear, amnesia, deadening,
disrupt, strip, crush, drain, divine and hallucinate. It puts a lock on the rest, **blackout**
included: no (*), and `MIND BLACKOUT` names no target, where every (*) ability takes one (its "your
locked target" wording is no guide alone: MIND IMPATIENCE, a (*) ability, says the same). The
players' rule is the working rule in the same room, but for blackout it disagrees with the wiki and
is untested; see [CONFLICTS.md](../CONFLICTS.md) #7. Log 1 cannot test it, because the monk held a
lock all fight.

**Rain is where Telepathy is cheapest.** Rain's "equilibrium recovery shall be significantly
increased" (wiki), and the user says Shikudo monks also use telepathy in Rain for that reason. It is
not Rain-only: log 1 cast its two afflictions in Willow. In log 1 a Telepathy round took the place
of that round's combo (the alias swapped the combo out for the MIND command); whether a monk can send
both in one round is open (log 2's blackout, below).

| Command | Line | Equilibrium used (form) | Wiki |
|---|---|---|---|
| MIND TRAVEL <T> | You drift on the waves of telepathy, allowing your mental power to carry you to your subject. | 0.85 s (Gaital); **0.72 s (Rain)** | 1.00 s |
| MIND LOCK <T> while locked | You must dissolve your current lock before attempting another. | | none listed |
| MIND IMPATIENCE <T> | You fill the mind of <T> with an impatient feeling. | 1.27 s (Willow) | 1.50 s |
| MIND PARALYSE <T> | You reach out with your mind and paralyse <T>. | 1.70 s (Willow) | 2.00 s |
| (the target died) | You have lost your telepathic lock upon <T>. | | |

Outside Rain every reading was 0.85 of the wiki's figure, a speed-up this character has everywhere
(cause unknown); the one Rain reading was 0.72. No victim-side line of any MIND ability has been
captured yet.

### Blackout

The user: **"Blackout is a CRITICAL affliction to give (you give it once, they usually touch tree to
cure and we give it again). Under blackout they cannot see what we do to them."** Mystor
(`.claude/classes/monk.md`): "Also if you arent using blackout at all in the rest of your attacks.
Blackout in rain is basically a no brainer. You can blackout, and then combo 1 time. And the combo is
hidden."
- **MIND BLACKOUT** (wiki): 800 mana and 4.00 s of equilibrium. Rain should shorten that; by how much
  is unmeasured.
- **The game's record** (`AFFLICTION SHOW blackout`): it lasts **4 seconds** and is cured by **time**.
  The victim gets no line when it lands, and "Your senses return to you as the blackout ends." when it
  expires. It "obscures your prompt and prevents you from seeing many things happening". It is not
  marked NoRandomCure, and in log 2 the **tree** cured it.
- **Seen live** (log 2, the victim's side): their prompt read BLACKOUT; the lines of their own
  actions ("You take a drink...", "You eat...", "You touch the tree...") and the bloodroot's cure line
  vanished while their curing kept firing, but "The elixir heals and soothes you." and their balance,
  ready, stun-ended and ferocity lines still printed; a stun ended with no visible cause; and they
  still saw the monk eat ("Dominius eats an aurum flake."). They touched the tree 1.85 s in, and it
  ended.
- **Why it matters:** a blackout they tree away is a tree (about 14 s cooldown, log 2) not spent on
  the lock, and the combo behind it is hidden. Give it again after the tree.
- **Not captured yet:** our own MIND BLACKOUT success line.

## Dispatch, as it was done

"Placing one foot on the chest of <T> to hold her in place, you drive your staff down with all
your strength into her weakened throat. The gurgling death rattle is the only sound to herald her
death as she gives a single great convulsion beneath your heel, then falls still." Then "You have
slain <T>."

The last minute (Gaital form): `sweep flashheel left` put her down at 13:17 ("The staff sweeps
the legs out from under Claes, sending her sprawling.") and **she never stood again**. Each round
the monk broke a leg again (`flashheel left ruku right ruku left`, `flashheel right ...`,
`flashheel left needle jinzuku`) and she spent her turns mending her legs; no "stands up" line
follows the sweep (that the broken leg is what kept her down is ASSUMED). The final needle pushed
the head over 100% and crushed the throat, and `dispatch Claes` followed at once. The logger's
limb tracker read head 110, torso 112, left arm 42, right arm 50, left leg 8, right leg 101.

## The two fights

**Log 1, the Shikudo's (86 s, a win).** Every combo round, and the Dispatch, sent one server alias:
`dismount`, `stand`, `wield staff`, `mind lock`, `parry <limb>`, the combo (or `dispatch Claes`),
`assess`. MIND IMPATIENCE went through the same alias with the combo swapped out for it. MIND
PARALYSE (`mp`) and both MIND TRAVELs (`mt`) went out as bare queued commands
(`queue addclearfull eb mind paralyse Claes`), without the alias's dismount, lock, parry or assess.
The plan, in order:
1. **Gaital:** dawnkick and kuro kuro, then flashheel and two kuros on one leg, over and over (the
   leg broke each time and was mended each time), then TRANSITION TO RAIN FORM at kata 12.
2. **Rain:** frontkick, kuro, ruku to the arm (prone, weariness or lethargy, clumsiness or healthleech).
3. **Oak** (at kata 18): nervestrike, livestrike, risingkick to the head; nervestrike, ruku torso,
   risingkick, then on to Willow.
4. **Willow:** flashheel, hiru, hiraku while she was prone (she mended her legs and stood up
   right after). MIND IMPATIENCE and MIND PARALYSE between combos, and SHATTER when she raised a
   shield.
5. Back through Rain and Oak (livestrike, kuro, risingkick to the torso) to **Gaital** at kata 13.
6. Gaital to Rain at kata 10, then ADOPT Gaital (4.1 s of balance); sweep and flashheel; flashheel
   and two rukus to the arms; flashheel, needle, jinzuku; **Dispatch**.

The Runewarden cured with kelp, goldenseal, ginseng, bloodroot, moss and her elixir, mending on
her legs after every flashheel, the tree tattoo, FOCUS, a shield tattoo, sileris, and a Dagaz
rune on the ground that cured afflictions periodically. See [runewarden-snb.md](runewarden-snb.md).

**Log 2, the Runewarden's (a loss for the monk).** Dominius opened in Rain (kuro, kuro,
frontkick), mixed in nervestrike, livestrike, hiru, hiraku, risingkick and flashheel, and cured
paralysis with magnesium again and again. Claes was blacked out once (15:04:39; the source is not
shown, most likely MIND BLACKOUT) and touched the tree 1.85 s later. It came inside one of his Oak
combo rounds: "[AFF]: Blackout" printed after his nervestrike and livestrike, before the prompt, and
no third attack printed (each of his other seven Oak rounds had a rising kick to the torso). The
unexplained "You are no longer stunned." may be that hidden kick. If the source was MIND BLACKOUT
(equilibrium), it went out in the same round as a combo (balance), which log 1's alias never did.
Settle it on our first MIND BLACKOUT. Claes sliced the torso to 104%, razed his shield and
rebounding, then impaled and disembowelled him.

## Mystor's six arena fights (2026-10-11, first pass)

Mystor's own logs: `kb/raw/logs/2026-10-11_mystor_*` (how to read his client's output:
`kb/raw/logs/README.md`). In five of the six he ran MIND SAPIENCE on the opponent, so the logs show
the opponent's own typed commands (`--> Agathon: dsl Mystor left leg epteth epteth`). His plan, in
his words (`kb/raw/players/shikudo-2026-10-11.txt`): Rain to 10 kata with two rounds of arm prep
(frontkick to the arm, kuro, ruku: damage, prone, clumsiness, healthleech, weariness, lethargy),
then Oak (asthma, slickness), then Willow for the lock.

| Log | Opponent | Result | How it ended |
|---|---|---|---|
| EveP2TVe | Belaziel, Depthswalker | lost, about 49 s | SHADOW DICTATE: "Belaziel leans forward and whispers a single word into your ear: "Die"." |
| FceAmb0o | Agathon, Infernal with two scimitars | won | three KAI CHOKEs took him to 249/7281 (3%); he died moments later |
| LcJC-rJ5 | Agathon, Apostate | won | SPINKICK to the head (100%), then DISPATCH |
| c.iJVmpL | Agathon, Infernal | won | MIND SCYTHE |
| t54WWU6b | Agathon (first read: Shaman, from his curses and jinxes; no Sapience in this log) | lost, truelocked | "A roar of triumph bursts from Agathon and with horrified realization, you watch as he brings his whirling scimitar towards your neck, severing your head from your body." |
| vNTjvghY | Agathon, Infernal | won | KAI CHOKE, then "Agathon collapses to the ground, his life snuffed out like a candle." |

**Measured by his client** (`[Bal Spent]` / `[Eq Spent]` lines, all six logs; script output in the
session scratchpad, `timings2.py`):
- **Balance:** 2.1 s for every combo except in Willow (1.9 s, flashheel + hiraku + hiru, 15 times),
  with dawnkick (2.8 s) and with spinkick (needle + spinkick + kuro, 3.7 s). A transition at the front
  of a combo and a SHATTER inside one cost nothing extra. His commonest combos: Rain frontkick + kuro
  + ruku (29 times; also frontkick + ruku + kuro/ruku), Oak nervestrike + risingkick + ruku / livestrike /
  kuro, Gaital flashheel + kuro/ruku + ruku/jinzuku, Maelstrom risingkick + jinzuku + ruku.
- **Equilibrium: Rain takes 0.72 of the wiki's figure and every other form 0.85.**

  | Ability | Rain | Other forms | Wiki |
  |---|---|---|---|
  | MIND IMPATIENCE | 1.07 s (20) | 1.27 s (12) | 1.50 s |
  | MIND PARALYSE | 1.44 s (26) | 1.70 s (2) | 2.00 s |
  | MIND CONFUSE | 1.44 s (1) | 1.70 s (2) | 2.00 s |
  | MIND HALLUCINATE | | 1.70 s (2) | 2.00 s |
  | MIND THROW | 2.16 s (2) | | 3.00 s |
  | MIND DISRUPT | 2.89 s (10) | 3.40 s (3) | 4.00 s |
  | MIND SAPIENCE | 2.89 s (13) | 3.40 s (1) | 4.00 s |
  | MIND SCYTHE | 2.89 s (1) | | 4.00 s |
  | MIND BATTER | 2.70 s (1) | | 4.00 s |
  | CURSEWARD | 2.89 s (12) | | |
  | KAI CHOKE | | 3.40 s (4) | 4.00 s |
  | KAI CRIPPLE | 2.89 s (1) | | |

  0.85 everywhere is this character's own speed-up; Mystor says he has the quick-witted trait
  (`.claude/classes/monk.md`). So Rain itself takes about another 15% off equilibrium (0.72 / 0.85).
  BATTER's single 2.70 s reading fits neither ratio.
- **Kata:** outside Rain no chain of his went past 12 (Oak, Gaital, Willow and Maelstrom each reached
  exactly 12 in FceAmb0o); Rain reached 16 (LcJC-rJ5). Log 1's monk reached 13 in Oak, so 12 is his
  habit or a soft limit, not a hard cap (CONFLICTS #8).

**New lines (not in this page before):**
- **Nervestrike does have a line naming the target:** "Horror overcomes the face of <T> as his body
  locks in paralysis." (48 times, each right after his nervestrike). This page said it had none, and no
  trigger of ours records it.
- **KAI CHOKE:** "<T> gasps and stumbles as an unseen force crushes the life breath out of him." It
  was his finisher in two fights; in vNTjvghY the kill line followed: "<T> collapses to the ground, his
  life snuffed out like a candle."
- **KAI CRIPPLE** (LcJC-rJ5:2726): his client showed all four of the target's limbs at level 1 right
  after (its own model, not game text).
- **The Infernal's death aura:** "You feel sickened and weak by the aura of death emanating from <T>."
  then "You take 547 magical, damage." (40 times). Before his attack he wipes his scimitar: "<T>
  carefully wipes all the venoms off of a Scimitar of Eagles." and, as he attacks, "<T>'s aura of
  weapons rebounding disappears.".

**What the opponents typed** (Sapience; grouped per prompt, script `sapience.py`):
- **Infernal** (FceAmb0o): `stand / wield scimitar<id> scimitar<id> / wipe scimitar<id> / dsl Mystor
  left leg <venom> <venom> / assess Mystor`. The venom pairs were epteth + epteth, xentio + curare and
  epseth + epseth, all on the left leg. Between attacks he cured with `eat aurum` (often after
  `outr aurum`), `fitness`, `eat magnesium`, `smoke malachite`, `sip health`, `apply quicksilver` and
  `touch tree`.
- **Apostate** (LcJC-rJ5): `stand`, then `touch mercy / order loyals kill Mystor / g body / truestare /
  deadeyes Mystor <aff> <aff> / contemplate Mystor`. The pairs were breach + sensitivity, impatience +
  paralysis, stupid + paralysis and clumsy + paralysis. He cured with `eat aurum`, `eat magnesium`,
  `outr potash / eat potash`, `focus mind`, `touch tree` and `sip health`. He also told his party what
  Mystor had (`pt Mystor: impatience paralysis`).
- **Depthswalker** (EveP2TVe):
  - Opening: `touch amnesia / stand / wield shield scythe / chrono assert / chrono loop boost / chrono
    dilation`, and a monolith (`artefact recall`, `chrono distortion`).
  - Every attack: `touch amnesia / stand / put bomb in pack / get body / wipe scythe / wield shield
    scythe / shadow attune Mystor to degeneration / shadow instill scythe with
    <retribution|madness|depression> / chrono assert / shadow reap Mystor <venom> / assess Mystor /
    contemplate Mystor`.
  - The kill: `wield scythe dagger / unwield right / unwield left / intone tooros / shadow dictate
    Mystor`.
  - He cured with `eat kelp`, `touch tree` and `sip health`.

Full write-up of each fight (timeline, the opponent's rotation and curing order, every distinct game
line, lessons): [fights/](fights/README.md).

## What our triggers record (CONFIRMED-in-code, test_shikudo_tracking.lua)

Our queued attacks open the "Affs Post Queue - Gated" and "3rd Person Shikudo" trigger groups
until the next prompt (`misc_scripts/001_Queue_Scanning.lua`, `318_Prompt_Trigger.lua`).

- **Strike triggers (563-585)** pair a strike line with the damage line one or two rows later and
  record the affliction. The strike line is matched by its **start** (v4.7.413), because a full
  line with a long staff wraps at this user's 119-124 columns. They record nothing when no damage
  line prints: parried strikes (right), light strikes and absorbed blows (wrong; see below).
- **Effect-line triggers** (`3rd_person_shikudo/`, `calls/`, 586) record from the effect line,
  which prints whenever the affliction lands. They are the only record of livestrike and hiru as
  a later strike, and of light and absorbed blows.
- **Dedupe:** a strike trigger sets `ignoreThirdPerson`, and the effect-line trigger for the same
  hit skips once and clears it, so kuro does not step from weariness to lethargy twice. **587
  clears the flag at every strike line** (v4.7.414); before that, a strike with no effect-line
  partner (nervestrike, frontkick, risingkick, spinkick, ruku to the arm) left it set, and the
  next absorbed or light blow's effect line was skipped. Log 1 has the case at 12:14: a combo
  ended with ruku to the arm, and the next kuro's damage line never printed.
- **Telepathy** (`telepathy_tekura/`, the same gated window): confuse, batter, paralyse, stupidity,
  disrupt and impatience have triggers; blackout, epilepsy, amnesia, strip, deadening, scythe, fear,
  pacify, daze, isolate and clamp do not. A MIND affliction sent outside the server queue is never
  seen by them. No alias does that today: `mba`, `mp`, `mi` and `md` queue, and the unqueued `min`,
  `ml`, `mu`, `mhl`, `mha` and `mhd` send LOCK, UNLOCK and HALLUCINATE, which these triggers do not
  match (the lock line, 701, is ungated).
- **Blackout on the target:** nothing records MIND BLACKOUT. The only blackout recorders are Psion
  LIGHTSTEAL (525) and Knight CONCUSS (`snb/008`), both on a prone target, each clearing it after a
  fixed 3.5 s (the game says 4). The tracker's tree pool does not include blackout, so a tree under
  blackout never cures it in our model: the tree is charged to one or two of the target's OTHER
  afflictions instead, when it carries any (`onTargetTreeV3`, then trigger 389's `tSingleRandom()`
  erases the first one present on its own list), and blackout stays until its timer.
- **The Shikudo offense sends no Telepathy today** (the only automatic MIND command is the PvE
  basher's `aconfig monk` MIND CRUSH): the lock offense (007) waits on an equilibrium field nothing
  sets, puts every ability behind the mind lock, and sends bare words (`paralyse`) instead of
  `MIND PARALYSE`. A fourth picker, `disruptmind()` (`levi_scripts/telepathy/001_DISRUPT.lua`), is
  loaded but nothing calls it: it queues `mind blackout`, then CONFUSE, DISRUPT and IMPATIENCE, keyed
  off `tAffs.blackout`, which nothing sets for MIND BLACKOUT. Phase 2 of the rework.
- **A refused transition:** the live trigger `shikudo/002_Reset_Failsafe` zeroes our kata count
  (`ataxia.vitals.kata = 0`, echo "-= reset kata =-") on "A kata of at least N must be performed",
  and `basher/002_Class_Bashing.lua` (2361, 2620) relies on it; log 1 shows the game KEEPS the chain
  (phase 2).
- **Still not recorded:** light or absorbed **nervestrike** (paralysis) and **ruku to the arm**
  (clumsiness, healthleech), which have no target-named effect line; **dawnkick**'s epilepsy
  (line not captured); and target **stuns** (no duration is known). The fix is to hold a strike
  as pending until the next strike or the prompt and drop it on a parry, fumble or dodge line
  (planned with the offense rework, `docs/plans/shikudo-offense-review-2026-10-11.md`).

## Conflicts and open questions

- **Blackout and the mind lock:** the wiki says blackout needs one; the players' rule (a lock only
  for out-of-room targets and certain skills) says not in the same room. Settle it on the first
  live MIND BLACKOUT without a lock.
- **Kata limits:** no game number (the wiki: Rain allows twice the normal length, Tykonos never
  stumbles); our code caps at 12, and 24 in Rain. Log 1's Oak 13 and Rain 18 without a stumble rule
  out only a certain stumble at 12, since a stumble is a chance that grows. Kai Surge: the code
  assumes 31 kai (TK6 sends KAI SURGE with no kai check at all, 007 uses 31 only for a READY echo,
  and only switched-off 008 gates on it); the wiki says 45 (Kaido).
- **Prone extras (hiru's confusion, hiraku's and risingkick's stun):** the wiki has them; neither
  log shows a different line when they apply (hiru and hiraku hit a prone target at 12:29).
- **First-in-combo lines for hiru, hiraku, needle and jinzuku** come from our older triggers, not
  from these logs. Thrust, dart, spinkick, dawnkick-on-prone and Crescent are not in the logs.
- See [CONFLICTS.md](../CONFLICTS.md) for the open items.
