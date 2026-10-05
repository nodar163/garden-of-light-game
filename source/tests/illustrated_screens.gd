extends SceneTree
const Main=preload("res://scripts/main.gd")
const Saves=preload("res://scripts/save_store.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=Main.new(); game.store=Saves.new("user://illustrated-screens-"+str(OS.get_process_id())+".json")
	root.add_child(game); game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); await process_frame
	game.store.data.garden.intro_done=true; game.store.data.tutorial_seen=["garden","light","match"]
	var screens: Dictionary={"modes":game.garden_ui.modes,"levels":game.show_levels,"match-levels":game.show_match_levels,"settings":game.show_settings,"journal":game.garden_ui.journal,"upgrades":game.garden_ui.business.upgrades,"album":game.garden_ui.business.album}
	for name_value in screens:
		screens[name_value].call()
		for i in 3: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/screen-"+name_value+".png")
	game.queue_free(); await process_frame; await create_timer(.15).timeout
	print("Illustrated screens rendered: ",screens.size()); quit()
