#!/usr/bin/env python3
"""
make_music.py - generates all background music and sound effects for Christmas Buddy.

Everything is synthesised with numpy and written as MP3 through soundfile
(libsndfile with its built-in LAME encoder), so there is no audio licence to
track. The melodies are public domain carols, all composed before 1900, played
without lyrics.

Run from the project folder:

    python scripts/make_music.py

Output: assets/audio/*.mp3 (44.1 kHz, mono, constant bit rate).

Layout of this file:
  1. constants
  2. note name parser and small music helpers
  3. the synth (a music box / celesta voice) and a convolution reverb
  4. tune data: melody, chords, tempo and the source of each transcription
  5. arrangement: melody + arpeggiated chords + bass, two or more passes
  6. mastering and MP3 writing
  7. sound effects
  8. main: renders everything and prints a table
"""

import math
import os

import numpy as np
import soundfile as sf

# ---------------------------------------------------------------------------
# 1. constants
# ---------------------------------------------------------------------------

SR = 44100
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(ROOT, "assets", "audio")

PEAK_DB = -1.0            # every file is normalised to this peak
MUSIC_RMS_DB = -15.5      # shared loudness target for the music tracks (RMS of the whole file);
                          # set so every track needs a little soft limiting (about 0 to 2 dB)
MP3_COMPRESSION = 0.65    # libsndfile CBR mapping on this machine: 0.65 -> 128 kbps, 0.7 -> 112 kbps
FADE_IN = 1.0
FADE_OUT = 2.0
TAIL_SILENCE = 0.3
RING_OUT = 2.2            # seconds kept after the last note so decays and reverb can finish
MIN_LEN, MAX_LEN = 60.0, 90.0
REVERB_MIX = 0.22

# ---------------------------------------------------------------------------
# 2. note names and small music helpers
# ---------------------------------------------------------------------------

NOTE_INDEX = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}


def _split_pitch(text):
    """'F#' -> (5, 1), 'Bb' -> (11, -1). Returns (pitch class before accidental, accidental)."""
    letter = text[0].upper()
    if letter not in NOTE_INDEX:
        raise ValueError(f"bad note name {text!r}")
    acc = 0
    rest = text[1:]
    while rest and rest[0] in "#b":
        acc += 1 if rest[0] == "#" else -1
        rest = rest[1:]
    return NOTE_INDEX[letter], acc, rest


def note_to_midi(name):
    """'C4' -> 60 (middle C), 'F#5' -> 78, 'Bb3' -> 58."""
    pc, acc, rest = _split_pitch(name)
    return 12 * (int(rest) + 1) + pc + acc


def midi_to_freq(midi):
    return 440.0 * 2 ** ((midi - 69) / 12)


def parse_seq(text):
    """Parse 'G4:1 F#4:0.5 R:1 | C:4 | ...' into a list of (name or None, beats).

    Tokens are NAME:BEATS where NAME is a note ('G4'), a chord ('D7') or 'R' for a
    rest / no chord. Beats are quarter notes. Bar lines '|' are only for reading."""
    out = []
    for tok in text.split():
        if tok == "|":
            continue
        name, beats = tok.split(":")
        out.append((None if name.upper() == "R" else name, float(beats)))
    return out


def bar_groups(text):
    """The same text split at bar lines, each group as a list of (name, beats)."""
    groups = [g.strip() for g in text.replace("\n", " ").split("|")]
    return [parse_seq(g) for g in groups if g]


def bar_beats(meter):
    num, den = (int(v) for v in meter.split("/"))
    return num * 4.0 / den


CHORD_TONES = {          # arpeggio voicings, three tones each (the 5th is dropped on 7th chords)
    "": (0, 4, 7),
    "m": (0, 3, 7),
    "7": (0, 4, 10),
    "m7": (0, 3, 10),
    "dim": (0, 3, 6),
}


def chord_voicing(symbol, low_midi):
    """'D7' -> (root midi, [three midi notes]) with the root placed in the octave
    that starts at low_midi."""
    pc, acc, quality = _split_pitch(symbol)
    if quality not in CHORD_TONES:
        raise ValueError(f"unknown chord {symbol!r}")
    root = low_midi + (pc + acc - low_midi) % 12
    return root, [root + o for o in CHORD_TONES[quality]]


# ---------------------------------------------------------------------------
# 3. synth and reverb
# ---------------------------------------------------------------------------

