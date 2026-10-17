# Chief Keef type beat generator — implementation brief

Status (2026-10-17, v0.1.1): application modules and launch block now compile under source-built SuperCollider **3.14.1**. Startup, multi-seed plan checks, an eight-bar NRT waveform check, and a headless real-time lifecycle smoke test have passed. Full acceptance, visible GUI/device, and listening sign-off remain incomplete; see README.md and `test-results/current-run.md`.

## Intended result

Open `main.scd` in the SuperCollider IDE and evaluate its single launch block. After boot and resource initialization, a small window appears and a new original instrumental starts automatically. The beat follows an arranged song form and loops that arrangement until stopped. A fresh launch or New Beat creates a different composition; Play after Stop restarts the current composition from its intro.

The reference is early Chicago drill associated with Chief Keef and Young Chop, centered on the 2012 *Finally Rich* sound within the requested 2012–2014 period. Favor ominous, memorable synth motifs, strong half-time backbeats, clipped kicks, tuned sustained sub bass, and deliberate space for a rapper. Do not copy existing melodies, vocals, producer tags, or recordings. Later Chief Keef experiments and UK/Brooklyn drill are outside the default palette.

There is no universal Chief Keef song structure. This project uses constrained production templates described in MUSICAL_SPEC.md. These templates and all numerical generation rules are design choices, not claims about how every reference recording was made.

## Evidence and current limitations

The checkout initially contained the design handoff without application code. Matching 3.14.1 language/server binaries have now been built from the official source release for headless validation. An eight-bar NRT render and real-time output capture using JACK's dummy backend were checked numerically. No visible GUI interaction, physical audio-device check, or listening comparison has been performed.

Requests to music research/search destinations including Google, Sound On Sound, Red Bull, FACT, YouTube, and Wikipedia were denied by the environment's network proxy. Consequently, this handoff does **not** claim newly verified producer interviews, track transcriptions, BPM measurements, or listening results. The musical specification is an informed proposal with explicit reference-listening and primary-source verification tasks. Technical source verification and musical source verification have different statuses.

## Runtime and dependencies

- Required: matching SuperCollider 3.14.1 language and scsynth binaries, standard library, Qt GUI, and a working stereo output device for interactive use.
- Linux interactive use additionally needs a working supported audio backend and desktop/display. Headless NRT rendering can validate audio synthesis without a playback device, but does not validate the desktop GUI or audible device output.
- Support native Windows, macOS, and Linux installations through relative project paths. Validate on at least one named OS; do not claim all three were tested unless they were.
- No Quarks, sc3-plugins, proprietary VSTs, Python runtime, internet connection, API keys, or third-party samples are required for normal playback.
- Optional local one-shots use the import contract in ASSETS.md. Their absence must not prevent playback.

## Interface and behavior

There are exactly three musical controls. Transport buttons and read-only status are separate.

| Control | Range | Initial value | Commit point |
| --- | --- | --- | --- |
| Tempo | integer 130–150 BPM | 140 | next bar |
| Activity | 0.00–1.00 | 0.50 | next bar |
| Intensity | 0.00–1.00 | 0.55 | next bar |

Activity selects additional hats, rolls, and percussion from a precomputed candidate plan. Intensity changes melodic brightness and enables a quiet upper hook layer; it does not turn up the master. Exact mappings live in MUSICAL_SPEC.md. Display pending settings until applied. Existing note tails keep their original durations; new note durations use the new tempo.

Buttons: Play, Stop, New Beat. Play is idempotent while playing. Stop cancels scheduling immediately and fades/drains owned audio resources. New Beat preserves the three control values and commits a newly prepared plan at the next bar while playing; while stopped it replaces the plan without starting playback. Read-only status shows state, seed, key, section/bar, active settings, and actionable errors. A seed override is available through the programming interface/configuration, not a fourth musical control.

Normal launches exclude the previous seed when relaunching in the same language session. Seed reuse explicitly reproduces the composition given the same generator version, settings, and asset identities. Reproducibility means the same notes, rhythm, arrangement, and patch choices; noise-based synthesis and audio hardware need not produce byte-identical WAV files.

## Completion standard

Deliver a runnable local project, clear launch instructions, a zero-download default sound palette, functioning GUI, deterministic plan generation, safe lifecycle handling, and the meaningful tests in ACCEPTANCE_TESTS.md. Include actual test logs and a concise listening review. Keep passed, failed, skipped, and unrun checks distinct.

MIDI export, DAW integration, recording controls, a piano roll, network services, vocals, a large sample browser, learned audio models, and exact track recreations are excluded from the first implementation. NRT render tooling is a verification aid, not an extra GUI feature.

## Document authority

PROJECT_BRIEF defines product scope. MUSICAL_SPEC owns musical rules and control mappings. ARCHITECTURE owns runtime/data contracts. ASSETS owns asset handling. ACCEPTANCE_TESTS owns validation. IMPLEMENTATION_PLAN orders the work. Resolve inconsistencies explicitly and update affected documents rather than silently inventing different defaults.
