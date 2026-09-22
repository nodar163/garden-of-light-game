extends SceneTree
const Main = preload("res://scripts/main.gd")
const Saves = preload("res://scripts/save_store.gd")
var checks := 0
var failures := 0

func check(value: bool, message: String) -> void:
	checks+=1
	if not value: failures+=1; printerr("FAIL: ",message)

func _initialize() -> void: call_deferred("run")

func capture(name_value: String) -> void:
	await process_frame
	await process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/match-"+name_value+".png")

func run() -> void:
	var game=Main.new()
	game.store=Saves.new("user://match-ui-test.json")
	for suffix in ["",".tmp",".bak"]:
		if FileAccess.file_exists(game.store.path+suffix): DirAccess.remove_absolute(game.store.path+suffix)
	game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(game)
	await process_frame
	game.show_home()
	check(game.sound.music.playing and not game.sound.nature.playing,"menu uses melody without nature")
	game.sound._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	check(game.sound.music.stream_paused,"backgrounding pauses nature")
	game.sound._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	check(not game.sound.music.stream_paused,"foreground restores nature")
	await capture("home")
	game.show_match_levels()
	check(not game.sound.nature.playing,"nature fades out of home")
	check(game.match_unlocked()==1,"separate mode starts at level one")
	await capture("levels")
	game.open_match(2)
	check(game.page=="match_levels","locked level cannot open")
	game.open_match(1)
	await process_frame
	check(not game.match_hint_button.disabled,"hint initially available")
	game.match_hint()
	check(not game.match_view.hint_cells.is_empty(),"hint shows legal action")
	await capture("play")
	var action: Array=game.match_model.level.witness[0]
	game.match_view.animate_move(int(action[0]),int(action[1]))
	check(game.match_view.busy,"input locked during animation")
	var saved_moves: int=game.match_model.moves
	game.match_view.animate_move(int(action[0]),int(action[1]))
	check(game.match_model.moves==saved_moves,"rapid second gesture cannot spend a move")
	var disk=Saves.new(game.store.path); disk.load_data()
	check(disk.data.match3.boards["1"]==JSON.parse_string(JSON.stringify(game.match_model.snapshot())),"settled model saved before animation")
	await game.match_view.animation_done
	check(not game.match_view.busy,"animation completes and unlocks input")
	game.restart_match()
	game.match_view.animate_move(int(action[0]),int(action[1]))
	var mid_animation: Dictionary=game.match_model.snapshot()
	game.show_home()
	await process_frame
	game.open_match(1)
	check(game.match_model.snapshot()==mid_animation,"leaving during cascade restores settled state")
	game.restart_match()
	game.match_view.reduced=true
	var tool_moves: int=game.match_model.moves
	game.select_match_tool(0)
	game.match_view.choose(14)
	check(game.match_model.moves==tool_moves and game.match_model.tools_left[0]==0,"tool UI consumes tool without move")
	check(game.tool_buttons[0].disabled,"consumed tool disabled")
	game.show_home(); await process_frame; game.open_match(1)
	check(game.match_model.tools_left[0]==0,"tool inventory survives page change")
	game.restart_match()
	game.show_starter()
	await process_frame
	var menu=game.get_child(game.get_child_count()-1)
	check(menu is PopupMenu,"starter choice opens")
	menu.id_pressed.emit(1); menu.hide()
	check(game.match_model.starter_used and game.match_model.powers.count("burst")==1,"starter UI places bomb")
	game.match_model.powers[15]="bee"
	game.match_view.shown=game.match_model.snapshot(); game.match_view.queue_redraw()
	await capture("premium-powers")
	game.restart_match()
	for id in [1,26,126,250]:
		game.store.data.match3.completed=range(1,id)
		game.store.data.settings.reduce_motion=true
		game.open_match(id)
		await process_frame
		await capture("level-"+str(id))
		for step in game.match_model.level.witness:
			await game.match_view.animate_move(int(step[0]),int(step[1]))
			check(game.store.last_error=="","move save succeeds")
		check(game.match_model.won() and game.match_next.visible,"victory UI "+str(id))
		check(game.store.data.match3.completed.count(id)==1,"single bouquet reward")
		check(game.store.data.completed.is_empty(),"old mode progress untouched")
		game.save_match(); check(game.store.data.match3.completed.count(id)==1,"reward idempotent")
		await capture("victory-"+str(id))
	game.show_home()
	game.toggle("music")
	check(not game.sound.nature.playing and not game.sound.music.playing,"music switch stops nature and music")
	game.store.data.settings.language="en"
	game.show_match_help(); await capture("help-en")
	game.open_match(250); game.restart_match()
	await capture("expert-en")
	game.match_model.moves=0; game.refresh_match()
	check(game.match_hint_button.disabled and game.match_message.text.contains("Out of moves"),"out-of-moves retry state")
	await capture("out-of-moves")
	var path: String=game.store.path
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	for suffix in ["",".tmp",".bak"]:
		if FileAccess.file_exists(path+suffix): DirAccess.remove_absolute(path+suffix)
	print("Match UI checks: %d; failures: %d" % [checks,failures])
	quit(1 if failures else 0)