# Music box voice: a sine fundamental plus a few partials. The 5.4x partial is
# deliberately inharmonic; it gives the bell-like sheen.
MUSIC_BOX_PARTIALS = ((1.0, 1.0), (2.0, 0.5), (3.0, 0.2), (5.4, 0.08))
BASS_PARTIALS = ((1.0, 1.0), (2.0, 0.4), (3.0, 0.15))


def music_box_note(freq, vel, length, rng, tau=0.36, partials=MUSIC_BOX_PARTIALS,
                   brightness=1.0, detune_cents=4.0):
    """One struck note: instant attack, exponential decay.

    tau is the decay time constant of the fundamental in seconds (the note is
    about -40 dB after 4.6 tau, so tau 0.36 rings for roughly 1.5 s). Higher
    partials die faster, as they do on a real tine. A little random detune and
    the velocity-dependent brightness keep it from sounding mechanical."""
    n = max(1, int(length * SR))
    t = np.arange(n) / SR
    f0 = freq * 2 ** (rng.uniform(-detune_cents, detune_cents) / 1200)
    tau *= min(1.3, max(0.7, (600.0 / f0) ** 0.2))      # high notes ring a little shorter
    out = np.zeros(n)
    for i, (ratio, gain) in enumerate(partials):
        f = f0 * ratio
        if f > 0.45 * SR:
            continue
        tau_i = tau / (1 + 0.5 * (ratio - 1))
        g = gain if i == 0 else gain * brightness * (0.55 + 0.45 * vel)
        out += g * np.exp(-t / tau_i) * np.sin(2 * np.pi * f * t + rng.uniform(0, 2 * np.pi))
    a = min(n, int(0.0015 * SR))                        # 1.5 ms ramp: instant to the ear, no click
    out[:a] *= np.linspace(0.0, 1.0, a)
    r = min(n, int(0.03 * SR))
    out[n - r:] *= np.linspace(1.0, 0.0, r)
    return out * vel


def add_at(buf, sig, start_sec):
    """Mix sig into buf starting at start_sec, clipping to the buffer."""
    i = int(round(start_sec * SR))
    if i < 0:
        sig = sig[-i:]
        i = 0
    n = min(len(sig), len(buf) - i)
    if n > 0:
        buf[i:i + n] += sig[:n]


def band_noise(n, lo, hi, rng):
    """White noise band-limited to lo..hi Hz (0 = open end), peak normalised."""
    spec = np.fft.rfft(rng.standard_normal(n))
    f = np.fft.rfftfreq(n, 1.0 / SR)
    m = np.ones_like(f)
    if lo:
        m *= 0.5 * (1 + np.tanh((f - lo) / (0.3 * lo)))
    if hi:
        m *= 0.5 * (1 - np.tanh((f - hi) / (0.3 * hi)))
    x = np.fft.irfft(spec * m, n)
    return x / (np.max(np.abs(x)) + 1e-12)


def make_reverb_ir(rng, length=1.4, predelay=0.012):
    """A small synthetic room: decaying noise whose treble dies faster than its
    bass (three bands, three decay rates). Convolving with it is a very dense
    multi-tap delay. Returned with unit energy, so the mix in apply_reverb is
    the wet level relative to dry."""
    n = int(length * SR)
    t = np.arange(n) / SR
    ir = (band_noise(n, 0, 1200, rng) * np.exp(-t / 0.50)
          + 0.8 * band_noise(n, 1200, 4500, rng) * np.exp(-t / 0.30)
          + 0.5 * band_noise(n, 4500, 0, rng) * np.exp(-t / 0.15))
    ir *= np.clip((t - predelay) / 0.02, 0.0, 1.0)      # nothing before the predelay, then a quick build-up
    return ir / np.sqrt(np.sum(ir ** 2))


def apply_reverb(x, ir, mix):
    n = len(x) + len(ir) - 1
    nfft = 1 << (n - 1).bit_length()
    wet = np.fft.irfft(np.fft.rfft(x, nfft) * np.fft.rfft(ir, nfft), nfft)[:len(x)]
    return x + mix * wet


# ---------------------------------------------------------------------------
# 4. tune data
# ---------------------------------------------------------------------------
#
# Notation: NAME:BEATS tokens, beats in quarter notes, '|' between bars, 'R' for
# a rest (melody) or no chord (chords). Pitches are written as in the source;
# 'transpose' (semitones) is applied when rendering, so all tunes sound one
# octave above the written pitch, which is where a music box lives.
#
# arp_low is the lowest root allowed for the arpeggiated chords (about an
# octave below the melody), arp_sub the subdivision of the arpeggio in beats,
# arp_pattern indexes the three chord tones (0 = root) across one bar.

