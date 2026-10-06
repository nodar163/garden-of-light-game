extends SceneTree
const Main=preload("res://scripts/main.gd")
const Saves=preload("res://scripts/save_store.gd")
const Prologue=preload("res://scripts/prologue.gd")
const Guide=preload("res://scripts/tutorial.gd")
var checks:=0
var failures:=0
var game: Control
func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok: failures+=1; printerr("FAIL: ",label)
func _initialize() -> void: call_deferred("run")
func settle() -> void:
	await process_frame; await process_frame; await process_frame
func memory() -> Control:
	for child in game.root_box.get_children():
		if child is Prologue: return child
	return null
func tap(view: Control, at: Vector2) -> void:
	var event:=InputEventMouseButton.new(); event.button_index=MOUSE_BUTTON_LEFT; event.position=at; event.pressed=true; view._gui_input(event); event.pressed=false; view._gui_input(event)
func practice(view: Control) -> void:
	var points: Array=view.endpoints()
	tap(view,points[0]); tap(view,points[1])
func capture(name_value: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/prologue-"+name_value+".png")
func buttons(node: Node) -> Array:
	var result: Array=[]
	if node is Button: result.append(node)
	for child in node.get_children(): result.append_array(buttons(child))
	return result
func bounds(node: Node) -> void:
	for b in buttons(node):
		if not b.is_visible_in_tree(): continue
		check(game.get_global_rect().grow(1).encloses(b.get_global_rect()),"button fits: "+b.text)
		check(b.size.y>=99,"touch height: "+b.text)
func run() -> void:
	root.size=Vector2i(320,568)
	game=Main.new(); game.store=Saves.new("user://prologue-check-"+str(OS.get_process_id())+".json")
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(game.store.path+suffix): DirAccess.remove_absolute(game.store.path+suffix)
	root.add_child(game); game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); await settle()
	var intro:=memory()
	check(intro!=null and intro.step==0,"fresh player starts before storm")
	check(game.store.data.garden.repairs.is_empty(),"restored intro does not repair actual garden")
	await capture("happy"); bounds(intro)
	intro.advance(); await settle()
	check(intro.next_button.disabled,"must practice or explicitly skip")
	var original: Dictionary=game.store.data.garden.duplicate(true)
	for i in 4:
		check(not intro.room.perform_drop("flower",4,Vector2.ZERO),"invalid action cannot advance")
		practice(intro.room); await settle(); check(intro.room.lesson==i+1,"nursery two-tap step "+str(i))
	check(game.store.data.garden==original,"practice does not spend coins or grant harvest")
	check(intro.room.g().farm.harvested>0,"real harvest rules exercised")
	await capture("nursery"); bounds(intro)
	intro.advance(); await settle()
	for i in 3:
		practice(intro.room); await settle(); check(intro.room.lesson==i+1,"shop two-tap step "+str(i))
	check(intro.room.g().farm.orders_done==1,"one practice sale")
	check(not intro.room.perform_drop("bouquet",0,intro.room.projected(intro.room.CASH)),"no duplicate sale")
	await capture("shop"); bounds(intro)
	intro.advance(); intro.advance(); await settle(); check(intro.step==4,"storm follows sale")
	await capture("storm")
	var loaded:=Saves.new(game.store.path); loaded.load_data(); check(loaded.data.garden.prologue_step==4,"resume saved chapter")
	intro.advance(); await settle(); await capture("breakup"); bounds(intro)
	intro.advance(); await settle(); bounds(intro); intro.finish(); await settle()
	check(game.page=="home" and game.store.data.garden.intro_done,"finish begins rebuilding")
	check(game.store.data.garden.coins==50 and game.store.data.garden.repairs.is_empty(),"storm did not erase earned assets")
	check(game.garden_ui.next_goal().action=="plant","first goal has planting action")
	game.store.data.garden.coins=1200; game.store.data.garden.repairs=[0,1,2,3]; game.store.data.tutorial_seen=Guide.KEYS.duplicate()
	var veteran: Dictionary=game.store.data.duplicate(true)
	for language in ["ru","en"]:
		game.store.data.settings.language=language
		game.garden_ui.replay=true; game.garden_ui.intro(0); await settle(); intro=memory()
		for id in 7:
			intro.step=id; intro.show_step(); await settle(); bounds(intro)
		intro.finish(); await settle()
		check(game.store.data.garden==veteran.garden,"replay preserves existing garden "+language)
		game.show_settings(); await settle(); bounds(game.shell)
	var corrupt: Dictionary=game.store.data.duplicate(true); corrupt.garden.prologue_step=2.5
	check(not Saves.valid(corrupt),"fractional intro checkpoint rejected")
	corrupt.garden.erase("prologue_step"); check(Saves.valid(corrupt),"old saves remain accepted")
	game.queue_free(); await process_frame
	print("Prologue checks=",checks," failures=",failures); quit(1 if failures else 0)
