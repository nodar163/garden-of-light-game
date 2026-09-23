extends SceneTree
const Main=preload("res://scripts/main.gd")
const Saves=preload("res://scripts/save_store.gd")
const Rules=preload("res://scripts/garden_rules.gd")
var checks:=0
var failures:=0
var game: Control

func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1; printerr("FAIL: ",message)

func _initialize() -> void: call_deferred("run")

func capture(name_value: String) -> void:
	await process_frame; await process_frame; await process_frame
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/redesign-"+name_value+".png")

func buttons(node: Node) -> Array:
	var result: Array=[]
	if node is Button: result.append(node)
	for child in node.get_children(): result.append_array(buttons(child))
	return result

func layout_check() -> void:
	for b in buttons(game.shell):
		if b.is_visible_in_tree(): check(game.get_global_rect().grow(1).encloses(b.get_global_rect()),"visible button fits: "+b.text)

func run() -> void:
	root.size=Vector2i(390,700)
	game=Main.new(); game.store=Saves.new("user://redesign-"+str(OS.get_process_id())+".json")
	game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); root.add_child(game); await process_frame
	game.store.data.completed=range(1,31); Rules.sync(game.store.data)
	Rules.buy(game.store.data.garden,0,0)
	game.show_home(); await capture("home-mobile"); layout_check()
	check(game.garden_ui.map_view.size.y==game.size.y,"garden fills home height")
	var coins: int=game.store.data.garden.coins
	game.garden_ui.modes(); await capture("modes-mobile"); layout_check()
	var plays: Array=buttons(game.shell).filter(func(b): return b.text=="Продолжить")
	check(plays.size()==2,"both modes have a continue action")
	plays[1].pressed.emit(); await process_frame
	check(game.page=="play" and int(game.puzzle.level.id)==31,"light mode resumes first unfinished level")
	game.show_home(); game.garden_ui.modes(); await process_frame
	plays=buttons(game.shell).filter(func(b): return b.text=="Продолжить")
	plays[0].pressed.emit(); await process_frame
	check(game.page=="match","match mode opens from modes")
	game.garden_ui.focus_task(); await capture("goal-mobile"); layout_check()
	var map=game.garden_ui.map_view
	var point: Vector2=map.screen_point(Rules.REPAIR_POS[0]*map.WORLD)
	check(point.y<game.garden_ui.hud.footer.get_global_rect().position.y-40,"task target is above the bottom card")
	game.garden_ui.areas(); await process_frame
	var popup=game.get_child(game.get_child_count()-1)
	check(popup is PopupMenu and popup.item_count==5,"five named garden areas")
	popup.id_pressed.emit(4); popup.hide(); await capture("pond-mobile")
	check(game.garden_ui.map_view.focus_index==24,"area navigation focuses pond")
	check(game.garden_ui.map_view.visible_area()==4,"empty-place markers follow the selected area")
	check(game.store.data.garden.coins==coins,"navigation never spends coins")
	game.store.data.settings.language="en"; game.show_home(); await capture("home-en"); layout_check()
	game.garden_ui.modes(); await capture("modes-en"); layout_check()
	root.size=Vector2i(360,640); game.show_home(); await capture("home-small"); layout_check()
	var path: String=game.store.path
	game.queue_free(); await process_frame
	# AudioServer releases stopped playback on its next mix cycle.
	await create_timer(0.15).timeout
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(path+suffix): DirAccess.remove_absolute(path+suffix)
	print("Garden redesign checks: %d; failures: %d" % [checks,failures]); quit(1 if failures else 0)
