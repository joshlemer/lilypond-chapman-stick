\version "2.26.0"

%% ============================================================================
%% lilypond-chapman-stick -- StaffTab notation for the Chapman Stick in LilyPond
%% Version 1.0.0  .  Requires LilyPond 2.26+  .  Public domain (CC0-1.0)
%%
%% \include this file, then use \new ChapmanStickStaff / \new ChapmanStaff.
%% ============================================================================
%%
%% Write music the normal way; three things per note shape it into StaffTab, and
%% each is a plain LilyPond post-event -- no special command:
%%
%%   PITCH        the note itself -> staff position, and (with the staff's
%%                tuning) the FRET, printed above the melody staff / below the
%%                bass staff.  Chord frets are joined by "." (e.g. "5.5.7").
%%   \1 .. \6     STRING -> a hollow box drawn ON that string's staff line.
%%   -1 .. -4     FINGER -> notehead SHAPE: 1 index = circle, 2 middle = diamond,
%%                3 ring = triangle, 4 little = square.  FILL follows DURATION
%%                (short = filled, half/whole = open) -- StaffTab's fill rule.
%%
%% FRET and STRING are complementary: give either one and the other is derived
%% from the note's pitch (fret = note - open string).  So \3 alone shows the
%% derived fret on string 3, and \fr 12 alone draws the box on whichever string
%% plays that fret.  Give both to pin them exactly.  Turn this off with
%% \with { stickAutoFret = ##f } (then only what you type explicitly is shown).
%% As is standard for the Chapman Stick, notate an octave above sounding and use
%% the octave-down clefs (\clef "treble_8" / "bass_8"); the tunings below are in
%% that same written pitch, so notes and open strings line up directly.
%% Get a "note below open string" warning?  The note is lower than that string's
%% open pitch -- write it higher (') or use a lower-numbered string.

%%   Single note:  g'8\1-2        string 1, middle finger (fret from pitch)
%%   Explicit fret: c'8\fr 12     fret 12; string (box) derived from it
%%   In a chord:   <c\5-1 e'\4-3> each note carries its own string/finger
%%   Whole passage: \onString 6 { a b c }   put a run of notes on one string
%%
%% Every staff line is labelled with its open-string pitch.  On a Chapman staff
%% \1..\6 and -1..-4 REPLACE LilyPond's usual string-number / fingering marks
%% (the plain circled number / digit is suppressed).
%%
%% STAVES -- make Stick staves like any other; declare the tuning ONCE on the
%% group and each staff just marks its side:
%%   \new ChapmanStickStaff \with { stickTuning = \stickTwelveStringClassic } <<
%%     \new ChapmanStaff \with { \stickMelody } \melodyMusic
%%     \new ChapmanStaff \with { \stickBass }   \bassMusic
%%   >>
%% ChapmanStickStaff braces the two halves (a Stick grand staff).  ChapmanStaff
%% \alias Staff, so it also nests in StaffGroup / your own layout, takes any
%% \with overrides, and works alone (put stickTuning on it directly).
%% A tuning is a name string ("12StringClassic"), a variable
%% (\stickTwelveStringClassic), an inline '(("D4"..)("C1"..)) SPN pair, or a
%% single side's SPN list (top line -> bottom, C4 = middle C).
%% ============================================================================


%% ---- string number -> staff line ----------------------------------------
%% Staff lines are at staff-positions 4, 2, 0, -2, -4 (top -> bottom).  With
%% the usual 5 strings/staff, string 1 = top line ... string 5 = bottom line.
%% A 12-string Stick has 6 strings/staff, so one string falls OFF the 5 lines:
%%   * melody grows UPWARD  -- string 1 sits at +6 (first ledger position above)
%%   * bass   grows DOWNWARD -- the last string sits at -6 (low-E ledger below)
%% We never draw a ledger line there; the box/label just floats at that height.
%% stk-count (strings on this staff) and stk-up (melody? -> overflow upward) are
%% set per-staff and read here; for 5 strings the two directions coincide.
#(define (stk-string-pos n count up?)
   (if up?
       (- (* 2 (- count n)) 4)          ; melody: bottom string anchored at -4
       (- 4 (* 2 (- n 1)))))

%% ---- custom NoteHead properties -----------------------------------------
%% Registering them lets \tweak / \override set arbitrary per-notehead data
%% that our stencil callback and fret engraver read back.
#(set-object-property! 'stk-string 'backend-type? integer?)
#(set-object-property! 'stk-string 'backend-doc "StaffTab: string number for the box marker")
#(set-object-property! 'stk-fret 'backend-type? integer?)
#(set-object-property! 'stk-fret 'backend-doc "StaffTab: fret number for the above/below-staff label")
#(set-object-property! 'stk-count 'backend-type? integer?)
#(set-object-property! 'stk-count 'backend-doc "StaffTab: number of strings on this staff (5 or 6)")
#(set-object-property! 'stk-up 'backend-type? boolean?)
#(set-object-property! 'stk-up 'backend-doc "StaffTab: overflow extra strings upward (melody) vs downward (bass)")
#(set-object-property! 'stk-open 'backend-type? list?)
#(set-object-property! 'stk-open 'backend-doc "StaffTab: open-string semitones (from middle C), top string first")

%% ---- custom CONTEXT properties -------------------------------------------
%% Register these so \with { stickTuning = ... } / { stickSide = ... } are
%% accepted (an unregistered context property is rejected with a warning).
%% `stickTuning` is inherited from a ChapmanStickStaff down to its ChapmanStaff
%% children; `stickSide` is set per staff.  We add them to LilyPond's internal
%% property lists directly (the public helper isn't exposed in every build).
#(let ((lily-mod (resolve-module '(lily))))
   (for-each
    (lambda (spec)
      (let ((sym (car spec)))
        (set-object-property! sym 'translation-type? (cadr spec))
        (set-object-property! sym 'translation-doc (caddr spec))
        (for-each
         (lambda (lname)
           (let ((v (module-variable lily-mod lname)))
             (if v (variable-set! v (cons sym (variable-ref v))))))
         '(all-translation-properties all-user-translation-properties))))
    (list (list 'stickTuning scheme?
                "StaffTab: this staff/group's tuning (name, SPN pitch pair, or side list)")
          (list 'stickSide symbol?
                "StaffTab: which half this staff is -- 'up (melody) or 'down (bass)")
          (list 'stickAutoFret boolean?
                "StaffTab: auto-derive the missing one of fret/string from the other + pitch (default #t)"))))

%% ---- open-string pitch helpers -------------------------------------------
%% A tuning names each open string in scientific pitch notation ("F#3", "Bb0",
%% "C4"; C4 = middle C).  From that one spelling we get BOTH the staff-line
%% label (letter+accidental, octave dropped) and the absolute semitone used to
%% derive frets:  fret = semitones(played note) - semitones(open string).
#(define (stk-spn-split spn)                 ; -> (values name-without-octave octave)
   (let loop ((k (string-length spn)))
     (if (and (> k 0) (char-numeric? (string-ref spn (- k 1))))
         (loop (- k 1))
         (values (substring spn 0 k)
                 (or (string->number (substring spn k (string-length spn))) 4)))))
#(define (stk-spn->label spn)
   (call-with-values (lambda () (stk-spn-split spn)) (lambda (name oct) name)))
#(define (stk-spn->semitone spn)             ; semitones from middle C (C4 = 0)
   (call-with-values (lambda () (stk-spn-split spn))
     (lambda (name oct)
       (let ((pc  (case (char-upcase (string-ref name 0))
                    ((#\C) 0) ((#\D) 2) ((#\E) 4) ((#\F) 5)
                    ((#\G) 7) ((#\A) 9) ((#\B) 11) (else 0)))
             (acc (let loop ((k 1) (a 0))
                    (if (< k (string-length name))
                        (loop (+ k 1) (case (string-ref name k)
                                        ((#\#) (+ a 1)) ((#\b) (- a 1)) (else a)))
                        a))))
         (+ pc acc (* 12 (- oct 4)))))))

%% Centre (X) of a standard notehead glyph.  Our custom circle/diamond heads
%% are drawn centred on the origin and then shifted to THIS point, so they line
%% up with the built-in triangle/square heads and sit centred over the note --
%% not shifted left (which happened when we only aligned the left edge).
#(define (stk-head-center grob)
   (let ((ext (ly:stencil-extent
                (ly:font-get-glyph (ly:grob-default-font grob) "noteheads.s2") X)))
     (/ (+ (car ext) (cdr ext)) 2.0)))

%% A true CIRCLE notehead (LilyPond's default head is an oval).  Filled for
%% short notes, an open ring for half/whole notes -- keeping fill = duration.
#(define (stk-circle-head grob)
   (let* ((filled (>= (ly:grob-property grob 'duration-log 2) 2))
          (circ   (grob-interpret-markup grob
                    (if filled
                        #{ \markup \draw-circle #0.55 #0.0  ##t #}
                        #{ \markup \draw-circle #0.5  #0.13 ##f #}))))
     (ly:stencil-translate-axis circ (stk-head-center grob) X)))

%% A DIAMOND notehead (middle finger): a square stood on its corner -- equal
%% diagonals give 90-degree corners (not the vertically squished miThin glyph),
%% sized so its top/bottom points just clear the staff lines.  Filled for short
%% notes, an outline for half/whole; centred on the standard head like the circle.
#(define (stk-diamond-head grob)
   (let* ((filled (>= (ly:grob-property grob 'duration-log 2) 2))
          (r      0.56)                     ; half-diagonal; >0.5 clears the lines
          (dia    (grob-interpret-markup grob
                    (if filled
                        #{ \markup \polygon #(list (cons 0 r) (cons r 0)
                                                   (cons 0 (- r)) (cons (- r) 0)) #}
                        #{ \markup \path #0.13 #(list (list 'moveto 0 r) (list 'lineto r 0)
                                                      (list 'lineto 0 (- r)) (list 'lineto (- r) 0)
                                                      (list 'closepath)) #}))))
     (ly:stencil-translate-axis dia (stk-head-center grob) X)))

%% Where the stem meets our circle/diamond: right edge for an up-stem, left edge
%% for a down-stem, so the stem is tangent to the circle / meets the side point
%% of the diamond.  (+/-1.0 = the extreme edge.)
#(define (stk-circle-stem-attachment grob)
   (let* ((stem (ly:grob-object grob 'stem))
          (dir  (if (ly:grob? stem) (ly:grob-property stem 'direction) UP)))
     (if (< dir 0) (cons -1.0 0.0) (cons 1.0 0.0))))

%% A hollow (outlined, transparent inside) string-marker box that sits ON TOP
%% of string line <n>.  Drawn from four thin filled edges so the inside stays
%% empty; given empty extent so it never disturbs spacing/stems.
#(define (stk-string-box-stencil grob n)
   (let* ((count (ly:grob-property grob 'stk-count 5))
          (up    (ly:grob-property grob 'stk-up #t))
          (line  (stk-string-pos n count up))
          (pos  (ly:grob-property grob 'staff-position 0))
          (dy   (/ (- line pos) 2.0))      ; staff-pos units -> spaces (line)
          (w    1.2)                        ; half width of the box
          (h    0.25)                        ; box height (~20% of a staff space)
          (t    0.08)                       ; outline thickness
          (y0   (- dy 0.02))                ; bottom edge ~on the line
          (y1   (+ y0 h))                   ; top edge (box sits above line)
          (edge (lambda (x1 x2 ya yb)
                  (ly:round-filled-box (cons x1 x2) (cons ya yb) 0.0)))
          (box  (ly:stencil-add
                  (edge (- w) w y0 (+ y0 t))          ; bottom
                  (edge (- w) w (- y1 t) y1)          ; top
                  (edge (- w) (+ (- w) t) y0 y1)      ; left
                  (edge (- w t) w y0 y1))))           ; right
     (ly:make-stencil (ly:stencil-expr box) empty-interval empty-interval)))

%% Horizontal fan-out for a chord's string boxes: shift each box left (lowest
%% fret) -> right (highest), spaced evenly across the DISTINCT frets present in
%% the note column.  Equal frets (and single notes) -> 0, i.e. box centred on
%% the notehead.  Range is +/- (stk-string-spread * half-width) staff-spaces.
%% stk-string-spread = max box offset as a fraction of its half-width.
#(define stk-string-spread 0.5)
#(define (stk-box-xoffset grob)
   (let ((f (ly:grob-property grob 'stk-fret #f)))
     (if (not f) 0.0
         (let* ((nc    (ly:grob-parent grob X))
                (heads (if (ly:grob? nc)
                           (ly:grob-array->list (ly:grob-object nc 'note-heads))
                           (list grob)))
                (frets (sort (delete-duplicates
                               (filter-map (lambda (h) (ly:grob-property h 'stk-fret #f)) heads)) <))
                (nd    (length frets))
                (idx   (list-index (lambda (x) (= x f)) frets)))
           (if (or (<= nd 1) (not idx)) 0.0
               (* stk-string-spread 0.8 (- (* 2.0 (/ idx (- nd 1))) 1.0)))))))

%% Global notehead stencil: pick the head shape from 'style ('circle -> our
%% circle, otherwise the built-in glyph, which handles fill-by-duration itself)
%% and, when this note carries a string number, add the box on top -- centred on
%% the notehead and fanned out by fret within a chord (see stk-box-xoffset).
%% Plain notes (no string/finger) have style unset and no stk-string, so render
%% normally.
%% The string number (\1..\6 -> stk-string) and finger (-1..-4 -> style) that a
%% note may carry are folded into these grob properties EARLY by
%% Stk_input_engraver, so here we just read the properties back.
#(define (stk-note-stencil grob)
   (let* ((style (ly:grob-property grob 'style 'default))
          (n     (ly:grob-property grob 'stk-string #f))
          (raw   (cond ((eq? style 'circle)      (stk-circle-head grob))
                       ((eq? style 'stk-diamond) (stk-diamond-head grob))
                       (else                     (ly:note-head::print grob)))))
     (if (or n (memq style '(circle stk-diamond doThin laThin)))
         ;; Normalise every StaffTab head to a standard notehead's footprint:
         ;; center the ink on the standard glyph's centre AND report the standard
         ;; glyph's X-extent, so the note column / stem position all four shapes
         ;; identically (otherwise a narrower shape like the circle drifts).
         (let* ((std   (ly:stencil-extent
                         (ly:font-get-glyph (ly:grob-default-font grob) "noteheads.s2") X))
                (mid   (/ (+ (car std) (cdr std)) 2.0))
                (inked (ly:stencil-translate-axis
                         (ly:stencil-aligned-to raw X CENTER) mid X))
                (head  (ly:make-stencil (ly:stencil-expr inked)
                                        std (ly:stencil-extent inked Y))))
           (if n
               (ly:stencil-add head
                 (ly:stencil-translate-axis (stk-string-box-stencil grob n)
                                            (+ mid (stk-box-xoffset grob)) X))
               head))
         raw)))

%% ---- finger -> notehead style -------------------------------------------
%% Maps a fingering digit char (1..4, from a -1..-4 post-event) to the notehead
%% style the stencil draws.  (Letters kept as aliases in case a caller uses them.)
#(define (stk-finger-style ch)              ; finger digit -> notehead style
   (case ch ((#\i #\1) 'circle)          ; index  1
            ((#\m #\2) 'stk-diamond)     ; middle 2  (our square-on-corner diamond)
            ((#\a #\3) 'doThin)          ; ring   3
            ((#\c #\4) 'laThin)          ; little 4
            (else 'default)))

%% ---- \1..\6 / -1..-4 reader ----------------------------------------------
%% LilyPond's own string-number (\1..\6) and fingering (-1..-4) post-events ride
%% along in each note's `articulations`.  This Staff-level engraver reads them
%% off every note head as it is acknowledged -- the same point (and the same way)
%% LilyPond's New_fingering_engraver does, which is more reliable than reading
%% them back at stencil time -- and folds them into our grob properties:
%%   string-number -> NoteHead.stk-string  (drives the string bar)
%%   fingering digit -> NoteHead.style      (1 circle, 2 diamond, 3 tri, 4 sq)
%% We only fill in a property still at its default, so an explicit override on a
%% note would win.
%% Apply a fingering digit (1..4) to a note head as a StaffTab shape, unless the
%% head already carries an explicit style.
#(define (stk-shape-head! head digit)
   (when (and (integer? digit) (ly:grob? head)
              (eq? 'default (ly:grob-property head 'style 'default)))
     (let ((sty (stk-finger-style (integer->char (+ 48 digit)))))
       (unless (eq? sty 'default)
         (ly:grob-set-property! head 'style sty)
         (when (memq sty '(circle stk-diamond))
           (ly:grob-set-property! head 'stem-attachment stk-circle-stem-attachment))))))

%% Apply a "fingering" grob to a note head.  A \fr postfix rides in as a hidden
%% fingering carrying an stk-fret property -> set the head's fret; a real -1..-4
%% fingering has only a digit -> set the head's shape.  (An explicit value on the
%% head wins in either case.)
#(define (stk-finger-apply! fg head)
   (let ((fret (ly:grob-property fg 'stk-fret #f)))
     (if (integer? fret)
         (when (and (ly:grob? head)
                    (not (integer? (ly:grob-property head 'stk-fret #f))))
           (ly:grob-set-property! head 'stk-fret fret))
         (stk-shape-head! head (ly:event-property (ly:grob-property fg 'cause) 'digit)))))

%% Resolve this staff's StaffTab config from context properties `stickTuning`
%% (inherited from the enclosing ChapmanStickStaff, or set on the staff) and
%% `stickSide` ('up = melody, 'down = bass).  -> (count up? opens labels), #f if
%% not a configured Stick staff.
#(define (stk-context-config context)
   (let ((tuning (ly:context-property context 'stickTuning #f))
         (side   (ly:context-property context 'stickSide #f)))
     (and tuning (memq side '(up down))
          (let* ((up    (eq? side 'up))
                 (names (stk-side-pitches tuning up)))
            (list (length names) up
                  (map stk-spn->semitone names)
                  (map stk-spn->label names))))))

%% After strings (\1..\6) and explicit frets (\fr) are in place, fill in the
%% OTHER of {fret, string} from the note's pitch -- when `stickAutoFret` is on
%% (default #t):
%%   string but no fret -> fret = note - open[string]
%%   fret but no string  -> the string whose open pitch is exactly (note - fret)
%% If neither is derivable (or auto-fret is off) the note keeps whatever it has.
#(define (stk-derive-head! context head)
   (when (ly:context-property context 'stickAutoFret #t)
     (let ((str   (ly:grob-property head 'stk-string #f))
           (fret  (ly:grob-property head 'stk-fret #f))
           (opens (ly:grob-property head 'stk-open '()))
           (ev    (ly:grob-property head 'cause)))
       (when (and (pair? opens) (ly:stream-event? ev)
                  (ly:pitch? (ly:event-property ev 'pitch)))
         (let ((sem (ly:pitch-semitones (ly:event-property ev 'pitch))))
           (cond
            ;; string given, fret missing -> derive the fret
            ((and (integer? str) (not (integer? fret)) (<= 1 str (length opens)))
             (let ((f (- sem (list-ref opens (- str 1)))))
               (if (< f 0)
                   (ly:warning "stafftab: note is below open string ~a (fret ~a)" str f)
                   (ly:grob-set-property! head 'stk-fret f))))
            ;; fret given, string missing -> derive the string whose open pitch
            ;; equals (note - fret); if none matches, leave it (no box)
            ((and (integer? fret) (not (integer? str)))
             (let loop ((i 1) (os opens))
               (cond ((null? os) #f)
                     ((= (car os) (- sem fret)) (ly:grob-set-property! head 'stk-string i))
                     (else (loop (+ i 1) (cdr os))))))))))))

#(define (Stk_input_engraver context)
   (let ((cfg #f) (fingers '()) (heads '()))   ; cfg = (count up? opens labels)
     (make-engraver
      ((initialize engraver)
       (set! cfg (stk-context-config context))
       (when cfg     ; set the open-string LINE LABELS before InstrumentName is made
         (ly:context-set-property! context 'instrumentName
           (stk-names-markup (list-ref cfg 1) (list-ref cfg 3)))))
      (acknowledgers
       ((note-head-interface engraver grob source-engraver)
        (set! heads (cons grob heads))
        (when cfg    ; stamp this staff's tuning data onto the head for the stencils
          (ly:grob-set-property! grob 'stk-count (list-ref cfg 0))
          (ly:grob-set-property! grob 'stk-up    (list-ref cfg 1))
          (ly:grob-set-property! grob 'stk-open  (list-ref cfg 2)))
        ;; string number (\1..\6) rides in the note's articulations -> stk-string
        (let ((ev (ly:grob-property grob 'cause)))
          (when (ly:stream-event? ev)
            (for-each
             (lambda (art)
               (let ((sn (ly:event-property art 'string-number)))
                 (when (and (number? sn)
                            (not (number? (ly:grob-property grob 'stk-string #f))))
                   (ly:grob-set-property! grob 'stk-string sn))))
             (ly:event-property ev 'articulations)))))
       ;; A fingering (-1..-4) -- and a \fr postfix, which rides in as a hidden
       ;; fingering -- is NOT in the note's articulations, but LilyPond still
       ;; makes a Fingering grob.  Collect them; at end of timestep resolve each
       ;; to its note head(s) (X-parent is the head in a chord, the whole
       ;; NoteColumn on a lone note) and apply the shape or fret.
       ((finger-interface engraver grob source-engraver)
        (set! fingers (cons grob fingers))))
      ((stop-translation-timestep engraver)
       ;; 1. apply fingerings (notehead shapes) and \fr frets to their heads
       (for-each
        (lambda (fg)
          (let ((par (ly:grob-parent fg X)))
            (cond
             ((and (ly:grob? par) (grob::has-interface par 'note-head-interface))
              (stk-finger-apply! fg par))
             ((and (ly:grob? par) (grob::has-interface par 'note-column-interface))
              (let ((hs (ly:grob-object par 'note-heads)))
                (when (ly:grob-array? hs)
                  (for-each (lambda (h) (stk-finger-apply! fg h))
                            (ly:grob-array->list hs))))))))
        fingers)
       ;; 2. now that strings + explicit frets are set, auto-derive the missing one
       (for-each (lambda (h) (stk-derive-head! context h)) heads)
       (set! fingers '())
       (set! heads '())))))

%% ---- fret label engraver -------------------------------------------------
%% Each timestep, collect the noteheads carrying a fret, sort high->low pitch
%% (TOP note first), and emit ONE TextScript ("5.5.7") anchored to their note
%% column.  Direction (above the melody staff / below the bass staff) follows
%% the staff's `stickSide` context property.
#(define (Stk_fret_engraver context)
   (let ((heads '()))
     (make-engraver
      (acknowledgers
       ((note-head-interface engraver grob source-engraver)
        (set! heads (cons grob heads))))
      ((stop-translation-timestep engraver)
       (let ((fretted (filter (lambda (h) (ly:grob-property h 'stk-fret #f)) heads)))
         (when (pair? fretted)
           (let* ((sorted (sort fretted
                            (lambda (a b) (> (ly:grob-property a 'staff-position 0)
                                             (ly:grob-property b 'staff-position 0)))))
                  (txt    (string-join
                            (map (lambda (h) (number->string (ly:grob-property h 'stk-fret)))
                                 sorted) "."))
                  (nh     (car sorted))                 ; top notehead of the column
                  (col    (ly:grob-parent nh X))        ; its NoteColumn
                  (label  (ly:engraver-make-grob engraver 'TextScript nh))
                  (d      (if (eq? (ly:context-property context 'stickSide 'up) 'down)
                              DOWN UP)))
             (ly:grob-set-property! label 'text (make-simple-markup txt))
             (ly:grob-set-property! label 'direction d)
             ;; Centre the label's INK on the notehead's centre, both measured in
             ;; the NoteColumn frame.  We compute the offset ourselves (target
             ;; minus half the label's own width) because setting X-offset to a
             ;; custom callback bypasses the self-alignment-X machinery.
             (ly:grob-set-parent! label X col)
             (ly:grob-set-parent! label Y (ly:grob-parent nh Y))
             (ly:grob-set-property! label 'X-offset
               (lambda (lbl)
                 (- (interval-center (ly:grob-extent nh col X))
                    (interval-center (ly:grob-extent lbl lbl X)))))
             ;; Let the label FLOAT just past the notes (outside-staff): this
             ;; auto-clears the staff and any ledger notes, reserves vertical
             ;; space so consecutive systems get a small gap only where a fret
             ;; row exists, and needs no fragile staff-position math (which isn't
             ;; available this early anyway).  staff-padding keeps a small, even
             ;; gap from the staff so level passages read as a straight row.
             (ly:grob-set-property! label 'outside-staff-priority 350)
             (ly:grob-set-property! label 'staff-padding 1.2))))
       (set! heads '())))))

%% ---- per-line string labels (printed to the left of each clef) ----------
%% Each label is pinned to an ABSOLUTE height in staff-spaces from the middle
%% line:  +2 = top line, +1, 0 = middle, -1, -2 = bottom line.  Offsets are in
%% staff-spaces (not font units), so \fontsize only resizes the letters -- it
%% never shifts them off the lines.  \general-align centres each letter on its
%% line (Y) and right-aligns them against the clef (X).
#(define-markup-command (stk-staffline layout props y txt) (number? markup?)
   (interpret-markup layout props
     #{ \markup \translate #(cons 0.0 y)
        \general-align #Y #CENTER \general-align #X #RIGHT #txt #}))

%% Build an open-string label column, one name per string, top line downward.
%% `up` chooses the overflow side for a 6th string (melody up / bass down), so
%% the labels land on exactly the same lines as the string-box markers.
%% A transparent strut forces the column's vertical extent to be SYMMETRIC about
%% y=0 (the middle line); otherwise InstrumentName centres its (lopsided, for 6
%% strings) extent on the staff and the whole column slides off the lines.
#(define (stk-names-markup up labels)
   (let* ((count (length labels))
          (ys    (map (lambda (n) (/ (stk-string-pos n count up) 2.0)) (iota count 1)))
          (m     (+ (apply max (map abs ys)) 0.4))       ; clear the letter heights
          (rows  (map (lambda (y txt) (make-stk-staffline-markup y txt)) ys labels))
          (strut (make-with-dimensions-markup (cons 0.0 0.0) (cons (- m) m) (make-null-markup))))
     (make-fontsize-markup -6 (make-overlay-markup (cons strut rows)))))

%% ---- the ChapmanStaff / ChapmanStickStaff contexts -----------------------
%% ChapmanStaff bakes in everything tuning-INDEPENDENT (the two engravers plus
%% the notehead / label cosmetics), so you create a Stick staff like any other
%% and stay in control -- \alias Staff, nests in StaffGroup / PianoStaff, takes
%% any \with overrides:
%%   \new ChapmanStaff \with { stickTuning = \stickTwelveStringClassic \stickMelody
%%                             \override Beam.positions = #'(-4 . -4) }  % your tweaks
%%     \relative c' { g'8\1-2 ... }
%% or, inside a ChapmanStickStaff, put the tuning on the group and just \stickMelody
%% / \stickBass on each staff.  A tuning is a name ("12StringClassic"), a variable
%% (\stickTwelveStringClassic), an inline '((mel)(bass)) pair, or one side's list.

%% Register ChapmanStaff + ChapmanStickStaff for every score (a top-level
%% \layout sets defaults merged into each \score, so users need not touch their
%% own \layout).  ChapmanStickStaff groups a melody+bass pair (so one tuning can
%% be shared) with a plain system-start bar -- no piano brace.
\layout {
  \context {
    \Staff
    \name ChapmanStaff
    \alias Staff
    %% read \1..\6 / -1..-4 / \fr into stk-string / notehead style / stk-fret;
    %% consist this BEFORE the fret engraver so a \fr fret (resolved at end of
    %% timestep) is in place when the fret label is emitted.
    \consists #Stk_input_engraver
    \consists #Stk_fret_engraver
    \override InstrumentName.self-alignment-X = #RIGHT   % hug the clef
    \override InstrumentName.padding = #0.3
    %% Route EVERY notehead through our stencil (harmless for plain notes -- it
    %% falls back to the default head) so a bare \1..\6 / -1..-4 still shapes it.
    \override NoteHead.stencil = #stk-note-stencil
    %% ...and hide LilyPond's built-in string-number circle and fingering digit:
    %% \1..\6 and -1..-4 are repurposed as StaffTab string bars / head shapes.
    \override StringNumber.stencil = ##f
    \override Fingering.stencil = ##f
  }
  \context {
    \PianoStaff
    \name ChapmanStickStaff
    \accepts ChapmanStaff
    \defaultchild ChapmanStaff
    %% no piano brace -- just the plain system-start bar (as ungrouped staves get)
    \override SystemStartBrace.stencil = ##f
    systemStartDelimiter = #'SystemStartBar
  }
  \context { \Score \accepts ChapmanStaff \accepts ChapmanStickStaff }
}

%% ---- standard Chapman Stick tunings --------------------------------------
%% Each entry:  (name  (melody strings top->bottom)  (bass strings top->bottom)).
%% Each string is an open pitch in SCIENTIFIC PITCH NOTATION (C4 = middle C), so
%% the fret can be derived automatically (fret = played-note - open-string) and
%% the staff-line label is just the letter name with the octave dropped.  Set a
%% tuning via the `stickTuning` context property (on a ChapmanStickStaff or a
%% ChapmanStaff).  Octaves were
%% resolved from tunings.yaml (melody descends top->bottom, bass ascends; the
%% 12-string melodies that carry no anchor follow their 10-string sibling).
#(define stk-tunings
  '(;; --- 10-string (5 melody + 5 bass) ---
    ("10StringMatchedReciprocal"          ("C4" "G3" "D3" "A2" "E2")           ("C1" "G1" "D2" "A2" "E3"))
    ("10StringClassic"                    ("D4" "A3" "E3" "B2" "F#2")          ("C1" "G1" "D2" "A2" "E3"))
    ("10StringBaritoneMelody"             ("A3" "E3" "B2" "F#2" "C#2")         ("C1" "G1" "D2" "A2" "E3"))
    ("10StringDeepMatchedReciprocal"      ("Bb3" "F3" "C3" "G2" "D2")          ("Bb0" "F1" "C2" "G2" "D3"))
    ("10StringRaisedMatchedReciprocal"    ("D4" "A3" "E3" "B2" "F#2")          ("D1" "A1" "E2" "B2" "F#3"))
    ("10StringFullBaritone"               ("A3" "E3" "B2" "F#2" "C#2")         ("D1" "A1" "E2" "B2" "F#3"))
    ("10StringDualBassReciprocal"         ("C4" "G3" "D3" "A2" "E2")           ("B0" "F#1" "C#2" "G#2" "D#3"))
    ("10StringAlto"                       ("G4" "D4" "A3" "E3" "B2")           ("C2" "G2" "D3" "A3" "E4"))
    ("10StringGregHowardExtendedAlto"     ("A4" "E4" "B3" "F#3" "C#3")         ("C2" "G2" "D3" "A3" "E4"))
    ("10StringBobCulbertsonExpandedAlto"  ("A4" "E4" "B3" "F#3" "C#3")         ("A2" "E3" "B3" "F#4" "C#5"))
    ;; --- 12-string (6 melody + 6 bass) ---
    ("12StringMatchedReciprocal"          ("C4" "G3" "D3" "A2" "E2" "B1")      ("C1" "G1" "D2" "A2" "E3" "B3"))
    ("12StringClassic"                    ("D4" "A3" "E3" "B2" "F#2" "C#2")    ("C1" "G1" "D2" "A2" "E3" "B3"))
    ("12StringMatchedReciprocalHighBass4th" ("C4" "G3" "D3" "A2" "E2" "B1")    ("C1" "G1" "D2" "A2" "E3" "A3"))
    ("12StringClassicHighBass4th"         ("C4" "G3" "D3" "A2" "E2" "A1")      ("C1" "G1" "D2" "A2" "E3" "A3"))
    ("12StringDeepMatchedReciprocal"      ("Bb3" "F3" "C3" "G2" "D2" "A1")     ("Bb0" "F1" "C2" "G2" "D3" "A3"))
    ("12StringDualBassReciprocal"         ("F4" "C4" "G3" "D3" "A2" "E2")      ("B0" "F#1" "C#2" "G#2" "D#3" "A#3"))
    ("12StringMirrored4ths"               ("C4" "G3" "D3" "A2" "E2" "B1")      ("E1" "A1" "D2" "G2" "C3" "F3"))))

#(define (stk-tuning-lookup name)
   (or (assoc name stk-tunings)
       (ly:error "stafftab: unknown tuning ~s -- see stk-tunings for the list" name)))

%% Expose every standard tuning as a LilyPond VARIABLE, so it can be used by name
%% without quotes:  \stickTwelveStringClassic  ->  (("D4" ...) ("C1" ...)).  A
%% \-identifier is LETTERS ONLY (no digits), so digits in the tuning name are
%% spelled out (12 -> Twelve, 10 -> Ten, 4 -> Four) and a "stick" prefix is added.
%% Generated from the table so there's no second copy to maintain; usable
%% anywhere a tuning is taken -- e.g. \with { tuning = \stickTwelveStringClassic }.
#(define (stk-num->word n)
   (case n ((4) "Four") ((10) "Ten") ((12) "Twelve") (else (number->string n))))
#(define (stk-alpha-name s)                  ; digit runs -> words (legal \-id)
   (let ((len (string-length s)) (out '()))
     (let loop ((i 0))
       (if (>= i len)
           (apply string-append (reverse out))
           (if (char-numeric? (string-ref s i))
               (let dl ((j i) (acc 0))
                 (if (and (< j len) (char-numeric? (string-ref s j)))
                     (dl (+ j 1) (+ (* acc 10) (- (char->integer (string-ref s j)) 48)))
                     (begin (set! out (cons (stk-num->word acc) out)) (loop j))))
               (begin (set! out (cons (string (string-ref s i)) out))
                      (loop (+ i 1))))))))
#(for-each
  (lambda (entry)
    (ly:parser-define! (string->symbol (string-append "stick" (stk-alpha-name (car entry))))
                       (cdr entry)))
  stk-tunings)

%% Register a custom tuning ONCE, by name, then reuse it by name anywhere.
%% Strings are open pitches in scientific pitch notation (C4 = middle C):
%%   \addStickTuning "MyStick" #'("D4" "A3" "E3" "B2" "F#2" "C#2")
%%                             #'("C1" "G1" "D2" "A2" "E3" "B3")
%%   ... \with { stickTuning = "MyStick" }
addStickTuning =
#(define-void-function (name melody bass) (string? list? list?)
   (set! stk-tunings (cons (list name melody bass) stk-tunings)))

%% Resolve a tuning argument into (melody-names bass-names).  Accepts either a
%% STANDARD TUNING NAME (string, looked up in stk-tunings) or an inline custom
%% tuning given as the two name lists  '((melody...) (bass...))  -- so a whole
%% Stick tuning is declared in ONE place and shared by both staves.
#(define (stk-resolve-tuning t)
   (cond ((string? t) (cdr (stk-tuning-lookup t)))
         ((and (list? t) (= (length t) 2) (list? (car t)) (list? (cadr t))) t)
         (else (ly:error
                 "stafftab: tuning must be a name string or '((melody) (bass)) lists, got ~s" t))))

%% Resolve any tuning form to ONE side's open-string pitch list (top -> bottom):
%%   a name string ("12StringClassic")   -> that side of the named tuning
%%   a '((mel)(bass)) pair / variable     -> that side
%%   a flat list of SPN strings           -> used as-is (already this side)
#(define (stk-side-pitches tuning up)
   (cond ((string? tuning)
          (let ((p (stk-resolve-tuning tuning))) (if up (car p) (cadr p))))
         ((and (pair? tuning) (list? (car tuning)))     ; ((mel) (bass))
          (if up (car tuning) (cadr tuning)))
         ((list? tuning) tuning)                        ; this side's pitches
         (else (ly:error "stafftab: bad tuning ~s" tuning))))

%% \with side markers for a ChapmanStaff.  The staff reads its `stickTuning`
%% (inherited from the enclosing ChapmanStickStaff, or set on the staff itself)
%% plus its side and configures the lines / labels / fret side at run time:
%%   \new ChapmanStickStaff \with { stickTuning = \stickTwelveStringClassic } <<
%%     \new ChapmanStaff \with { \stickMelody } \melodyMusic
%%     \new ChapmanStaff \with { \stickBass }   \bassMusic
%%   >>
%% For a lone staff, set the tuning on it too:
%%   \new ChapmanStaff \with { stickTuning = \stickTwelveStringClassic \stickMelody } ...
stickMelody = \with { stickSide = #'up }
stickBass   = \with { stickSide = #'down }

%% Spell a fret out EXPLICITLY as a lightweight POST-EVENT, alongside \1..\6 and
%% -1..-4:  c'8\fr 7   (this wins over the derived value; needs no string).
%% It rides in as a hidden fingering carrying stk-fret, which Stk_input_engraver
%% routes onto the notehead.  Works in chords per note too:  <c\fr 5 e\fr 7>.
fr =
#(define-event-function (n) (index?)
   #{ -\tweak stk-fret #n #(make-music 'FingeringEvent 'digit n) #})

%% Apply a STRING to a whole passage instead of note-by-note:
%%   \onString 6 { a b c d }      -- all four on string 6
%% Adds \<n> to every note that doesn't already carry a string, so notes with
%% their own \1..\6 keep it.  Works on chords too (each bare note gets it).
onString =
#(define-music-function (n music) (index? ly:music?)
   (music-map
    (lambda (m)
      (when (and (music-is-of-type? m 'note-event)
                 (not (any (lambda (a) (number? (ly:music-property a 'string-number)))
                           (ly:music-property m 'articulations '()))))
        (ly:music-set-property! m 'articulations
          (cons (make-music 'StringNumberEvent 'string-number n)
                (ly:music-property m 'articulations '()))))
      m)
    (ly:music-deep-copy music)))
