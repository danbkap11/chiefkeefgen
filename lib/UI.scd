(
var open, refresh, close, activeController, window, views, formatSnapshot, updateControl, api;
activeController = nil;
window = nil;
views = IdentityDictionary.new;

formatSnapshot = { |snapshot|
	var stateName, seedText, active, pending, statusText, errorText;
	stateName = snapshot[\state].asString.capitalize;
	seedText = if(snapshot[\seed].notNil) { snapshot[\seed].asString } { "pending" };
	active = snapshot[\active];
	pending = snapshot[\pending];
	statusText = "State: %    Seed: %    Key: %    Section: %    Bar: %/%    Active % BPM / A % / I %".format(
		stateName, seedText, snapshot[\key], snapshot[\section], snapshot[\bar], snapshot[\totalBars],
		active[\tempo], active[\activity].round(0.01), active[\intensity].round(0.01));
	if(pending.notNil) {
		statusText = statusText ++ "\nPending: % BPM / A % / I %".format(pending[\tempo], pending[\activity].round(0.01), pending[\intensity].round(0.01))
	};
	if(snapshot[\fallbackRoles].notEmpty) {
		statusText = statusText ++ "\nSynthesized fallback: %".format(snapshot[\fallbackRoles].join(", "))
	};
	errorText = snapshot[\error];
	if(errorText.notNil and: { errorText.size > 0 }) { statusText = statusText ++ "\n%".format(errorText) };
	statusText
};

updateControl = { |controller, key, value|
	try { controller[\setPending].value(key, value) } { |error| error.errorString.warn }
};

open = { |controller|
	var w, status, tempoLabel, activityLabel, intensityLabel, tempoSlider, activitySlider, intensitySlider;
	var playButton, stopButton, newButton, current;
	if(window.notNil and: { window.isClosed.not }) { window.close };
	activeController = controller;
	w = Window("Chief Keef Drill Beat Generator", Rect(0, 0, 620, 300));
	window = w;
	views = IdentityDictionary.new;
	StaticText(w, Rect(18, 10, 580, 28)).string_("Original early Chicago drill · deterministic composition · no downloads required")
		.font_(Font(\Helvetica, 14));
	tempoLabel = StaticText(w, Rect(20, 54, 155, 24)).string_("Tempo: 140 BPM");
	tempoSlider = Slider(w, Rect(185, 54, 410, 24)).value_(0.5).action_({ |slider|
		var tempo;
		tempo = (130 + (slider.value * 20)).round.asInteger;
		tempoLabel.string = "Tempo: % BPM".format(tempo);
		updateControl.value(controller, \tempo, tempo)
	});
	activityLabel = StaticText(w, Rect(20, 96, 155, 24)).string_("Activity: 0.50");
	activitySlider = Slider(w, Rect(185, 96, 410, 24)).value_(0.5).action_({ |slider|
		var value;
		value = slider.value.round(0.01);
		activityLabel.string = "Activity: %".format(value);
		updateControl.value(controller, \activity, value)
	});
	intensityLabel = StaticText(w, Rect(20, 138, 155, 24)).string_("Intensity: 0.55");
	intensitySlider = Slider(w, Rect(185, 138, 410, 24)).value_(0.55).action_({ |slider|
		var value;
		value = slider.value.round(0.01);
		intensityLabel.string = "Intensity: %".format(value);
		updateControl.value(controller, \intensity, value)
	});
	playButton = Button(w, Rect(20, 184, 130, 36)).states_([["Play"]]).action_({
		try { controller[\start].value } { |error| error.errorString.warn }
	});
	stopButton = Button(w, Rect(166, 184, 130, 36)).states_([["Stop"]]).action_({
		controller[\stop].value
	});
	newButton = Button(w, Rect(312, 184, 160, 36)).states_([["New Beat"]]).action_({
		try { controller[\newBeat].value } { |error| error.errorString.warn }
	});
	status = StaticText(w, Rect(20, 232, 580, 58)).string_("Preparing the audio server…")
		.font_(Font(\Helvetica, 11));
	views[\status] = status;
	views[\tempoLabel] = tempoLabel; views[\activityLabel] = activityLabel; views[\intensityLabel] = intensityLabel;
	views[\tempoSlider] = tempoSlider; views[\activitySlider] = activitySlider; views[\intensitySlider] = intensitySlider;
	views[\play] = playButton; views[\stop] = stopButton; views[\new] = newButton;
	w.onClose_({
		if(activeController === controller) {
			activeController = nil;
			window = nil;
			views.clear;
			controller[\dispose].value
		}
	});
	w.front;
	defer { refresh.value(controller) };
	w
};

refresh = { |controller|
	if((activeController === controller) and: { window.notNil and: { window.isClosed.not } }) {
		var snapshot, visible;
		snapshot = controller[\snapshot].value;
		visible = snapshot[\pending] ? snapshot[\active];
		views[\status].string = formatSnapshot.value(snapshot);
		views[\tempoLabel].string = "Tempo: % BPM".format(visible[\tempo]);
		views[\activityLabel].string = "Activity: %".format(visible[\activity].round(0.01));
		views[\intensityLabel].string = "Intensity: %".format(visible[\intensity].round(0.01));
		views[\tempoSlider].value = ((visible[\tempo] - 130) / 20).clip(0, 1);
		views[\activitySlider].value = visible[\activity].clip(0, 1);
		views[\intensitySlider].value = visible[\intensity].clip(0, 1);
		views[\play].enabled = [\ready, \playing].includes(snapshot[\state]);
		views[\stop].enabled = [\playing, \stopping].includes(snapshot[\state]);
		views[\new].enabled = [\ready, \playing].includes(snapshot[\state]);
	};
	window
};

close = { |controller|
	if(activeController === controller) {
		activeController = nil;
		if(window.notNil and: { window.isClosed.not }) { window.close };
		window = nil;
		views.clear
	};
	nil
};

api = IdentityDictionary.new;
api[\open] = open;
api[\refresh] = refresh;
api[\close] = close;
api
)
