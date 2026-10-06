extends SceneTree
const Main=preload("res://scripts/main.gd")
const Saves=preload("res://scripts/save_store.gd")
var game: Control
func _initialize() -> void: root.size=Vector2i(390,700); call_deferred("run")
func sample(name_value: String) -> void:
	for i in 15: await process_frame
	var times: Array=[]
	for i in 90:
		var start:=Time.get_ticks_usec()
		await RenderingServer.frame_post_draw
		times.append(Time.get_ticks_usec()-start)
		await process_frame
	times.sort()
	print(name_value," median_us=",times[45]," p95_us=",times[85]," draw_calls=",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
func run() -> void:
	game=Main.new(); game.store=Saves.new("user://world-perf-"+str(OS.get_process_id())+".json"); root.add_child(game); game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await process_frame
	game.store.data.garden.intro_done=true; game.store.data.tutorial_seen=["garden","light","match","nursery","shop"]; game.store.data.garden.repairs=[0,1,2,3]
	game.garden_ui.replay=true; game.garden_ui.intro(0); await sample("Prologue")
	var memory: Control=game.root_box.get_child(0)
	memory.step=4; memory.show_step(); await sample("Storm")
	await create_timer(4.1).timeout
	var landscape: Control=memory.body.get_child(2)
	if landscape.is_processing(): printerr("Storm animation did not stop"); quit(1); return
	await sample("Storm stopped")
	game.show_home(); await sample("Garden")
	game.garden_ui.business.nursery(); await sample("Nursery")
	game.garden_ui.business.shop(); await sample("Shop")
	game.store.data.match3.completed=range(1,250)
	game.open_match(250)
	if game.page!="match": printerr("Match benchmark did not open a board"); quit(1); return
	await sample("Match 250")
	game.open_level(250); await sample("Light")
	game.queue_free(); await process_frame; quit()