TUNES = [
    # Source: Paul Hardy's Xmas Tunebook 2019, "Jingle Bells" (X:10002, K:G, 4/4),
    # via abcnotation.com (tunePage?a=pghardy.net/tunebooks/pgh_xmas_tunebook/0034).
    # Chords also from that transcription. Verse + chorus = one pass.
    dict(
        name="jingle_bells", title="Jingle Bells (Pierpont, 1857)", seed=1,
        source="Paul Hardy's Xmas Tunebook via abcnotation.com, X:10002",
        meter="4/4", bpm=184, transpose=12, pickup=0.0,
        arp_low="G3", arp_sub=1.0, arp_pattern=(0, 1, 2, 1),
        melody="""
D4:1 B4:1 A4:1 G4:1 | D4:3 D4:0.5 D4:0.5 | D4:1 B4:1 A4:1 G4:1 | E4:4 |
E4:1 C5:1 B4:1 A4:1 | F#4:3 R:0.5 F#4:0.5 | D5:1 D5:1 C5:1 A4:1 | B4:3 R:0.5 D4:0.5 |
D4:1 B4:1 A4:1 G4:1 | D4:3 R:0.5 D4:0.5 | D4:1 B4:1 A4:1 G4:1 | E4:3 R:0.5 E4:0.5 |
E4:1 C5:1 B4:1 A4:1 | D5:1 D5:1 D5:1 D5:1 | E5:1 D5:1 C5:1 A4:1 | G4:2 D5:2 |
B4:1 B4:1 B4:2 | B4:1 B4:1 B4:2 | B4:1 D5:1 G4:1.5 A4:0.5 | B4:4 |
C5:1 C5:1 C5:1.5 C5:0.5 | C5:1 B4:1 B4:1 B4:0.5 B4:0.5 | B4:1 A4:1 A4:1 B4:1 | A4:2 D5:2 |
B4:1 B4:1 B4:2 | B4:1 B4:1 B4:2 | B4:1 D5:1 G4:1.5 A4:0.5 | B4:4 |
C5:1 C5:1 C5:1.5 C5:0.5 | C5:1 B4:1 B4:1 B4:0.5 B4:0.5 | D5:1 D5:1 C5:1 A4:1 | G4:2 R:2 |
""",
        chords="""
G:4 | G:4 | G:4 | C:4 | Am:4 | D7:4 | D7:4 | G:4 |
G:4 | G:4 | G:4 | C:4 | Am:4 | G:4 | D7:4 | G:2 D7:2 |
G:4 | G:4 | G:4 | G:4 | C:4 | G:4 | A7:4 | D7:4 |
G:4 | G:4 | G:4 | G:4 | C:4 | G:4 | D7:4 | G:4 |
""",
    ),

    # Source: Colin Hume's ABC collection, "We Wish You a Merry Christmas" (X:1482,
    # K:G, 3/4), via abcnotation.com (tunePage?a=colinhume.com/ABC.txt/1484), melody
    # voice V:1 only. Cross-checked against Paul Hardy's Xmas Tunebook X:23001, which
    # agrees except that Hardy has E C E instead of E E E in bar 2; Hume's reading is
    # the usual one. Chords mostly Hume's, with Hardy's G in bar 13.
    dict(
        name="we_wish_you", title="We Wish You a Merry Christmas", seed=2,
        source="Colin Hume's ABC via abcnotation.com, X:1482; checked against Paul Hardy X:23001",
        meter="3/4", bpm=132, transpose=12, pickup=1.0,
        arp_low="G3", arp_sub=0.5, arp_pattern=(0, 1, 2, 1, 2, 1),
        melody="""
D4:1 |
G4:1 G4:0.5 A4:0.5 G4:0.5 F#4:0.5 | E4:1 E4:1 E4:1 | A4:1 A4:0.5 B4:0.5 A4:0.5 G4:0.5 | F#4:1 D4:1 D4:1 |
B4:1 B4:0.5 C5:0.5 B4:0.5 A4:0.5 | G4:1 E4:1 D4:0.5 D4:0.5 | E4:1 A4:1 F#4:1 | G4:2 D4:1 |
G4:1 G4:1 G4:1 | F#4:2 F#4:1 | G4:1 F#4:1 E4:1 | D4:2 A4:1 |
B4:1 A4:0.5 A4:0.5 G4:0.5 G4:0.5 | D5:1 D4:1 D4:0.5 D4:0.5 | E4:1 A4:1 F#4:1 | G4:2 |
""",
        chords="""
R:1 |
G:3 | C:3 | A7:3 | D:3 | B7:3 | Em:3 | Am:2 D7:1 | G:3 |
G:3 | D:3 | A7:3 | D7:3 | G:3 | D:3 | Am:2 D7:1 | G:2 |
""",
    ),

    # Source: Colin Hume's ABC collection, "Deck the Halls" (X:339, K:F, 2/2, written
    # here as 4/4 with the quarter note as the beat), via abcnotation.com
    # (tunePage?a=colinhume.com/ABC.txt/0338). Chords from the same transcription.
    dict(
        name="deck_the_halls", title="Deck the Halls (Welsh, Nos Galan)", seed=3,
        source="Colin Hume's ABC via abcnotation.com, X:339",
        meter="4/4", bpm=120, transpose=12, pickup=0.0,
        arp_low="F3", arp_sub=0.5, arp_pattern=(0, 1, 2, 1, 0, 1, 2, 1),
        melody="""
C5:1.5 Bb4:0.5 A4:1 G4:1 | F4:1 G4:1 A4:1 F4:1 | G4:0.5 A4:0.5 Bb4:0.5 G4:0.5 A4:1.5 G4:0.5 | F4:1 E4:1 F4:2 |
C5:1.5 Bb4:0.5 A4:1 G4:1 | F4:1 G4:1 A4:1 F4:1 | G4:0.5 A4:0.5 Bb4:0.5 G4:0.5 A4:1.5 G4:0.5 | F4:1 E4:1 F4:2 |
G4:1.5 A4:0.5 Bb4:1 G4:1 | A4:1.5 Bb4:0.5 C5:1 G4:1 | A4:0.5 Bb4:0.5 C5:1 D5:0.5 E5:0.5 F5:1 | E5:1 D5:1 C5:2 |
C5:1.5 Bb4:0.5 A4:1 G4:1 | F4:1 G4:1 A4:1 F4:1 | D5:0.5 D5:0.5 D5:0.5 D5:0.5 C5:1.5 Bb4:0.5 | A4:1 G4:1 F4:2 |
""",
        chords="""
F:4 | Dm:4 | Gm:2 F:2 | C:2 F:2 |
F:4 | Dm:4 | Gm:2 F:2 | C:2 F:2 |
C:4 | F:2 C:2 | F:2 Dm:2 | G7:2 C:2 |
F:4 | Dm:4 | Bb:2 F:2 | C:2 F:2 |
""",
    ),

    # Source: English Wikipedia, "Silent Night", the "Contemporary" LilyPond score
    # (\relative c'' in C major, 6/8; the article transposes it to D for display).
    # Transcribed from the raw wikitext. Chords are the standard I / IV / V7 harmony.
    dict(
        name="silent_night", title="Silent Night (Gruber, 1818)", seed=4,
        source="English Wikipedia 'Silent Night', contemporary score (LilyPond, C major 6/8)",
        meter="6/8", bpm=60, transpose=12, pickup=0.0,
        arp_low="G3", arp_sub=0.5, arp_pattern=(0, 1, 2, 0, 1, 2),
        melody="""
G4:0.75 A4:0.25 G4:0.5 E4:1.5 | G4:0.75 A4:0.25 G4:0.5 E4:1.5 | D5:1 D5:0.5 B4:1.5 | C5:1 C5:0.5 G4:1.5 |
A4:1 A4:0.5 C5:0.75 B4:0.25 A4:0.5 | G4:0.75 A4:0.25 G4:0.5 E4:1.5 |
A4:1 A4:0.5 C5:0.75 B4:0.25 A4:0.5 | G4:0.75 A4:0.25 G4:0.5 E4:1.5 |
D5:1 D5:0.5 F5:0.75 D5:0.25 B4:0.5 | C5:1.5 E5:1 R:0.5 |
C5:0.75 G4:0.25 E4:0.5 G4:0.75 F4:0.25 D4:0.5 | C4:2.5 R:0.5 |
""",
        chords="""
C:3 | C:3 | G7:3 | C:3 | F:3 | C:3 | F:3 | C:3 | G7:3 | C:3 | C:1.5 G7:1.5 | C:3 |
""",
    ),

    # Source: English Wikipedia, "O Tannenbaum", the LilyPond score (sopranoC and
    # sopranoV, \relative c' in G major, 3/4 with an eighth-note pickup), with
    # chordNamesC and chordNamesV from the same score. Form A A B A per pass.
    dict(
        name="o_christmas_tree", title="O Christmas Tree (O Tannenbaum)", seed=5,
        source="English Wikipedia 'O Tannenbaum' score (LilyPond, G major 3/4)",
        meter="3/4", bpm=88, transpose=12, pickup=0.5,
        arp_low="G3", arp_sub=0.5, arp_pattern=(0, 1, 2, 1, 2, 1),
        melody=(
            "D4:0.5 | G4:0.75 G4:0.25 G4:1 A4:1 | B4:0.75 B4:0.25 B4:1.5 B4:0.5 | "
            "A4:0.5 B4:0.5 C5:1 F#4:1 | A4:1 G4:1 R:0.5 |\n"
        ) * 2 + (
            "D5:0.5 | D5:0.5 B4:0.5 E5:1.5 D5:0.5 | D5:0.5 C5:0.5 C5:1.5 C5:0.5 | "
            "C5:0.5 A4:0.5 D5:1.5 C5:0.5 | C5:0.5 B4:0.5 B4:1 R:0.5 |\n"
        ) + (
            "D4:0.5 | G4:0.75 G4:0.25 G4:1 A4:1 | B4:0.75 B4:0.25 B4:1.5 B4:0.5 | "
            "A4:0.5 B4:0.5 C5:1 F#4:1 | A4:1 G4:1 R:0.5 |\n"
        ),
        chords=(
            "R:0.5 | G:2 D:1 | G:3 | Am:2 D7:1 | D7:1 G:1.5 |\n"
        ) * 2 + (
            "R:0.5 | G7:1 C:2 | D7:3 | D7:3 | G:2.5 |\n"
        ) + (
            "R:0.5 | G:2 D:1 | G:3 | Am:2 D7:1 | D7:1 G:1.5 |\n"
        ),
    ),

    # Source: Paul Hardy's Xmas Tunebook 2019, "Good King Wenceslas" (X:7004, K:G, 4/4),
    # via abcnotation.com (tunePage?a=pghardy.net/tunebooks/pgh_xmas_tunebook/0020).
    # Cross-checked against Colin Hume's X:539 (tunePage?a=colinhume.com/ABC.txt/0541):
    # identical notes. Chords are a blend of the two.
    dict(
        name="good_king_wenceslas", title="Good King Wenceslas", seed=6,
        source="Paul Hardy's Xmas Tunebook via abcnotation.com, X:7004; identical in Colin Hume X:539",
        meter="4/4", bpm=116, transpose=12, pickup=0.0,
        arp_low="G3", arp_sub=0.5, arp_pattern=(0, 1, 2, 1, 0, 1, 2, 1),
        melody="""
G4:1 G4:1 G4:1 A4:1 | G4:1 G4:1 D4:2 | E4:1 D4:1 E4:1 F#4:1 | G4:2 G4:2 |
G4:1 G4:1 G4:1 A4:1 | G4:1 G4:1 D4:2 | E4:1 D4:1 E4:1 F#4:1 | G4:2 G4:2 |
D5:1 C5:1 B4:1 A4:1 | B4:1 A4:1 G4:2 | E4:1 D4:1 E4:1 F#4:1 | G4:2 G4:2 |
D4:1 D4:1 E4:1 F#4:1 | G4:1 G4:1 A4:2 | D5:1 C5:1 B4:1 A4:1 | G4:2 C5:2 | G4:4 |
""",
        chords="""
G:4 | G:4 | C:2 D7:2 | G:4 |
Em:2 C:2 | G:2 D:2 | C:2 D7:2 | G:4 |
G:4 | D7:2 Em:2 | C:2 D7:2 | G:4 |
D:4 | G:2 D7:2 | G:4 | Em:2 C:2 | G:4 |
""",
    ),
]


