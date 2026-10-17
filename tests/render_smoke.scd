(
var root, compose, sound, plan, context, bundles, addAt, hookStart, nodeID, target, message;
var duration, score, options, resultDir;
try {
	if(Main.version != "3.14.1") { Error("SuperCollider 3.14.1 required").throw };
	root = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ "..").standardizePath;
	resultDir = root +/+ "test-results";
	File.mkdir(resultDir);
	resultDir = resultDir +/+ "startup-fix";
	File.mkdir(resultDir);
	compose = thisProcess.interpreter.executeFile(root +/+ "lib/Compose.scd");
	sound = thisProcess.interpreter.executeFile(root +/+ "lib/Sound.scd");
	plan = compose[\compile].value(17);
	context = (tempo: 140, intensity: 0.55, buses: (drums: 16, bass: 18, music: 20, send: 22),
		assets: IdentityDictionary.new,
		durations: (kick: 0.11, snare: 0.13, clap: 0.10, hatClosed: 0.043, hatOpen: 0.24,
			perc: 0.06, cymbal: 0.75, bass: 0.1, lead: 0.1, upper: 0.1, pad: 0.1));
	bundles = Dictionary.new;
	addAt = { |time, command| bundles[time] = (bundles[time] ? []).add(command) };
	sound[\definitions].value.do { |definition| addAt.value(0.0, [\d_recv, definition.asBytes]) };
	// The production graph: source groups precede the private stereo master group.
	addAt.value(0.05, [\g_new, 1000, 1, 1, 1001, 1, 1000,
		1002, 1, 1001, 1007, 1, 1002, 1003, 1, 1001, 1004, 1, 1001, 1005, 1, 1000]);
	addAt.value(0.05, [\s_new, \ckgMaster, 1006, 1, 1005,
		\out, 0, \drumBus, 16, \bassBus, 18, \musicBus, 20, \sendBus, 22, \enabled, 1, \level, 0.8]);
	hookStart = plan[\sections].detect { |section| section[\type] == \hook }[\startBar];
	nodeID = 2000;
	8.do { |bar|
		compose[\barView].value(plan, hookStart + bar, (activity: 0.50, intensity: 0.55)).do { |event|
			var time;
			time = 0.1 + (((bar * 4) + (event[\tick] / 96)) * (60 / 140));
			message = sound[\makeMessage].value(event, context, plan);
			if(message[\role] == \hatClosed) { addAt.value(time, [\n_set, 1007, \gate, -1.01]) };
			target = if([\kick, \snare, \clap, \hatClosed, \hatOpen, \perc, \cymbal].includes(message[\role])) {
				if(message[\role] == \hatOpen) { 1007 } { 1002 }
			} { if(message[\role] == \bass) { 1003 } { 1004 } };
			addAt.value(time, [\s_new, message[\patch], nodeID, 1, target] ++ message[\controls]);
			nodeID = nodeID + 1
		}
	};
	duration = 0.1 + (8 * 4 * 60 / 140) + 2.0;
	addAt.value(duration, [\g_freeAll, 1000]);
	score = Score(bundles.keys.asArray.sort.collect { |time| [time] ++ bundles[time] });
	options = ServerOptions.new.numOutputBusChannels_(2).numInputBusChannels_(0);
	// All score timestamps are seconds. This is an isolated test process only.
	TempoClock.default.tempo = 1;
	if(File.exists(resultDir +/+ "smoke.wav")) { File.delete(resultDir +/+ "smoke.wav") };
	score.recordNRT(resultDir +/+ "smoke.osc", resultDir +/+ "smoke.wav",
		sampleRate: 48000, headerFormat: "WAV", sampleFormat: "float", options: options,
		duration: duration, action: { |exitCode|
			"NRT renderer exited %; % voices; expected duration % seconds".format(exitCode, nodeID - 2000, duration).postln;
			exitCode.exit
		})
} { |error| error.reportError; 1.exit };
)
