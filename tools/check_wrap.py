"""A trigger pattern must be able to fit on ONE physical line.

Achaea wraps server-side at the player's width, so a long game line reaches Mudlet as two or more
rows and a trigger sees each row on its own. This user's width measures 119-124 columns (from the
break points in their own pastes, v4.7.351). A pattern that can never fit on one row can never
match -- and fails silently: no error, no echo, the state it maintains simply never changes.

That happened three times in one week (v4.7.336-347): the belch "room is fouled" refusal, the
soulstorm landing for long mob names, and the gravehands confirmation, which made every Apostate
room cast its summon twice. See CHANGELOG v4.7.351.

WHAT THIS CATCHES: an anchored full-line regex (`^...$`) or a plain substring whose SHORTEST
possible text is wider than the wrap. That class can never match a wrapped line.

WHAT IT CANNOT CATCH: a short fragment that straddles the break (the gravehands case -- 61
characters, but starting at column 88 of a 148-character line). That needs the full line, so it
lives in src_new/tests/test_trigger_wrap.lua, which wraps known lines and runs the real patterns.

ALLOWLIST: pre-existing triggers flagged when this check was written. Several are probably real
(Meteorite, Calcify, the Aeonic distortion proc); they are listed so the check can guard every NEW
pattern today without silently changing old ones in the same release. Remove an entry when it is
fixed -- the check fails on a stale entry, so the list cannot rot.
v4.7.436: until then a pattern folded onto a second YAML line was skipped entirely; reading it
added the 139 files that were hidden that way (the Rampage proc, 033, was the one fixed).
"""
import io
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TRIGGERS = ROOT / 'src_new' / 'triggers'
WIDTH = 118  # one below the measured 119 minimum

