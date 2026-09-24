extends SceneTree
const Rules=preload("res://scripts/garden_rules.gd")
const Story=preload("res://scripts/garden_story.gd")
const Saves=preload("res://scripts/save_store.gd")
const Main=preload("res://scripts/main.gd")
var checks:=0
var failures:=0
func check(ok: bool,text: String) -> void:
	checks+=1
	if not ok: failures+=1; printerr("FAIL: ",text)
func _initialize() -> void: call_deferred("run")
func buttons(node: Node) -> Array:
	var found: Array=[]
	if node is Button: found.append(node)
	for child in node.get_children(): found.append_array(buttons(child))
	return found
func capture(game: Control,title: String) -> void:
	await process_frame; await process_frame; await process_frame
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/story-"+title+".png")
func run() -> void:
	var data: Dictionary=Saves.defaults()
	check(not data.garden.has("story"),"old state before migration")
	Rules.sync(data); var g: Dictionary=data.garden
	check(Saves.valid(data),"migration valid")
	check(not Story.claim(g,0),"unready chapter rejected")
	check(Rules.buy(g,0,0),"first bed affordable")
	check(Story.claim(g,0),"first scene")
	check(not Story.claim(g,0),"scene reward cannot repeat")
	data.completed=range(1,13); Rules.sync(data)
	check(Story.claim(g,1),"existing levels count")
	check(Rules.repair(g,0),"entrance affordable within first twelve")
	check(Story.claim(g,2),"entrance scene")
	check(not Story.deliver(g,0),"missing bouquet variety rejected")
	check(Rules.buy(g,1,1),"second flower affordable")
	check(Story.deliver(g,0),"Anna order")
	var money: int=g.coins
	check(not Story.deliver(g,0) and g.coins==money,"no duplicate order payment")
	check(Story.claim(g,3) and Story.claim(g,4),"first chapter complete")
	check(g.story.evening and g.coins>=0,"evening unlocked without overspending")
	check(Rules.move(g,0,2) and int(g.plots["2"])==0,"move to free plot")
	check(Rules.move(g,2,1) and int(g.plots["2"])==1,"swap occupied plots")
	check(g.coins==money,"moving costs nothing")
	check(Story.style(g,0,2) and not Story.style(g,1,2),"only restored buildings can be styled")
	var bad: Dictionary=data.duplicate(true); bad.garden.story.styles["0"]=7
	check(not Saves.valid(bad),"invalid style rejected")
	var path: String="user://story-test-"+str(OS.get_process_id())+".json"
	var save=Saves.new(path); save.data=data
	check(save.write(),"story saved")
	var restored=Saves.new(path); restored.load_data()
	check(restored.data.garden.story.claimed.size()==5,"story restored")
	check(not restored.import_copy("bad") and restored.data.garden.coins==money,"invalid backup preserves progress")
	check(restored.import_copy(JSON.stringify(data)),"backup restored")
	root.size=Vector2i(390,700)
	var game=Main.new(); game.store=restored; game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); root.add_child(game); await process_frame
	game.store.data=data; game.store.data.garden.intro_done=true
	game.show_home(); await capture(game,"home-evening")
	game.garden_ui.journal(); await capture(game,"journal")
	var journal=preload("res://scripts/garden_journal.gd").new(game.garden_ui)
	journal.orders(); await capture(game,"orders")
	journal.album(); await capture(game,"album")
	game.garden_ui.select_place("repair",0); await capture(game,"styles")
	for b in buttons(game.shell):
		if b.is_visible_in_tree(): check(game.get_global_rect().grow(1).encloses(b.get_global_rect()),"style button fits: "+b.text)
	game.show_backup(); await capture(game,"backup")
	game.store.data.garden.story.last_mode="light"; game.show_home(); await process_frame
	var light: Array=buttons(game.shell).filter(func(b): return b.text.begins_with("Дорожки света"))
	check(light.size()==1,"home resumes preferred mode")
	game.store.data.settings.language="en"; journal.orders(); await capture(game,"orders-en")
	root.size=Vector2i(360,640); game.garden_ui.select_place("repair",0); await capture(game,"styles-small")
	for b in buttons(game.shell):
		if b.is_visible_in_tree(): check(game.get_global_rect().grow(1).encloses(b.get_global_rect()),"small style button fits: "+b.text)
	game.queue_free(); await process_frame; await create_timer(.2).timeout
	for suffix in ["",".tmp",".bak"]:
		if FileAccess.file_exists(path+suffix): DirAccess.remove_absolute(path+suffix)
	print("STORY checks=",checks," failures=",failures)
	quit(1 if failures else 0)
