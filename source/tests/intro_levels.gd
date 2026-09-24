extends SceneTree
const Rules=preload("res://scripts/match_rules.gd")
func _initialize() -> void:
	var levels: Array=JSON.parse_string(FileAccess.get_file_as_string("res://match_levels/levels.json"))
	var failures:=0
	for data in levels.slice(0,15):
		var model=Rules.new(); model.record_frames=false; model.setup(data)
		for step in data.witness:
			if not model.play(int(step[0]),int(step[1])): failures+=1
		if not model.won(): failures+=1
	print("First 15 solutions: failures=",failures)
	quit(1 if failures else 0)