# ---------------------------------------------------------------------------
# 5. arrangement
# ---------------------------------------------------------------------------

def check_bars(tune):
    """Sanity check on the transcription: every bar must add up to the meter.
    A short group is allowed as a pickup, or when the following pickup group
    completes it, or at the very end."""
    bar = bar_beats(tune["meter"])
    for label in ("melody", "chords"):
        groups = [sum(b for _, b in g) for g in bar_groups(tune[label])]
        i = 0
        while i < len(groups):
            s = groups[i]
            if abs(s - bar) < 1e-6:
                i += 1
            elif s < bar and i == 0:
                i += 1                                    # pickup at the start
            elif s < bar and i + 1 < len(groups) and abs(s + groups[i + 1] - bar) < 1e-6:
                i += 2                                    # partial bar closed by a pickup
            elif s < bar and i == len(groups) - 1:
                i += 1                                    # partial last bar
            else:
                raise ValueError(f"{tune['title']}: {label} group {i} has {s} beats, bar is {bar}")
    mel = sum(b for _, b in parse_seq(tune["melody"]))
    cho = sum(b for _, b in parse_seq(tune["chords"]))
    if abs(mel - cho) > 1e-6:
        raise ValueError(f"{tune['title']}: melody has {mel} beats but chords {cho}")


