---
topic: shikudo-combat
confidence: mixed (tagged per claim)
sources:
  - kb/raw/logs/2026-10-11_shikudo-vs-runewarden-snb_attacker.txt
  - kb/raw/logs/2026-10-11_runewarden-snb-vs-shikudo_defender.txt
  - kb/raw/logs/2026-10-11_mystor_*.txt (Mystor's six arena fights)
  - kb/raw/wiki/Shikudo.wiki
  - kb/raw/wiki/Telepathy.wiki
  - kb/raw/wiki/Kaido.wiki
  - kb/raw/live/affliction_show/blackout.txt, disrupted.txt
  - the user and Mystor, in game, 2026-10-11 (Telepathy and the mind lock; blackout)
code:
  - src_new/triggers/levi_ataxia/for_levi/leviticus/563-587 (strike triggers, strike-start dedupe reset)
  - src_new/triggers/levi_ataxia/for_levi/leviticus/789 + src_new/scripts/.../levi_scripts/shikudo/010_Shikudo_Strike_Ledger.lua (the strike ledger)
  - src_new/triggers/levi_ataxia/for_levi/leviticus/calls/ (effect-line triggers)
  - src_new/triggers/levi_ataxia/for_levi/leviticus/3rd_person_shikudo/ (effect-line triggers)
  - src_new/triggers/levi_ataxia/for_levi/leviticus/telepathy_tekura/
  - src_new/triggers/levi_ataxia/for_levi/leviticus/164, 165 (kata chain and lapse), 698 (ASSESS), 389 (the target's tree)
  - src_new/scripts/levi_ataxia/levi/ataxia/monk/003_Shikudo_Extras.lua, 004_Kai_And_Kata.lua (kai, kata, ASSESS state)
  - src_new/scripts/levi_ataxia/levi/levi_scripts/shikudo/006_CC_Shikudo_Dispatch.lua, 007_CC_Shikudo_Lock.lua
  - src_new/tests/test_shikudo_tracking.lua, test_shikudo_ledger.lua, test_monk_kai_kata.lua, test_telepathy_tracking.lua, test_target_tree.lua
last_verified: 2026-10-12
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
  three-attack combo, 6 after the next, and so on. **KAI and MIND commands add nothing** (Mystor's
  prompts): `[Rain]:3` before and after a KAI CRIPPLE (LcJC-rJ5:2700, :2728), `[Willow]:3` through
  three KAI CHOKEs (FceAmb0o:6386-6447), and `[Rain]:9` through a MIND IMPATIENCE and four MIND
  PARALYSEs (FceAmb0o:2593-2739). So a run of kai or MIND rounds lets the chain age toward its lapse.
- **The chain lapses** when no strike comes for a while: "You can no longer maintain your deadly
  kata." (vNTjvghY:5967), about 20 s after the last chain line (10:40:43 at :5377, the lapse at
  10:41:03). The form is kept: the next prompt reads `[Rain]:0` (:5968). It appears once in the
  eight logs, against 55 form changes in Mystor's prompts alone, so a transition does not print it.
  Since v4.7.419 trigger 165 zeroes `ataxia.vitals.kata` on it and stamps `ataxiaTemp.kataLapseAt`;
  trigger 164 writes the chain line's count to `ataxia.vitals.kata` and stamps `ataxiaTemp.kataAt`.
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
  0, and **every strike sent counts**: fumbled, parried, light and SHATTER alike. An INLINE
  transition is judged after the combo's strikes: in log 1 (attacker:960-961) the chain line ("3")
  prints, then the refusal. Since v4.7.419 a real form change zeroes our `ataxia.vitals.kata` too
  (`shikudo_checkForms(true)`, `monk/003`), because charstats may not report the new chain until
  the next strike. **The wording our lock offense sends has only been seen refused:** 007 sends
  `;transition to the <form> form` after the combo (007:545 at HEAD), the wiki's detail wording
  (Shikudo.wiki:116; its syntax line, :112, has no THE). No log here shows it; they show the inline
  `transition <form>` and Mystor's separate `transition to <form> form`. But the PvE basher sent the
  same wording, after its combo, until v4.7.68, and the game answered it with the kata refusal
  (CHANGELOG v4.7.68 and commit 9064ca04, from a live log not kept in kb/raw), so the game reads it
  as a TRANSITION. Whether it succeeds at kata 5+ is unseen.
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
  - **Our policy (v4.7.419), not a game limit:** `ataxia_KATA` in `ataxia/monk/004_Kai_And_Kata.lua`
    leaves a form once the chain AFTER the combo reaches 12 (Rain 15; Tykonos as soon as a
    transition is legal, at 5), from how Mystor fights (no chain past 12 outside Rain; Rain to 15 in
    11 of 19 stints, 16 at most). `ataxia_kataShouldLeave(form, kata, strikes)` judges it, and
    the alias `skata` shows the caps or saves an override (it warns past the longest chains seen
    without a stumble, 13 and Rain 18). **No offense reads this policy yet:** 006 and 007 keep
    their own caps (12, 24 in Rain; 006:82-88, 007:71-78 at HEAD), and the basher keeps its own
    PvE literals (`SHIKUDO_BASH_ROTATION`, `basher/002`), which `skata` deliberately never changes.
  - **A probable stumble is recorded** (v4.7.419, `monk/003` `shikudo_formChanged`): a move into
    Tykonos that we did not ask for, while a chain was alive (a chain line in the last 30 s, and no
    lapse line or earlier form change since it, in an earlier round), goes into
    `ataxiaTemp.shikudoStumbles` and echoes "[Shikudo] probable STUMBLE from <form> at kata <n> --
    keep the line above". "Asked for" means a TRANSITION, ADOPT or DISPATCH/INCAPACITATE naming
    Tykonos, or a CRESCENT, sent in the last 6 s (the `sysDataSendRequest` watcher in monk/004). A
    combo's inline transition to any other form (`transition rain`) does not count: a long chain
    carrying its transition is exactly when a stumble is likeliest. It decides nothing; it is how the first stumble line gets kept
    ([CONFLICTS.md](../CONFLICTS.md) #8).
- **ASSESS gives the target's health,** which Crescent needs (it requires 50% or less):
  "You glance over <T> and see that her health is at 4463/5460 [81%]." The monk in log 1 ran
  `assess` after every combo. `698_Assess` stores the floored percentage in `ataxiaTemp.lastAssess`,
  which 006's Crescent reads (v4.7.417). Since v4.7.419 it also keeps the raw numbers and whom they
  were for (`lastAssessHp`, `lastAssessMax`, `lastAssessAt`, `lastAssessWho`), and
  `ataxia_assessAtMostHalf()` (monk/004) reads them: floored, 3540/7000 (50.57%) reads 50. No
  offense calls that helper yet.

## The lines of each attack

Each strike prints up to three lines: the **strike line** (it carries the staff's name, so it is
long: up to 147 columns), the **damage line** (only when the blow does limb damage), and an
**effect line** when the affliction lands. Most attacks print a different strike line when they
are the **first** attack of a combo and when they **follow** another one.

| Attack | Strike line, first in the combo | Strike line, later in the combo | Effect line | Gives | Limb damage |
|---|---|---|---|---|---|
| kuro | Dropping into a lower stance, you sweep <staff> at the left thigh of <T>. | Falling back into a low crouch, you lash out with a swift strike at the left thigh of <T>. | The staff cracks across the left thigh of <T>. | weariness; lethargy if already weary | 8.4% leg |
| ruku | You whip <staff> at <T> in a controlled arc, bringing its length to crack against her torso. | You spin a full rotation, bringing <staff> around in a blur of motion to smash into the torso of <T>. (or "the right arm of <T>") | torso: <T> staggers as the staff cracks across her ribs, sweat breaking out upon her forehead. arm: The staff connects to the right arm with a resounding crack, the limb flopping uselessly. | torso: slickness. arm: clumsiness; healthleech if already clumsy | 8.4% |
| nervestrike | You whip <staff> at the side of <T>'s neck. | (not seen) | "Horror overcomes the face of <T> as his body locks in paralysis." (Mystor's logs; recorded since v4.7.415) | paralysis | 12.3% head |
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

**DISPATCH works outside Gaital, and can name a form.** Mystor's Apostate kill (LcJC-rJ5, his
client's summary lines): at `[Gaital]:5` (:5834) one command sent `transition to rain form/dispatch
Agathon oak` (:5847); "You: Rain Form" (:5851), "You: Dispatch -> Agathon" (:5852), then "You have
slain Agathon." (:5859). So the Dispatch landed from Rain, as the wiki allows ("may be used
regardless of your form", Shikudo.wiki:369), with Oak named as the form to flow into.

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
  habit or a soft limit, not a hard cap (CONFLICTS #8). Over his six logs his prompts show 19 Rain
  stints, 11 of them ending at 15 or 16, and no other form past 12: our kata policy (above) is
  taken from this.
- **Kai costs, measured from his prompt's `K:` (kai is a percentage, 0-100), all equal to the
  wiki:** KAI BOOST 11 (`K:12%` to `K:1%`, LcJC-rJ5:546-575), KAI CRIPPLE 41 (`K:100%` to `K:59%`,
  LcJC-rJ5:2700-2728), KAI CHOKE 10 (`K:95%`, 85, 75, 65 over three chokes, FceAmb0o:6386-6447). No
  log has a KAI SURGE, so its cost is still the wiki's 45 (CONFLICTS #9). BOOST went out in the same
  command as a combo (`parry left leg/kai boost/combo Agathon ...`, LcJC-rJ5:561).
- **"Doubleaff" is his client's annotation, not game text.** His client tags each strike line with
  `Kata is N`, and adds `Doubleaff` after a ruku to the ARM from the 10th action of a chain and after
  a kuro from the 12th: every one at or above those counts in his six logs, none below, and never
  a ruku to the torso (which gives only slickness, with nothing to double). It fits what he told
  us: "I try to achieve 9/10 kata for the double up on kuro and ruku" (transcript in
  `.claude/classes/monk.md`) and "shooting for 10 kata in rain with 2x arm prep"
  (`kb/raw/players/shikudo-2026-10-11.txt:22`). Nothing in our code reads it, and AB SHIKUDO RUKU /
  KURO have not been checked for it.

**New lines (not in this page before):**
- **Nervestrike does have a line naming the target:** "Horror overcomes the face of <T> as his body
  locks in paralysis." (48 times, each right after his nervestrike, light ones included). This page
  said it had none. Since v4.7.415 `3rd_person_shikudo/008` records paralysis from it.
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
  line prints: parried strikes (right), light strikes and absorbed blows (the effect lines and the
  strike ledger record those; see below).
- **Effect-line triggers** (`3rd_person_shikudo/`, `calls/`) record from the effect line, which
  prints whenever the affliction lands. They are the only record of livestrike and hiru as a later
  strike, and of light and absorbed blows other than ruku to the arm (the strike ledger, below).
  v4.7.419 deleted two duplicates: 586, a copy of `3rd_person_shikudo/004` that recorded slickness
  a second time after every ruku to the torso, and the switched-off `calls/004`, an arm-line
  recorder with no target check.
- **Dedupe:** a strike trigger sets `ignoreThirdPerson`, and the effect-line trigger for the same
  hit skips once and clears it, so kuro does not step from weariness to lethargy twice. **587
  clears the flag at every strike line** (v4.7.414); before that, a strike with no effect-line
  partner (nervestrike, frontkick, risingkick, spinkick, ruku to the arm) left it set, and the
  next absorbed or light blow's effect line was skipped. Log 1 has the case at 12:14: a combo
  ended with ruku to the arm, and the next kuro's damage line never printed. Since v4.7.419
  `3rd_person_shikudo/001` (livestrike) skips once too, so a damaged livestrike records asthma
  once (576 already recorded it from the damage line); before, it recorded asthma twice.
- **The strike ledger** (phase 3a, v4.7.419: `levi_scripts/shikudo/010_Shikudo_Strike_Ledger.lua`,
  the global `shikudoLedger`, and trigger 789) records **ruku to the arm**, whose effect line names
  no target: "The staff connects to the right arm with a resounding crack, the limb flopping
  uselessly." That line prints on light, absorbed and damaged hits alike (after all 47 rukus to
  the arm in vNTjvghY). 587 opens an entry at every strike line (and reads up to two more rows when
  the strike line wraps); 789 hands the ledger every line that can end a strike; the prompt (318)
  expires the entry. An arm line counts only for the strike in flight, and only when that strike
  is a ruku to the same arm, at our target, under 2 s old and not dropped: then it records
  clumsiness, or healthleech once the target is clumsy, with 578's party relay, once per strike. A
  parry by the target, "You fumble your strike, the attack going wide." and a shield's rebound
  ("A dizzying beam of energy strikes you as your attack rebounds off of ...") DROP the strike.
  **Nothing is recorded without a line:** in Mystor's six logs all 202 strikes with no damage line
  were followed at once by an outcome line (174 effect lines, 17 parries, 8 fumbles, 3 damage
  lines; the counts are in the `010` header), so a strike that ends with no line is counted, never
  committed. Diagnostics: `shikudoLedger.unresolved` (strikes that ended with no outcome line,
  text in `lastUnresolved`) and `shikudoLedger.refused` (arm lines the strike in flight did not fit,
  with `lastRefused = { why, text }`; why is `unfinished` (the wrapped tail never came), `stale`,
  `not a ruku to that arm` or `other target`). With `shikudoLedger.debug = true` both echo the
  strike's text, which is how an unseen outcome line or wording gets captured. **Not yet checked
  live.** The FIRST-strike ruku to the arm line ("You whip <staff> at <T> in a controlled arc,
  bringing its length to crack against her right arm.") is ASSUMED from trigger 584's older pattern:
  no log has it (the torso form is at attacker:1807). If the game words it differently, the ledger
  refuses it as `not a ruku to that arm` and reports the text.
- **Telepathy** (`telepathy_tekura/`, the same gated window): confuse, batter, paralyse, stupidity,
  disrupt and impatience have triggers; blackout, epilepsy, amnesia, strip, deadening, scythe, fear,
  pacify, daze, isolate and clamp do not. A MIND affliction sent outside the server queue is never
  seen by them. No alias does that today: `mba`, `mp`, `mi` and `md` queue, and the unqueued `min`,
  `ml`, `mu`, `mhl`, `mha` and `mhd` send LOCK, UNLOCK and HALLUCINATE, which these triggers do not
  match (the lock line, 701, is ungated). Since v4.7.419 `mp` sends `mind paralyse`, the spelling the
  game accepted (attacker:1063-1064 sent, :1067 "You reach out with your mind and paralyse Claes."),
  not `paralyze`; `mrap`, which read an `affstrack` nothing assigns and threw on every use, is gone.
- **Blackout on the target:** nothing records MIND BLACKOUT (our own success line has never been
  captured). The two blackout recorders, Psion LIGHTSTEAL (525) and Knight CONCUSS (`snb/008`), both
  only on a prone target, record it since v4.7.419 through `ataxia_tarAffTimed("blackout")` for the
  game's 4 s (`ataxia_TARGET_AFF_SECONDS` in 017); a repeat restarts the clock. Before, each used a
  raw 3.5 s timer that a second blackout never cancelled, so the first timer erased the second
  blackout early. 525 now calls "blackout" to the party only when it lands, and names the person
  struck rather than the global `target`. A tree also cures it (below).
- **The target's tree is one charge** (v4.7.419, every class). Blackout has been in the tree pool
  since v4.7.416. With V3 on, trigger 389 calls `ataxia_targetTreeV3()` (`curing/002`), which lets
  `onTargetTreeV3` branch over the pool, then clears from tAffs (through `ataxia_tarAffFaded`, so
  blackout's 4 s clock stops too) every pool affliction that was present before the tree and is
  below 0.01 after it. When nothing branch-tracked in the pool was present and V3 accepted the tree
  (not an illusion), it also takes ONE level-1 broken limb, the first present (left leg, right leg,
  left arm, right arm): V3 tracks limbs simply and cannot branch them. `tSingleRandom({ noErase =
  true })` then erases nothing. Before, `tSingleRandom()` erased its own pick on top of the
  branching, so one tree on asthma, slickness and blackout summed to 4/3 afflictions where the truth
  is 2, and a real lock piece was lost. With V3 off, `tSingleRandom()` still erases one. 389 also
  stamps `ataxiaTemp.targetTreeAt` (the target's last tree); a target switch resets `tBals.tree` but
  not the stamp, so read it only while `tBals.tree` is false.
- **Telepathy in the offense** (v4.7.417): the lock offense (007) sends MIND IMPATIENCE, MIND BATTER
  or MIND PARALYSE <target> on equilibrium (`ataxia.vitals.eq`, 007:428-445 at HEAD), with no mind
  lock first, chained after the round's combo (007:535-540; whether a MIND command and a combo can
  share one queued round is untested). The dispatch offense (006) sends none, and no offense sends
  MIND BLACKOUT. The PvE basher's `aconfig monk` MIND CRUSH is separate. `disruptmind()`
  (`levi_scripts/telepathy/001_DISRUPT.lua`), which nothing called, was deleted in v4.7.419.
- **A refused transition keeps our kata count** (v4.7.417): `shikudo/002_Reset_Failsafe` still
  matches "A kata of at least N must be performed" but no longer zeroes `ataxia.vitals.kata`. The
  basher comments that assumed a reset are corrected (`basher/002_Class_Bashing.lua` 2620 in
  v4.7.417, 2361 in v4.7.419).
- **Nervestrike's own effect line** (`3rd_person_shikudo/008`, v4.7.415) records paralysis, so a light
  or absorbed nervestrike is recorded too; with a damage line, 563 records it and sets the dedupe flag.
- **The target's CONCENTRATE** ("<T>'s eyes lose their focus suddenly.", trigger 788, v4.7.415) clears
  `disrupted`, its only cure (AFFLICTION SHOW: "Cure(s): Concentrate", no duration). Since v4.7.419
  MIND DISRUPT (`telepathy_tekura/007`) gives it through `ataxia_tarAffTimed("disrupted", 10)`, a
  10 s backstop for a concentrate we miss that a re-disrupt restarts, and 788 clears it through
  `ataxia_tarAffFaded`, which also cancels that clock.
- **Still not recorded:** **dawnkick**'s epilepsy (line not captured); target **stuns** (no duration
  is known); MIND BLACKOUT (line not captured); what KAI CRIPPLE does to the target's limbs (no
  trigger). Light and absorbed ruku to the arm is recorded since v4.7.419 (the strike ledger,
  above), which expires a pending strike at the prompt and never commits it.

## Conflicts and open questions

- **Blackout and the mind lock:** the wiki says blackout needs one; the players' rule (a lock only
  for out-of-room targets and certain skills) says not in the same room. Settle it on the first
  live MIND BLACKOUT without a lock. The likely refusal is "You require a mindlock to perform that
  ability.", the line Mystor got for MIND PRINT and SAPIENCE without a lock (LcJC-rJ5:7-10); no
  trigger gags or reads it. "You do not possess a mindlock." is the other candidate: trigger
  `allies_enemies/012` matches it, no log has it, and since v4.7.419 012 no longer deletes it.
- **Kata limits:** no game number (the wiki: Rain allows twice the normal length, Tykonos never
  stumbles). 006 and 007 cap at 12, and 24 in Rain; our written policy (monk/004, v4.7.419) leaves
  at 12 and Rain 15, but no offense reads it yet. Log 1's Oak 13 and Rain 18 without a stumble rule
  out only a certain stumble at 12, since a stumble is a chance that grows. The stumble recorder
  (monk/003) flags the first probable stumble so its line can be kept.
- **Kai Surge cost:** the wiki says 45 (Kaido); no log has a surge. Since v4.7.419 the cost is
  `ataxia_KAI_COST.surge = 45` (monk/004). TK6 sends its KAI SURGE / KAI CRIPPLE dismount only when
  `ataxia_kaiAfford` says it can pay (unknown kai is not enough), and the `ks` alias warns when kai
  is known short and sends anyway, so a surge at kai 31-44 can now be sent to settle it (CONFLICTS
  #9). 007 still echoes "KAI SURGE READY" at 31 kai read from `vitals.class` (display only; 007:41,
  497-498 at HEAD). The surge's no-remount window (trigger `monk/002`, 15 s) is the code's own guess:
  the wiki says only "The effect will fade over time." (Kaido.wiki:322).
- **Prone extras (hiru's confusion, hiraku's and risingkick's stun):** the wiki has them; neither
  log shows a different line when they apply (hiru and hiraku hit a prone target at 12:29).
- **First-in-combo lines for hiru, hiraku, needle and jinzuku** come from our older triggers, not
  from these logs. Thrust, dart, spinkick, dawnkick-on-prone and Crescent are not in the logs.
- See [CONFLICTS.md](../CONFLICTS.md) for the open items.
