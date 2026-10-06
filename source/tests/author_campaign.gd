extends SceneTree
const Rules=preload("res://scripts/match_rules.gd")
func _initialize() -> void:
	var all: Array=JSON.parse_string(FileAccess.get_file_as_string("res://match_levels/levels.json"))
	all.resize(250)
	for id in range(251,1001):
		var chapter: int=(id-251)/75
		var targets: Array=[0,0,0,0,0,0]
		for j in 3: targets[(id+j)%6]=28+chapter*2+id%5
		var dew: Array=[]; dew.resize(49); dew.fill(0)
		var obstacles: Array=[]; obstacles.resize(49); obstacles.fill(0)
		var layers: Array=[]; layers.resize(49); layers.fill(0)
		for k in mini(49,24+chapter*2): dew[(k*17+id*7)%49]=2 if k%3==0 else 1
		for k in 6+chapter/3:
			var index: int=(k*13+id*3)%49
			obstacles[index]=1+(k+id)%4; layers[index]=2
		var data: Dictionary={"id":id,"size":7,"colors":6,"moves":240,"seed":17001+id*7919,"targets":targets,"dew":dew,"obstacles":obstacles,"layers":layers,"chapter":(id-1)/25}
		var model=Rules.new(); model.record_frames=false; model.setup(data)
		var route: Array=[]
		while not model.won() and route.size()<220:
			var action: Array=model.suggest()
			if action.is_empty() or not model.play(action[0],action[1]): printerr("Authoring failed ",id); quit(1); return
			route.append(action)
		if not model.won(): printerr("Unsolved ",id); quit(1); return
		data.moves=route.size()+maxi(5,10-chapter/2)+(4 if id%5==1 else 0)
		data.witness=route; all.append(data)
		if id%25==0: print("Verified match level ",id)
	var file:=FileAccess.open("res://match_levels/levels.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(all)); file.close(); print("1000 match levels authored"); quit()
