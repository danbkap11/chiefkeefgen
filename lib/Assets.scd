(
var roles, hashFile, inspectManifest, attachCatalog, loadBuffers, release, api;
roles = [\kick, \snare, \hatClosed, \hatOpen, \perc, \cymbal];

hashFile = { |path|
	var args, pipe, line, status, result;
	args = Platform.case(
		\linux, { ["sha256sum", path] },
		\osx, { ["/usr/bin/shasum", "-a", "256", path] },
		\windows, { ["powershell.exe", "-NoProfile", "-NonInteractive", "-Command",
			"[Console]::Out.Write((Get-FileHash -LiteralPath $args[0] -Algorithm SHA256).Hash)", path] }
	);
	if(args.isNil) { Error("no supported SHA-256 command is available on this platform").throw };
	pipe = Pipe.argv(args, "r");
	line = pipe.getLine;
	status = pipe.close;
	if(status != 0 or: { line.isNil }) { Error("SHA-256 command failed for %".format(path)).throw };
	result = line.split($ ).first.toLower;
	if(result.size != 64 or: { result.findRegexp("^[0-9a-f]{64}$").isNil }) {
		Error("SHA-256 command returned an invalid digest for %".format(path)).throw
	};
	result
};

inspectManifest = { |projectRoot|
	var rows, header, file, line, fields, root, manifestPath, path, sf, asset;
	var uniqueIds, byRole, digest, parsedRows, role, channels, sampleRate, gain;
	root = projectRoot.standardizePath;
	manifestPath = root +/+ "assets" +/+ "manifest.tsv";
	byRole = IdentityDictionary.new;
	roles.do { |item| byRole[item] = Array.new };
	if(File.exists(manifestPath).not) {
		"Optional assets/manifest.tsv not found; using synthesized sounds.".postln;
		^((entries: [], byRole: byRole, identity: "synth-core-v1", errors: []))
	};
	file = File(manifestPath, "r");
	if(file.isOpen.not) { Error("cannot read %".format(manifestPath)).throw };
	header = file.getLine;
	if(header.isNil or: { header.split($\t).size != 13 }) {
		file.close;
		Error("manifest must have the documented 13-column TSV header").throw
	};
	uniqueIds = Set.new;
	parsedRows = Array.new;
	line = file.getLine;
	while { line.notNil } {
		if(line.stripWhiteSpace.size > 0) {
			fields = line.split($\t);
			if(fields.size != 13) {
				"Skipping malformed asset manifest row (expected 13 tab-separated fields).".warn
			} {
				try {
					role = fields[1].asSymbol;
					if(fields[0].size == 0 or: { uniqueIds.includes(fields[0]) }) { Error("empty or duplicate asset_id").throw };
					if(roles.includes(role).not) { Error("unsupported optional sample role %".format(role)).throw };
					if(fields[5].size > 0) { Error("only unpitched drum samples are supported").throw };
					if(["CC0-1.0", "CC-BY-4.0", "CC-BY-3.0"].includes(fields[9]).not) { Error("raw redistribution requires CC0 or a supported CC-BY license").throw };
					if(fields[7].beginsWith("https://").not or: { fields[8].size == 0 } or: { fields[10].beginsWith("https://").not }) {
						Error("source, creator, and license URL are required").throw
					};
					path = fields[2];
					if(path.size == 0 or: { path.beginsWith("/") } or: { path.find("..").notNil } or: { path.includes($\\) }) {
						Error("asset path must stay below assets/ and contain no parent traversal").throw
					};
					channels = fields[3].asInteger;
					if([1, 2].includes(channels).not) { Error("sample must be mono or stereo").throw };
					sampleRate = fields[4].asInteger;
					if(sampleRate < 8000 or: { sampleRate > 192000 }) { Error("unsupported sample rate").throw };
					gain = fields[6].asFloat;
					if(gain < -24 or: { gain > 0 }) { Error("asset gain adjustment must be between -24 and 0 dB").throw };
					if(fields[12].size != 64 or: { fields[12].findRegexp("^[0-9a-f]{64}$").isNil }) { Error("invalid SHA-256 in manifest").throw };
					path = (root +/+ "assets" +/+ path).standardizePath;
					if(File.exists(path).not) { Error("optional file not found: %".format(fields[2])).throw };
					sf = SoundFile.new;
					if(sf.openRead(path).not) { Error("unsupported or corrupt sound file: %".format(fields[2])).throw };
					if(sf.numChannels != channels or: { sf.sampleRate.asInteger != sampleRate } or: { sf.numFrames <= 0 } or: {
						sf.duration > 2.0
					}) { sf.close; Error("audio metadata does not match manifest/2 second limit").throw };
					if(sampleRate != sf.sampleRate.asInteger) { sf.close; Error("sample rate mismatch").throw };
					sf.close;
					digest = hashFile.value(path);
					if(digest != fields[12].toLower) { Error("SHA-256 mismatch for %".format(fields[2])).throw };
					asset = IdentityDictionary.new;
					asset[\assetId] = fields[0];
					asset[\role] = role;
					asset[\path] = path;
					asset[\channels] = channels;
					asset[\sampleRate] = sampleRate;
					asset[\duration] = sf.duration;
					asset[\gain] = gain.dbamp;
					asset[\sha256] = digest;
					uniqueIds.add(fields[0]);
					parsedRows.add(asset)
				} { |error|
					"Optional sample row rejected: %".format(error.errorString).warn
				}
			}
		};
		line = file.getLine
	};
	file.close;
	parsedRows.sort { |a, b| a[\assetId] < b[\assetId] }.do { |item| byRole[item[\role]].add(item) };
	rows = parsedRows.collect { |item| [item[\assetId], item[\sha256], item[\role].asString] };
	((entries: parsedRows, byRole: byRole, identity: rows.asCompileString, errors: []))
};

attachCatalog = { |plan, catalog, composeApi|
	var catalogById, identities, entries, role, candidates;
	catalogById = IdentityDictionary.new;
	entries = Array.new;
	catalog[\entries].do { |item| catalogById[item[\assetId]] = item; entries.add(item) };
	plan[\bars].do { |bar|
		bar[\candidates].do { |item|
			var choices;
			choices = catalog[\byRole][item[\role]] ? [];
			if(choices.notEmpty) {
				item[\assetId] = choices[item[\id] % choices.size][\assetId]
			}
		}
	};
	identities = entries.collect { |item| [item[\assetId], item[\sha256], item[\role].asString] };
	plan[\assetIdentities] = (identities ++ [["synth-core", "v1", "synth"]]).sort;
	plan[\canonicalPlan] = composeApi[\canonical].value(plan);
	plan
};

loadBuffers = { |server, catalog, token, isCurrent, done, failed|
	Routine({
		var loaded, buffer, condition, currentToken, validRows, asset, channels;
		loaded = IdentityDictionary.new;
		currentToken = token;
		validRows = catalog[\entries];
		validRows.do { |item|
			var completed, timedOut, selectedChannels, requestedBuffer;
			completed = false;
			timedOut = false;
			condition = Condition.new;
			selectedChannels = if(item[\channels] == 1) { [0] } { [0, 1] };
			requestedBuffer = Buffer.readChannel(server, item[\path], channels: selectedChannels, action: { |loadedBuffer|
				if(completed.not) { completed = true; requestedBuffer = loadedBuffer; condition.unhang } { loadedBuffer.free }
			});
			SystemClock.sched(10, {
				if(completed.not) { completed = true; timedOut = true; condition.unhang };
				nil
			});
			condition.hang;
			if(isCurrent.value(currentToken).not) {
				if(requestedBuffer.notNil) { requestedBuffer.free };
			} {
				if(timedOut or: { requestedBuffer.isNil } or: { requestedBuffer.numFrames <= 0 } or: { requestedBuffer.numChannels != item[\channels] }) {
				if(requestedBuffer.notNil) { requestedBuffer.free };
				"Asset % did not load; using synthesized fallback.".format(item[\assetId]).warn
				} {
				asset = IdentityDictionary.new;
				asset[\assetId] = item[\assetId];
				asset[\role] = item[\role];
				asset[\buffer] = requestedBuffer;
				asset[\channels] = item[\channels];
				asset[\gain] = item[\gain];
				asset[\duration] = item[\duration];
				asset[\sha256] = item[\sha256];
				loaded[item[\assetId]] = asset
				}
			};
		};
		server.sync;
		if(isCurrent.value(currentToken)) { done.value(loaded) } { loaded.values.do { |item| item[\buffer].free }; failed.value("stale sample load discarded") }
	}).play(SystemClock);
};

release = { |loaded, server, done|
	Routine({
		loaded.values.do { |item| if(item[\buffer].notNil) { item[\buffer].free } };
		server.sync;
		done.value
	}).play(SystemClock)
};

api = IdentityDictionary.new;
api[\hashFile] = hashFile;
api[\inspectManifest] = inspectManifest;
api[\attachCatalog] = attachCatalog;
api[\loadBuffers] = loadBuffers;
api[\release] = release;
api
)
