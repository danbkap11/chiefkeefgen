(
var root, compose, config, assertions, signatures, seeds, baseline, plan, failures, signature, arrangementPlan;
try {
root = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ "..").standardizePath;
compose = thisProcess.interpreter.executeFile(root +/+ "lib" +/+ "Compose.scd");
config = thisProcess.interpreter.executeFile(root +/+ "lib" +/+ "Config.scd");
assertions = 0;
signatures = Set.new;
seeds = (1..100);
seeds.do { |seed|
	[\A, \B].do { |arrangement|
		arrangementPlan = compose[\compile].value(seed, "synth-core-v1", arrangement);
		failures = compose[\validatePlan].value(arrangementPlan);
		if(failures.notEmpty or: { arrangementPlan[\bars].size != if(arrangement == \A) { 96 } { 80 } }) {
			Error("seed % arrangement % failed: %".format(seed, arrangement, failures.join(", "))).throw
		};
		assertions = assertions + 1
	};
	plan = compose[\compile].value(seed, "synth-core-v1");
	failures = compose[\validatePlan].value(plan);
	if(failures.notEmpty) { Error("seed %: %".format(seed, failures.join(", "))).throw };
	assertions = assertions + 1;
	baseline = compose[\canonical].value(plan);
	12345.rand;
	if(compose[\canonical].value(compose[\compile].value(seed, "synth-core-v1")) != baseline) {
		Error("seed % did not reproduce its canonical plan".format(seed)).throw
	};
	assertions = assertions + 1;
	signature = [plan[\tonicPc], plan[\motif][\templateId], plan[\kickTemplateId],
		plan[\bars].collect { |bar| [bar[\sectionType], bar[\chordRootDegree], bar[\gesture],
			bar[\candidates].collect { |event| [event[\tick], event[\role], event[\midi]] }] }].asCompileString;
	signatures.add(signature);
	[
		(tempo: 130, activity: 0.0, intensity: 0.0),
		(tempo: 150, activity: 1.0, intensity: 1.0)
	].do { |controls|
		var events;
		events = compose[\barView].value(plan, 0, controls);
		if(events.isEmpty) { Error("filtered bar unexpectedly empty").throw };
		assertions = assertions + 1
	}
};
if(signatures.size < 80) { Error("only % distinct musical signatures in 100 seeds".format(signatures.size)).throw };
assertions = assertions + 1;
[130, 140, 150].do { |tempo| config[\validate].value((tempo: tempo, activity: 0.5, intensity: 0.55)); assertions = assertions + 1 };
"PLAN TESTS PASSED: % assertions; 100 seeds; % distinct signatures".format(assertions, signatures.size).postln;
0.exit;
} { |error| error.reportError; 1.exit };
)
