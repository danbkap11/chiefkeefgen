(
var defaults, validate, freshSeed, config;
defaults = IdentityDictionary.new;
defaults[\schemaVersion] = 1;
defaults[\generatorVersion] = "0.1.1";
defaults[\seed] = nil;
defaults[\tempo] = 140;
defaults[\activity] = 0.50;
defaults[\intensity] = 0.55;
defaults[\gui] = true;
defaults[\autoplay] = true;
defaults[\server] = Server.default;
defaults[\audioOutputs] = 2;
defaults[\sampleRate] = 48000;
defaults[\latency] = 0.20;

validate = { |input|
	var output, value;
	output = IdentityDictionary.new;
	input = input ? IdentityDictionary.new;
	output[\schemaVersion] = defaults[\schemaVersion];
	output[\generatorVersion] = defaults[\generatorVersion];
	[\tempo, \activity, \intensity, \seed, \gui, \autoplay,
	 \audioOutputs, \sampleRate, \latency, \server].do { |key|
		value = input[key];
		if(value.isNil) { value = defaults[key] };
		output[key] = value;
	};
	if(output[\tempo].isNumber.not or: { output[\tempo] != output[\tempo] } or: {
		(output[\tempo] < 130) or: { output[\tempo] > 150 }
	}) { Error("tempo must be between 130 and 150 BPM").throw };
	output[\tempo] = output[\tempo].round.asInteger;
	[\activity, \intensity].do { |key|
		value = output[key];
		if(value.isNumber.not or: { value != value } or: { value < 0 } or: { value > 1 }) {
			Error("% must be a finite number from 0 to 1".format(key)).throw
		};
		output[key] = value.asFloat.round(0.000001)
	};
	if(output[\seed].notNil and: {
		output[\seed].isInteger.not or: { output[\seed] < 1 } or: { output[\seed] > 2147483646 }
	}) { Error("seed must be a positive integer no greater than 2147483646").throw };
	if(output[\audioOutputs] != 2) { Error("this project requires two output channels").throw };
	if(output[\sampleRate].isNumber.not or: { output[\sampleRate] < 44100 } or: { output[\sampleRate] > 192000 }) {
		Error("sampleRate must be between 44100 and 192000 Hz").throw
	};
	if(output[\latency].isNumber.not or: { output[\latency] < 0.02 } or: { output[\latency] > 2 }) {
		Error("latency must be between 0.02 and 2 seconds").throw
	};
	[\gui, \autoplay].do { |key|
		if(output[key].isKindOf(Boolean).not) { Error("% must be true or false".format(key)).throw }
	};
	output
};

freshSeed = { |previous|
	var candidate;
	candidate = 2147483646.rand + 1;
	if(candidate == previous) { candidate = if(candidate >= 2147483646) { 1 } { candidate + 1 } };
	candidate
};

config = IdentityDictionary.new;
config[\defaults] = defaults;
config[\validate] = validate;
config[\freshSeed] = freshSeed;
config
)