def first_bar_text(tune):
    """The pickup (if any) and the first full bar as note names, for eyeballing."""
    groups = bar_groups(tune["melody"])
    bar = bar_beats(tune["meter"])
    take = 2 if sum(b for _, b in groups[0]) < bar - 1e-6 else 1
    parts = []
    for g in groups[:take]:
        parts.append(" ".join(f"{n or 'rest'}:{b:g}" for n, b in g))
    return " | ".join(parts)


def arrange(tune, rng):
    """Render melody, arpeggio and bass for as many passes as needed to reach
    MIN_LEN (at least two). Returns (mix, seconds of music, passes)."""
    melody = parse_seq(tune["melody"])
    chords = parse_seq(tune["chords"])
    beat = 60.0 / tune["bpm"]
    bar = bar_beats(tune["meter"])
    pickup = tune["pickup"]
    tr = tune["transpose"]
    pass_beats = sum(b for _, b in melody)
    pass_sec = pass_beats * beat
    passes = max(2, math.ceil(MIN_LEN / pass_sec))
    music_sec = passes * pass_sec
    n = int((music_sec + RING_OUT) * SR)
    mel = np.zeros(n)
    acc = np.zeros(n)

    def in_bar(b):                      # position inside the bar, in beats
        pos = (b - pickup) % bar
        return 0.0 if pos > bar - 1e-6 else pos

    # melody: accent on the downbeat, a bit less on other beats, less again off the beat
    for p in range(passes):
        b = p * pass_beats
        for name, beats in melody:
            if name is not None:
                pos = in_bar(b)
                vel = 1.0 if pos < 1e-6 else (0.9 if abs(pos - round(pos)) < 1e-6 else 0.8)
                vel *= rng.uniform(0.92, 1.0)
                jitter = 0.0 if b == 0 else rng.uniform(-0.006, 0.006)
                length = min(2.4, max(1.5, beats * beat + 0.8))
                note = music_box_note(midi_to_freq(note_to_midi(name) + tr), vel, length, rng)
                add_at(mel, note, b * beat + jitter)
            b += beats

    # accompaniment: bass on chord changes (and on each bar line a chord lasts
    # through), arpeggio on every subdivision with the pattern locked to the bar
    low = note_to_midi(tune["arp_low"])
    sub = tune["arp_sub"]
    pattern = tune["arp_pattern"]
    for p in range(passes):
        b = p * pass_beats
        for symbol, beats in chords:
            if symbol is not None:
                root, tones = chord_voicing(symbol, low)
                end = b + beats
                q = b
                while q < end - 1e-6:
                    bass = music_box_note(midi_to_freq(root - 12), 0.5 * rng.uniform(0.9, 1.0), 2.0, rng,
                                          tau=0.8, partials=BASS_PARTIALS, brightness=0.8)
                    add_at(acc, bass, q * beat)
                    q += bar - in_bar(q)
                q = b
                while q < end - 1e-6:
                    k = int(round(in_bar(q) / sub)) % len(pattern)
                    vel = 0.32 * (1.0 if in_bar(q) < 1e-6 else 0.85) * rng.uniform(0.85, 1.0)
                    note = music_box_note(midi_to_freq(tones[pattern[k]]), vel, 1.3, rng,
                                          tau=0.3, brightness=0.7)
                    add_at(acc, note, q * beat + rng.uniform(-0.005, 0.005))
                    q += sub
            b += beats

    return mel + acc, music_sec, passes


