extends SceneTree
const Main=preload("res://scripts/main.gd")
const Saves=preload("res://scripts/save_store.gd")
const Guides=preload("res://scripts/tutorial.gd")
var game: Control
var failures:=0
var checks:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1; printerr("FAIL: ",label)
func _initialize() -> void: root.size=Vector2i(390,700); call_deferred("run")
func settle() -> void:
	for i in 4: await process_frame
func shot(name_value: String) -> void:
	await settle(); await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/expansion-"+name_value+".png")
func buttons(node: Node) -> void:
	if node is Button and node.is_visible_in_tree():
		check(game.get_global_rect().grow(1).encloses(node.get_global_rect()),"button fits: "+node.text)
		check(node.size.y>=99,"touch height: "+node.text)
	for child in node.get_children(): buttons(child)
func bench(name_value: String) -> void:
	var times: Array=[]
	for i in 90:
		var start:=Time.get_ticks_usec()
		await RenderingServer.frame_post_draw; times.append(Time.get_ticks_usec()-start); await process_frame
	times.sort(); print(name_value," render-wait median_us=",times[45]," p95_us=",times[85])
func run() -> void:
	game=Main.new(); game.store=Saves.new("user://estate-ui-"+str(OS.get_process_id())+".json"); root.add_child(game); game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); await settle()
	game.store.data.garden.intro_done=true; game.store.data.garden.repairs=[0,1,2,3,4]; game.store.data.tutorial_seen=Guides.KEYS.duplicate()
	game.store.data.completed=range(1,1001); game.store.data.match3.completed=range(1,1001); Saves.Garden.sync(game.store.data)
	for en in [false,true]:
		game.store.data.settings.language="en" if en else "ru"
		for inside in [false,true]:
			game.garden_ui.estate.open(inside); await settle(); buttons(game)
			await shot(("house" if inside else "estate")+("-en" if en else "-ru"))
			game.garden_ui.estate.map.focus_area(0); await settle()
			game.garden_ui.estate.map.pick(game.garden_ui.estate.map.screen(game.garden_ui.estate.map.points()[0])); await settle()
			check(game.page=="estate_repair","tap object opens repair"); buttons(game)
			await shot("repair-"+str(inside)+"-"+str(en))
	game.garden_ui.estate.open(true); await settle(); await bench("House")
	game.garden_ui.estate.open(false); await settle(); await bench("Estate")
	game.store.data.garden.farm.stock=[9,9,9,9,9,9]; game.garden_ui.business.shop(); await shot("shop"); await bench("Shop")
	game.garden_ui.business.nursery(); await shot("nursery"); await bench("Nursery")
	game.show_match_levels(); game.match_group=39; game.show_match_levels(); await settle(); buttons(game)
	game.open_match(1000); await settle(); check(game.page=="match","1000th match opens"); await bench("Match1000")
	game.open_level(1000); await settle(); check(game.page=="play","1000th light opens")
	for key in ["house","estate","shop","nursery"]:
		game.tutorial.open(key); await settle(); buttons(game.tutorial.layer); await shot("guide-"+key); game.tutorial.finish()
	game.queue_free(); await settle(); print("Estate UI checks=",checks," failures=",failures); quit(1 if failures else 0)