ALLOWLIST = {
    'levi_ataxia/for_levi/leviticus/006_GAG.lua',
    'levi_ataxia/for_levi/leviticus/124_ROCKSLIDE.lua',
    'levi_ataxia/for_levi/leviticus/172_Hiru.lua',
    'levi_ataxia/for_levi/leviticus/175_Needle.lua',
    'levi_ataxia/for_levi/leviticus/176_Ruku.lua',
    'levi_ataxia/for_levi/leviticus/185_Dart.lua',
    'levi_ataxia/for_levi/leviticus/193_ISAZ.lua',
    'levi_ataxia/for_levi/leviticus/223_Strip_Shield_Reb.lua',
    'levi_ataxia/for_levi/leviticus/224_Hammer_raze.lua',
    'levi_ataxia/for_levi/leviticus/269_LegSlash_Left.lua',
    'levi_ataxia/for_levi/leviticus/270_LegSlash_Right.lua',
    'levi_ataxia/for_levi/leviticus/286_Deathblow_(Asthma).lua',
    'levi_ataxia/for_levi/leviticus/2h_oppression/001_Warhammer_-_Devestate.lua',
    'levi_ataxia/for_levi/leviticus/319_Back_to_life.lua',
    'levi_ataxia/for_levi/leviticus/330_Battlerage_Small.lua',
    'levi_ataxia/for_levi/leviticus/331_Battlerage_Large.lua',
    'levi_ataxia/for_levi/leviticus/332_Battlerage_Special.lua',
    'levi_ataxia/for_levi/leviticus/335_Mob_Razed.lua',
    'levi_ataxia/for_levi/leviticus/337_Our_Attacks.lua',
    'levi_ataxia/for_levi/leviticus/338_Our_Attacks_2.lua',
    'levi_ataxia/for_levi/leviticus/364_Parry_PVE.lua',
    'levi_ataxia/for_levi/leviticus/400_Rebounding_Strip.lua',
    'levi_ataxia/for_levi/leviticus/406_Shield_Strip.lua',
    'levi_ataxia/for_levi/leviticus/407_Writhed_Impale.lua',
    'levi_ataxia/for_levi/leviticus/429_Proned.lua',
    'levi_ataxia/for_levi/leviticus/496_Explosion_(nobrand).lua',
    'levi_ataxia/for_levi/leviticus/512_Justice_1.lua',
    'levi_ataxia/for_levi/leviticus/522_Deathblow.lua',
    'levi_ataxia/for_levi/leviticus/526_RavagedMind.lua',
    'levi_ataxia/for_levi/leviticus/528_Bloodfire.lua',
    'levi_ataxia/for_levi/leviticus/553_No_Impale.lua',
    'levi_ataxia/for_levi/leviticus/580_Legs_1.lua',
    'levi_ataxia/for_levi/leviticus/635_WRENCH_TORSO.lua',
    'levi_ataxia/for_levi/leviticus/640_Fly_1.lua',
    'levi_ataxia/for_levi/leviticus/652_Deathstrike.lua',
    'levi_ataxia/for_levi/leviticus/656_Judge_II.lua',
    'levi_ataxia/for_levi/leviticus/663_Devour_two.lua',
    'levi_ataxia/for_levi/leviticus/664_Devour_start_on_someone_else.lua',
    'levi_ataxia/for_levi/leviticus/665_Displace_start.lua',
    'levi_ataxia/for_levi/leviticus/666_Displace_finish.lua',
    'levi_ataxia/for_levi/leviticus/670_Deathstrike_continued.lua',
    'levi_ataxia/for_levi/leviticus/674_Execute_two.lua',
    'levi_ataxia/for_levi/leviticus/679_Heartseed.lua',
    'levi_ataxia/for_levi/leviticus/680_Heartseed_2.lua',
    'levi_ataxia/for_levi/leviticus/681_Jack-in-the-Box_start.lua',
    'levi_ataxia/for_levi/leviticus/682_Jack-in-the-Box_two.lua',
    'levi_ataxia/for_levi/leviticus/685_Judgement_three.lua',
    'levi_ataxia/for_levi/leviticus/692_Reave_started.lua',
    'levi_ataxia/for_levi/leviticus/697_Vinewreathe.lua',
    'levi_ataxia/for_levi/leviticus/722_Stunned.lua',
    'levi_ataxia/for_levi/leviticus/724_Undead_Squeeze.lua',
    'levi_ataxia/for_levi/leviticus/761_Inkmilling_done.lua',
    'levi_ataxia/for_levi/leviticus/air_lord/001_Asphyxiation.lua',
    'levi_ataxia/for_levi/leviticus/air_lord/004_Strangle.lua',
    'levi_ataxia/for_levi/leviticus/apostate/006_NO_CATH.lua',
    'levi_ataxia/for_levi/leviticus/arankesh/001_TURN.lua',
    'levi_ataxia/for_levi/leviticus/ataxia/007_Soulrend.lua',
    'levi_ataxia/for_levi/leviticus/bard/005_No_Rapier.lua',
    'levi_ataxia/for_levi/leviticus/bindings_done/007_Maligus_Binding.lua',
    'levi_ataxia/for_levi/leviticus/bindings_done/011_Syvis_Binding.lua',
    'levi_ataxia/for_levi/leviticus/bindings_done/015_Arayan_Binding.lua',
    'levi_ataxia/for_levi/leviticus/brand_lines/001_Brand_Hit.lua',
    'levi_ataxia/for_levi/leviticus/clean-up/002_Line_Deletion.lua',
    'levi_ataxia/for_levi/leviticus/colours/001_Deathblow.lua',
    'levi_ataxia/for_levi/leviticus/creville/002_Lock_up_the_surgeon.lua',
    'levi_ataxia/for_levi/leviticus/creville/005_Start_escort.lua',
    'levi_ataxia/for_levi/leviticus/curing_bals/006_Active_Used.lua',
    'levi_ataxia/for_levi/leviticus/dangerous_things/005_Unnameable.lua',
    'levi_ataxia/for_levi/leviticus/dangerous_things/007_Sylvan_Burst.lua',
    'levi_ataxia/for_levi/leviticus/dangerous_things/009_Displace_3rd_Person.lua',
    'levi_ataxia/for_levi/leviticus/deathcape/001_Death_Cape_Growing.lua',
    'levi_ataxia/for_levi/leviticus/deliverance/004_Deliverance_kill.lua',
    'levi_ataxia/for_levi/leviticus/denizen_attacks_misc_lines/002_Denizen_Clean-up.lua',
    'levi_ataxia/for_levi/leviticus/denizen_attacks_misc_lines/005_Mobs_Misc_(wont_track).lua',
    'levi_ataxia/for_levi/leviticus/denizen_attacks_misc_lines/006_Mobs_Misc_(wont_track)_2.lua',
    'levi_ataxia/for_levi/leviticus/denizen_attacks_misc_lines/010_Denizen_Clean-up_2.lua',
    'levi_ataxia/for_levi/leviticus/determine_class/001_Airlord_Class_Grab.lua',
    'levi_ataxia/for_levi/leviticus/devastate/002_Legs.lua',
    'levi_ataxia/for_levi/leviticus/domination_stuff/007_Bubonis.lua',
    'levi_ataxia/for_levi/leviticus/dragon/001_Dragon_Roar.lua',
    'levi_ataxia/for_levi/leviticus/dragon/004_NO_ELEMENTAL.lua',
    'levi_ataxia/for_levi/leviticus/dragon/006_INCANTATION.lua',
    'levi_ataxia/for_levi/leviticus/dragon/008_FORMED.lua',
    'levi_ataxia/for_levi/leviticus/fishing/001_FishCast.lua',
    'levi_ataxia/for_levi/leviticus/fishing/010_NoLine.lua',
    'levi_ataxia/for_levi/leviticus/forms/001_Tykonos.lua',
    'levi_ataxia/for_levi/leviticus/general/005_Firestorm_up.lua',
    'levi_ataxia/for_levi/leviticus/general/024_Meteorite.lua',
    'levi_ataxia/for_levi/leviticus/general/026_Calcify.lua',
    'levi_ataxia/for_levi/leviticus/heartbeat_1st_person/003_Paralysis.lua',
    'levi_ataxia/for_levi/leviticus/heartbeat_1st_person/005_Epilepsy.lua',
    'levi_ataxia/for_levi/leviticus/heartbeat_1st_person/006_Addiction.lua',
    'levi_ataxia/for_levi/leviticus/heartbeat_1st_person/007_Impatience.lua',
    'levi_ataxia/for_levi/leviticus/highlighting/005_Mizik_Destroying_Mushrooms.lua',
    'levi_ataxia/for_levi/leviticus/highlighting/048_Aeonic_Distortion_Proc.lua',
    'levi_ataxia/for_levi/leviticus/homunculus/001_Focus_Knock.lua',
    'levi_ataxia/for_levi/leviticus/kicks/006_WRENCH_HEAD.lua',
    'levi_ataxia/for_levi/leviticus/kicks/006_kick_hit.lua',
    'levi_ataxia/for_levi/leviticus/leviatax/001_NO_MORE_RADIANCE.lua',
    'levi_ataxia/for_levi/leviticus/logographs/003_Epilepsy_Sun.lua',
    'levi_ataxia/for_levi/leviticus/logographs/007_Addiction_Scarab.lua',
    'levi_ataxia/for_levi/leviticus/logographs/009_Scytherus_Scorpion.lua',
    'levi_ataxia/for_levi/leviticus/mining/004_Prospect_General.lua',
    'levi_ataxia/for_levi/leviticus/misc/003_Ensorcelled.lua',
    'levi_ataxia/for_levi/leviticus/misc/009_Raze.lua',
    'levi_ataxia/for_levi/leviticus/misc/010_Traced_Logograph.lua',
    'levi_ataxia/for_levi/leviticus/misc_stuff/001_Aeon_Hit.lua',
    'levi_ataxia/for_levi/leviticus/passive_active/010_Phoenix_(BM).lua',
    'levi_ataxia/for_levi/leviticus/priest/007_Inquisition.lua',
    'levi_ataxia/for_levi/leviticus/replace_lines/007_Head.lua',
    'levi_ataxia/for_levi/leviticus/shaman/010_Failed_Tzantza.lua',
    'levi_ataxia/for_levi/leviticus/snb_attack_report/001_Torment_SnB.lua',
    'levi_ataxia/for_levi/leviticus/staffcast/005_Immolation_Staff.lua',
    'levi_ataxia/for_levi/leviticus/stances/001_DRAGON.lua',
    'levi_ataxia/for_levi/leviticus/stances/001_Rain_Form.lua',
    'levi_ataxia/for_levi/leviticus/stances/005_Maelstrom_Form.lua',
    'levi_ataxia/for_levi/leviticus/sylvan/003_Thunderclap.lua',
    'levi_ataxia/for_levi/leviticus/sylvan/005_Bolt.lua',
    'levi_ataxia/for_levi/leviticus/sylvan/013_Thunderclap_(nodeaf).lua',
    'levi_ataxia/for_levi/leviticus/tarot/002_RuinateLovers.lua',
    'levi_ataxia/for_levi/leviticus/tattoo_stuff/006_Tattoo_Inked.lua',
    'levi_ataxia/for_levi/leviticus/telepathy/001_NO_MORE_RADIANCE.lua',
    'levi_ataxia/for_levi/leviticus/unknown_checks/004_Pinchaura.lua',
    'levi_ataxia/for_levi/leviticus/unknown_checks/005_FIRE_SCALD.lua',
    'levi_ataxia/for_levi/leviticus/unnamable/001_Horror.lua',
    'levi_ataxia/for_levi/leviticus/unnamable/002_Addiction.lua',
    'levi_ataxia/for_levi/leviticus/unnamable/003_Nausea.lua',
    'levi_ataxia/for_levi/leviticus/unnamable/004_Manaleech.lua',
    'levi_ataxia/for_levi/leviticus/voicecraft/009_Epic_(Paralysis).lua',
    'levi_ataxia/for_levi/leviticus/water_lord/012_++_LATCH_KILL_++.lua',
    'mudlet-mapper/mudlet_mapper/012_Wormhole.lua',
    'mudlet-mapper/mudlet_mapper/achaea/042_Alchemist_ether_seek.lua',
    'mudlet-mapper/mudlet_mapper/doors/007_Bolted.lua',
    'mudlet-mapper/mudlet_mapper/lusternia/002_mmp_Lusternia_Scent.lua',
    'mudlet-mapper/mudlet_mapper/lusternia/013_Masquerade_ball_snowglobe.lua',
    'mudlet-mapper/mudlet_mapper/lusternia/019_Pyramid_probe_#.lua',
    'mudlet-mapper/mudlet_mapper/lusternia/020_Pentagon_probe_#.lua',
    'mudlet-mapper/mudlet_mapper/lusternia/021_Pyramid_port.lua',
    'mudlet-mapper/mudlet_mapper/lusternia/022_Pyramid_probe.lua',
    'mudlet-mapper/mudlet_mapper/lusternia/024_Astrology_scry.lua',
    'mudlet-mapper/mudlet_mapper/lusternia/030_Chemwood_walk_delay.lua',
    'mudlet-mapper/mudlet_mapper/lusternia/034_Forced_Movement.lua',
    'mudlet-mapper/mudlet_mapper/lusternia/delayed_bix_movement/001_Teleport_Delays.lua',
    'mudlet-mapper/mudlet_mapper/lusternia/rifts_and_paths/001_Successful_transverse.lua',
    'mudlet-mapper/mudlet_mapper/lusternia/rifts_and_paths/003_Successful_pathfind.lua',
}


