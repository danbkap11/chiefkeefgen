# Musical specification

## Evidence register

**Verified technical sources:** see ARCHITECTURE.md's links to the exact SuperCollider 3.14.1 tag.

**Musical reference recordings, selected from prior knowledge:** Chief Keef, “I Don't Like” (original 2012 release; distinguish from the later multi-artist remix); “Love Sosa” (*Finally Rich*, 2012); “Hate Bein' Sober” (*Finally Rich*, 2012). These are primary musical references to audition, not evidence that a named producer used a particular synth, sample pack, DAW setting, or algorithm. Their audio and credits were not newly accessed in this investigation.

Use “I Don't Like” to assess terse motif identity, low-end impact, and rhythmic space; “Love Sosa” to assess a persistent melodic center and the effect of layering/dropouts; “Hate Bein' Sober” to assess larger hook energy and the balance between melody and percussion. These are listening questions and interpretive directions, not measured transcriptions. Do not copy their musical material.

**Primary-source research gap:** music websites and searches were blocked by the proxy. No verified interview quotation or exact reference-track BPM is asserted. Before claiming historical authenticity, find and inspect a Young Chop production breakdown/interview, verify the recording version and credits, and log the exact URL, author/channel, date, relevant passage/time, and supported claim. The attempted destinations were [Sound On Sound search](https://www.soundonsound.com/search/all?terms=young%20chop), [FACT search](https://www.factmag.com/?s=Young+Chop), and [YouTube search](https://www.youtube.com/results?search_query=Young+Chop+Love+Sosa+making+of); these search links are discovery leads, not supporting citations. Do not invent missing URLs, quotes, measurements, or source access.

**Everything numerical below is a proposed generator rule.** The design can be implemented and tested while source access is unavailable, with the research limitation preserved. Sonic authenticity remains subject to listening review.

## Time, feel, and identity

- Meter: 4/4. One clock beat is one quarter note. Tempo defaults to 140 BPM, adjustable 130–150. The perceived half-time pulse is 65–75 BPM; do not accidentally clock the same pattern at half speed again.
- Resolution: 96 integer ticks per quarter; 384 ticks per bar. A sixteenth is 24 ticks, an eighth 48, an eighth-note triplet 32, and a sixteenth-note triplet 16.
- Default feel is straight. A seed may choose hat-only offbeat delay from 0, 2, or 4 ticks. Never move the principal kick or snare for humanization. Rolls remain straight and all shifted events stay inside their bar.
- Select tonic pitch class from C, D, F, G, A, or B-flat. Natural minor scale semitones are `[0, 2, 3, 5, 7, 8, 10]`; no automatic modulation.
- A song retains one tonic, one primary lead patch, one four-bar motif, one eight-bar harmonic cycle, one two-bar kick template, and one kit. Repetition establishes the beat. Variations modify the ends of phrases and instrument masks; they do not replace the motif each bar.

## Harmony and motif generation

Use zero-based diatonic degrees. Choose one harmonic cycle at generation time: `[0, 0, 5, 5]` (weight 0.65) or `[0, 5, 2, 6]` (weight 0.35). Each entry lasts two bars. These weights are composition defaults, not measured historical frequencies.

For a diatonic degree `d`, the pitch offset is `scale[d mod 7] + 12 * floor(d / 7)`. Use positive modulo and floor division. For current chord-root degree `r`, chord tones have degrees `r + [0, 2, 4]`. Octave placement may change; pitch class must not. Bass plays the current root, with occasional chord fifths as specified below.

Generate an original four-bar motif from one of these onset templates; each nested list is one bar in ticks:

| Template | Bar 1 | Bar 2 | Bar 3 | Bar 4 |
| --- | --- | --- | --- | --- |
| A | 0, 144, 288 | 0, 240 | 0, 144, 288 | 96, 288 |
| B | 0, 192 | 48, 192, 288 | 0, 192 | 48, 240 |
| C | 0, 96, 288 | 96, 288 | 0, 96, 288 | 192 |

Select motif-relative degrees from `[0, 2, 4]`, favoring 0 and 2; set the first degree to 0. Store the chosen relative degrees and rhythm once, then map them to each current chord. Primary lead range is MIDI 60–84, folding by octaves. Assign lengths from 48, 96, or 144 ticks, clipped before the next lead onset and the bar boundary, with a short release included in that budget. Keep the lead monophonic. Use one repeated rhythmic accent/velocity shape across the motif.

Only at the final bar of each eight-bar phrase may the last lead note move to another chord tone or be omitted. Precompute the decision. Optional passing notes are deferred from v1; every lead note is a chord tone. Pads voice triads in MIDI 48–72 and favor nearest-voice movement between chords. Retrigger the pad quietly each bar even when harmony is unchanged, with envelope release included before the next bar. Their sustained sound must remain quieter than the motif. In v1 **all pitched notes end by their bar boundary**: this keeps next-bar tempo changes from making an old-duration bass/lead/pad overlap a new harmony or voice. Reverb and unpitched drum tails may cross the boundary.

## Drums and bass

All ticks below are relative to the bar, with 0 as its first downbeat.

| Role | Foundation | Constrained variation |
| --- | --- | --- |
| Snare/clap | layered backbeat at tick 192, quarter-note beat 3 | transition gestures do not add a second snare |
| Kick | choose a two-bar template below and repeat | the dropout gesture may remove late kick onsets; no fill adds extra kicks |
| Closed hat | ticks 0, 96, 192, 288 | add offbeat eighths and limited subdivisions using Activity |
| Open hat | optional tick 144 or 336 | at most one/bar in hook; at most one/two bars in verse; Activity >= 0.65 |
| Percussion | no obligatory part | at most two/bar, off principal snare, Activity >= 0.65 |

Two-bar kick templates, listed as bar 1 / bar 2:

- K1: `[0, 144, 264]` / `[0, 120, 240, 336]`.
- K2: `[0, 168, 288]` / `[0, 96, 264]`.
- K3: `[0, 120, 336]` / `[0, 144, 288]`.

Keep chosen templates intact except for section muting, intentional final-bar dropouts, and the bounded fill. Avoid replacing this backbeat with a continuously syncopated modern drill pattern.

808/sub bass is a pitched instrument separate from the short kick. For each two-bar cell, derive bass entrances from its kick onsets: always keep the first downbeat when bass is active, keep two or three other selected onsets, and omit the rest. Retain this selection through repetitions. At least 80% of bass notes use the current chord root; optional fifths are allowed only on weak onsets and must be chord tones. No chromatic runs, continuous portamento, or automatic sliding-bass vocabulary in v1.

Fold bass pitch into MIDI 28–43, preferring the octave nearest the previous note. All new notes must fit the current chord. Hold durations start at 48–288 ticks, then clip to the next bass onset, bar boundary, section mute boundary, or harmony boundary, whichever comes first; clipping may produce a value shorter than 48 ticks. Include attack/release in the duration budget; maintain a 2 ms gap before the next bass onset in playback. A low kick tail (~80–130 ms) plus a gentler bass attack (~8 ms) provide separation. Use modest saturation for upper harmonics, mono low end, and no bass reverb. Listen for masking and phase cancellation; independent kick and bass roles do not guarantee a good mix.

Hat velocities use a repeating strong/weak pattern, approximately 1.0 / 0.65. Rolls are quiet and occupy the final 96 ticks of at most one bar per four-bar phrase, only in an eligible fill. Choose sixteenth or sixteenth-triplet spacing, remove regular hats that collide, cap all closed-hat events at 24/bar, and never put a roll in every bar. Closed hats choke open hats using the instrument's short forced-release behavior.

## Arrangement

Choose A with weight 0.8 or B with weight 0.2. Loop the completed arrangement, retaining the same seed and planned phrase variations. New Beat is the explicit way to get a new composition.

| Template | Ordered sections | Total |
| --- | --- | --- |
| A (default) | Intro 8, Hook 16, Verse 16, Hook 16, Verse 16, Hook 16, Outro 8 bars | 96 bars |
| B (compact) | Intro 4, Hook 16, Verse 16, Hook 16, Verse 16, Hook 8, Outro 4 bars | 80 bars |

At 140 BPM these last about 164.6 and 137.1 seconds. Number local bars from zero internally and label them from one in the GUI. Reset the eight-bar harmonic cycle at each section's start; a compact four-bar intro/outro deliberately uses its first four bars.

| Section | Required instrument mask and energy |
| --- | --- |
| Intro | Lead from bar 1 at reduced brightness, no kick/bass/snare; quiet quarter hats only in second half; pad allowed. Silence the final 48 ticks before the hook. |
| Hook | Full foundational drums, bass, primary motif, quiet pad; optional upper layer according to Intensity; fills at ends of 8-bar phrases. |
| Verse | Foundation drums and bass; primary motif active for first 2 bars of each 4-bar block and absent for the next 2; pad quieter; no upper layer; one fill at section end. |
| Outro | No upper layer, pad fades; first half retains kick/snare/bass and sparse motif, second half removes bass/kick and leaves lead plus sparse hats; final beat is a breath before looping. |

Transitions use contrast and selective muting, not a mandatory riser sample. At eligible boundaries choose exactly one precomputed gesture: final 48-tick kick/bass dropout, a quiet hat fill, or a cymbal hit on the next section's first beat. Do not stack all gestures. The Intro/Outro silence rules take precedence. Short tails may extend through a breath; do not start new notes there. Clamp pitched durations at harmony/mute boundaries.

## Three control mappings

All controls commit together at the next bar; while stopped they update active values immediately. Clamp and validate numeric values before storing. No playback-time randomness is introduced by control changes.

| Control | Exact mapping |
| --- | --- |
| Tempo | Integer 130–150, initial 140; `clock.tempo = BPM / 60`. Ticks and sections do not change. Compute newly triggered envelope seconds using active tempo. Existing tails retain their seconds. |
| Activity | 0–1, initial 0.50. Foundation hats have minimum 0.00; offbeat eighth hats 0.25; selected extra sixteenths, open hats and percussion 0.65; eligible triplet rolls and extra snare/kick fills 0.85. A candidate plays iff its `minActivity <= activeActivity` and section/fill masks allow it. Motif, harmony, essential kick/snare, and bass foundation remain fixed. |
| Intensity | 0–1, initial 0.55. Primary lead low-pass cutoff `600 * (10 ** intensity)` Hz (600–6000); pad cutoff `400 * (7.5 ** intensity)` Hz (400–3000). Hook-only upper motif layer enabled at >= 0.65, at one octave above the lead, MIDI <= 96, and -12 dB relative to primary lead. No upper layer elsewhere. Master gain does not change. |

Candidate selection, roll positions, and optional percussion positions are made once by the seed. Raising Activity adds eligible candidates instead of rerolling the whole rhythm. Foundation events always have `minActivity = 0`. Section masks override Activity. Intro/Outro hats are limited to quarter notes even at maximum Activity. Intensity affects new notes on the commit bar; do not demand instant retuning/filtering of existing finite tails.

## Timbres and initial mix

Primary lead is a restrained synthetic brass/saw or bell/pluck patch chosen once per seed. Alternate patches share the same motif. Pads are filtered triads; drums are punchy and comparatively dry. No vocal shouts are necessary. See ASSETS.md for synthesis recipes.

Initial per-voice peak scales before envelopes: kick 0.22; snare including clap layer 0.14 total; closed hat 0.035; open hat 0.04; percussion 0.035; bass 0.18; primary lead 0.07; each pad voice 0.035. These are conservative engineering starting values, not measured mix levels. Velocity multiplies these scales. No automatic per-beat normalization.

Send only melodic parts and a little snare to short reverb, with no kick/bass send. Keep the bass centered; use modest melodic width. Master high-pass 20 Hz, remove DC, fixed gain 0.8, limiter ceiling 0.89 with `dur = 0.01` (20 ms added latency). Limiters do not replace gain staging. Luna may calibrate fixed gains within +/-6 dB after rendering/listening; record the final values and rationale, keep the controls' behavior, and rerun level tests.

## Listening sign-off

Review at least three seeds against the three reference recordings when they are available. Report motif memorability, half-time pulse, rhythmic space, sound palette, low-end clarity, and section contrast. Record specific shortcomings and adjust generator rules rather than adding random events. An audio peak test cannot establish genre authenticity; mark listening unrun if it was not performed.
