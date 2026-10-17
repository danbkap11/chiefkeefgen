# Sound library and asset handling

## Default decision

The complete default palette is synthesized with SuperCollider's standard UGens. No sample download is required. This provides a portable, inspectable baseline; it does not establish that synthesized substitutes sound identical to historical drum samples or commercial presets. Judge the result by listening, especially the clap/snare and lead.

No audio assets were downloaded for this design handoff. There are no verified third-party licenses, source URLs, or sample checksums to list yet. Do not populate the manifest with invented hashes or download a pack merely because its marketing mentions Chief Keef.

## Core palette

| Stable asset/patch ID | Role and recipe | Lifetime and output contract |
| --- | --- | --- |
| synth:kick:v1 | sine with rapid pitch fall roughly 135 to 48 Hz over 40 ms, tiny filtered-noise transient | 80–130 ms amplitude decay, no send, center |
| synth:snare:v1 | filtered noise plus low sine body near 180 Hz, quiet staggered clap transients inside the same patch | combined level bounded, <=300 ms, small reverb send |
| synth:hatClosed:v1 | high-passed noise, optional fixed metallic sine components | 25–60 ms, no low end |
| synth:hatOpen:v1 | same palette with longer decay and modest band shaping | 150–350 ms; exposed gate supports 10 ms choke |
| synth:perc:v1 | short filtered-noise/rim-like accent | <=180 ms, quiet, fixed timbre per song |
| synth:cymbal:v1 | high-passed noise with a darker long decay | <=1.2 s, quiet section accent |
| synth:bass:v1 | tuned sine with restrained second harmonic/saturation, quick initial pitch settling confined to attack | ~8 ms attack, >=20 ms release within planned duration; no reverb; mono |
| synth:leadBrass:v1 | restrained saw/pulse pair, fixed slight detune, low-pass envelope | finite note, >=5 ms attack, <=80 ms release within duration budget |
| synth:leadBell:v1 | sine carrier with low-index fixed-ratio sine FM, quieter partials | finite pluck, short softened attack, <=120 ms release within budget |
| synth:pad:v1 | filtered saw/sine blend, three chord voices maximum, small fixed pan spread | finite notes ending before harmonic change; <=120 ms release included |

Choose leadBrass or leadBell once per seed with equal weight. The optional upper motif uses the same patch with the specified octave/gain mapping. Limit detune to roughly +/-6 cents and keep bass tuning exact. “808” here describes the sustained tuned sub-bass role; it is not a claim to have reproduced a specific drum machine or sample.

All voice amplitude envelopes use `EnvGen` with finite length, `doneAction: Done.freeSelf`, and a connected gate for negative-gate forced release. Do not rely solely on PlayBuf completion to end sample voices; a separate finite amplitude envelope must support choking, replacement, and Stop. Envelope segments must fit short notes, scaling hold/release if needed without negative times. The kick, snare layer sum, saturated bass, and effects return must obey MUSICAL_SPEC's gain staging.

## Optional samples

Samples can improve a clap, snare, hat, kick transient, or rim accent. They replace the corresponding synthetic role rather than doubling its gain. Keep optional acquisition to approximately 6–12 useful one-shots. The entire project must keep working with the optional directory empty.

For v1, import **unpitched drum one-shots only**. Bass and melodic timbres remain synthesized, avoiding hidden root-note and pitch-shift assumptions. The manifest includes root_midi for future extension, but it must be blank for these imports. Reject pitched sample imports with an explicit unsupported-role message rather than playing them out of tune.

Potential discovery locations are [Freesound](https://freesound.org/) (filter individual items for CC0) or the original creator's clearly licensed download page. These are acquisition leads, not vetted assets. A “royalty-free” license may permit use in songs while prohibiting redistribution of the raw one-shot; check the actual terms for each item. Prefer CC0 or an explicit license permitting raw asset redistribution in this repository. Exclude ambiguous ripped kits, extracted song audio, and samples needing credentials at runtime.

Acquisition procedure for Luna, only if useful:

1. Find a specific original asset page and inspect its license. Record direct source/download URL, creator, license name/version/URL, and attribution requirements. If access is denied or rights are unclear, retain the synthesized fallback.
2. Download with TLS verification; obtain individual audio files instead of running installers. Preserve original source/license text. Inspect sample format and content.
3. Compute SHA-256 of the exact imported file. If trimming/resampling, record a new imported-file hash and retain original-file hash/provenance separately. Never copy a checksum from a different file or silently overwrite an existing asset.
4. Add the manifest row and any required attribution/license files. Resolve normalized gain once; do not normalize every launch.
5. Verify both imported playback and missing-file fallback. Optional assets must never become an undocumented startup dependency.

## Manifest format

`assets/manifest.tsv` is UTF-8 tab-separated text with this exact header; it starts with no data rows:

```text
asset_id\trole\tpath\tchannels\tsample_rate\troot_midi\tgain_db\tsource_url\tcreator\tlicense_id\tlicense_url\tattribution\tsha256
```

The displayed `\t` sequences denote actual tab separators in the implemented file. Each row describes one imported file. No tabs/newlines inside a value; no executable sclang, remote script, or JSON library is needed. asset_id must be unique and stable. role is one of kick, snare, hatClosed, hatOpen, perc, cymbal. `path` is relative to assets/, with no traversal outside that directory. `channels` is 1 or 2. `sample_rate` is a positive integer; `root_midi` is blank; `gain_db` is a finite conservative adjustment, initially -6 dB. `sha256` is 64 lowercase hex characters for that file. Attribution may be empty only if the inspected license permits it.

The importer should verify SHA-256 using an available standard OS tool (`sha256sum`, `shasum -a 256`, or PowerShell Get-FileHash) or an explicitly documented equivalent. Optional-import validation may use extra tooling; standard synthesized playback must not depend on it. If file integrity cannot be checked, exclude that optional entry and report it. Cache verified identity with size/mtime for unchanged local files; modification invalidates the cache.

Use WAV PCM16/PCM24 or float32, mono or stereo, 44.1/48 kHz, duration <=2 s. Imports may convert other licensed source formats once, but the imported artifact must meet this contract. Reject empty/corrupt files, >2 channels, implausible rates, unexpected hashes, duplicate IDs, and unsupported roles. Warn once per rejected entry and substitute its synthetic role. A missing or header-only manifest means a valid synthesized-only catalog.

## Loading and playback

Preflight with SoundFile metadata before allocating buffers. `Buffer.read` is asynchronous; collect successful callbacks, inspect loaded frame/channel counts, monitor relevant failures, then sync before publishing the catalog. Bound loading to 10 s per file; track late completions and free their buffers rather than orphaning them. Do not alter the catalog mid-song as files appear. Reload on explicit initialization; display which roles use fallbacks.

Use fixed-channel mono/stereo PlayBuf SynthDefs, `BufRateScale.kr(bufnum)` for natural-speed playback across server rates, and conservative per-asset gain. Downmix stereo drum one-shots to mono when the role is centered; the original channel count still selects the matching SynthDef. Amplitude envelopes cap decay/tails and support forced release. Do not use server buffer numbers as stable asset IDs.

Same seed plus a different asset manifest is not the same timbral input. Record content identities in the plan and test report. Buffer cleanup follows Engine ownership: drain playback before freeing buffers; do not free a buffer while any owned voice or queued bundle can reference it.