# ---------------------------------------------------------------------------
# 6. mastering and writing
# ---------------------------------------------------------------------------

def soft_limit(x, ceiling, knee=0.55):
    """Leaves everything below knee*ceiling untouched and bends the rest with a
    smooth power curve so the loudest sample lands exactly on the ceiling. The
    curve is slope-continuous at the knee and flat at the top, so a few loud
    music box attacks are rounded off without any audible edge."""
    t = knee * ceiling
    a = np.abs(x)
    pre = a.max()
    if pre <= ceiling:
        return x
    r = (pre - t) / (ceiling - t)
    over = a > t
    u = (a[over] - t) / (pre - t)
    y = x.copy()
    y[over] = np.sign(x[over]) * (t + (ceiling - t) * (1 - (1 - u) ** r))
    return y


def master(x, rms_db=None, fade_in=0.0, fade_out=0.0, peak_db=PEAK_DB, tail=TAIL_SILENCE):
    """Fades, optional loudness match (with a soft limiter if that pushes peaks
    over the ceiling), peak normalisation, trailing silence.
    Returns (audio, dB of limiting that was needed)."""
    x = x.copy()
    if fade_in:
        k = int(fade_in * SR)
        x[:k] *= np.linspace(0.0, 1.0, k)
    if fade_out:
        k = int(fade_out * SR)
        x[len(x) - k:] *= 0.5 * (1 + np.cos(np.linspace(0, np.pi, k)))
    ceiling = 10 ** (peak_db / 20)
    limited_db = 0.0
    if rms_db is not None:
        x *= 10 ** (rms_db / 20) / np.sqrt(np.mean(x ** 2))
        pre = np.max(np.abs(x))
        if pre > ceiling:
            limited_db = 20 * math.log10(pre / ceiling)
            x = soft_limit(x, ceiling)
    x *= ceiling / np.max(np.abs(x))
    x = np.concatenate([x, np.zeros(int(tail * SR))])
    return x, limited_db


