# Ordered implementation plan for Luna

Implementation record (2026-10-17, v0.1.1): matching SuperCollider 3.14.1 language/server binaries were built from the official source release. Startup, basic plan invariants/determinism/diversity, an eight-bar NRT waveform check, and headless lifecycle smoke checks now pass. The complete milestones below remain the acceptance target; full audio matrices, full lifecycle stress, optional asset fixtures, visible GUI/device checks, and listening review are still incomplete. See `test-results/current-run.md` for actual executed counts.

## 1. Establish the exact runtime

Read all seven documents, inspect the checkout and host, and obtain matching official SuperCollider 3.14.1 language/server binaries with normal TLS/signature/checksum verification. Prefer an official release for the host over an unpinned package version. Record OS, version strings, audio/display availability, and installation method. Do not substitute a different release and call it 3.14.1 validation.

Deliver: README prerequisites/launch steps and a short environment inventory. A missing desktop/audio device is a specific interactive-testing limitation; proceed with pure-language/NRT work. Default runtime must need no network or third-party samples. Check available resources before considering a source build; a source build is a fallback, not the initial task.

## 2. Build and verify the pure composition layer

Implement Config, Compose, and Arrange with the schemas, templates, collision rules, seed isolation, and canonical serialization. Start with the synthesized catalog identities only. Generate whole 80/96-bar plans before audio. Do not produce arbitrary independent live random streams.

Deliver: headless plan test runner with nonzero failure exit, deterministic fixtures, and fresh result logs. Verify all tested seeds for harmonic membership, note/rhythm bounds, section totals, bounded complexity, and repeatable filtering. Use a separate signature excluding seed to measure diversity. Fix composition failures before adding GUI complexity.

## 3. Implement the stock sound palette and NRT path

Implement Sound's SynthDefs and message adapter, then a finite NRT graph using those exact components. Render a complete arrangement at 140 BPM. Use 48 kHz stereo float WAV, 0.10 s preroll and 2 s release tail. Verify success exit status, expected duration, finite/nonzero samples, and controlled peak. Audition when audio monitoring is available.

Deliver: default timbres, complete-plan render tool, and audio test results. Calibrate fixed gains within the documented bounds and update the final values if needed. Do not use the limiter to hide a persistently overloaded source mix. Implement synth fallback first; optional downloads can wait until the default is working.

## 4. Implement real-time engine and ownership

Build initialization, graph ordering, one private TempoClock/Routine, timed bundles, next-bar commits, quantized New Beat, and plan looping. Implement Stop/dispose early, including token invalidation and the queued-bundle drain interval. Keep the normal server alive and preserve other users of it.

Deliver: programmatic transport and integration tests exercising actual scsynth. Verify Play idempotence, Stop/Play, repeated New Beat, double launch, close during boot/load, CmdPeriod, server loss, and cleanup. Compare against owned-resource baselines. Do not treat “no language exception” as evidence of correct audio scheduling.

## 5. Add the three-control Qt interface

Build the window on AppClock with Tempo, Activity, Intensity, Play, Stop, New Beat, and read-only status. Use pending settings; never mutate musical state directly from a widget callback. Show actual committed values, current seed/key, section, and fallback/error status. Launch must autoplay after initialization.

Deliver: manual/integration GUI results on a named supported desktop. Test limits and rapid interactions during playing, stopping, loading, and pending generation. Avoid another musical parameter control unless scope is explicitly changed.

## 6. Add optional asset support

Implement manifest parsing, validation, async loading with timeout/stale-load cleanup, fixed-channel sample playback, and fallback. A header-only manifest is a normal successful setup. If a small licensed library materially improves sound and network access permits it, acquire assets according to ASSETS.md and record real provenance/hashes. Downloads are optional; the import/fallback code path and a generated local test WAV fixture should still be verified.

Deliver: header-only manifest, import instructions, missing/corrupt/unsupported asset tests, and attribution for any actual downloads. Keep external assets out if their redistribution permission cannot be established.

## 7. Complete musical review and delivery

Run ACCEPTANCE_TESTS.md with the actual version. Render at least three contrasting seeds and inspect/listen to transitions and the high-Activity/high-Intensity case. When accessible, audition the named reference recordings and inspect a credible Young Chop primary-source breakdown; update the evidence register only with claims actually supported. If research/listening is unavailable, preserve that distinction and report it.

Deliver a runnable project, exact launch/test commands, actual test output, short listening notes, and remaining limitations. Every result must refer to the current code and current-run artifacts. Fix environment/setup issues and diagnosed code failures within the implementation scope. Do not report tests as passed merely because test files exist.

## Completion gate

All required automated checks must pass for a fully validated implementation. Interactive/aural sign-off requires actual interactive/aural evidence. If a genuine external blocker remains, finish the independent work and report the exact unrun checks and prerequisite. A headless-tested deliverable can be useful, but is not a fully GUI/device/listening-tested release.
