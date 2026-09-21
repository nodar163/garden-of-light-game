extends SceneTree
const Rules = preload("res://scripts/puzzle.gd")
const Saves = preload("res://scripts/save_store.gd")
var checks := 0
var failures := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + message)

func _initialize() -> void:
	var fingerprints: Dictionary = {}
	var previous_score := 0
	for id in range(1, 251):
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://levels/%02d.json" % id))
		check(Rules.validate(data) == "", "level schema %d" % id)
		if id >= 51:
			var fingerprint := JSON.stringify([data.cells, data.start])
			check(not fingerprints.has(fingerprint), "unique new board %d" % id)
			fingerprints[fingerprint] = true
			check(int(data.design.difficulty_score) >= previous_score, "nondecreasing authoring difficulty %d" % id)
			previous_score = int(data.design.difficulty_score)
		var p = Rules.new()
		p.setup(data)
		check(not p.won(), "level starts unsolved %d" % id)
		check(data.cells.count("tee") == 0 if id <= 10 else data.cells.count("tee") > 0, "branch introduction")
		var initial: Array = p.rotations.duplicate()
		check(not p.turn(data.cells.find("source")), "source is fixed")
		check(not p.turn(data.cells.find("plant")), "plant is fixed")
		check(not p.turn(-1) and not p.turn(1000), "out of bounds")
		var chosen: int = p.hint_index()
		p.turn(chosen)
		check(p.undo() and p.rotations == initial, "undo restores exact board")
		for _step in data.cells.size():
			if p.won():
				break
			p.apply_hint(p.hint_index())
		check(p.won(), "hints solve level %d" % id)
		check(p.hint_index() == -1, "no hint after victory")
		p.restart()
		check(p.rotations == initial and p.history.is_empty(), "restart clears history")
		p.setup(data, data.solution)
		check(p.won(), "authored solution works %d" % id)
		for i in data.cells.size():
			if data.cells[i] == "straight":
				p.rotations[i] = (int(p.rotations[i])+2)%4
		check(p.won(), "equivalent straight rotations accepted")
	for r in 4:
		check(Rules.mask("source",r) == (1 << r), "direction rotation")
	check(Rules.mask("tee",1) == 7, "tee rotation")
	# A loop with two attached terminal nodes: BFS must terminate and visit all.
	var loop := {"id":99,"size":3,"cells":["corner","tee","plant","tee","corner","empty","source","empty","empty"],"start":[1,2,3,1,3,0,0,0,0],"solution":[1,2,3,1,3,0,0,0,0]}
	var p = Rules.new()
	p.setup(loop)
	check(p.won() and p.lit().size() == 6, "cycle and branches propagate without looping")
	p.rotations[3] = 0
	check(not p.won(), "broken connection blocks light")
	var wrap := {"id":98,"size":3,"cells":["empty","empty","source","plant","empty","empty","empty","empty","empty"],"start":[0,0,1,3,0,0,0,0,0],"solution":[0,0,1,3,0,0,0,0,0]}
	p.setup(wrap)
	check(not p.won(), "row edges never wrap")
	var multiple := {"id":97,"size":3,"cells":["empty","plant","empty","source","tee","plant","empty","empty","empty"],"start":[0,2,0,1,0,3,0,0,0],"solution":[0,2,0,1,0,3,0,0,0]}
	p.setup(multiple)
	check(p.won(), "both plants connected")
	p.rotations[4] = 2
	check(not p.won(), "all plants required, not just one")
	var save = Saves.new("user://automated-test-save.json")
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(save.path+suffix):
			DirAccess.remove_absolute(save.path+suffix)
	check(save.complete(1) and not save.complete(1), "reward is idempotent")
	save.data.boards["1"] = [0,0,0,1,2,3,0,0,0]
	save.data.settings.language = "en"
	check(save.write(), "first save written")
	save.data.current = 2
	check(save.write(), "replacement save written")
	var reopened = Saves.new(save.path)
	reopened.load_data()
	check(reopened.data.current == 2 and reopened.data.settings.language == "en", "progress and settings round-trip")
	check(reopened.data.boards["1"] == save.data.boards["1"], "board round-trip")
	var file := FileAccess.open(save.path, FileAccess.WRITE)
	file.store_string("{broken")
	file.close()
	reopened.load_data()
	check(reopened.recovered and reopened.data.completed == [1], "corrupt save recovers backup")
	check(not Saves.valid({"version":1}), "malformed save rejected")
	var invalid = Saves.defaults()
	invalid.settings.music = "yes"
	check(not Saves.valid(invalid), "invalid settings rejected")
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(save.path+suffix):
			DirAccess.remove_absolute(save.path+suffix)
	print("Checks: %d; failures: %d" % [checks, failures])
	quit(1 if failures else 0)
