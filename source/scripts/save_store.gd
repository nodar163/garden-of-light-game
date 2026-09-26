extends RefCounted
const Garden=preload("res://scripts/garden_rules.gd")
var path: String
var data: Dictionary
var recovered := false
var last_error := ""

func _init(location: String = "user://progress.json") -> void:
	path = location
	data = defaults()

static func defaults() -> Dictionary:
	return {"version":1, "completed":[], "current":1, "boards":{}, "match3":{"current":1,"completed":[],"boards":{}}, "garden":Garden.defaults(), "tutorial_seen":[], "settings":{"language":"ru", "music":true, "sound":true, "reduce_motion":false}}

static func valid(value: Variant) -> bool:
	if not value is Dictionary or value.get("version") != 1:
		return false
	if value.has("garden") and not Garden.valid(value.garden): return false
	if value.has("tutorial_seen"):
		if not value.tutorial_seen is Array: return false
		for key in value.tutorial_seen:
			if key not in ["garden","light","match"]: return false
	if not value.get("completed") is Array or not value.get("boards") is Dictionary or not value.get("settings") is Dictionary:
		return false
	if not typeof(value.get("current")) in [TYPE_INT, TYPE_FLOAT] or float(value.current) != int(value.current) or int(value.current) < 1:
		return false
	for id in value.completed:
		if not typeof(id) in [TYPE_INT, TYPE_FLOAT] or float(id) != int(id) or int(id) < 1:
			return false
	for board in value.boards.values():
		if not board is Array:
			return false
		for rotation in board:
			if not typeof(rotation) in [TYPE_INT, TYPE_FLOAT] or float(rotation) != int(rotation) or rotation < 0 or rotation > 3:
				return false
	if value.settings.get("language") not in ["ru", "en"]:
		return false
	for key in ["music", "sound", "reduce_motion"]:
		if not value.settings.get(key) is bool:
			return false
	if value.has("match3"):
		var extra: Variant = value.match3
		if not extra is Dictionary or not extra.get("completed") is Array or not extra.get("boards") is Dictionary: return false
		if not typeof(extra.get("current")) in [TYPE_INT,TYPE_FLOAT] or int(extra.current) < 1 or int(extra.current) > 250: return false
		for id in extra.completed:
			if not typeof(id) in [TYPE_INT,TYPE_FLOAT] or float(id) != int(id) or int(id) < 1 or int(id) > 250: return false
		for board in extra.boards.values():
			if not board is Dictionary: return false
	return true

func read_valid(file_path: String) -> Variant:
	if not FileAccess.file_exists(file_path):
		return null
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return null
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		return null
	var parsed: Variant = parser.data
	return parsed if valid(parsed) else null

func load_data() -> void:
	for candidate in [path, path + ".tmp", path + ".bak"]:
		var loaded: Variant = read_valid(candidate)
		if loaded != null:
			data = loaded
			if not data.has("match3"): data.match3 = {"current":1,"completed":[],"boards":{}}
			data.match3.current = int(data.match3.current)
			for i in data.match3.completed.size(): data.match3.completed[i] = int(data.match3.completed[i])
			data.current = int(data.current)
			for i in data.completed.size():
				data.completed[i] = int(data.completed[i])
			for key in data.boards:
				for i in data.boards[key].size():
					data.boards[key][i] = int(data.boards[key][i])
			Garden.sync(data)
			recovered = candidate != path
			return
	recovered = FileAccess.file_exists(path)
	data = defaults()

func write() -> bool:
	last_error = ""
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		last_error = "Cannot write temporary save"
		return false
	file.store_string(JSON.stringify(data))
	file.flush()
	file.close()
	if read_valid(path + ".tmp") == null:
		last_error = "Save verification failed"
		return false
	if read_valid(path) != null:
		if DirAccess.copy_absolute(path, path + ".bak") != OK:
			last_error = "Cannot back up save"
			return false
	var error := DirAccess.rename_absolute(path + ".tmp", path)
	# Windows scanners/readers can briefly hold the destination open.
	# Keep the verified temporary file and backup intact while retrying.
	if OS.get_name() == "Windows":
		for attempt in 3:
			if error == OK:
				break
			OS.delay_msec(20 * (attempt + 1))
			error = DirAccess.rename_absolute(path + ".tmp", path)
	if error != OK:
		last_error = "Cannot replace save: " + str(error)
		return false
	return true

func complete(id: int) -> bool:
	if id in data.completed:
		return false
	data.completed.append(id)
	Garden.sync(data)
	return true

func garden_transaction(action: Callable) -> bool:
	var previous: Dictionary=data.garden.duplicate(true)
	if not action.call(data.garden): return false
	if write(): return true
	data.garden=previous
	return false

func import_copy(text_value: String) -> bool:
	if text_value.length()>4000000: return false
	var parser:=JSON.new()
	if parser.parse(text_value)!=OK: return false
	var candidate: Variant=parser.data
	if not valid(candidate): return false
	var previous: Dictionary=data.duplicate(true)
	data=candidate
	if not data.has("match3"): data.match3={"current":1,"completed":[],"boards":{}}
	Garden.sync(data)
	if write():
		load_data()
		return true
	data=previous
	return false
