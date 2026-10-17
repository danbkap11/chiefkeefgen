# Acceptance and validation specification

Status (2026-10-17, v0.1.1): real 3.14.1 startup checks, a subset of P1, an eight-bar A1 smoke render, and a subset of R1/lifecycle checks have passed. Matching headless binaries were built from the official source release. The complete suites below have not all passed. See `test-results/current-run.md` for counts, logs, and remaining checks.

## Test harness and evidence

Use standalone `sclang` test scripts, not a required third-party test framework. Plan-only tests need no server or window. Render tests use matching 3.14.1 scsynth in NRT mode. Interactive tests require a desktop and working output backend. Use a unique current-run directory under test-results/ and record runtime versions, OS, generator version, seed/settings, asset identities, command, exit code, expected/executed assertion counts, and artifact paths.

Suggested CLI interfaces to implement from the repository root:

```text
sclang -D tests/startup_tests.scd
sclang -D tests/plan_tests.scd
sclang -D tests/render_smoke.scd
python3 tests/check_wav.py test-results/startup-fix/smoke.wav 15.814285714286
sclang -D tests/lifecycle_smoke.scd
```

These implemented runners have been executed under matching 3.14.1 binaries. They are regression/smoke checks, not the whole acceptance matrix below. The lifecycle runner requires an available backend; Linux CI used JACK dummy. On desktop use the IDE for main.scd and the manual procedures below. Headless execution does not prove that the visible GUI or physical audio device works.

Runners must terminate with 0 only after their selected checks complete and with nonzero on assertion failure, timeout, boot/render failure, or missing required results. Shell wrappers must preserve underlying status. Don't swallow errors in an always-successful callback or silently reduce a failing suite to zero tests. Set test timeouts; allow initial boot up to 20 s, per-file optional loading up to 10 s, and NRT rendering up to 180 s for a full song on the reference host, reporting a resource limit if exceeded.

## P1 — Composition invariants (required)

For seeds 1–100, compile both arrangement templates through a test-only selector or template-expansion fixture, and compile the normal weighted selection. Report actual cases and assertions executed. Verify:

- Sections are contiguous with exactly 96 bars for A and 80 for B; all bars contain 384 ticks. No negative/out-of-range event ticks, duplicate IDs, invalid pitches, nonfinite values, or unsupported roles.
- Same seed/catalog/generator version gives identical canonical plan twice, including after unrelated random operations and fake UI actions. Same plan/settings gives identical filtered events. Dictionary/catalog insertion order changes do not change identity-sorted results.
- At least 80 distinct structural signatures among the 100 normal seeds, excluding seed metadata. The sample set includes at least three tonic choices and two motif/kick templates. Treat this as a diversity regression test, not a proof of musical quality.
- Every bass and lead pitch class belongs to the current chord; pad voices form that triad. Bass root proportion >=80% across the song, bass MIDI 28–43, primary lead 60–84, pad 48–72, upper <=96.
- Lead notes and bass notes do not overlap their next same-role note, bar boundary, or harmony/mute boundaries in the static plan. Pad voices release within the bar and retrigger next bar. This bar cap also protects tempo commits from overlap caused by old-second-based pitched durations. A runtime New Beat crossfade is a separate 30 ms exception.
- No kick/bass/snare in Intro; Verse has the specified two-bars-on/two-bars-off lead mask; no upper in Verse/Intro/Outro; Outro removal rules and final-beat breath hold. Core motif/rhythm choices persist through repetitions.
- All applicable full-drum bars have the main snare at tick 192, except an explicitly defined transition mute. Kick patterns match the selected template except documented fill/dropout changes.
- Filtered closed hats <=24/bar, roll <=one bar/four-bar phrase, percussion <=2/bar, and no duplicate same-role onsets. Playing open hats replace closed hats at the same tick.
- For Activity 0, 0.25, 0.50, 0.65, 0.85, 1, additional eligible rhythmic candidates appear at their thresholds without changing harmony, lead or foundational drum/bass decisions. Account for open-hat replacement when comparing closed-hat sets; compare the combined hat-onset set instead.
- Intensity changes exactly the documented cutoff mappings and hook upper-layer gate; it does not change the underlying composition or master gain. Tempo changes no tick positions or bar counts.

## A1 — Real synthesis/NRT (required)

Render full A/B arrangements using the synthesized catalog and shared production graph/adapter. Use seed fixtures that exercise both lead patches. Minimum matrix: three distinct seeds at 140 BPM/default Activity/Intensity, plus one eight-bar full-hook excerpt at 130 BPM/controls 0 and another at 150 BPM/controls 1. Explicitly identify which full render exercises which arrangement. Obtain exact fixture seeds from the actual compiler; do not pretend unverified seed numbers necessarily choose different templates.

For each WAV, verify fresh output, successful renderer exit, 48 kHz stereo float format, finite samples, nonzero signal in intended active sections, no absolute peak above 0.90, and duration within 0.10 s of `bars * 4 * 60/BPM + 0.10 + 2.0`. Full A/140 is approximately 166.67 s including preroll/tail; B/140 approximately 139.24 s. A limiter ceiling test is about sample peaks; do not claim intersample true-peak compliance.

Check role stems or adapter-event logs for snare timing, section masks, bass tuning, and pitched duration clipping. Inspect pre-limiter sum as well as final output; persistent >1.0 pre-limiter peaks or audibly constant gain reduction require gain/mix correction. A master peak measurement alone cannot prove bass pitch or arrangement correctness.

