# Lilypond-chapman-stick

**StaffTab notation library for the [Chapman Stick](https://en.wikipedia.org/wiki/Chapman_Stick) in [LilyPond](https://lilypond.org).**

Requires **LilyPond 2.26** or newer. Public domain (**CC0-1.0**).

![A basic scale and chord in StaffTab notation](screenshots/basic-scale-and-chord.png)

[StaffTab](https://en.wikipedia.org/wiki/Chapman_Stick#Notation) is a notation system developed by Emmett Chapman and Greg Howard for the Chapman Stick. As on piano, music is written on the grand staff and the left hand plays the bottom staff (called the bass staff), while the right hand plays the top staff (called the melody staff). The music is written one octave lower than it sounds. Lilypond-chapman-stick makes this explicit by using [Octave Clefs](https://en.wikipedia.org/wiki/Clef#Octave_clefs). The system incorporates **string**, **fret**, and **finger** information into standard music notation.:

- **String**: a hollow box drawn on the staff line that corresponds to the string on the instrument, as indicated by the labeled lines on the left of the staff. 
- **Finger**: the notehead's *shape* (index = circle, middle = diamond, ring =
  triangle, pinky = square); fill follows duration as usual. 
- **Fret**: a number above the melody staff / below the bass staff

---

## Installation

Download the latest release and unzip it in your desired location.

Add the unzipped folder to Lilypond's path. This can be done in [Frescrobaldi](https://frescobaldi.org/) as follows.

1. Inside Frescobaldi, open the Preferences window by selecting from the top menu: **File -> Preferences**

![](docs/images/installation/02.png)

2. Navigate to the **LilyPond** preferences on the left hand side

![](docs/images/installation/03.png)

3. On the bottom right, in the **LilyPond Include Path** section, click **+ Add...**, and add the unzipped folder to the path
![](docs/images/installation/04.png)

Then, you can create a new file 

## Quick start

See [](./examples/basic-scale-and-chord.ly)
```lilypond
\version "2.26.0"

\include "lilypond-chapman-stick.ily"

melody = \fixed c {
  \clef "treble_8" 
  \time 4/4
  \key c \major
  
  \tempo ""
  \slurUp
  
  f-1\5 g-2\5 a-1\4 b-2\4 | c'1-3\4
}

bass = \fixed c, {
  \clef "bass_8"
  \time 4/4
  \key c \major
  
  <g=-1\3 b'-4\5 d'-2\4>1 | <c-1\2 g-2\3 e'-4\4>1
}

\score {
  \new ChapmanStickStaff \with { stickTuning = \stickTwelveStringMatchedReciprocal } <<
    \new ChapmanStickMelodyStaff \melody
    \new ChapmanStickBassStaff \bass
  >>
}

```

---

## Writing notes

Pitches, finger, and string use standard Lilypond notation. Lilypod usually derives fret from the string and the pitch, but this library also adds an additional operator to explicitly annotate the fret. Examples of all 3 found below:

|Expression|Meaning|Image|
|---|---|---|
| `c` | C note (specifically C3), with no extra information | ![](docs/images/expressions/plain.png)
| `c\1 c\2 c\3 c\4 c\5 c\6` | on **string 1,2,3,4**, draws string indicator box on line 3 from the top. | ![](docs/images/expressions/string_indicators.png)
| `c-1 c-2 c-3 c-4` | **finger 1 (index), 2 (middle), 3 (ring), 4 (pinky)**  sets notehead to circle, diamond, triangle, square | ![](docs/images/expressions/finger_indicators.png)
| `c\fr12 c\fr5` | **fret 12, fret 5**. Fret numbers placed above/below the staff. Note that space is allowed between `\fr` and the fret number | ![](docs/images/expressions/fret_indicators.png)
| `c\fr X` or `c\fr0` | the "X" fret fret; `\fr 0 and \fr0` is the same. "X" requires a space between `\fr` and `"X"` | ![](docs/images/expressions/fret_x_indicator.png)
| `c\5-1\fr7` | pin all three explicitly | ![](docs/images/expressions/all_indicators.png)
| `<c-1\2\fr1 e'-4\4\fr2 g-2\3\fr3>` | apply all 3 to each note inside a chord | ![](docs/images/expressions/all_indicators_chord.png)
| `\onString 6 { a4 b c d e f g a }` | put a whole run on string 6 | ![](docs/images/expressions/group_string_indicator.png)

### Fret and string are complementary 
give either and the other is derived from the note's pitch 

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
