(
var root, modules, specifications, assertions, check, config, controller, catalog, definitions;
root = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ "..").standardizePath;
assertions = 0;
check = { |condition, message|
	if(condition.not) { Error(message).throw };
	assertions = assertions + 1
};
try {
	check.value(Main.version == "3.14.1", "SuperCollider 3.14.1 required");
	modules = IdentityDictionary.new;
	specifications = [
		[\Config, [\validate, \freshSeed]],
		[\Compose, [\compile, \canonical, \validatePlan, \barView]],
		[\Sound, [\definitions, \makeMessage]],
		[\Assets, [\inspectManifest, \attachCatalog, \loadBuffers, \release]],
		[\Engine, [\new]],
		[\UI, [\open, \refresh, \close]]
	];
	specifications.do { |spec|
		var path, module;
		path = root +/+ "lib" +/+ (spec[0].asString ++ ".scd");
		module = thisProcess.interpreter.executeFile(path);
		check.value(module.isKindOf(IdentityDictionary), "Module did not compile/load: " ++ path);
		spec[1].do { |key|
			check.value(module[key].isKindOf(Function), "% missing %".format(path, key))
		};
		modules[spec[0]] = module
	};
	check.value(File.readAllString(root +/+ "main.scd").compile.notNil, "main.scd did not compile");
	config = modules[\Config][\validate].value((gui: false, autoplay: false, seed: 17));
	check.value(config[\tempo] == 140, "default tempo");
	check.value(config[\activity] == 0.5, "default Activity");
	check.value((config[\intensity] - 0.55).abs < 0.000001, "default Intensity");
	catalog = modules[\Assets][\inspectManifest].value(root);
	check.value(catalog[\entries].isEmpty, "fixture expects the shipped header-only manifest");
	catalog = modules[\Assets][\inspectManifest].value(root +/+ "missing-fixture-folder");
	check.value(catalog[\entries].isEmpty, "missing manifest must fall back without nonlocal return");
	definitions = modules[\Sound][\definitions].value;
	check.value(definitions.size == 14, "all 14 production SynthDefs must be retained");
	definitions.do { |definition|
		check.value(definition.asBytes.size > 0, "empty SynthDef: " ++ definition.name)
	};
	controller = modules[\Engine][\new].value(config, root, modules[\Config], modules[\Compose],
		modules[\Sound], modules[\Assets], modules[\UI]);
	check.value(controller[\state].value == \loading, "initial controller state");
	controller[\setPending].value(\tempo, 145);
	check.value(controller[\snapshot].value[\active][\tempo] == 145, "stopped tempo update");
	controller[\dispose].value;
	check.value(controller[\state].value == \disposed, "dispose before boot");
	controller[\dispose].value;
	check.value(controller[\state].value == \disposed, "idempotent dispose");
	"STARTUP TESTS PASSED: % assertions".format(assertions).postln;
	0.exit
} { |error|
	error.reportError;
	"STARTUP TESTS FAILED after % assertions".format(assertions).postln;
	1.exit
};
)
