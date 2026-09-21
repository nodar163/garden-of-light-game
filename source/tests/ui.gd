extends SceneTree
const Main = preload("res://scripts/main.gd")
const Saves = preload("res://scripts/save_store.gd")
var failures := 0
var checks := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)

func _initialize() -> void:
	call_deferred("run")

func capture(name_value: String) -> void:
	await process_frame
	await process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/" + name_value + ".png")

func run() -> void:
	var game = Main.new()
	game.store = Saves.new("user://ui-test-save.json")
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(game.store.path + suffix):
			DirAccess.remove_absolute(game.store.path + suffix)
	game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(game)
	await process_frame
	check(game.page == "home" and game.unlocked() == 1, "new player sees home and first level")
	await capture("home")
	check(game.levels.size() == 250, "all 250 levels loaded")
	for id in range(1,251):
		game.open_level(id)
		await process_frame
		if id == 250:
			await capture("expert-unsolved")
		check(not game.puzzle.won() and game.status.text.contains("/ %d" % game.puzzle.level.cells.count("plant")), "initial flower state %d" % id)
		var index: int = game.puzzle.hint_index()
		var previous: Array = game.puzzle.rotations.duplicate()
		var rect: Rect2 = game.board.field_rect()
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = true
		var n: int = int(game.puzzle.level.size)
		event.position = rect.position + Vector2(index%n+0.5,index/n+0.5)*rect.size.x/n
		game.board._gui_input(event)
		check(game.puzzle.rotations != previous, "pointer input turns tile %d" % id)
		var intermediate: Array = game.puzzle.rotations.duplicate()
		var disk = Saves.new(game.store.path)
		disk.load_data()
		check(disk.data.boards.get(str(id)) == intermediate, "each turn saved on disk %d" % id)
		game.undo()
		check(game.puzzle.rotations == previous, "UI undo %d" % id)
		for _step in game.puzzle.level.cells.size():
			if game.puzzle.won():
				break
			game.hint()
			check(game.selected_hint >= 0 and game.board.hint == game.selected_hint, "hint highlights before changing")
			game.hint()
			check(game.store.last_error == "", "hint save succeeds %d" % id)
		check(game.puzzle.won() and game.next_button.visible, "victory exposes next button %d" % id)
		check(game.store.data.boards.has(str(id)), "save uses stable integer level key")
		check(game.store.data.completed.size() == id, "one flower awarded %d" % id)
		game.refresh()
		check(game.store.data.completed.size() == id, "refresh does not duplicate rewards")
		if id == 4:
			await create_timer(0.6).timeout
			await capture("bloom")
	game.show_garden()
	await capture("garden")
	game.change_garden(4)
	check(game.garden_section == 4, "fifth garden available")
	await capture("garden-final")
	game.show_levels()
	game.select_group(9)
	check(game.level_group == 9, "last group reachable")
	await capture("levels")
	game.show_settings()
	game.toggle("music")
	check(not game.sound.music.playing, "music toggle stops playback")
	game.toggle("reduce_motion")
	game.store.data.settings.language = "en"
	game.open_level(1)
	check(game.board.reduced and game.status.text.contains("clearing"), "English, saved board, and reduced motion applied")
	game.restart()
	check(not game.puzzle.won() and game.store.data.completed.size() == 250, "replay keeps rewards")
	await capture("english")
	game.show_settings()
	await capture("settings")
	game.store.data.settings.music = true
	game.sound.configure(game.store.data.settings)
	game.sound.chime()
	await process_frame
	game.sound._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	check(game.sound.music.stream_paused and game.sound.effect.stream_paused, "backgrounding pauses audio")
	game.sound._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	check(not game.sound.music.stream_paused, "foreground restores audio state")
	var reread = Saves.new(game.store.path)
	reread.load_data()
	check(reread.data.completed.size() == 250 and reread.data.settings.language == "en", "UI progress survives reload")
	game.queue_free()
	await process_frame
	await create_timer(0.15).timeout
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(reread.path + suffix):
			DirAccess.remove_absolute(reread.path + suffix)
	print("UI checks: %d; failures: %d" % [checks, failures])
	quit(1 if failures else 0)
