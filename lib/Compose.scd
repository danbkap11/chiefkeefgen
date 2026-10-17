(
var compile, validatePlan, canonical, barView, keyNames, api;
keyNames = ["C", "C#", "D", "Eb", "E", "F", "F#", "G", "Ab", "A", "Bb", "B"];

compile = { |seed, catalogIdentity="synth-core-v1", arrangementOverride=nil|
	var build, plan;
	build = Routine({
		var tonicPc, scale, progression, kickTemplates, kickTemplateId, kickTemplate;
		var motifTemplates, motifTemplateId, motifRhythm, motifDegrees, motifCount;
		var leadPatch, sectionTemplates, sections, totalBars, bars, incomingCymbal;
		var eventId, tonicOffset, degreeOffset, foldPitch, makeEvent;
		var barIndex, section, localBar, chordIndex, chordRootDegree, chordPitchClasses;
		var events, kickOnsets, bassOnsets, hats, hatsExtra, hatsSixteenth, openChoice;
		var percChoices, activeDrums, activeBass, activeLead, activePad, outroHalf;
		var gesture, eligibleGesture, rhythmBar, onsetIndex, onset, nextOnset, duration;
		var bassExtraCount, shuffled, padDegrees, midi, midiList, midiCandidates;
		var sectionRecord, sectionArrays, eventArrays, canonicalArray, id;
		var progressIndex, noteDegree, noteOffset, pitchClass, swing, rollTicks;

		thisThread.randSeed = seed;
		scale = [0, 2, 3, 5, 7, 8, 10];
		tonicPc = [0, 2, 5, 7, 9, 10].choose;
		progression = if(1.0.rand < 0.65) { [0, 0, 5, 5] } { [0, 5, 2, 6] };
		kickTemplates = [
			[[0, 144, 264], [0, 120, 240, 336]],
			[[0, 168, 288], [0, 96, 264]],
			[[0, 120, 336], [0, 144, 288]]
		];
		kickTemplateId = [\K1, \K2, \K3].choose;
		kickTemplate = kickTemplates[[\K1, \K2, \K3].indexOf(kickTemplateId)];
		motifTemplates = [
			[[0, 144, 288], [0, 240], [0, 144, 288], [96, 288]],
			[[0, 192], [48, 192, 288], [0, 192], [48, 240]],
			[[0, 96, 288], [96, 288], [0, 96, 288], [192]]
		];
		motifTemplateId = [\A, \B, \C].choose;
		motifRhythm = motifTemplates[[\A, \B, \C].indexOf(motifTemplateId)];
		motifCount = motifRhythm.collect(_.size).sum;
		motifDegrees = Array.fill(motifCount) { [0, 0, 2, 2, 4].choose };
		motifDegrees[0] = 0;
		leadPatch = if(1.0.rand < 0.5) { \leadBrass } { \leadBell };
		swing = [0, 2, 4].choose;

		sectionTemplates = [
			[
				[\intro, 8], [\hook, 16], [\verse, 16],
				[\hook, 16], [\verse, 16], [\hook, 16], [\outro, 8]
			],
			[
				[\intro, 4], [\hook, 16], [\verse, 16],
				[\hook, 16], [\verse, 16], [\hook, 8], [\outro, 4]
			]
		];
		id = if(arrangementOverride.isNil) {
			if(1.0.rand < 0.8) { 0 } { 1 }
		} {
			if(arrangementOverride == \A or: { arrangementOverride == 0 }) { 0 } {
				if(arrangementOverride == \B or: { arrangementOverride == 1 }) { 1 } {
					Error("arrangementOverride must be A, B, 0, or 1").throw
				}
			}
		};
		sectionTemplates = sectionTemplates[id];
		sections = Array.new;
		totalBars = 0;
		sectionTemplates.do { |item|
			sections = sections.add((id: sections.size, type: item[0], startBar: totalBars, bars: item[1]));
			totalBars = totalBars + item[1]
		};

		tonicOffset = { |degree| scale.wrapAt(degree % 7) + (degree.div(7) * 12) };
		degreeOffset = { |degree| tonicPc + tonicOffset.value(degree) };
		foldPitch = { |value, low, high|
			var result;
			result = value;
			while { result < low } { result = result + 12 };
			while { result > high } { result = result - 12 };
			result
		};
		eventId = 0;
		makeEvent = { |tick, role, midiValue=nil, lengthTicks=nil, velocity=0.7, minActivity=0.0, minIntensity=0.0, patch=nil, pan=0.0|
			var item;
			item = IdentityDictionary.new;
			item[\id] = eventId;
			item[\tick] = tick.asInteger;
			item[\role] = role;
			item[\patchId] = patch ? role;
			item[\assetId] = nil;
			item[\midi] = midiValue;
			item[\lengthTicks] = lengthTicks;
			item[\velocity] = velocity.asFloat.round(0.000001);
			item[\pan] = pan.asFloat.round(0.000001);
			item[\minActivity] = minActivity.asFloat.round(0.000001);
			item[\minIntensity] = minIntensity.asFloat.round(0.000001);
			eventId = eventId + 1;
			item
		};

		bars = Array.newClear(totalBars);
		incomingCymbal = false;
		barIndex = 0;
		sections.do { |sectionRecord|
			sectionRecord[\bars].do { |unused|
				var newSection, sectionLocal, isFillBar, bassSelection, dropFill;
				var allowedHats, selectedPerc, melodyOn, shouldUsePad, shouldUseBass;
				var roleList, degreesNow, pitchOptions, chordRootPitch;

				localBar = barIndex - sectionRecord[\startBar];
				newSection = (localBar == 0);
				activeDrums = [\hook, \verse].includes(sectionRecord[\type]) or: {
					(sectionRecord[\type] == \outro) and: { localBar < sectionRecord[\bars].div(2) }
				};
				activeBass = activeDrums;
				activeLead = sectionRecord[\type] != \outro or: { localBar < sectionRecord[\bars].div(2) };
				activePad = [\hook, \verse, \intro].includes(sectionRecord[\type]) or: {
					(sectionRecord[\type] == \outro) and: { localBar < sectionRecord[\bars].div(2) }
				};
				if(sectionRecord[\type] == \verse) { activeLead = (localBar % 4) < 2 };
				isFillBar = [\hook, \verse].includes(sectionRecord[\type]) and: { localBar % 8 == 7 };
				gesture = if(isFillBar) { [\dropout, \hatRoll, \cymbal].choose } { nil };
			events = Array.new;
				chordIndex = (localBar.div(2)) % 4;
				chordRootDegree = progression[chordIndex];
				chordRootPitch = degreeOffset.value(chordRootDegree);
				chordPitchClasses = [0, 2, 4].collect { |degree| (tonicPc + tonicOffset.value(chordRootDegree + degree)) % 12 };

				if(incomingCymbal) { events = events.add(makeEvent.value(0, \cymbal, nil, nil, 0.38, 0, 0, \cymbal)) };
				incomingCymbal = false;

				if(activeDrums) {
					kickOnsets = kickTemplate[localBar % 2].copy;
					dropFill = (gesture == \dropout);
					kickOnsets.do { |tick|
						if(dropFill.not or: { tick < 336 }) {
							events = events.add(makeEvent.value(tick, \kick, nil, nil, if(tick == 0) { 0.95 } { 0.78 }, 0, 0, \kick))
						}
					};
					if([\hook, \verse].includes(sectionRecord[\type]) or: { sectionRecord[\type] == \outro }) {
						events = events.add(makeEvent.value(192, \snare, nil, nil, 0.85, 0, 0, \snare));
						events = events.add(makeEvent.value(192, \clap, nil, nil, 0.44, 0, 0, \clap, -0.04))
					};
					bassOnsets = [0];
					bassSelection = kickOnsets.copyRange(1, kickOnsets.size - 1).scramble;
					bassExtraCount = if(bassSelection.size >= 2) { 2 } { bassSelection.size };
					bassOnsets = bassOnsets ++ bassSelection.keep(bassExtraCount);
					bassOnsets = bassOnsets.as(Set).asArray.sort;
					bassOnsets.do { |tick|
						var position, following, chosenLength, pitch;
						position = bassOnsets.indexOf(tick);
						following = if(position < (bassOnsets.size - 1)) { bassOnsets[position + 1] } { 384 };
						chosenLength = [96, 144, 192, 240, 288].choose.min(following - tick).min(384 - tick);
						pitch = foldPitch.value(28 + ((tonicPc + tonicOffset.value(chordRootDegree)) - 28).mod(12), 28, 43);
						if(dropFill and: { tick >= 336 }) { nil } {
							events = events.add(makeEvent.value(tick, \bass, pitch, chosenLength, if(tick == 0) { 0.95 } { 0.74 }, 0, 0, \bass, 0))
						}
					}
				};

				allowedHats = if(sectionRecord[\type] == \intro) {
					if(localBar >= sectionRecord[\bars].div(2)) { [0, 192] } { [] }
				} {
					if(sectionRecord[\type] == \outro) {
						if(localBar >= sectionRecord[\bars].div(2)) { [0, 192] } { [0, 96, 192, 288] }
					} { [0, 96, 192, 288] }
				};
				allowedHats.do { |tick, index|
					events = events.add(makeEvent.value(tick, \hatClosed, nil, nil, if(index.even) { 0.92 } { 0.58 }, 0, 0, \hatClosed))
				};
				if([\hook, \verse].includes(sectionRecord[\type])) {
				hats = [48, 144, 240, 336];
					hats.do { |tick|
						events = events.add(makeEvent.value((tick + swing).min(383), \hatClosed, nil, nil, 0.51, 0.25, 0, \hatClosed))
					};
					hatsSixteenth = [24, 72, 120, 168, 216, 264, 312, 360].scramble.keep(4).sort;
					hatsSixteenth.do { |tick|
						events = events.add(makeEvent.value(tick, \hatClosed, nil, nil, 0.37, 0.65, 0, \hatClosed))
					};
					if((sectionRecord[\type] == \hook) or: { localBar.even }) {
						openChoice = [144, 336].choose;
						events = events.add(makeEvent.value(openChoice, \hatOpen, nil, nil, 0.44, 0.65, 0, \hatOpen))
					};
					percChoices = [48, 240, 336].scramble.keep(2).sort;
					percChoices.do { |tick|
						events = events.add(makeEvent.value(tick, \perc, nil, nil, 0.30, 0.65, 0, \perc))
					}
				};
				if(gesture == \hatRoll) {
					rollTicks = [288, 312, 336, 360];
					rollTicks.do { |tick|
						events = events.add(makeEvent.value(tick, \hatClosed, nil, nil, 0.34, 0.85, 0, \hatClosed))
					}
				};

				if(activePad) {
					degreesNow = [chordRootDegree, chordRootDegree + 2, chordRootDegree + 4];
					midiList = degreesNow.collect { |degree|
						var result;
						result = 48 + degreeOffset.value(degree);
						while { result > 72 } { result = result - 12 };
						while { result < 48 } { result = result + 12 };
						result
					}.sort;
					midiList.do { |note, voice|
						events = events.add(makeEvent.value(0, \pad, note, 360, if(sectionRecord[\type] == \outro) { 0.17 } { 0.33 }, 0, 0, \pad, [-0.12, 0, 0.12][voice]))
					}
				};

				if(activeLead) {
					rhythmBar = localBar % 4;
					hats = motifRhythm[rhythmBar];
					hats.do { |tick, noteIndex|
						var flatIndex, nextTick, degree, frequencyOffset, targetPitch, noteTicks;
						flatIndex = motifRhythm.keep(rhythmBar).collect(_.size).sum;
						flatIndex = flatIndex + noteIndex;
						degree = chordRootDegree + motifDegrees[flatIndex];
						frequencyOffset = tonicOffset.value(degree);
						targetPitch = foldPitch.value(60 + tonicPc + frequencyOffset, 60, 84);
						nextTick = if(noteIndex < (hats.size - 1)) { hats[noteIndex + 1] } { 384 };
						noteTicks = [48, 96, 144].choose.min(nextTick - tick).min(384 - tick);
						events = events.add(makeEvent.value(tick, \lead, targetPitch, noteTicks,
							[0.88, 0.63, 0.76, 0.55].wrapAt(flatIndex % 4), 0, 0, leadPatch, 0))
					}
				};
				if(sectionRecord[\type] == \hook) {
					// Upper-layer candidates are always present in the plan; Intensity gates them at playback.
					events = events.reject { |item| item[\role] == \upper };
					events.copy.do { |item|
						if(item[\role] == \lead and: { item[\midi] <= 84 }) {
							events = events.add(makeEvent.value(item[\tick], \upper, item[\midi] + 12, item[\lengthTicks], 0.18, 0, 0.65, leadPatch, 0))
						}
					}
				};
				if(gesture == \cymbal) { incomingCymbal = true };
				if(activeDrums.not) {
					// Intro/outro use only the deliberately sparse quarter-note hat grid.
					events = events.reject { |item| [\hatOpen, \perc].includes(item[\role]) }
				};
				events = events.sort { |a, b| if(a[\tick] == b[\tick]) { a[\id] < b[\id] } { a[\tick] < b[\tick] } };
				bars[barIndex] = (index: barIndex, sectionId: sectionRecord[\id], sectionType: sectionRecord[\type], localBar: localBar,
					chordRootDegree: chordRootDegree, gesture: gesture, candidates: events);
				barIndex = barIndex + 1;
			}
		};

		plan = IdentityDictionary.new;
		plan[\schemaVersion] = 1;
		plan[\generatorVersion] = "0.1.1";
		plan[\seed] = seed;
		plan[\tonicPc] = tonicPc;
		plan[\keyName] = keyNames[tonicPc];
		plan[\scale] = scale;
		plan[\ticksPerBeat] = 96;
		plan[\ticksPerBar] = 384;
		plan[\harmonicDegrees] = progression;
		plan[\motif] = (templateId: motifTemplateId, rhythm: motifRhythm, degrees: motifDegrees);
		plan[\kickTemplateId] = kickTemplateId;
		plan[\paletteId] = leadPatch;
		plan[\swingTicks] = swing;
		plan[\sections] = sections;
		plan[\bars] = bars;
		plan[\assetIdentities] = [catalogIdentity.asString, "synth-core-v1"].as(Set).asArray.sort;
		plan[\canonicalPlan] = nil;
		plan[\canonicalPlan] = canonical.value(plan);
		plan.yield;
	});
	build.next
};

canonical = { |plan|
	var sectionRows, barRows, eventRows;
	sectionRows = plan[\sections].collect { |section|
		[section[\id], section[\type].asString, section[\startBar], section[\bars]]
	};
	barRows = plan[\bars].collect { |bar|
		eventRows = bar[\candidates].collect { |item|
			[item[\id], item[\tick], item[\role].asString, item[\patchId].asString, item[\assetId], item[\midi],
				item[\lengthTicks], item[\velocity].round(0.000001), item[\pan].round(0.000001),
				item[\minActivity].round(0.000001), item[\minIntensity].round(0.000001)]
		};
		[bar[\index], bar[\sectionId], bar[\sectionType].asString, bar[\localBar], bar[\chordRootDegree],
			if(bar[\gesture].isNil) { "" } { bar[\gesture].asString }, eventRows]
	};
	[	plan[\schemaVersion], plan[\generatorVersion], plan[\seed], plan[\tonicPc], plan[\scale],
		plan[\harmonicDegrees], [plan[\motif][\templateId].asString, plan[\motif][\rhythm], plan[\motif][\degrees]],
		plan[\kickTemplateId].asString, plan[\paletteId].asString, plan[\assetIdentities], sectionRows, barRows
	].asCompileString
};

validatePlan = { |plan|
	var errors, ids, prevBar, event, pitchClasses, chordDegrees, offset, duration, nextLead, nextBass, bassNotes, bassRoots;
	errors = Array.new;
	if(plan.isKindOf(IdentityDictionary).not) { Error("plan must be an IdentityDictionary").throw };
	if(plan[\schemaVersion] != 1) { errors = errors.add("unsupported plan schema") };
	if([80, 96].includes(plan[\bars].size).not) { errors = errors.add("arrangement must contain 80 or 96 bars") };
	if(plan[\sections].collect { |item| item[\bars] }.sum != plan[\bars].size) { errors = errors.add("section lengths do not equal the plan length") };
	ids = Set.new;
	plan[\bars].do { |bar, barIndex|
		if(bar[\index] != barIndex) { errors = errors.add("bar index mismatch at %".format(barIndex)) };
		if([\intro, \hook, \verse, \outro].includes(bar[\sectionType]).not) { errors = errors.add("invalid section at bar %".format(barIndex)) };
		bar[\candidates].do { |item|
			if(item[\id].isInteger.not or: { ids.includes(item[\id]) }) { errors = errors.add("invalid or duplicate event id") };
			ids.add(item[\id]);
			if(item[\tick].isInteger.not or: { item[\tick] < 0 } or: { item[\tick] >= 384 }) { errors = errors.add("event tick outside bar") };
			if(item[\velocity].isNumber.not or: { item[\velocity] < 0 } or: { item[\velocity] > 1 }) { errors = errors.add("invalid velocity") };
			if(item[\midi].notNil and: { item[\midi].isInteger.not }) { errors = errors.add("pitched event MIDI value must be an integer") };
			if(item[\minActivity].isNumber.not or: { item[\minActivity] < 0 } or: { item[\minActivity] > 1 }) { errors = errors.add("invalid activity threshold") };
			if(item[\minIntensity].isNumber.not or: { item[\minIntensity] < 0 } or: { item[\minIntensity] > 1 }) { errors = errors.add("invalid intensity threshold") };
			if(item[\midi].notNil and: { item[\lengthTicks].isInteger.not or: { item[\lengthTicks] < 1 } or: { item[\lengthTicks] > (384 - item[\tick]) } }) {
				errors = errors.add("pitched duration crosses a bar boundary")
				};
			if(item[\role] == \bass and: { item[\midi].inclusivelyBetween(28, 43).not }) { errors = errors.add("bass MIDI pitch outside the specified range") };
			if(item[\role] == \lead and: { item[\midi].inclusivelyBetween(60, 84).not }) { errors = errors.add("lead MIDI pitch outside the specified range") };
			if(item[\role] == \upper and: { item[\midi].inclusivelyBetween(72, 96).not }) { errors = errors.add("upper MIDI pitch outside the specified range") };
			if(item[\role] == \pad and: { item[\midi].inclusivelyBetween(48, 72).not }) { errors = errors.add("pad MIDI pitch outside the specified range") };
		};
		if(bar[\sectionType] == \intro and: { bar[\candidates].any { |item| [\kick, \bass, \snare, \clap].includes(item[\role]) } }) {
			errors = errors.add("intro contains a prohibited kick, bass, or snare")
		};
		if(bar[\sectionType] != \hook and: { bar[\candidates].any { |item| item[\role] == \upper } }) { errors = errors.add("upper layer outside hook") }
	};
	errors
};

barView = { |plan, index, controls|
	var bar, activity, intensity, candidates, roleCounts, openTicks;
	bar = plan[\bars][index];
	controls = controls ? IdentityDictionary.new;
	activity = controls[\activity] ? 0.5;
	intensity = controls[\intensity] ? 0.55;
	candidates = bar[\candidates].select { |item|
		(item[\minActivity] <= activity) and: { item[\minIntensity] <= intensity }
	};
	openTicks = candidates.select { |item| item[\role] == \hatOpen }.collect { |item| item[\tick] }.as(Set);
	candidates = candidates.reject { |item| (item[\role] == \hatClosed) and: { openTicks.includes(item[\tick]) } };
	roleCounts = Dictionary.new;
	candidates.do { |item|
		var key;
		key = [item[\role], item[\tick], item[\midi]];
		roleCounts[key] = item
	};
	candidates = roleCounts.values.asArray.sort { |a, b|
		var rankA, rankB, roles;
		roles = [\kick, \bass, \snare, \clap, \hatClosed, \hatOpen, \perc, \cymbal, \pad, \lead, \upper];
		rankA = roles.indexOf(a[\role]); rankB = roles.indexOf(b[\role]);
		if(a[\tick] == b[\tick]) {
			if(rankA == rankB) { a[\id] < b[\id] } { rankA < rankB }
		} { a[\tick] < b[\tick] }
	};
	candidates
};

api = IdentityDictionary.new;
api[\version] = "0.1.1";
api[\compile] = compile;
api[\validatePlan] = validatePlan;
api[\canonical] = canonical;
api[\barView] = barView;
api[\keyNames] = keyNames;
api
)