def min_len(p):
    """Shortest text a (simple) regex can match, as a character count. Deliberately generous --
    every uncertain construct counts as zero or one -- so a flag is never a false alarm."""
    s = p
    s = re.sub(r'\\[dDwWsS][+]\??', 'x', s)
    s = re.sub(r'\\[dDwWsS][*?]\??', '', s)
    s = re.sub(r'\\[dDwWsS]', 'x', s)
    s = re.sub(r'\((?:\?:)?[^()]*\)[?*]', '', s)
    s = re.sub(r'\([^()]*\|[^()]*\)', 'x', s)        # alternation: count as one char
    s = re.sub(r'\[[^\]]*\][+*]?', 'x', s)
    s = re.sub(r'\.\{\d+,\d+\}', '', s)
    s = re.sub(r'\.[+]\??', 'x', s)
    s = re.sub(r'\.[*]\??', '', s)
    s = re.sub(r'\\(.)', lambda m: m.group(1), s)
    s = re.sub(r'[()|?^$]', '', s)
    return len(s)


def patterns(text):
    header = text.split(']]--')[0]
    # A plain (unquoted) scalar can continue on indented lines; YAML folds them with one space.
    # Missing that skipped the whole pattern: the Rampage proc (highlighting/033) was 128
    # characters and never measured (v4.7.436).
    for m in re.finditer(r"- pattern: ('(?:[^']|'')*'|[^\n]*(?:\n[ \t]+(?!type:)[^\n]*)*)\n\s+type: (\d)",
                         header):
        raw, typ = m.group(1), m.group(2)
        if raw.startswith("'"):
            raw = re.sub(r'\s*\n\s*', ' ', raw[1:-1]).replace("''", "'")
        else:
            raw = re.sub(r'\s*\n\s*', ' ', raw)
        yield raw, typ