Use the actual SynthDefs and routing for these checks. A separately written test sine wave is only a diagnostic and cannot satisfy A1. Do not compare noise-containing WAV files byte-for-byte for seed determinism; compare plans and event logs instead.

## R1 — Real-time clock and control commits (required)

On a real server, log dispatch musical ticks, committed settings, and scheduled server timestamps for at least eight bars. Verify TempoClock tempo is BPM/60, snare spacing has the intended half-time feel, and no cumulative bar drift arises from incorrect wait arithmetic.

While playing, move each control immediately before and after a bar-boundary snapshot. Assert it commits exactly at the documented next eligible boundary, latest pending value wins, and GUI changes cannot create additional transport Routines. Existing notes may keep their old seconds; newly triggered notes must use the new tempo. Confirm that each chord/bass relationship stays valid after changes.

Trigger New Beat mid-bar, including repeated rapid presses. Before adoption the old plan continues. At the next boundary with a fully prepared plan, the active seed changes, old source voices force-release within 30 ms, new Intro starts at bar zero, and control values persist. The mixer can retain a reverb tail; no old arrangement events occur after adoption. If compile misses a boundary, verify Pending rather than an off-grid start.

Log and investigate late OSC/server failures. Confirm at least two complete arrangement loops via a test-speed clock/event-log integration run; use separate listening at normal tempo rather than treating accelerated playback as the sonic result.

## L1 — Lifecycle/ownership (required)

Record the baseline of project-owned nodes/groups, buses, buffers, hooks, and live scheduler references. Keep an unrelated test synth/group on the shared server to verify scoped cleanup.

1. Launch normally; auto-start after readiness. Launch again during playing and again during boot/loading. Only the latest controller/window can publish playback. No duplicate scheduler survives.
2. Press Play repeatedly: one Routine and one play graph. Run Stop/Play 20 times. Stop drains queued bundles before bus/group reuse; no late notes, monotonic resource growth, or node-not-found bursts. Play restarts the same plan from its intro.
3. Request New Beat repeatedly, then Stop before adoption. No stale compilation callback can restart transport. New Beat while stopped updates the plan and keeps transport stopped.
4. Close the window while playing and while a load is outstanding. Disposal is idempotent; after drain/load completion no project nodes, buffers, buses, responders, or hooks remain. The unrelated synth/group remains intact.
5. CmdPeriod stops scheduling and does not restart automatically. The next explicit Play reconstructs the necessary graph; no references to already-freed nodes are used.
6. Quit/kill the owned test server during playback and during initialization. Show a bounded actionable failure, stop scheduling, and reject callbacks for the old incarnation. On explicit recovery, load fresh resources. Do not free old IDs against a rebooted server.

After Stop, session buffers may remain by design, but play graph/buses/clock must be gone. After Dispose, all project-owned resources must return to baseline. Report actual observed counts, not only expected values. Monitor typical playback for at least five minutes: target peak CPU <50% on the stated reference host and <=64 concurrent voice synths; diagnose failure without silently removing parts. Include host limits in performance claims.

## S1 — Optional asset path/fallback (required code-path checks)

No download is required. Generate a tiny local mono/stereo WAV fixture for tests and a real checksum with an available tool. Verify accepted manifests/load/readiness, sample-rate correction, both channel-specific SynthDefs, and choke behavior. Test missing manifest/file, wrong checksum, malformed row, corrupt audio, unsupported channels/pitched role, loading failure, and delayed completion during disposal. Each rejected optional asset gets one clear warning and the synthesized role. Never leave a silent kit slot or orphaned late buffer.

Actual third-party sample playback/license checks are conditional on importing those assets. Mark them skipped with reason if the shipped catalog is synth-only; this does not skip S1's local fixture/fallback tests.

## G1 — GUI and audible output (required for interactive sign-off)

On an actual desktop with audio output, launch from the documented IDE block without preparatory code. Hear an original musical intro after initialization, then full hook and later section contrast. Verify all labels, defaults, ranges, pending-state feedback, transport behavior, read-only seed/key/section, window close, and readable boot/asset errors. Test two successive normal launches and explicit seed replay.

Do not count a window screenshot, PID, open UDP port, or NRT WAV alone as audible real-time validation. If desktop/device access is unavailable, list G1 as unrun and explain what was verified headlessly.

## M1 — Listening and research review (required for musical sign-off)

Audition three contrasting full beats and both control extremes at normal speed. Assess memorable recurring motif, half-time backbeat, kick/808 separation, lack of machine-gun rolls, musical verse/hook contrast, sensible transitions, absence of clicks/harshness, and space for vocals. Log short concrete notes and any adjustments. If reference recordings are accessible, compare against the named original versions without copying them.

Primary-source research is currently blocked. If access becomes available, record an inspected producer source and which claims it supports. Do not label the numerical templates as historical facts. If listening or research cannot be done, mark the respective item unrun/blocked; automated tests cannot establish authenticity.

## Final report format

Report each suite as passed, failed, skipped/conditional, or unrun/blocked, with actual counts and current-run evidence. Summarize supported OS/runtime, launch steps, verified capabilities, limitations, and any external action needed. No blanket “all tests pass” if any selected required suite is unrun. Optional sample acquisition and blocked historical research must not be disguised as missing core runtime dependencies.
