\version "2.26.0"

\include "src/stafftab.ily"

\header {
  title = "Ode to Joy"
  subtitle = "from Symphony no.9"
  composer = "Ludwig Van Beethoven (1770-1827)"
}


melody = \fixed c {
  \clef "treble_8" 
  \time 4/4
  \tempo "Allego maestoso"
  \slurUp
   
  <c-3\6 e-2\fr12>4 ( e-2 f-3 g-1\4 | g-1 f-3\5 e-2 d-1 | c-3\6 c d-1\5 e-2 | e4.-2 d8-1\6 <b,-3\6 d-1\5>2) | \break
  <c-3\6 e-2\fr12>4 ( e-2 f-3 g-1\4 | g-1 f-3\5 e-2 d-1 | c-3\6 c-1 d-2 e-3 | d4.-2 c8-1 c2-1)  | \break 
  d4-2\p d-2 (e-3 c-1 | d-2 e8-3 f-1 e4-3 c-1 | d-2 e8-3 f-1 e4-3 d-2 | c-1 d-2) r e( \f  ~ | \break 
  e-2  e-2 f-3 g-1 | g-1 f-3 e-2 d-1 | c-1 c-1 d-2 e-3 d4.-2 c8-1 c2-2) \bar "|."
}




bass = \fixed c, {
  \clef "bass_8"
  \time 4/4

  <c-1\2 g-2\3>1 | g2-2 2-2 | <c-1\2 e'-4\4 g-2\3>1 | g2-2 2-2 | \break
  <c-1\2 g-2\3>1| g2-2 2-2 | <c-1\2 e'-4\4 g-2\3>1 | g2-2 c-1 | \break
  g1-2 | 2-1 2-2 | 2-1 gis-2 | a4-3 fis-1 g2-2 | \break
  c2-1 bes-4 | a-3 f-2 | e4-1 e-2 g-1 c-2 | g2-1 <c-1\2 e'-4\4 g-2\3>2 \bar "|."
}


%% Declare the tuning ONCE on the ChapmanStickStaff (in \with); each child
%% ChapmanStaff just marks its side and inherits the tuning.  You own each
%% \new ... \with { } and can add any overrides; the group braces the two halves
%% like a piano grand staff.
\score {
  \new ChapmanStickStaff \with { stickTuning = \stickTwelveStringMatchedReciprocal } <<
    \new ChapmanStaff \with { \stickMelody }
    \melody
    \new ChapmanStaff \with { \stickBass }
    \bass
  >>
}
