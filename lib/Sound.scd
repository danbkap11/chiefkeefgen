(
var definitions, makeMessage, baseGains, pitchPatches, rolePatches, api;
baseGains = IdentityDictionary.new;
baseGains[\kick] = 0.22; baseGains[\snare] = 0.115; baseGains[\clap] = 0.025;
baseGains[\hatClosed] = 0.035; baseGains[\hatOpen] = 0.04; baseGains[\perc] = 0.035;
baseGains[\cymbal] = 0.025; baseGains[\bass] = 0.18; baseGains[\lead] = 0.07;
baseGains[\upper] = 0.018; baseGains[\pad] = 0.035;

definitions = {
	var defs;
	defs = Array.new;
	defs = defs.add(SynthDef(\ckgKick, { |out=0, gate=1, amp=0.22, dur=0.11|
		var env, pitch, tone, click, sig;
		env = EnvGen.kr(Env.perc(0.001, dur.max(0.03), 1, -4), gate, doneAction: Done.freeSelf);
		pitch = EnvGen.kr(Env([2.5, 1, 0.86], [0.034, 0.045], \exp));
		tone = SinOsc.ar(51 * pitch);
		click = BPF.ar(WhiteNoise.ar(0.35), 2400, 0.65) * EnvGen.kr(Env.perc(0.0005, 0.008));
		sig = (tone + click) * env * amp;
		Out.ar(out, Pan2.ar(LeakDC.ar(sig), 0))
	}));
	defs = defs.add(SynthDef(\ckgSnare, { |out=0, gate=1, amp=0.115, dur=0.13|
		var env, noiseEnv, body, noise, sig;
		env = EnvGen.kr(Env.perc(0.001, dur.max(0.03), 1, -4), gate, doneAction: Done.freeSelf);
		noiseEnv = EnvGen.kr(Env.perc(0.001, 0.12, 1, -5));
		noise = BPF.ar(WhiteNoise.ar, 2100, 0.72) * noiseEnv;
		body = SinOsc.ar(180) * EnvGen.kr(Env.perc(0.001, 0.07, 1, -5));
		sig = (noise * 0.82 + body * 0.18) * env * amp;
		Out.ar(out, Pan2.ar(LeakDC.ar(sig), 0))
	}));
	defs = defs.add(SynthDef(\ckgClap, { |out=0, gate=1, amp=0.025, dur=0.10, pan=0|
		var env, source, taps, sig;
		env = EnvGen.kr(Env.perc(0.001, dur.max(0.025), 1, -5), gate, doneAction: Done.freeSelf);
		source = HPF.ar(WhiteNoise.ar, 1300);
		taps = DelayN.ar(source, 0.018, [0, 0.006, 0.013]).sum * 0.333;
		sig = taps * EnvGen.kr(Env.perc(0.001, 0.085, 1, -5)) * env * amp;
		Out.ar(out, Pan2.ar(sig, pan))
	}));
	defs = defs.add(SynthDef(\ckgHatClosed, { |out=0, gate=1, amp=0.035, dur=0.043, pan=0|
		var env, metallic, sig;
		env = EnvGen.kr(Env.perc(0.0005, dur.max(0.008), 1, -6), gate, doneAction: Done.freeSelf);
		metallic = Mix(SinOsc.ar([6380, 8720, 11310], 0, [0.18, 0.1, 0.07]));
		sig = HPF.ar(WhiteNoise.ar(0.6) + metallic, 4800);
		Out.ar(out, Pan2.ar(sig * env * amp, pan))
	}));
	defs = defs.add(SynthDef(\ckgHatOpen, { |out=0, gate=1, amp=0.04, dur=0.24, pan=0|
		var env, metallic, sig;
		env = EnvGen.kr(Env.perc(0.001, dur.max(0.04), 1, -5), gate, doneAction: Done.freeSelf);
		metallic = Mix(SinOsc.ar([6380, 8720, 11310], 0, [0.18, 0.1, 0.07]));
		sig = HPF.ar(WhiteNoise.ar(0.48) + metallic, 4300);
		Out.ar(out, Pan2.ar(sig * env * amp, pan))
	}));
	defs = defs.add(SynthDef(\ckgPerc, { |out=0, gate=1, amp=0.035, dur=0.06, pan=0.15|
		var env, sig;
		env = EnvGen.kr(Env.perc(0.001, dur.max(0.012), 1, -5), gate, doneAction: Done.freeSelf);
		sig = BPF.ar(PinkNoise.ar, 1450, 0.28) + (SinOsc.ar(820) * EnvGen.kr(Env.perc(0.001, 0.022)) * 0.3);
		Out.ar(out, Pan2.ar(sig * env * amp, pan))
	}));
	defs = defs.add(SynthDef(\ckgCymbal, { |out=0, gate=1, amp=0.025, dur=0.75|
		var env, sig;
		env = EnvGen.kr(Env.perc(0.002, dur.max(0.08), 1, -4), gate, doneAction: Done.freeSelf);
		sig = HPF.ar(WhiteNoise.ar, 3900) + Mix(SinOsc.ar([4900, 6540, 8100], 0, [0.09, 0.07, 0.06]));
		Out.ar(out, Pan2.ar(sig * env * amp, 0))
	}));
	defs = defs.add(SynthDef(\ckgBass, { |out=0, gate=1, amp=0.18, freq=55, dur=0.28, pan=0|
		var env, settle, fundamental, harmonic, sig;
		env = EnvGen.kr(Env.perc(0.005, (dur - 0.005).max(0.018), 1, -4), gate, doneAction: Done.freeSelf);
		settle = EnvGen.kr(Env([1.12, 1, 1], [0.008, 0.008]));
		fundamental = SinOsc.ar(freq * settle);
		harmonic = SinOsc.ar((freq * 2) * settle) * 0.12;
		sig = ((fundamental + harmonic) * 2).tanh * 0.5 * env * amp;
		Out.ar(out, Pan2.ar(LeakDC.ar(sig), 0))
	}));
	defs = defs.add(SynthDef(\ckgLeadBrass, { |out=0, send=0, gate=1, amp=0.07, freq=440, dur=0.38, pan=0, cutoff=1600|
		var env, oscillator, sig;
		env = EnvGen.kr(Env.perc(0.005, (dur - 0.005).max(0.03), 1, -4), gate, doneAction: Done.freeSelf);
		oscillator = (Saw.ar(freq * [0.996, 1.004]).sum * 0.36) + (Pulse.ar(freq * 0.5, 0.48) * 0.12);
		sig = LPF.ar(oscillator, cutoff.clip(400, 10000)) * env * amp;
		Out.ar(out, Pan2.ar(sig, pan));
		Out.ar(send, Pan2.ar(sig * 0.22, pan))
	}));
	defs = defs.add(SynthDef(\ckgLeadBell, { |out=0, send=0, gate=1, amp=0.07, freq=440, dur=0.36, pan=0, cutoff=1600|
		var env, modulator, carrier, sig;
		env = EnvGen.kr(Env.perc(0.006, dur.max(0.03), 1, -5), gate, doneAction: Done.freeSelf);
		modulator = SinOsc.ar(freq * 2.4, 0, freq * 0.035);
		carrier = SinOsc.ar(freq + modulator) + (SinOsc.ar(freq * 2) * 0.14);
		sig = LPF.ar(carrier, cutoff.clip(400, 10000)) * env * amp;
		Out.ar(out, Pan2.ar(sig, pan));
		Out.ar(send, Pan2.ar(sig * 0.22, pan))
	}));
	defs = defs.add(SynthDef(\ckgPad, { |out=0, send=0, gate=1, amp=0.035, freq=220, dur=0.85, pan=0, cutoff=1200|
		var env, saw, tone, sig;
		env = EnvGen.kr(Env.linen(0.004, (dur - 0.012).max(0.008), 0.008, 1, \sine), gate, doneAction: Done.freeSelf);
		saw = Saw.ar(freq) * 0.16;
		tone = SinOsc.ar(freq) * 0.55;
		sig = LPF.ar(saw + tone, cutoff.clip(400, 5000)) * env * amp;
		Out.ar(out, Pan2.ar(sig, pan));
		Out.ar(send, Pan2.ar(sig * 0.42, pan))
	}));
	defs = defs.add(SynthDef(\ckgSampleMono, { |out=0, gate=1, amp=0.035, bufnum=0, rate=1, dur=0.3, pan=0|
		var env, source;
		env = EnvGen.kr(Env.perc(0.001, dur.max(0.025), 1, -5), gate, doneAction: Done.freeSelf);
		source = PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum) * rate, doneAction: 0);
		Out.ar(out, Pan2.ar(source * env * amp, pan))
	}));
	defs = defs.add(SynthDef(\ckgSampleStereo, { |out=0, gate=1, amp=0.035, bufnum=0, rate=1, dur=0.3|
		var env, source;
		env = EnvGen.kr(Env.perc(0.001, dur.max(0.025), 1, -5), gate, doneAction: Done.freeSelf);
		source = PlayBuf.ar(2, bufnum, BufRateScale.kr(bufnum) * rate, doneAction: 0);
		Out.ar(out, source * env * amp)
	}));
	defs = defs.add(SynthDef(\ckgMaster, { |out=0, drumBus=0, bassBus=2, musicBus=4, sendBus=6, level=0.8, enabled=1|
		var drums, bass, music, send, reverb, sig;
		drums = In.ar(drumBus, 2);
		bass = In.ar(bassBus, 2);
		music = In.ar(musicBus, 2);
		send = In.ar(sendBus, 2);
		reverb = FreeVerb2.ar(send[0], send[1], 1, 0.35, 0.6);
		sig = drums + bass + music + (reverb * 0.12);
		sig = HPF.ar(LeakDC.ar(sig), 20) * Lag.kr(enabled.clip(0, 1), 0.03) * level;
		Out.ar(out, Limiter.ar(sig, 0.89, 0.01))
	}));
	defs
};

