(
var root, configApi, compose, sound, assets, engine, config, server, controller;
var assertions, check, waitFor, capture, captured, captureDone, initialSeed, wantedSeed, failures, failureListener;
root = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ "..").standardizePath;
assertions = 0;
check = { |condition, message|
	if(condition.not) { Error(message).throw };
	assertions = assertions + 1
};
waitFor = { |predicate, seconds, message|
	var start;
	start = Main.elapsedTime;
	while { predicate.value.not and: { (Main.elapsedTime - start) < seconds } } { 0.05.wait };
	check.value(predicate.value, message)
};
Routine({
	try {
		check.value(Main.version == "3.14.1", "SuperCollider 3.14.1 required");
		configApi = thisProcess.interpreter.executeFile(root +/+ "lib/Config.scd");
		compose = thisProcess.interpreter.executeFile(root +/+ "lib/Compose.scd");
		sound = thisProcess.interpreter.executeFile(root +/+ "lib/Sound.scd");
		assets = thisProcess.interpreter.executeFile(root +/+ "lib/Assets.scd");
		engine = thisProcess.interpreter.executeFile(root +/+ "lib/Engine.scd");
		server = Server(\ckgSmoke, NetAddr("127.0.0.1", 57141),
			ServerOptions.new.numOutputBusChannels_(2).numInputBusChannels_(0).sampleRate_(48000));
		failures = List.new;
		failureListener = OSCFunc({ |message| failures.add(message.copy) }, '/fail', server.addr);
		config = configApi[\validate].value((seed: 17, gui: false, autoplay: true, server: server));
		controller = engine[\new].value(config, root, configApi, compose, sound, assets, nil);
		controller[\initialize].value;
		waitFor.value({ controller[\state].value == \playing }, 20, "autoplay did not reach Playing");
		initialSeed = controller[\snapshot].value[\seed];
		check.value(controller[\snapshot].value[\schedulerCount] == 1, "exactly one transport");
		controller[\start].value;
		check.value(controller[\snapshot].value[\schedulerCount] == 1, "Play is idempotent");
		capture = Buffer.alloc(server, 48000, 2);
		SynthDef(\ckgSmokeCapture, { |buf=0|
			RecordBuf.ar(In.ar(0, 2), buf, loop: 0, doneAction: 2)
		}).send(server);
		server.sync;
		Synth.tail(server.defaultGroup, \ckgSmokeCapture, [\buf, capture.bufnum]);
		1.1.wait;
		captureDone = false;
		capture.loadToFloatArray(action: { |data| captured = data; captureDone = true });
		waitFor.value({ captureDone }, 5, "output capture did not complete");
		capture.free; capture = nil; server.sync;
		controller[\stop].value;
		waitFor.value({ controller[\state].value == \ready }, 5, "Stop did not drain/release its graph");
		check.value(controller[\snapshot].value[\ownedBuses] == 0, "Stop leaked audio buses");
		check.value(captured.abs.maxItem > 0.0001, "production real-time master output is silent");
		check.value(captured.abs.maxItem <= 0.9, "production output exceeds peak ceiling");
		"REAL-TIME CAPTURE: peak %; % samples".format(captured.abs.maxItem, captured.size).postln;
		controller[\start].value;
		waitFor.value({ controller[\state].value == \playing }, 5, "Play after Stop failed");
		check.value(controller[\snapshot].value[\seed] == initialSeed, "Play changed the current seed");
		controller[\setPending].value(\tempo, 145);
		controller[\setPending].value(\activity, 1);
		check.value(controller[\snapshot].value[\active][\tempo] == 140, "tempo committed inside a bar");
		waitFor.value({ controller[\snapshot].value[\active][\tempo] == 145 }, 4, "next-bar tempo did not commit");
		check.value(controller[\snapshot].value[\active][\activity] == 1, "controls did not commit together");
		wantedSeed = 42;
		controller[\newBeat].value(wantedSeed);
		waitFor.value({ controller[\snapshot].value[\seed] == wantedSeed }, 5, "New Beat did not adopt its prepared plan");
		check.value(controller[\snapshot].value[\active][\tempo] == 145, "New Beat changed the controls");
		controller[\stop].value;
		waitFor.value({ controller[\state].value == \ready }, 5, "second Stop failed");
		controller[\newBeat].value(43);
		waitFor.value({ controller[\snapshot].value[\seed] == 43 }, 5, "stopped New Beat did not replace its plan");
		check.value(controller[\state].value == \ready, "stopped New Beat started playback");
		controller[\dispose].value;
		check.value(controller[\state].value == \disposed, "dispose failed");
		server.sync;
		check.value(failures.isEmpty, "server reported failed OSC commands: " ++ failures.asString);
		failureListener.free;
		"LIFECYCLE SMOKE PASSED: % assertions".format(assertions).postln;
		server.quit;
		0.3.wait;
		0.exit
	} { |error|
		error.reportError;
		if(failureListener.notNil) { failureListener.free };
		if(controller.notNil) { controller[\dispose].value };
		if(capture.notNil) { capture.free };
		if(server.notNil) { server.quit };
		"LIFECYCLE SMOKE FAILED after % assertions".format(assertions).postln;
		0.3.wait;
		1.exit
	}
}).play(SystemClock);
)
