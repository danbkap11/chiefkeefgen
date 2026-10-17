(
var projectRoot, previousController, previousSeed, launch;
projectRoot = PathName(thisProcess.nowExecutingPath).pathOnly.standardizePath;
previousController = currentEnvironment[\ckg];
previousSeed = if(previousController.notNil) { previousController[\snapshot].value[\seed] } { nil };

launch = {
	var configApi, composeApi, soundApi, assetsApi, uiApi, engineApi, config, controller;
	try {
		configApi = thisProcess.interpreter.executeFile(projectRoot +/+ "lib" +/+ "Config.scd");
		composeApi = thisProcess.interpreter.executeFile(projectRoot +/+ "lib" +/+ "Compose.scd");
		soundApi = thisProcess.interpreter.executeFile(projectRoot +/+ "lib" +/+ "Sound.scd");
		assetsApi = thisProcess.interpreter.executeFile(projectRoot +/+ "lib" +/+ "Assets.scd");
		uiApi = thisProcess.interpreter.executeFile(projectRoot +/+ "lib" +/+ "UI.scd");
		engineApi = thisProcess.interpreter.executeFile(projectRoot +/+ "lib" +/+ "Engine.scd");
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