pitchPatches = IdentityDictionary.new;
pitchPatches[\lead] = { |plan|
	if(plan[\paletteId] == \leadBrass) { \ckgLeadBrass } { \ckgLeadBell }
};
pitchPatches[\upper] = { |plan|
	if(plan[\paletteId] == \leadBrass) { \ckgLeadBrass } { \ckgLeadBell }
};
rolePatches = IdentityDictionary.new;
rolePatches[\kick] = \ckgKick; rolePatches[\snare] = \ckgSnare; rolePatches[\clap] = \ckgClap;
rolePatches[\hatClosed] = \ckgHatClosed; rolePatches[\hatOpen] = \ckgHatOpen;
rolePatches[\perc] = \ckgPerc; rolePatches[\cymbal] = \ckgCymbal;
rolePatches[\bass] = \ckgBass; rolePatches[\pad] = \ckgPad;

makeMessage = { |item, context, plan|
	var patch, frequency, duration, amp, cutoff, pan, controls, outBus, sendBus, role, pitches, asset;
	role = item[\role];
	patch = rolePatches[role];
	if([\lead, \upper].includes(role)) { patch = pitchPatches[role].value(plan) };
	asset = if(item[\assetId].notNil) { context[\assets][item[\assetId]] } { nil };
	if(asset.notNil) {
		patch = if(asset[\channels] == 1) { \ckgSampleMono } { \ckgSampleStereo };
		amp = (baseGains[role] ? 0.035) * item[\velocity] * asset[\gain];
	};
	if(patch.isNil) { Error("no SynthDef for role %".format(item[\role])).throw };
	frequency = if(item[\midi].notNil) { item[\midi].midicps } { 440 };
	duration = if(item[\lengthTicks].notNil) { (item[\lengthTicks] / 96) * (60 / context[\tempo]) } { context[\durations][role] ? 0.1 };
	if(asset.notNil) { duration = duration.min(asset[\duration]) };
	amp = if(asset.notNil) { (baseGains[role] ? 0.035) * item[\velocity] * asset[\gain] } { (baseGains[role] ? 0.035) * item[\velocity] };
	cutoff = if(role == \pad) { 400 * (7.5 ** context[\intensity]) } { 600 * (10 ** context[\intensity]) };
	pan = item[\pan];
	outBus = context[\buses][if([\kick, \snare, \clap, \hatClosed, \hatOpen, \perc, \cymbal].includes(role)) { \drums } { if(role == \bass) { \bass } { \music } }];
	sendBus = context[\buses][\send];
	controls = [\out, outBus, \gate, 1, \amp, amp, \dur, duration];
	pitches = [\bass, \lead, \upper, \pad].includes(role);
	if(pitches) { controls = controls ++ [\freq, frequency] };
	if([\clap, \hatClosed, \hatOpen, \perc, \bass, \lead, \upper, \pad].includes(role)) { controls = controls ++ [\pan, pan] };
	if([\lead, \upper, \pad].includes(role)) { controls = controls ++ [\cutoff, cutoff] };
	if([\lead, \upper, \pad].includes(role)) { controls = controls ++ [\send, sendBus] };
	if(asset.notNil) { controls = controls ++ [\bufnum, asset[\buffer].bufnum, \rate, 1] };
	(patch: patch, controls: controls, role: role, eventId: item[\id])
};

api = IdentityDictionary.new;
api[\definitions] = definitions;
api[\makeMessage] = makeMessage;
api[\baseGains] = baseGains;
api
)
