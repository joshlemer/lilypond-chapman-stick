\version "2.26.0"

\include "lilypond-chapman-stick.ily"

\header {
  title = ""
  subtitle = ""
  composer = ""
}


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
    \new ChapmanStaff \with { \stickMelody }
    \melody
    \new ChapmanStaff \with { \stickBass }
    \bass
  >>
}
