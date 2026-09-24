extends SceneTree
const Main=preload("res://scripts/main.gd")
const Saves=preload("res://scripts/save_store.gd")
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1; printerr("FAIL: ",label)
func _initialize() -> void: call_deferred("run")
func buttons(node: Node) -> Array:
	var result: Array=[]
	if node is Button: result.append(node)
	for child in node.get_children(): result.append_array(buttons(child))
	return result
func run() -> void:
	root.size=Vector2i(390,700)
	var game=Main.new(); game.store=Saves.new("user://photo-"+str(OS.get_process_id())+".json"); game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); root.add_child(game); await process_frame
	game.store.data.settings.language="en"; game.garden_ui.open_garden(); await process_frame
	check(buttons(game.shell).any(func(b): return b.text=="Photo"),"photo opens from garden")
	game.garden_ui.photo(); await process_frame
	check(game.page=="garden_photo","photo page")
	var photo_buttons:=buttons(game.shell)
	check(photo_buttons.size()==1 and photo_buttons[0].visible,"only back button shown")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/photo-instructions.png")
	await create_timer(3.2).timeout
	check(not photo_buttons[0].visible,"chrome hides for screenshot")
	root.get_texture().get_image().save_png("res://artifacts/photo-clean.png")
	var stage: Control=game.root_box.get_child(0)
	var scene: Control=stage.get_child(0)
	scene.place_selected.emit("plot",0)
	check(photo_buttons[0].visible,"touch returns controls")
	photo_buttons[0].pressed.emit(); await process_frame
	check(game.page=="garden","return keeps game")
	game.queue_free(); await process_frame; await create_timer(.15).timeout
	for suffix in ["",".tmp",".bak"]:
		var path: String="user://photo-"+str(OS.get_process_id())+".json"+suffix
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	print("Photo checks=",checks," failures=",failures); quit(1 if failures else 0)
