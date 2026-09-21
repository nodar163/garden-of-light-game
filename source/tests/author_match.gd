extends SceneTree
const Rules = preload("res://scripts/match_rules.gd")

func _initialize() -> void:
	var all: Array = []
	for id in range(1,251):
		var n := 6 if id <= 25 else 7
		var chapter := (id-1)/25
		var targets: Array = [0,0,0,0,0,0]
		var colors := 4 if id <= 15 else 5 if id <= 100 else 6
		var count := 1 if id <= 5 else 2 if id <= 75 else 3
		for j in count: targets[(id+j)%colors] = 9+chapter*3+(id-1)%25/5
		var dew: Array = []
		dew.resize(n*n); dew.fill(0)
		if id >= 11:
			for k in mini(n*n, 3+chapter*3+(id%5)):
				var i := (k*17+id*7)%(n*n)
				dew[i] = 2 if id >= 126 and k%3 == 0 else 1
		var data := {"id":id,"size":n,"colors":colors,"moves":220,"seed":7001+id*7919,"targets":targets,"dew":dew}
		var model = Rules.new()
		model.record_frames = false
		model.setup(data)
		var route: Array = []
		while not model.won() and route.size() < 180:
			var action: Array = model.suggest()
			if action.is_empty() or not model.play(action[0],action[1]):
				printerr("No valid authoring action: ",id); quit(1); return
			route.append(action)
		if not model.won(): printerr("Authoring route failed: ",id); quit(1); return
		# Witness proves solvability with the exact refill seed. Margin eases early play.
		data.moves = route.size()+maxi(4,12-chapter)
		data.witness = route
		data.chapter = chapter
		all.append(data)
		if id%25 == 0: print("Authored match levels: ",id,"; last solution moves: ",route.size())
	DirAccess.make_dir_recursive_absolute("res://match_levels")
	var file := FileAccess.open("res://match_levels/levels.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(all,"\t"))
	file.close()
	print("250 deterministic match levels with verified winning routes authored.")
	quit()
