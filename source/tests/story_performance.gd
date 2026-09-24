extends SceneTree
const Main=preload("res://scripts/main.gd")
const Saves=preload("res://scripts/save_store.gd")
const Rules=preload("res://scripts/garden_rules.gd")
var frame_times: Array=[]
var active:=false
var report: Dictionary={}
func _initialize() -> void: call_deferred("run")
func _process(delta: float) -> bool:
	if active: frame_times.append(delta*1000)
	return false
func stats(values: Array) -> Dictionary:
	values.sort()
	return {"samples":values.size(),"median_ms":values[values.size()/2],"p95_ms":values[int(values.size()*.95)],"max_ms":values.back()}
func run() -> void:
	root.size=Vector2i(390,700)
	var game=Main.new(); game.store=Saves.new("user://perf-story.json"); game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); root.add_child(game)
	await process_frame
	game.store.data.completed=range(1,251); game.store.data.match3.completed=range(1,251); Rules.sync(game.store.data)
	for i in 30: game.store.data.garden.plots[str(i)]=i%14
	game.store.data.garden.repairs=[0,1,2,3,4]; game.store.data.garden.story.evening=true
	game.garden_ui.open_garden(); await create_timer(.3).timeout
	frame_times=[]; active=true
	for i in 180:
		game.garden_ui.map_view.camera.x=1600+sin(i*.035)*480
		game.garden_ui.map_view.queue_redraw()
		await process_frame
	active=false; report.garden_pan=stats(frame_times)
	game.open_match(250); await create_timer(.3).timeout
	frame_times=[]; active=true
	for step in game.match_model.level.witness.slice(0,4):
		game.match_view.animate_move(int(step[0]),int(step[1]))
		if game.match_view.busy: await game.match_view.animation_done
	active=false; report.cascade=stats(frame_times)
	var times: Array=[]
	for i in 15:
		var start:=Time.get_ticks_usec()
		game.show_home(); await process_frame
		game.open_match(250); await process_frame
		times.append((Time.get_ticks_usec()-start)/1000.0)
	report.two_screen_transition=stats(times)
	var save_times: Array=[]
	for i in 10:
		var start:=Time.get_ticks_usec(); game.store.write(); save_times.append((Time.get_ticks_usec()-start)/1000.0)
	report.save_full_progress=stats(save_times)
	FileAccess.open("res://artifacts/story-performance.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print(JSON.stringify(report))
	game.queue_free(); await process_frame; await create_timer(.2).timeout
	for suffix in ["",".tmp",".bak"]:
		if FileAccess.file_exists("user://perf-story.json"+suffix): DirAccess.remove_absolute("user://perf-story.json"+suffix)
	quit()