def db(v):
    return 20 * math.log10(max(v, 1e-12))


def write_mp3(path, x):
    sf.write(path, x.astype(np.float32), SR, format="MP3", subtype="MPEG_LAYER_III",
             compression_level=MP3_COMPRESSION, bitrate_mode="CONSTANT")
    info = sf.info(path)
    return info.duration, os.path.getsize(path)


# ---------------------------------------------------------------------------
# 7. sound effects
# ---------------------------------------------------------------------------

def end_fade(x, seconds):
    k = min(len(x), int(seconds * SR))
    x[len(x) - k:] *= np.linspace(1.0, 0.0, k)
    return x


def small_bell(freq, vel, rng):
    """One tiny sleigh bell: inharmonic partials, very short ring."""
    return music_box_note(freq, vel, 0.3, rng, tau=0.07, detune_cents=0.0,
                          partials=((1.0, 1.0), (1.83, 0.6), (2.71, 0.35), (3.9, 0.15)))


def sfx_jingle(rng, ir):
    """Sleigh bells shaken about nine times a second for 1.2 s: a fixed set of
    little bells re-struck on every shake plus a bright metallic rattle."""
    buf = np.zeros(int(1.2 * SR))
    bells = rng.uniform(2400, 5600, size=7)
    t = 0.0
    while t < 0.95:
        amp = min(1.0, 0.45 + t / 0.25)                               # swells in
        amp *= 1.0 if t < 0.65 else max(0.15, 1.0 - (t - 0.65) / 0.4)  # dies away
        for f in bells:
            if rng.random() < 0.85:
                add_at(buf, small_bell(f, amp * rng.uniform(0.4, 1.0), rng), t + rng.uniform(0, 0.03))
        m = int(0.06 * SR)
        rattle = band_noise(m, 2500, 9000, rng) * np.exp(-np.arange(m) / SR / 0.012)
        add_at(buf, 0.35 * amp * rattle, t)
        t += (1 / 9.0) * rng.uniform(0.9, 1.1)
    return end_fade(apply_reverb(buf, ir, 0.15), 0.15)


