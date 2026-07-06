\version "2.26.0"

\include "lilypond-chapman-stick.ily"

\header {
  title = "Title"
  subtitle = "Subtitle"
  composer = "Composer"
  arranger = "Arranger"
}

\paper { 
  tagline = ##f %% drop the "Music engraving by LilyPond" footer
}   


melody = \fixed c {
  \clef "treble_8" 
  \time 4/4
  
  f-1\5 g-2\5 a-1\4 b-2\4 | c'1-3\4
}

bass = \fixed c, {
  \clef "bass_8"
  \time 4/4
  
  <g=-1\3 b'-4\5 d'-2\4>1 | <c-1\2 g-2\3 e'-4\4>1
  \bar "|."
}

\score {
  \new ChapmanStickStaff \with {
    stickTuning    = \stickTwelveStringMatchedReciprocal
    instrumentName = "Chapman Stick"
  } <<
    \new ChapmanStickMelodyStaff \melody
    \new ChapmanStickBassStaff \bass
  >>
}
