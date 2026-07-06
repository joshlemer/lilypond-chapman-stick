\version "2.26.0"

\include "lilypond-chapman-stick.ily"


\header {
  title = "Title"
  subtitle = "Subtitle"
  composer = "Composer"
  arranger = "Arranger"

}

\paper { tagline = ##f }   %% drop the "Music engraving by LilyPond" footer


melody = \fixed c {
  \clef "treble_8" 
  \time 4/4
  \key c \major
  
  %\tempo ""
  \slurUp
  
  f-1\5 g-2\5 a-1\4 b-2\4 | c'1-3\4
}

bass = \fixed c, {
  \clef "bass_8"
  \time 4/4
  \key c \major
  
  <g=-1\3 b'-4\5 d'-2\4>1 | <c-1\2 g-2\3 e'-4\4>1
}
tuningA = \makeStickTuning "My Stick" #'("D4" "A3" "E3" "B2" "F#2" "C#2") #'("C1" "G1" "D2" "A2" "E3" "B3")
tuning = \stickTwelveStringMatchedReciprocal

\score {
  \new ChapmanStickStaff \with {
    stickTuning    = \tuningA
    instrumentName = \markup \right-column { "Chapman Stick"
                                             \line { "in " \stickTuningName #tuningA } }
  } <<
    \new ChapmanStickMelodyStaff \melody
    \new ChapmanStickBassStaff \bass
  >>
  \layout { indent = 30\mm }   %% reserve room at the left for the instrument name
}