def sfx_chime(rng, ir):
    """One warm bell (G5 with a hum tone below the fundamental) and a quick,
    quiet shimmer of three tiny notes above it."""
    buf = np.zeros(int(1.2 * SR))
    warm = ((0.5, 0.3), (1.0, 1.0), (2.0, 0.45), (3.0, 0.18), (5.4, 0.05))
    add_at(buf, music_box_note(midi_to_freq(note_to_midi("G5")), 1.0, 1.2, rng, tau=0.5, partials=warm), 0.0)
    for i, name in enumerate(("G6", "B6", "D7")):
        note = music_box_note(midi_to_freq(note_to_midi(name)), 0.22 - 0.03 * i, 0.5, rng, tau=0.14)
        add_at(buf, note, 0.05 + 0.055 * i)
    return end_fade(apply_reverb(buf, ir, 0.25), 0.15)


def sfx_wave(rng, ir):
    """Two tiny music box notes, E6 then G6, half a second in all."""
    buf = np.zeros(int(0.5 * SR))
    add_at(buf, music_box_note(midi_to_freq(note_to_midi("E6")), 0.9, 0.5, rng, tau=0.16), 0.0)
    add_at(buf, music_box_note(midi_to_freq(note_to_midi("G6")), 1.0, 0.37, rng, tau=0.16), 0.13)
    return end_fade(apply_reverb(buf, ir, 0.12), 0.08)


def sfx_puff(rng):
    """A soft snow puff: low-passed noise with a gentle 30 ms rise and a short decay."""
    n = int(0.3 * SR)
    t = np.arange(n) / SR
    x = band_noise(n, 150, 1400, rng)
    env = np.where(t < 0.03, 0.5 * (1 - np.cos(np.pi * t / 0.03)), np.exp(-(t - 0.03) / 0.07))
    return end_fade(x * env, 0.05)


# ---------------------------------------------------------------------------
# 8. main
# ---------------------------------------------------------------------------

def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    rows = []

    print("First bar of each melody as written in the data (everything sounds one octave higher):")
    for tune in TUNES:
        check_bars(tune)
        print(f"  {tune['title']}")
        print(f"      {first_bar_text(tune)}")
        print(f"      source: {tune['source']}")
    print()

    for tune in TUNES:
        rng = np.random.default_rng(tune["seed"])
        ir = make_reverb_ir(rng)
        mix, music_sec, passes = arrange(tune, rng)
        mix = apply_reverb(mix, ir, REVERB_MIX)
        x, limited = master(mix, rms_db=MUSIC_RMS_DB, fade_in=FADE_IN, fade_out=FADE_OUT)
        path = os.path.join(OUT_DIR, f"music_{tune['name']}.mp3")
        dur, size = write_mp3(path, x)
        note = f"{passes} passes at {tune['bpm']} bpm"
        note += f", limited {limited:.1f} dB" if limited > 0.005 else ", not limited (peak normalised)"
        if not MIN_LEN <= dur <= MAX_LEN:
            note += "  ** outside 60-90 s **"
        rows.append((os.path.basename(path), dur, db(np.max(np.abs(x))), db(np.sqrt(np.mean(x ** 2))), size, note))
        print(f"  wrote {os.path.basename(path)}")

    rng = np.random.default_rng(100)
    ir = make_reverb_ir(rng, length=0.8)
    effects = [
        ("sfx_jingle.mp3", sfx_jingle(rng, ir), PEAK_DB, "sleigh bells shake"),
        ("sfx_chime.mp3", sfx_chime(rng, ir), PEAK_DB, "warm bell with shimmer"),
        ("sfx_wave.mp3", sfx_wave(rng, ir), PEAK_DB, "two-note tinkle"),
        ("sfx_puff.mp3", sfx_puff(rng), -12.0, "snow puff, kept quiet at -12 dBFS"),
    ]
    for fname, audio, peak, note in effects:
        x, _ = master(audio, peak_db=peak, tail=0.0)
        path = os.path.join(OUT_DIR, fname)
        dur, size = write_mp3(path, x)
        rows.append((fname, dur, db(np.max(np.abs(x))), db(np.sqrt(np.mean(x ** 2))), size, note))
        print(f"  wrote {fname}")

    print()
    print(f"{'file':28s} {'seconds':>8s} {'peak dBFS':>10s} {'RMS dBFS':>9s} {'size kB':>8s}  note")
    for fname, dur, peak, rms, size, note in rows:
        print(f"{fname:28s} {dur:8.2f} {peak:10.2f} {rms:9.2f} {size / 1024:8.1f}  {note}")


if __name__ == "__main__":
    main()
