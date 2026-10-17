# Startup regression check — 2026-10-17, generator 0.1.1

The initial delimiter-only check missed the semicolon/declaration parser errors reported by the user. This revision fixes those errors and the follow-on startup/playback failures found with the real interpreter. Runtime validation is now available on this Linux host using a headless source build of matching **sclang 3.14.1 and scsynth 3.14.1**, plus JACK 1.9.22 with its dummy driver. No physical output device or visible Qt session was used.

## Current-run results

| Check | Actual result | Exit | Evidence |
| --- | --- | --- | --- |
| Module/main compilation, defaults, all 14 SynthDefs, missing/header-only manifest, controller creation/disposal | Passed, **48 assertions** | 0 | [startup.log](startup-fix/startup.log) |
| Basic P1 invariants, A/B forced templates, seed replay, diversity, filtered control extremes | Passed, **604 assertions**, seeds 1–100, 100 distinct musical signatures excluding seed | 0 | [plan.log](startup-fix/plan.log) |
| Eight-bar hook NRT smoke, seed 17, 140 BPM, Activity .50, Intensity .55 | Passed, **170 voice messages**, renderer completed | 0 | [render.log](startup-fix/render.log) |
| Fresh NRT WAV format/duration/signal | Passed: 48 kHz stereo float32, finite/nonzero, peak <=.90, duration within .10 s of 15.814286 s | 0 | [audio-check.log](startup-fix/audio-check.log) |
| Headless real-time smoke: autoplay/output capture, one scheduler, idempotent Play, Stop/Play, control commit, playing/stopped New Beat, cleanup and zero `/fail` replies | Passed, **21 assertions** | 0 | [lifecycle.log](startup-fix/lifecycle.log) |

The render artifact is `test-results/startup-fix/smoke.wav`, generated locally and excluded from Git. Logs are committed. `tests/render_smoke.scd` deletes any previous WAV before rendering, uses the actual compiler/voice adapter/SynthDefs, and sets Score's serialization timebase to one beat/sec in its isolated process. `tests/check_wav.py` reads and checks the rendered samples rather than treating a scheduled renderer as a pass.

## Environment and reproduction

Official source URL: https://github.com/supercollider/supercollider/releases/download/Version-3.14.1/SuperCollider-3.14.1-Source.tar.bz2

Downloaded source SHA-256: `ee640c68777ae697682066ce5c4a8b7e56c5b223e76c79c13b5be5387ee55bb2` (computed from the downloaded file).

The source was built under `/tmp/chiefkeefgen-sc3141/` using GCC 14.2 and CMake 4.4.4, with Qt/IDE, HID, Ableton Link, Supernova, Avahi, X11 plugins and upstream tests disabled; bundled Boost/YAML and the stock internal Green FFT were used. libsndfile and JACK link to the system libraries. These local developer tools and binaries are not project runtime dependencies or committed assets. See README.md for the exact suite commands using an installed 3.14.1 runtime. The real-time runner's JACK daemon and sclang were started in the same sandbox session; the daemon was stopped after the test.

## Remaining acceptance work

These smoke/regression checks do **not** establish complete P1/A1/R1/resource-ownership acceptance. Full-song A/B and extreme-control render matrices, pre-limiter overload/stem analysis, precise boundary/drift instrumentation, full lifecycle stress/resource baselines, generated optional sample-import fixtures, visible macOS/Qt behavior, physical-device playback, and listening review remain **unrun**. Source music research also remains unverified. The numerical waveform/capture results do not imply that audio was heard or that historical authenticity was established.
