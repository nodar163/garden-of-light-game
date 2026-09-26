extends SceneTree
const Main=preload("res://scripts/main.gd")
const Saves=preload("res://scripts/save_store.gd")
const Guide=preload("res://scripts/tutorial.gd")
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1; printerr("FAIL: ",label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var path: String="user://tutorial-test-"+str(OS.get_process_id())+".json"
	root.size=Vector2i(390,700)
	var game=Main.new(); game.store=Saves.new(path); game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(game); await process_frame
	check(Saves.valid(game.store.data),"fresh save stays valid")
	var old: Dictionary=game.store.data.duplicate(true); old.erase("tutorial_seen")
	check(Saves.valid(old),"old save without tutorial flags stays valid")
	old.tutorial_seen=["wrong"]; check(not Saves.valid(old),"unknown tutorial key rejected")
	game.garden_ui.open_garden(); await process_frame
	check(game.tutorial.section=="garden" and is_instance_valid(game.tutorial.layer),"first garden visit opens guide")
	check(game.tutorial.heading.text.length()>0 and game.tutorial.body.text.length()>0,"garden guide explains action")
	await RenderingServer.frame_post_draw; root.get_texture().get_image().save_png("res://artifacts/tutorial-first-garden.png")
	game.tutorial.advance(); game.tutorial.advance(); game.tutorial.advance(); await process_frame
	check(Guide.seen(game.store.data,"garden"),"garden guide is saved after final step")
	game.garden_ui.open_garden(); await process_frame
	check(not is_instance_valid(game.tutorial.layer),"garden guide does not repeat")
	await RenderingServer.frame_post_draw; root.get_texture().get_image().save_png("res://artifacts/tutorial-garden-menu.png")
	game.open_level(1); await process_frame
	check(game.tutorial.section=="light" and is_instance_valid(game.tutorial.layer),"first light level opens guide")
	await RenderingServer.frame_post_draw; root.get_texture().get_image().save_png("res://artifacts/tutorial-light.png")
	game.tutorial.finish(); await process_frame
	game.open_match(1); await process_frame
	check(game.tutorial.section=="match" and is_instance_valid(game.tutorial.layer),"first flower level opens guide")
	await RenderingServer.frame_post_draw; root.get_texture().get_image().save_png("res://artifacts/tutorial-match.png")
	game.tutorial.finish(); await process_frame
	check(Guide.seen(game.store.data,"light") and Guide.seen(game.store.data,"match"),"both mode flags saved")
	game.garden_ui.modes(); await process_frame
	await RenderingServer.frame_post_draw; root.get_texture().get_image().save_png("res://artifacts/tutorial-modes.png")
	game.garden_ui.guides(); await process_frame
	game.tutorial.open("garden"); await process_frame
	check(is_instance_valid(game.tutorial.layer),"guide can be replayed")
	game.tutorial.finish()
	root.size=Vector2i(360,640); game.store.data.settings.language="en"
	game.tutorial.open("match"); await process_frame
	check(game.tutorial.heading.text=="Make a flower cascade","English guide text")
	var bounds: Rect2=game.tutorial.next_button.get_global_rect()
	check(game.get_global_rect().grow(1).encloses(bounds),"guide button fits small phone: "+str(bounds))
	await RenderingServer.frame_post_draw; root.get_texture().get_image().save_png("res://artifacts/tutorial-small-en.png")
	game.tutorial.finish(); game.queue_free(); await process_frame
	for suffix in ["",".tmp",".bak"]:
		if FileAccess.file_exists(path+suffix): DirAccess.remove_absolute(path+suffix)
	print("Tutorial checks=",checks," failures=",failures); quit(1 if failures else 0)
