---
topic: shikudo-combat
confidence: mixed (tagged per claim)
sources:
  - kb/raw/logs/2026-10-11_shikudo-vs-runewarden-snb_attacker.txt
  - kb/raw/logs/2026-10-11_runewarden-snb-vs-shikudo_defender.txt
  - kb/raw/wiki/Shikudo.wiki
  - kb/raw/wiki/Telepathy.wiki
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
- **Balance:** 2.1 s for most combos (21 of 27 measured), 1.9 s, 2.8 s with dawnkick, once 4.1 s.
- **Transitions:** `TRANSITION <form>` inline at the end of a combo works (the form's line prints
  right after the combo's kata line), and so does a separate `TRANSITION TO RAIN FORM`. **A kata
  of at least 5 is required:** "A kata of at least 5 must be performed in order to flow from the
  Willows Shaken by the Wind to another." (also seen for Gaital). Seen: Rain to Oak at kata 6 and
  18, Oak to Willow at 6, Willow to Rain at 9, Oak to Gaital at 13. A new form starts the kata
  again at 0. `ADOPT GAITAL FORM` jumps straight there: "You clumsily transition from the form of
  Willows in Rain Storm into the form of Gaital."
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
| Gaital | You let your eyes fall closed and instinct guide you as you flow into the form of Gaital. | (not seen) |

## Telepathy

| Command | Line | Cost |
|---|---|---|
| MIND TRAVEL <T> | You drift on the waves of telepathy, allowing your mental power to carry you to your subject. | 0.85 s eq |
| MIND LOCK <T> while locked | You must dissolve your current lock before attempting another. | |
| MIND IMPATIENCE <T> | You fill the mind of <T> with an impatient feeling. | 1.27 s eq |
| MIND PARALYSE <T> | You reach out with your mind and paralyse <T>. | 1.70 s eq |
| (the target died) | You have lost your telepathic lock upon <T>. | |

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

**Log 1, the Shikudo's (86 s, a win).** Every round sent one server alias: `dismount`, `stand`,
`wield staff`, `mind lock`, `parry <limb>`, the combo, `assess`. The plan, in order:
1. **Rain:** dawnkick and kuro kuro, then flashheel and two kuros on one leg, over and over (the
   leg broke each time and was mended each time).
2. **Rain:** frontkick, kuro, ruku to the arm (prone, weariness or lethargy, clumsiness or healthleech).
3. **Oak** (at kata 18): nervestrike, livestrike, risingkick to the head; nervestrike, ruku torso,
   risingkick, then on to Willow.
4. **Willow:** flashheel, hiru, hiraku while she was prone (she mended her legs and stood up
   right after). MIND IMPATIENCE and MIND PARALYSE between combos, and SHATTER when she raised a
   shield.
5. Back through Rain and Oak (livestrike, kuro, risingkick to the torso) to **Gaital** at kata 13.
6. Rain, then ADOPT Gaital; sweep and flashheel; flashheel and two rukus to the arms; flashheel,
   needle, jinzuku; **Dispatch**.

The Runewarden cured with kelp, goldenseal, ginseng, bloodroot, moss and her elixir, mending on
her legs after every flashheel, the tree tattoo, FOCUS, a shield tattoo, sileris, and a Dagaz
rune on the ground that cured afflictions periodically. See [runewarden-snb.md](runewarden-snb.md).

**Log 2, the Runewarden's (a loss for the monk).** Dominius opened in Rain (kuro, kuro,
frontkick), mixed in nervestrike, livestrike, hiru, hiraku, risingkick and flashheel, and cured
paralysis with magnesium again and again. Claes sliced the torso to 104%, razed his shield and
rebounding, then impaled and disembowelled him.

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
- **Still not recorded:** light or absorbed **nervestrike** (paralysis) and **ruku to the arm**
  (clumsiness, healthleech), which have no target-named effect line; **dawnkick**'s epilepsy
  (line not captured); and target **stuns** (no duration is known). The fix is to hold a strike
  as pending until the next strike or the prompt and drop it on a parry, fumble or dodge line
  (planned with the offense rework, `docs/plans/shikudo-offense-review-2026-10-11.md`).

## Conflicts and open questions

- **SHATTER is not in the wiki's form lists**, yet it was used inside a combo in Willow form.
- **Prone extras (hiru's confusion, hiraku's and risingkick's stun):** the wiki has them; neither
  log shows a different line when they apply (hiru and hiraku hit a prone target at 12:29).
- **First-in-combo lines for hiru, hiraku, needle and jinzuku** come from our older triggers, not
  from these logs. Thrust, dart, spinkick, dawnkick-on-prone and Crescent are not in the logs.
- See [CONFLICTS.md](../CONFLICTS.md) for the open items.
