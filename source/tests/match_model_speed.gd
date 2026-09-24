extends SceneTree
const Rules=preload("res://scripts/match_rules.gd")
func _initialize() -> void:
	var levels: Array=JSON.parse_string(FileAccess.get_file_as_string("res://match_levels/levels.json"))
	for id in [1,126,250]:
		var level: Dictionary=levels[id-1]
		var model=Rules.new(); model.setup(level)
		var times: Array=[]
		for step in level.witness.slice(0,8):
			var started: int=Time.get_ticks_usec()
			model.play(int(step[0]),int(step[1]))
			times.append((Time.get_ticks_usec()-started)/1000.0)
		print("MODEL level=",id," first_moves_ms=",times)
	quit()
