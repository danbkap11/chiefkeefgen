# Copy this prompt to Luna with the other six Markdown files

Act as a senior SuperCollider developer and producer. **Implement the project now**, using the attached specification documents. Deliver a complete runnable original beat generator for **SuperCollider 3.14.1**, not another planning response.

Read these six files before coding: PROJECT_BRIEF.md, MUSICAL_SPEC.md, ARCHITECTURE.md, ASSETS.md, IMPLEMENTATION_PLAN.md, and ACCEPTANCE_TESTS.md. They contain the product scope, musical rules, interfaces, runtime lifecycle, asset format, milestones, and verification criteria. They require no prior chat history. The repository initially contains this design handoff; application code has not been written or runtime-tested. Inspect and preserve any user changes made since the handoff.

## Product to build

Evaluating one launch block in `main.scd` in the SuperCollider IDE must boot/initialize as necessary, open a small Qt window, and automatically play a fresh, coherent instrumental. The reference is Chief Keef's early Young Chop associated Chicago drill sound, centered on 2012 *Finally Rich* within the requested 2012–2014 period. Compose original music. Keep a memorable motif, coordinated drums/bass/harmony, deliberate repetition, and a complete verse/hook arrangement with restrained transitions.

Default tempo is 140 BPM in 4/4 with a half-time backbeat at quarter-note beat 3. Time resolution is 96 ticks/quarter and 384 ticks/bar. Use the specified natural-minor harmony, four-bar motif, two-bar kick templates, tuned mono sub bass, bounded hats/fills, section masks, and 96-bar default / 80-bar compact arrangement templates. Follow MUSICAL_SPEC's exact numerical rules and distinguish them from claims about historical production practice.

Provide exactly three musical controls:

- Tempo: integer 130–150 BPM, initially 140.
- Activity: 0–1, initially 0.50; enables precomputed rhythmic candidates at the documented thresholds.
- Intensity: 0–1, initially 0.55; maps to melodic filter brightness and a quiet hook-only upper layer, without raising the master.

Controls commit at bar boundaries; show active/pending values. Add Play, Stop, New Beat, and read-only state/seed/key/section information. Normal launch auto-plays a fresh seed. Play after Stop restarts the current composition. New Beat preserves the settings and adopts a prepared new plan at the next eligible bar while playing; while stopped it changes the plan without starting playback. Expose explicit seed replay through the programming/config interface.

## Architecture to follow

Use standard SuperCollider classes and stock scsynth UGens, without Quarks or proprietary instruments. Load modular `.scd` files relative to the entry point; require no class-library recompilation. Implement the module interfaces and SongPlan/candidate schemas in ARCHITECTURE.md.

Compile an entire immutable candidate song in an isolated seeded Routine. Use stable iteration and canonical serialization. Playback uses **one private TempoClock and one bar-aware Routine**, with no live random composition decisions. Convert BPM to beats/sec, wait tick differences/96, and send simultaneous events in timestamped OSC bundles. Keep future lookahead bounded to server latency. Use explicit ordered source/master groups, private buses, finite self-freeing voices, conservative gain, and output limiting. Preserve unrelated server activity.

Implement safe asynchronous boot/load synchronization, failure timeouts, generation tokens, next-bar parameter commits, quantized regeneration, hat choking, Stop, window close, CmdPeriod, server-loss handling, and repeated entry-point evaluation. Stopping a Routine does not recall OSC already sent: drain queued messages before freeing/reusing group/bus/buffer resources. Fixed-length envelopes need the documented negative-gate forced release rather than an ineffective gate=0 assumption. Keep cleanup scoped and idempotent.

Seed replay guarantees composition/event reproducibility for the same generator, settings and asset identities, not byte-identical noise-containing audio. Diversity tests must exclude the seed field when comparing musical signatures.

## Sounds and research

First deliver the full synthesized palette in ASSETS.md so the default works offline with no downloads. Implement optional drum one-shot imports and reliable fallback using the TSV manifest contract. Add only useful assets with inspected permission for raw-file redistribution, real provenance, attribution when needed, and real SHA-256 hashes. If acquisition is unavailable, keep the synthesized sounds and verify the importer with generated local fixtures. Do not invent license or checksum entries.

Technical APIs were checked against the official 3.14.1 tag; no application runtime checks have passed yet. External music research sites were network-blocked during the design. Do not invent citations, producer quotes, track BPM measurements, listening results, or claims of historical authenticity. If access is available, inspect a credible producer breakdown and audition the original reference recordings, then update only supported claims. Keep inaccessible research clearly marked while completing useful implementation and validation.

## Execution and validation

Work in the existing checkout; do not create a worktree unless requested. Follow IMPLEMENTATION_PLAN.md through completion: exact runtime, pure plan tests, SynthDefs/NRT rendering, real-time lifecycle, GUI, asset fallback, and musical review. Use reasonable defaults without stopping for routine confirmation. Resolve setup problems and implementation failures; ask only for information or access that truly prevents further useful progress.

Validate with matching 3.14.1 language and server binaries. Use the actual composition layer, voice-message adapter and production graph for both real-time and NRT tests. Implement the meaningful suites in ACCEPTANCE_TESTS.md: multi-seed invariant/determinism/diversity tests, full-song and extreme-control audio renders, real bar-boundary control tests, resource ownership/lifecycle stress, asset fallback, GUI/device checks and listening review. Record real assertion counts, exit codes, current-run artifacts, and observed resource counts. A scheduled renderer, empty test run, or open port does not count as a pass.

In an isolated NRT test process, set the Score serialization timebase to one beat/sec before writing already-second-based timestamps; do not modify the interactive default clock. Verify renderer exit, fresh WAV contents and duration, finite/nonzero signal, peak <=0.90, and the absence of persistent pre-limiter overload. Headless NRT does not validate a visible GUI, audio device, or musical authenticity.

Deliver the implemented project plus README install/launch/test instructions, header-only or populated asset manifest as appropriate, actual test output, and concise listening notes. Keep the seven design documents consistent with justified implementation adjustments; explain changes rather than silently dropping requirements. End with the exact launch steps and a suite-by-suite passed/failed/skipped/unrun report. If an external blocker remains, finish independent work and name the precise limitation and required action. Do not claim runtime, cross-platform, GUI, research, or listening validation that you did not perform.
