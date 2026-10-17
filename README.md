# Chief Keef-inspired drill beat generator

An original, seeded SuperCollider generator for the early Chicago drill sound associated with Young Chop and *Finally Rich*. The 2012–2014 stylistic frame is an influence, not a claim that the numerical templates reconstruct a specific track or historical workflow. The default palette is synthesized and works offline; optional drum one-shots can be added with inspected redistribution rights and SHA-256 values in `assets/manifest.tsv`.

## Requirements and launch

Use **SuperCollider 3.14.1** with scsynth. The Qt GUI needs a Qt-enabled IDE build and an available audio output device. Open `main.scd` in the IDE and evaluate the whole file (Cmd-Return on macOS, Ctrl-Return on Linux/Windows). It boots the server if needed, opens the small window, compiles a fresh composition, and starts playback. Re-evaluating the file disposes the previous controller before launching another.

The window has exactly three musical controls: Tempo (130–150 BPM, default 140), Activity (0–1, default .50), and Intensity (0–1, default .55). Values commit on bar boundaries. Play restarts the current plan after Stop; New Beat prepares a new plan and adopts it at a bar boundary while playing, or replaces the plan while stopped. The source line setting `config[\seed]` can be set to an integer for explicit seed replay. Composition and event choices reproduce for the same generator/settings/catalog; noise synthesis does not promise identical audio samples.

## Layout

`lib/` contains the configuration, composition, synth palette, asset importer, GUI, and lifecycle engine. `assets/manifest.tsv` is intentionally header-only. `tests/plan_tests.scd` is the standalone pure-plan test script; runtime, rendering, GUI, lifecycle stress, and listening checks are tracked in `ACCEPTANCE_TESTS.md`.

From the repository root, run the pure suite with `sclang tests/plan_tests.scd`. Use only a matching 3.14.1 language and server for the complete acceptance plan. This handoff includes no claim that SuperCollider source/runtime, NRT audio, GUI/device behavior, or listening has passed: the current execution host has no `sclang` or `scsynth`, and the official 3.14.1 release page has no Linux binary. See `test-results/current-run.md` for checks actually performed and blocked suites.

## Supported musical choices

The generator makes original natural-minor material with a recurring four-bar motif, two-bar kick templates, tuned mono sub, sparse half-time backbeat, bounded hat variation, restrained fills, and a verse/hook arrangement. The defaults are deliberately conservative. The values and section masks are implementation rules documented in `MUSICAL_SPEC.md`, not measured historical facts. No verified producer interview or reference-track measurement was available during this implementation, so historical research and audition remain unrun.
