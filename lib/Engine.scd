(
var makeEngine, api;
makeEngine = { |rawConfig, projectRoot, configApi, composeApi, soundApi, assetsApi, uiApi|
	var config, server, app, state, plan, pendingPlan, buffers, catalog, activeControls, pendingControls;
	var rootGroup, sourceGroup, drumsGroup, bassGroup, musicGroup, masterGroup, buses, masterSynth;
	var clock, playRoutine, activeNodes, openHatNodes, playToken, generationToken, loadToken;
	var barIndex, disposed, stopRequested, currentError, window, cmdHook, quitHook, appSeed;
		var eventSerial, transportRoutineCount, compilePending, stopWaiters, startPlayer, finishGraph;

	config = configApi[\validate].value(rawConfig);
	server = config[\server];
	state = \loading;
	plan = nil;
	pendingPlan = nil;
	buffers = IdentityDictionary.new;
	catalog = nil;
	activeControls = IdentityDictionary.new;
	activeControls[\tempo] = config[\tempo];
	activeControls[\activity] = config[\activity];
	activeControls[\intensity] = config[\intensity];
	pendingControls = nil;
	rootGroup = nil; sourceGroup = nil; drumsGroup = nil; bassGroup = nil; musicGroup = nil;
	masterGroup = nil; buses = IdentityDictionary.new; masterSynth = nil;
	clock = nil; playRoutine = nil; activeNodes = Array.new; openHatNodes = Array.new;
	playToken = 0; generationToken = 0; loadToken = 0;
	barIndex = 0; disposed = false; stopRequested = false; currentError = "";
	window = nil; cmdHook = nil; quitHook = nil; appSeed = config[\seed];
	eventSerial = 0; transportRoutineCount = 0; compilePending = false;
	stopWaiters = Array.new;

	app = IdentityDictionary.new;
	app[\projectRoot] = projectRoot.standardizePath;
	app[\version] = "0.1.0";
	app[\seed] = nil;
	app[\state] = { state };
	app[\snapshot] = {
		var output;
		output = IdentityDictionary.new;
		output[\state] = state;
		output[\seed] = if(plan.notNil) { plan[\seed] } { appSeed };
		output[\key] = if(plan.notNil) { plan[\keyName] } { "—" };
		output[\section] = if(plan.notNil) {
			var index, bar;
			index = if(plan[\bars].notEmpty) { barIndex % plan[\bars].size } { 0 };
			bar = if(plan[\bars].notEmpty) { plan[\bars][index] } { nil };
			if(bar.notNil) { "% %/%".format(bar[\sectionType].asString.capitalize, (bar[\localBar] + 1), plan[\sections][bar[\sectionId]][\bars]) } { "—" }
		} { "—" };
		output[\bar] = if(plan.notNil) { (barIndex % plan[\bars].size) + 1 } { 0 };
		output[\totalBars] = if(plan.notNil) { plan[\bars].size } { 0 };
		output[\active] = activeControls.copy;
		output[\pending] = if(pendingControls.notNil) { pendingControls.copy } { nil };
		output[\activity] = activeControls[\activity];
		output[\intensity] = activeControls[\intensity];
		output[\error] = currentError;
		output[\fallbackRoles] = if(catalog.notNil) { catalog[\byRole].keys.select { |role| catalog[\byRole][role].isEmpty }.collect(_.asString) } { [] };
		output[\ownedNodes] = if(rootGroup.notNil) { 1 + activeNodes.size } { 0 };
		output[\ownedBuses] = if(buses.notNil) { buses.size } { 0 };
		output[\schedulerCount] = if(playRoutine.notNil and: { playRoutine.isPlaying }) { 1 } { 0 };
		output
	};
	app[\refresh] = { if(uiApi.notNil) { uiApi[\refresh].value(app) } };

	app[\setPending] = { |control, value|
		var updated, validated;
		if([\tempo, \activity, \intensity].includes(control).not) { Error("unknown musical control %".format(control)).throw };
		updated = activeControls.copy;
		if(pendingControls.notNil) { updated.putAll(pendingControls) };
		updated[control] = value;
		validated = configApi[\validate].value(updated);
		updated = IdentityDictionary.new;
		updated[\tempo] = validated[\tempo]; updated[\activity] = validated[\activity]; updated[\intensity] = validated[\intensity];
		if(state == \playing) { pendingControls = updated } { activeControls = updated; pendingControls = nil };
		app[\refresh].value
	};
	app[\setSeed] = { |seed|
		var validated;
		validated = configApi[\validate].value((seed: seed, tempo: activeControls[\tempo], activity: activeControls[\activity], intensity: activeControls[\intensity]));
		appSeed = validated[\seed];
		app[\newBeat].value(appSeed)
	};

	app[\buildGraph] = {
		var keys;
		if(rootGroup.notNil) { true } {
			keys = [\drums, \bass, \music, \send];
			keys.do { |key| buses[key] = Bus.audio(server, 2) };
			rootGroup = Group.tail(server.defaultGroup);
			sourceGroup = Group.tail(rootGroup);
			drumsGroup = Group.tail(sourceGroup);
			bassGroup = Group.tail(sourceGroup);
			musicGroup = Group.tail(sourceGroup);
			masterGroup = Group.tail(rootGroup);
			masterSynth = Synth(\ckgMaster, [\out, 0, \drumBus, buses[\drums].index, \bassBus, buses[\bass].index,
				\musicBus, buses[\music].index, \sendBus, buses[\send].index, \enabled, 0, \level, 0.8], masterGroup, \addToTail);
			true
		}
	};

	app[\sendEvent] = { |event, tempo, intensity|
		var context, message, target, node, busIndices;
		context = IdentityDictionary.new;
		context[\tempo] = tempo;
		context[\intensity] = intensity;
		busIndices = IdentityDictionary.new;
		[\drums, \bass, \music, \send].do { |key| busIndices[key] = buses[key].index };
		context[\buses] = busIndices;
		context[\durations] = (kick: 0.11, snare: 0.13, clap: 0.10, hatClosed: 0.043, hatOpen: 0.24,
			perc: 0.06, cymbal: 0.75, bass: 0.1, lead: 0.1, upper: 0.1, pad: 0.1);
		context[\assets] = buffers;
		message = soundApi[\makeMessage].value(event, context, plan);
		target = if([\kick, \snare, \clap, \hatClosed, \hatOpen, \perc, \cymbal].includes(message[\role])) {
			drumsGroup
		} { if(message[\role] == \bass) { bassGroup } { musicGroup } };
		node = Synth(message[\patch], message[\controls], target, \addToTail);
		NodeWatcher.register(node);
		activeNodes = activeNodes.add(node);
		if(message[\role] == \hatOpen) { openHatNodes = openHatNodes.add(node) };
		eventSerial = eventSerial + 1;
		node
	};

		startPlayer = { |token|
			var run;
			if((token == playToken) and: { state == \starting } and: { disposed.not }) {
				state = \playing;
				currentError = "";
				barIndex = 0;
				clock = TempoClock(activeControls[\tempo] / 60, 0, 4);
				clock.permanent = false;
				run = Routine({
					var renderedBar, previousTick, uniqueTicks;
					transportRoutineCount = transportRoutineCount + 1;
					while { (token == playToken) and: { state == \playing } } {
						if(pendingControls.notNil) {
							activeControls = pendingControls.copy;
							pendingControls = nil;
							clock.tempo = activeControls[\tempo] / 60
						};
						if(pendingPlan.notNil) {
							var oldNodes;
							plan = pendingPlan;
							pendingPlan = nil;
							barIndex = 0;
							oldNodes = activeNodes.copy;
							server.makeBundle(server.latency, { oldNodes.do { |oldNode| oldNode.set(\gate, -1.03) } });
							activeNodes = oldNodes
						};
						activeNodes = activeNodes.reject { |node| node.isPlaying.not };
						openHatNodes = openHatNodes.reject { |node| node.isPlaying.not };
						renderedBar = composeApi[\barView].value(plan, barIndex % plan[\bars].size, activeControls);
						uniqueTicks = renderedBar.collect { |event| event[\tick] }.as(Set).asArray.sort;
						previousTick = 0;
						uniqueTicks.do { |eventTick|
							var groupEvents;
							if(eventTick > previousTick) { ((eventTick - previousTick) / 96).wait };
							groupEvents = renderedBar.select { |event| event[\tick] == eventTick };
							server.makeBundle(server.latency, {
								if(groupEvents.any { |event| event[\role] == \hatClosed }) {
									openHatNodes.do { |node| node.set(\gate, -1.01) };
									openHatNodes = Array.new
								};
								groupEvents.do { |event| app[\sendEvent].value(event, activeControls[\tempo], activeControls[\intensity]) }
							});
							previousTick = eventTick
						};
						((384 - previousTick) / 96).wait;
						barIndex = (barIndex + 1) % plan[\bars].size;
						app[\refresh].value
					};
					transportRoutineCount = (transportRoutineCount - 1).max(0)
				});
				playRoutine = run;
				run.play(clock, 0);
				app[\refresh].value
				true
			} { false }
		};

		finishGraph = { |finalState|
			if(server.serverRunning and: { rootGroup.notNil }) { rootGroup.free; server.sync };
			buses.values.do { |bus| bus.free };
			buses = IdentityDictionary.new;
			rootGroup = nil; sourceGroup = nil; drumsGroup = nil; bassGroup = nil; musicGroup = nil;
			masterGroup = nil; masterSynth = nil;
			activeNodes = Array.new; openHatNodes = Array.new;
			if(disposed.not) { state = finalState; app[\refresh].value };
			stopWaiters.copy.do(_.value);
			stopWaiters.clear
		};

		app[\start] = {
			var token;
			if(disposed) { Error("this controller has been disposed; evaluate main.scd again").throw };
			if([\playing, \starting].includes(state)) { nil } {
				if(state == \loading) { stopRequested = false; "Play is queued until initialization finishes.".postln } {
					if(state == \ready) {
						state = \starting;
						playToken = playToken + 1;
						token = playToken;
						barIndex = 0;
						app[\refresh].value;
						Routine({
							try {
								app[\buildGraph].value;
								server.sync;
								if((token == playToken) and: { state == \starting } and: { stopRequested.not } and: { disposed.not }) {
									startPlayer.value(token)
								} {
									finishGraph.value(if(disposed) { \disposed } { \ready })
								}
							} { |error|
								currentError = error.errorString;
								finishGraph.value(\error)
							};
						}).play(SystemClock)
					} { Error("cannot play in state %".format(state)).throw }
				}
			};
			app
		};

	app[\stop] = { |done|
		var callback;
		callback = done ? {};
		stopRequested = true;
		if([\starting, \playing, \stopping].includes(state)) {
			if(state == \playing) {
				state = \stopping;
				stopWaiters.add(callback);
				playToken = playToken + 1;
				if(playRoutine.notNil) { playRoutine.stop; playRoutine = nil; transportRoutineCount = 0 };
				if(clock.notNil) { clock.stop; clock = nil };
				if(masterSynth.notNil) { masterSynth.set(\enabled, 0) };
				app[\refresh].value;
				Routine({
					(server.latency.max(config[\latency]) + 0.10).wait;
					finishGraph.value(if(disposed) { \disposed } { \ready })
				}).play(SystemClock)
			} {
				stopWaiters.add(callback);
				if(state == \starting) { state = \stopping; playToken = playToken + 1; app[\refresh].value }
			}
		} { callback.value }
	};

	app[\newBeat] = { |seed=nil|
		var targetSeed, token;
		if(disposed) { Error("controller disposed").throw };
		if(catalog.isNil) { Error("wait for initialization before generating a beat").throw };
		targetSeed = seed ? configApi[\freshSeed].value(if(plan.notNil) { plan[\seed] } { appSeed });
		if(targetSeed.isInteger.not or: { targetSeed < 1 } or: { targetSeed > 2147483646 }) {
			Error("new beat seed is out of range").throw
		};
		if(plan.notNil and: { targetSeed == plan[\seed] } and: { seed.isNil }) { targetSeed = configApi[\freshSeed].value(targetSeed) };
		appSeed = targetSeed;
		generationToken = generationToken + 1;
		token = generationToken;
		compilePending = true;
		app[\refresh].value;
		Routine({
			var newPlan, failures;
			try {
				newPlan = composeApi[\compile].value(targetSeed, catalog[\identity]);
				newPlan = assetsApi[\attachCatalog].value(newPlan, catalog, composeApi);
				failures = composeApi[\validatePlan].value(newPlan);
				if(failures.notEmpty) { Error(failures.join("; ")).throw };
				if((token == generationToken) and: { disposed.not }) {
					if(state == \playing) { pendingPlan = newPlan } { plan = newPlan; pendingPlan = nil; barIndex = 0 };
					currentError = "";
					compilePending = false;
					app[\refresh].value
				}
			} { |error|
				if(token == generationToken) {
					compilePending = false;
					currentError = error.errorString;
					"Beat generation failed: %".format(currentError).warn;
					app[\refresh].value
				}
			}
		}).play(SystemClock);
		app
	};

	app[\dispose] = { |done|
		var finish, priorState;
		finish = done ? {};
		if(disposed) { finish.value } {
			priorState = state;
			disposed = true;
			state = \disposing;
			generationToken = generationToken + 1;
			loadToken = loadToken + 1;
			if(cmdHook.notNil) { CmdPeriod.remove(cmdHook); cmdHook = nil };
			if(quitHook.notNil) { ServerQuit.remove(quitHook, server); quitHook = nil };
			if(window.notNil and: { window.isClosed.not }) { window.close };
			if(uiApi.notNil) { uiApi[\close].value(app) };
			window = nil;
			if([\starting, \playing, \stopping].includes(priorState)) {
				state = priorState;
				app[\stop].value({
					state = \disposed;
					if(buffers.notEmpty and: { server.serverRunning }) { assetsApi[\release].value(buffers, server, { buffers.clear; finish.value }) } { buffers.clear; finish.value }
				});
				state = \disposing
			} {
				state = \disposed;
				if(buffers.notEmpty and: { server.serverRunning }) { assetsApi[\release].value(buffers, server, { buffers.clear; finish.value }) } { buffers.clear; finish.value }
			}
		};
		app
	};

	app[\openUI] = { window = uiApi[\open].value(app); window };
	app[\isCurrentLoad] = { |token| (token == loadToken) and: { disposed.not } };
	app[\initialize] = {
		var token, booted;
		if(Main.version != "3.14.1") {
			currentError = "SuperCollider 3.14.1 is required; this language reports %.".format(Main.version);
			state = \error;
			currentError.warn;
			app[\refresh].value
		} {
			loadToken = loadToken + 1; token = loadToken;
			booted = {
				Routine({
					var readyCondition, loaded;
					try {
						soundApi[\definitions].value.do { |definition| definition.send(server) };
						server.sync;
						catalog = assetsApi[\inspectManifest].value(projectRoot);
						loaded = IdentityDictionary.new;
						if(catalog[\entries].notEmpty) {
							readyCondition = Condition.new(false);
							assetsApi[\loadBuffers].value(server, catalog, token, app[\isCurrentLoad], { |loadedBuffers|
								loaded = loadedBuffers; readyCondition.test = true; readyCondition.signal
							}, { |message|
								currentError = message; readyCondition.test = true; readyCondition.signal
							});
							readyCondition.wait
						};
						if(app[\isCurrentLoad].value(token)) {
							buffers = loaded;
							plan = composeApi[\compile].value(appSeed ? configApi[\freshSeed].value(nil), catalog[\identity]);
							appSeed = plan[\seed];
							plan = assetsApi[\attachCatalog].value(plan, catalog, composeApi);
							if(composeApi[\validatePlan].value(plan).notEmpty) { Error("compiled initial plan failed validation").throw };
							state = \ready;
							cmdHook = { if([\starting, \playing, \stopping].includes(state)) {
								playToken = playToken + 1;
								if(playRoutine.notNil) { playRoutine.stop; playRoutine = nil };
								if(clock.notNil) { clock.stop; clock = nil };
								rootGroup = nil; sourceGroup = nil; drumsGroup = nil; bassGroup = nil; musicGroup = nil;
								masterGroup = nil; masterSynth = nil;
								buses.values.do(_.free); buses = IdentityDictionary.new;
								activeNodes = Array.new; openHatNodes = Array.new;
								if(disposed.not) { state = \ready; "Cmd-. stopped the beat. Press Play to rebuild playback.".postln };
								stopWaiters.copy.do(_.value); stopWaiters.clear;
								app[\refresh].value
							} };
							quitHook = { |quittingServer| if(quittingServer === server) {
								playToken = playToken + 1;
								if(playRoutine.notNil) { playRoutine.stop; playRoutine = nil };
								if(clock.notNil) { clock.stop; clock = nil };
								rootGroup = nil; sourceGroup = nil; drumsGroup = nil; bassGroup = nil; musicGroup = nil;
								masterGroup = nil; masterSynth = nil;
								buses.values.do(_.free); buses = IdentityDictionary.new;
								if(disposed.not) { state = \error; currentError = "audio server stopped; press Play after restarting it" };
								stopWaiters.copy.do(_.value); stopWaiters.clear;
								app[\refresh].value
							} };
							CmdPeriod.add(cmdHook);
							ServerQuit.add(quitHook, server);
							if(config[\gui]) {
								if(Platform.hasQt) { window = uiApi[\open].value(app) } { Error("Qt GUI is not available in this SuperCollider build").throw }
							};
						if(config[\autoplay] and: { stopRequested.not }) { app[\start].value };
						app[\refresh].value
						}
					} { |error|
						state = \error;
						currentError = error.errorString;
						"Initialization failed: %".format(currentError).warn;
						app[\refresh].value
					}
				}).play(SystemClock)
			};
			server.waitForBoot(booted, 100, { |failedServer|
				state = \error;
				currentError = "audio server did not boot after 20 seconds; check its audio device and language/server installation";
				currentError.warn;
				app[\refresh].value;
				false
			}, SystemClock)
		}
	};
	app[\newBeat] = app[\newBeat];
	app[\start] = app[\start];
	app[\play] = app[\start];
	app[\cancelInitialization] = { loadToken = loadToken + 1; generationToken = generationToken + 1; nil };
	app
};

	var api;
api = IdentityDictionary.new;
api[\new] = makeEngine;
api
)
