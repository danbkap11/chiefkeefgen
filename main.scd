(
var projectRoot, previousController, previousSeed, launch;
projectRoot = PathName(thisProcess.nowExecutingPath).pathOnly.standardizePath;
previousController = currentEnvironment[\ckg];
previousSeed = if(previousController.notNil) { previousController[\snapshot].value[\seed] } { nil };

launch = {
	var configApi, composeApi, soundApi, assetsApi, uiApi, engineApi, config, controller, loadModule;
	loadModule = { |name, required|
		var path, module;
		path = projectRoot +/+ "lib" +/+ (name ++ ".scd");
		module = thisProcess.interpreter.executeFile(path);
		if(module.isKindOf(IdentityDictionary).not) {
			Error("Failed to load %. Check the preceding compiler error.".format(path)).throw
		};
		required.do { |key|
			if(module[key].isKindOf(Function).not) {
				Error("Module % is missing function %.".format(name, key)).throw
			}
		};
		module
	};
	try {
		configApi = loadModule.value("Config", [\validate, \freshSeed]);
		composeApi = loadModule.value("Compose", [\compile, \validatePlan, \barView]);
		soundApi = loadModule.value("Sound", [\definitions, \makeMessage]);
		assetsApi = loadModule.value("Assets", [\inspectManifest, \loadBuffers, \release]);
		uiApi = loadModule.value("UI", [\open, \refresh, \close]);
		engineApi = loadModule.value("Engine", [\new]);
		config = configApi[\defaults].copy;
		config[\seed] = configApi[\freshSeed].value(previousSeed); // Set an integer here to replay a beat.
		config[\gui] = true;
		config[\autoplay] = true;
		controller = engineApi[\new].value(config, projectRoot, configApi, composeApi, soundApi, assetsApi, uiApi);
		currentEnvironment[\ckg] = controller;
		controller[\initialize].value;
		"Chief Keef type beat generator % · seed %".format(controller[\version], config[\seed]).postln;
		controller
	} { |error|
		error.reportError;
		currentEnvironment[\ckg] = nil;
		nil
	}
};

if(previousController.notNil) {
	previousController[\dispose].value(launch)
} {
	launch.value
}
)