def offenders(path):
    text = io.open(path, encoding='utf-8', errors='replace').read()
    out = []
    for raw, typ in patterns(text):
        if typ == '1':
            if raw.startswith('^') and raw.endswith('$') and min_len(raw) > WIDTH:
                out.append((min_len(raw), raw))
        elif typ in ('0', '2', '3') and len(raw) > WIDTH:  # substring, startOfLine, exactMatch
            out.append((len(raw), raw))
    return out


def main():
    new, seen = [], set()
    for path in sorted(TRIGGERS.rglob('*.lua')):
        rel = path.relative_to(TRIGGERS).as_posix()
        found = offenders(path)
        if not found:
            continue
        seen.add(rel)
        if rel not in ALLOWLIST:
            new.extend((rel, n, p) for n, p in found)
    stale = sorted(ALLOWLIST - seen)
    if new:
        print('check_wrap: FAIL -- %d pattern(s) can never fit on one %d-column line:' % (len(new), WIDTH))
        for rel, n, p in new:
            print('  %s  (%d chars)  %s' % (rel, n, p[:90]))
        print('Match an EARLY fragment of the line instead -- see src_new/tests/test_trigger_wrap.lua.')
    if stale:
        print('check_wrap: FAIL -- allowlisted but no longer too wide (remove from ALLOWLIST):')
        for rel in stale:
            print('  ' + rel)
    if new or stale:
        return 1
    print('check_wrap: OK -- no trigger pattern is wider than %d columns (%d pre-existing allowlisted).'
          % (WIDTH, len(ALLOWLIST)))
    return 0


if __name__ == '__main__':
    sys.exit(main())
