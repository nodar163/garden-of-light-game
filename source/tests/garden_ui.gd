extends SceneTree
const Main=preload("res://scripts/main.gd")
const Saves=preload("res://scripts/save_store.gd")
const Rules=preload("res://scripts/garden_rules.gd")
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1; printerr("FAIL: ",message)
func _initialize() -> void:
	root.size=Vector2i(432,768)
	call_deferred("run")
func capture(name_value: String) -> void:
	await process_frame; await process_frame
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/jack-"+name_value+".png")
func run() -> void:
	var game=Main.new(); game.store=Saves.new("user://garden-ui-test.json")
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(game.store.path+suffix): DirAccess.remove_absolute(game.store.path+suffix)
	game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); root.add_child(game)
	await process_frame
	check(game.page=="intro","first launch begins with Jack")
	check(not game.sound.nature.playing and game.sound.music.playing,"menu melody without nature")
	await capture("intro")
	game.garden_ui.next_intro(); await capture("ruins")
	game.garden_ui.next_intro(); game.garden_ui.next_intro()
	check(game.page=="garden" and game.garden_ui.pending==0,"guided first planting preview")
	check(game.store.data.garden.coins==50,"preview does not spend")
	await capture("first-plant")
	game.garden_ui.purchase()
	check(game.store.data.garden.coins==0 and game.store.data.garden.plots.size()==1,"first purchase committed once")
	game.garden_ui.purchase()
	check(game.store.data.garden.coins==0,"repeated purchase event cannot double charge")
	game.garden_ui.finish_intro(); await capture("home")
	check(game.store.data.garden.intro_done,"intro completion persists")
	game.store.data.completed=range(1,21); Rules.sync(game.store.data)
	game.garden_ui.slot=1; game.garden_ui.shop(); await capture("shop")
	game.garden_ui.preview(2); await capture("preview")
	game.garden_ui.pending=-1; game.garden_ui.show()
	check(game.store.data.garden.coins==500,"cancel preview leaves balance")
	game.garden_ui.preview(2); game.garden_ui.purchase()
	check(game.store.data.garden.coins==420,"purchase debits displayed price")
	var map=game.garden_ui.map_view
	var camera_before=map.camera
	var press:=InputEventMouseButton.new(); press.button_index=MOUSE_BUTTON_LEFT; press.pressed=true; press.position=Vector2(250,250)
	map._gui_input(press)
	var motion:=InputEventMouseMotion.new(); motion.relative=Vector2(-70,20); motion.position=Vector2(180,270)
	map._gui_input(motion)
	press.pressed=false; press.position=motion.position; map._gui_input(press)
	check(map.camera!=camera_before,"drag pans map")
	check(game.garden_ui.slot==1,"drag does not select or buy")
	map.zoom_by(1.3); check(map.zoom>0.5,"zoom controls work")
	game.garden_ui.slot=-1; game.garden_ui.repair_index=0; game.garden_ui.show(); await capture("repair")
	game.garden_ui.restore()
	check(0 in game.store.data.garden.repairs,"restoration purchase works")
	game.garden_ui.help(); await capture("help")
	var saved=Saves.new(game.store.path); saved.load_data()
	check(saved.data.garden.plots==game.store.data.garden.plots and saved.data.garden.coins==game.store.data.garden.coins,"purchases survive reload")
	game.store.data.completed=range(1,251); game.store.data.match3.completed=range(1,251); Rules.sync(game.store.data)
	for i in Rules.PLOT_COUNT: Rules.buy(game.store.data.garden,i,i%Rules.ITEMS.size())
	for i in Rules.REPAIRS.size(): Rules.repair(game.store.data.garden,i)
	game.garden_ui.slot=-1; game.garden_ui.repair_index=-1; game.garden_ui.message=""; game.garden_ui.show()
	game.garden_ui.map_view.overview(); await capture("restored")
	game.store.data.settings.language="en"; game.garden_ui.help(); await capture("help-en")
	game.queue_free(); await process_frame
	# AudioServer releases stopped playback on its next mix cycle.
	await create_timer(0.15).timeout
	print("Garden UI checks: %d; failures: %d" %[checks,failures])
	quit(1 if failures else 0)
