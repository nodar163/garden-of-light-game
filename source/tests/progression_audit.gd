extends SceneTree
const Main=preload("res://scripts/main.gd")
const Saves=preload("res://scripts/save_store.gd")
const Farm=preload("res://scripts/garden_farm.gd")
const Garden=preload("res://scripts/garden_rules.gd")
var checks:=0
var failures:=0
func check(ok: bool, name_value: String) -> void:
	checks+=1
	if not ok: failures+=1; printerr("FAIL: ",name_value)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var data:=Saves.defaults(); Garden.sync(data)
	check(Garden.buy(data.garden,0,0),"first free budget buys the first flower")
	var unlocked: Dictionary={}
	for level in range(1,60):
		data.completed.append(level); Garden.sync(data)
		for repair_id in 4:
			if repair_id in data.garden.repairs: continue
			var spec: Array=Garden.REPAIRS[repair_id]
			while data.garden.plots.size()<int(spec[3]) and data.garden.coins>=50:
				Garden.buy(data.garden,Garden.next_empty(data.garden),0)
			if Garden.repair(data.garden,repair_id): unlocked[repair_id]=level
			break
	check(int(unlocked.get(2,999))<=13,"nursery reachable by 13 new wins using starter flowers")
	check(int(unlocked.get(3,999))<=21,"shop reachable by 21 new wins using starter flowers")
	var legacy: Dictionary=data.garden.duplicate(true); legacy.farm.story_seen=range(12)
	check(Farm.valid(legacy.farm),"old completed 12-chapter save remains valid")
	check(Farm.next_story(legacy)==12,"old reader discovers the first added chapter")
	legacy.earned.clear()
	for id in range(1,251): legacy.earned.append("light:"+str(id)); legacy.earned.append("match:"+str(id))
	for id in range(12,18): check(Farm.claim_story(legacy,id),"new chapter unlocked in chronological order: "+str(id))
	check(Farm.next_story(legacy)==-1 and Farm.valid(legacy.farm),"all 18 chapters finish cleanly")
	legacy.farm.story_seen.append(0); check(not Farm.valid(legacy.farm),"duplicate story IDs rejected")
	var game=Main.new(); game.store=Saves.new("user://progression-audit-"+str(OS.get_process_id())+".json"); root.add_child(game)
	await process_frame
	game.store.data.tutorial_seen=["light"]; Farm.ensure(game.store.data.garden); Farm.plant(game.store.data.garden,0,0)
	game.open_level(1); game.puzzle.rotations=game.puzzle.level.solution.duplicate(); game.refresh(); game.persist()
	var coins: int=game.store.data.garden.coins
	check(int(game.store.data.garden.farm.beds["0"].growth)==1,"first solution grows crop once")
	game.open_level(1); check(int(game.store.data.garden.farm.beds["0"].growth)==1,"loading solved board gives no free growth")
	game.restart(); game.puzzle.rotations=game.puzzle.level.solution.duplicate(); game.refresh(); game.persist()
	check(int(game.store.data.garden.farm.beds["0"].growth)==2,"genuinely resolving earlier level grows crops")
	check(game.store.data.garden.coins==coins,"replay does not duplicate coin reward")
	game.refresh(); check(int(game.store.data.garden.farm.beds["0"].growth)==2,"refresh cannot duplicate growth")
	game.queue_free(); await process_frame; await create_timer(.15).timeout
	print("Progression audit checks=",checks," failures=",failures," unlock levels=",unlocked); quit(1 if failures else 0)
