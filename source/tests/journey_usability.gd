extends SceneTree
const Main=preload("res://scripts/main.gd")
const Saves=preload("res://scripts/save_store.gd")
const Garden=preload("res://scripts/garden_rules.gd")
const Farm=preload("res://scripts/garden_farm.gd")
const Story=preload("res://scripts/garden_story.gd")
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
func buttons(node: Node) -> Array:
	var result: Array=[]
	if node is Button: result.append(node)
	for child in node.get_children(): result.append_array(buttons(child))
	return result
func scroll_parent(node: Node) -> bool:
	while node!=null:
		if node is ScrollContainer: return true
		node=node.get_parent()
	return false
func capture(name_value: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/journey-"+name_value+".png")
func run() -> void:
	game=Main.new(); game.store=Saves.new("user://journey-check-"+str(OS.get_process_id())+".json"); root.add_child(game); game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); await settle()
	game.store.data=Saves.defaults(); Garden.sync(game.store.data); game.store.data.garden.intro_done=true; game.store.data.tutorial_seen=Guide.KEYS.duplicate()
	# Follow only the recommended goals, rather than assume they form a viable loop.
	for turn in 100:
		var g: Dictionary=game.store.data.garden
		if g.farm.orders_done>0: break
		var goal: Dictionary=game.garden_ui.next_goal()
		var changed:=false
		match goal.action:
			"plant": changed=Garden.buy(g,Garden.next_empty(g),0)
			"journal": changed=Story.claim(g,Story.next(g))
			"play": game.store.data.completed.append(game.store.data.completed.size()+1); Garden.sync(game.store.data); Farm.grow(g); changed=true
			"repair": changed=Garden.repair(g,goal.id)
			"nursery":
				if g.farm.beds.is_empty(): Farm.prepare(g,0); changed=Farm.plant(g,0,0)
				elif int(g.farm.beds["0"].growth)==3: changed=Farm.harvest(g,0)>0
				else: changed=Farm.water(g,0)
			"shop": Farm.arrange(g,0); Farm.wrap_bouquet(g,0); changed=Farm.serve(g)
		check(changed,"recommended goal is actionable: "+str(goal))
	check(game.store.data.garden.farm.orders_done==1,"one-goal route reaches the first real sale")
	check(game.store.data.completed.size()<=24,"first sale achievable without excessive extra levels")
	var coins: int=game.store.data.garden.coins
	game.garden_ui.repair_index=4; game.store.data.garden.coins=1000
	for i in 8: game.store.data.garden.plots[str(i)]=0
	game.garden_ui.restore(); await settle(); check(game.page=="repair_reveal","successful repair shows comparison")
	await capture("repair")
	var balance: int=game.store.data.garden.coins; game.garden_ui.restore(); check(game.store.data.garden.coins==balance,"cannot charge for same repair twice")
	game.open_match(1); game.store.data.match3.completed=[1]; game.open_match(2); game.match_model.moves=0; game.save_match(); game.refresh_match(); await settle()
	check(game.match_rest_button.visible,"failed attempt offers a familiar level")
	var hard: Dictionary=game.store.data.match3.boards["2"].duplicate(true)
	coins=game.store.data.garden.coins; game.match_rest(); await settle()
	check(int(game.match_model.level.id)==1 and game.match_model.moves>0,"break starts a playable completed level")
	check(game.store.data.match3.boards["2"]==hard and game.store.data.garden.coins==coins,"break preserves hard attempt and coins")
	var routes: Array=[game.show_home,game.show_settings,game.garden_ui.open_garden,game.garden_ui.modes,game.show_levels,game.show_match_levels,game.garden_ui.journal,game.garden_ui.business.nursery,game.garden_ui.business.shop,game.garden_ui.business.story,game.garden_ui.business.upgrades,game.garden_ui.business.album,game.garden_ui.open_shop,game.show_backup,func(): game.open_level(1),func(): game.open_match(1)]
	for dimensions in [Vector2i(320,568),Vector2i(390,844),Vector2i(768,1024)]:
		root.size=dimensions
		for language in ["ru","en"]:
			game.store.data.settings.language=language
			for route in routes:
				route.call(); await settle()
				var visible: Array=[]
				for b in buttons(game.shell):
					if not b.is_visible_in_tree() or b.mouse_filter==Control.MOUSE_FILTER_IGNORE: continue
					check(b.size.y>=99 and b.size.x>=99,"touch target "+b.text)
					if scroll_parent(b): continue
					check(game.get_global_rect().grow(2).encloses(b.get_global_rect()),"fits "+str(dimensions)+" "+game.page+" "+b.text)
					for other in visible: check(not b.get_global_rect().intersects(other.get_global_rect()),"buttons do not overlap: "+b.text)
					visible.append(b)
				if dimensions==Vector2i(320,568) and language=="ru" and game.page in ["match","settings","home"]: await capture(game.page)
	game.queue_free(); await process_frame
	print("Journey usability checks=",checks," failures=",failures); quit(1 if failures else 0)
