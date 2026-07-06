# lilypond-chapman-stick

**StaffTab notation for the [Chapman Stick](https://en.wikipedia.org/wiki/Chapman_Stick) in [LilyPond](https://lilypond.org).**

StaffTab writes Stick music on ordinary staves but adds the instrument-specific
information a Stick player needs — **which string**, **which finger**, and **which
fret** — directly onto the notes, deriving whatever you don't spell out.

- **String** → a hollow box drawn on that string's staff line.
- **Finger** → the notehead's *shape* (index = circle, middle = diamond, ring =
  triangle, little = square); fill follows duration as usual.
- **Fret** → a number above the melody staff / below the bass staff, **derived
  automatically** from the note's pitch and its string (or spell it out).
- Each staff line is **labelled** with its open-string pitch.

Requires **LilyPond 2.26** or newer. Public domain (**CC0-1.0**).

---

## Install

The library is a single file, `src/stafftab.ily`. Two ways to use it:

**A. Point LilyPond at the `src` directory** (keeps your score's include line clean):

```sh
lilypond -I /path/to/lilypond-chapman-stick/src your-score.ly
```
```lilypond
\include "stafftab.ily"
```

**B. Reference it by path** (no flags needed):

```lilypond
\include "/path/to/lilypond-chapman-stick/src/stafftab.ily"
```

Then compile the bundled example to see it working:

```sh
lilypond -o demo demo.ly       # demo.ly uses \include "src/stafftab.ily"
```

---

## Quick start

```lilypond
\include "stafftab.ily"

melody = \fixed c' { \clef "treble_8"  c4\5 e\4 g d }
bass   = \fixed c  { \clef "bass_8"   c1\2 }

\score {
  \new ChapmanStickStaff \with { stickTuning = \stickTwelveStringClassic } <<
    \new ChapmanStaff \with { \stickMelody } \melody
    \new ChapmanStaff \with { \stickBass }   \bass
  >>
}
```

---

## Writing notes

Each note is plain LilyPond plus optional post-events — no special note command:

| You write | Meaning |
|---|---|
| `c'` | pitch → staff position, and (with the tuning) the derived fret |
| `c'\3` | on **string 3** (draws the box); fret derived from pitch |
| `c'-2` | **middle finger** → diamond notehead (`-1`..`-4` = index/middle/ring/little) |
| `c'\fr 12` | **fret 12** spelled out; the string (box) is derived from it |
| `c'\fr X` | the **open** ("X") fret; `\fr 0` is the same |
| `c'\5-1\fr 7` | pin all three explicitly |
| `\onString 6 { a b c }` | put a whole run on string 6 |

**Fret and string are complementary** — give either and the other is derived from
the note's pitch (`fret = note − open string`):

- `\3` alone → shows the derived fret on string 3.
- `\fr 12` alone → draws the box on whichever string plays that fret.
- give both → pinned exactly.

Frets read **X**, **1**, **2**, **3**, … — the **X** fret is the open-string
position (the Chapman Stick's equivalent of a guitar's open string), so a note
sounding a string's open pitch shows **X** rather than `0`. Spell it out with
`\fr X` (any case) or `\fr 0`.

Turn derivation off (show only what you type) per staff, group, or mid-piece:

```lilypond
\with { stickAutoFret = ##f }
```

### The octave convention

As is standard for the Chapman Stick, **notate an octave above sounding** and use
the octave-down clefs, `\clef "treble_8"` and `\clef "bass_8"`. The tunings are
given in that same written pitch, so notes and open strings line up directly.

A `note is below open string N` warning means the note is lower than that string's
open pitch — write it higher (`'`) or use a lower-numbered (higher-pitched) string.

---

## Staves

`ChapmanStaff` is a normal staff (it `\alias`es `Staff`) that carries all the
StaffTab behaviour. `ChapmanStickStaff` braces a melody + bass pair into one Stick
grand staff and lets you declare the tuning once:

```lilypond
\new ChapmanStickStaff \with { stickTuning = \stickTwelveStringClassic } <<
  \new ChapmanStaff \with { \stickMelody } \melodyMusic   %% treble half
  \new ChapmanStaff \with { \stickBass }   \bassMusic     %% bass half
>>
```

Because `ChapmanStaff \alias`es `Staff`, it also nests in `StaffGroup` /
`PianoStaff`, takes any `\with` overrides, and works on its own — just put the
tuning on it directly:

```lilypond
\new ChapmanStaff \with { stickTuning = \stickTwelveStringClassic  \stickMelody
                          \override StaffSymbol.thickness = #1.2 } \melodyMusic
```

---

## Tunings

A `stickTuning` value can be:

- a **name string** — `stickTuning = "12StringClassic"`
- a **variable** — `stickTuning = \stickTwelveStringClassic` (compile-time
  checked; digits spelled out, so `12`→`Twelve`, `10`→`Ten`, `4`→`Four` — e.g.
  `10StringClassic` → `\stickTenStringClassic`)
- an **inline pair** of SPN pitch lists (melody then bass, top line → bottom,
  `C4` = middle C) — `stickTuning = #'(("C4" "G3" ...) ("C1" "G1" ...))`
- a **single side's** SPN list

### Built-in tunings

Every packaged tuning is listed below with its open strings in scientific pitch
notation (`C4` = middle C), **top line → bottom line** on each staff. Use any by
name (`stickTuning = "10StringClassic"`) or as its `\stick…` variable.

**10-string** (5 melody + 5 bass):

| Name | Melody (top→bottom) | Bass (top→bottom) |
|---|---|---|
| `10StringMatchedReciprocal` | C4 G3 D3 A2 E2 | C1 G1 D2 A2 E3 |
| `10StringClassic` | D4 A3 E3 B2 F#2 | C1 G1 D2 A2 E3 |
| `10StringBaritoneMelody` | A3 E3 B2 F#2 C#2 | C1 G1 D2 A2 E3 |
| `10StringDeepMatchedReciprocal` | Bb3 F3 C3 G2 D2 | Bb0 F1 C2 G2 D3 |
| `10StringRaisedMatchedReciprocal` | D4 A3 E3 B2 F#2 | D1 A1 E2 B2 F#3 |
| `10StringFullBaritone` | A3 E3 B2 F#2 C#2 | D1 A1 E2 B2 F#3 |
| `10StringDualBassReciprocal` | C4 G3 D3 A2 E2 | B0 F#1 C#2 G#2 D#3 |
| `10StringAlto` | G4 D4 A3 E3 B2 | C2 G2 D3 A3 E4 |
| `10StringGregHowardExtendedAlto` | A4 E4 B3 F#3 C#3 | C2 G2 D3 A3 E4 |
| `10StringBobCulbertsonExpandedAlto` | A4 E4 B3 F#3 C#3 | A2 E3 B3 F#4 C#5 |

**12-string** (6 melody + 6 bass):

| Name | Melody (top→bottom) | Bass (top→bottom) |
|---|---|---|
| `12StringMatchedReciprocal` | C4 G3 D3 A2 E2 B1 | C1 G1 D2 A2 E3 B3 |
| `12StringClassic` | D4 A3 E3 B2 F#2 C#2 | C1 G1 D2 A2 E3 B3 |
| `12StringMatchedReciprocalHighBass4th` | C4 G3 D3 A2 E2 B1 | C1 G1 D2 A2 E3 A3 |
| `12StringClassicHighBass4th` | C4 G3 D3 A2 E2 A1 | C1 G1 D2 A2 E3 A3 |
| `12StringDeepMatchedReciprocal` | Bb3 F3 C3 G2 D2 A1 | Bb0 F1 C2 G2 D3 A3 |
| `12StringDualBassReciprocal` | F4 C4 G3 D3 A2 E2 | B0 F#1 C#2 G#2 D#3 A#3 |
| `12StringMirrored4ths` | C4 G3 D3 A2 E2 B1 | E1 A1 D2 G2 C3 F3 |

### Custom tunings

**Inline, right in `\with`** — give `stickTuning` a pair of SPN lists, `(melody
bass)`, each ordered top line → bottom line (`C4` = middle C). This is the whole
tuning in one place; no registration needed:

```lilypond
\new ChapmanStickStaff \with {
  stickTuning = #'(("D4" "A3" "E3" "B2" "F#2" "C#2")   %% melody, top → bottom
                   ("C1" "G1" "D2" "A2" "E3" "B3"))    %% bass,   top → bottom
} <<
  \new ChapmanStaff \with { \stickMelody } \melody
  \new ChapmanStaff \with { \stickBass }   \bass
>>
```

You can also pass **one side's** list to a lone staff:

```lilypond
\new ChapmanStaff \with {
  stickTuning = #'("D4" "A3" "E3" "B2" "F#2" "C#2")    \stickMelody
} \melody
```

**Register by name for reuse** — declare it once with `\addStickTuning`, then
refer to it by name anywhere (melody list, then bass list):

```lilypond
\addStickTuning "MyStick" #'("D4" "A3" "E3" "B2" "F#2" "C#2")
                          #'("C1" "G1" "D2" "A2" "E3" "B3")
...
\with { stickTuning = "MyStick" }
```

---

## Reusable chords at different durations

A plain music variable can't take a trailing duration (`\foo1` parses as `\foo`
plus a chord-repeat). Wrap the chord in a small music function instead:

```lilypond
bassCEG =
#(define-music-function (dur) (ly:duration?)
   (music-map
    (lambda (m)
      (when (music-is-of-type? m 'rhythmic-event)
        (ly:music-set-property! m 'duration dur))
      m)
    #{ <c-1 e-2 g-4> #}))

%% ... then place it at any length:
\bassCEG 1   \bassCEG 2   \bassCEG 8.
```

---

## A note on how much to annotate

Lean **sparse**: annotate a string/finger where the position *changes* or the
choice is *non-obvious* (a shift, an awkward reach, the start of a phrase, a pitch
playable on more than one string). Because a fret label appears wherever a note
has a string, sparse annotation gives a clean "position map" instead of a number
on every note. Reserve fully-explicit annotation for method books, exercises, or
genuinely ambiguous passages.

---

## Example

`demo.ly` renders *Ode to Joy* for a 12-string matched-reciprocal Stick, showing
strings, finger shapes, derived and explicit frets, and both staves braced.

```sh
lilypond -o demo demo.ly
```

---

## License

Public domain — dedicated under [CC0 1.0](LICENSE.txt). Use it however you like.
