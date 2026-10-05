extends SceneTree
const Main=preload("res://scripts/main.gd")
const Saves=preload("res://scripts/save_store.gd")
const Farm=preload("res://scripts/garden_farm.gd")
const Rules=preload("res://scripts/garden_rules.gd")
const World=preload("res://scripts/farm_world.gd")
var checks:=0
var failures:=0

func check(ok: bool, value: String) -> void:
	checks+=1
	if not ok: failures+=1; printerr("FAIL: ",value)

func _initialize() -> void:
	root.size=Vector2i(390,700); call_deferred("run")

func settle() -> void:
	for i in 10: await process_frame

func drag(view: Control, from: Vector3, to: Vector3) -> void:
	var start: Vector2=view.projected(from)
	var finish: Vector2=view.projected(to)
	var event:=InputEventMouseButton.new(); event.button_index=MOUSE_BUTTON_LEFT; event.pressed=true; event.position=start
	view._gui_input(event)
	var motion:=InputEventMouseMotion.new(); motion.position=finish; motion.relative=finish-start; view._gui_input(motion)
	event.position=finish; event.pressed=false; view._gui_input(event)
	await settle()

func capture(name_value: String) -> void:
	await settle()
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/illustrated-"+name_value+".png")

func run() -> void:
	var game=Main.new(); var path: String="user://world-test-"+str(OS.get_process_id())+".json"
	game.store=Saves.new(path); root.add_child(game); game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); await settle()
	game.store.data.garden.intro_done=true; game.store.data.tutorial_seen=["garden","light","match"]
	game.store.data.garden.coins=500
	game.garden_ui.business.nursery(); await settle()
	var view: Control=game.root_box.get_child(1)
	check(view is World,"nursery uses the illustrated interactive room")
	for i in 6:
		check(view.source_at(view.projected(World.BED_POS[i]))==["bed",i],"bed %d hit area follows artwork" % i)
		check(view.source_at(view.projected(view.seed_pos(i)))==["seed",i],"seed %d hit area follows artwork" % i)
	await drag(view,World.TOOL_POS[0],World.BED_POS[0])
	check(0 in game.store.data.garden.farm.prepared,"spade drag prepares soil")
	await drag(view,view.seed_pos(0),World.BED_POS[0])
	check(game.store.data.garden.farm.beds.has("0"),"seed drag plants a bed")
	await drag(view,World.TOOL_POS[1],World.BED_POS[0])
	check(int(game.store.data.garden.farm.beds["0"].growth)==1,"watering drag grows the flower")
	await drag(view,World.TOOL_POS[1],World.BED_POS[0])
	check(int(game.store.data.garden.farm.beds["0"].growth)==1,"repeated watering cannot farm infinite growth")
	for i in 2: Farm.grow(game.store.data.garden)
	view.refresh(); await capture("nursery")
	await drag(view,World.BED_POS[0],World.TOOL_POS[2])
	check(game.store.data.garden.farm.stock[0]==2,"flower drag harvests into basket")
	check(not game.store.data.garden.farm.beds["0"].watered,"harvest resets watering")
	await drag(view,World.BED_POS[0],World.TOOL_POS[2])
	check(game.store.data.garden.farm.stock[0]==2,"unripe bed cannot be harvested twice")
	game.garden_ui.business.shop(); await settle(); view=game.root_box.get_child(1)
	for i in 6: check(view.source_at(view.projected(World.STOCK_POS[i]))==["flower",i],"display %d hit area follows artwork" % i)
	for i in 3: check(view.source_at(view.projected(view.paper_pos(i)))==["paper",i],"paper %d hit area follows artwork" % i)
	await drag(view,World.STOCK_POS[0]+Vector3(0,.9,0),World.DESK+Vector3(0,1.7,0))
	check(game.store.data.garden.farm.draft.flowers==[0],"shelf flower moves onto bouquet table")
	var saved=Saves.new(path); saved.load_data()
	check(saved.data.garden.farm.draft.flowers==[0],"unfinished bouquet survives reload")
	await drag(view,view.paper_pos(1),World.DESK+Vector3(0,1.7,0))
	check(game.store.data.garden.farm.draft.wrapped and game.store.data.garden.farm.draft.wrap==1,"paper drag wraps a illustrated bouquet")
	await capture("shop-bouquet")
	var before: int=int(game.store.data.garden.coins)
	check(view.near(view.point(view.QUEUE[0]-Vector2(0,.055)),World.CASH,1.5),"bouquet can be handed directly to the customer")
	await drag(view,World.DESK+Vector3(0,1.8,0),World.CASH+Vector3(0,.6,-.5))
	check(game.store.data.garden.farm.orders_done==1 and game.store.data.garden.coins>before,"checkout drag commits one paid order")
	check(game.store.data.garden.farm.stock[0]==1 and game.store.data.garden.farm.draft.flowers.is_empty(),"sale deducts inventory exactly once and clears table")
	check(not Farm.serve(game.store.data.garden),"queue animation cannot duplicate an empty sale")
	await create_timer(.55).timeout
	check(not view.busy and is_zero_approx(view.queue_offset),"queue finishes moving and accepts the next order")
	check(Farm.valid(game.store.data.garden.farm),"all gesture operations produce valid saved data")
	game.show_home(); await capture("home")
	game.garden_ui.map_view.select_at(game.garden_ui.map_view.screen_point(game.garden_ui.map_view.NURSERY_POS*game.garden_ui.map_view.WORLD))
	check(game.page=="nursery","nursery building opens from main garden")
	game.show_home(); await settle()
	game.garden_ui.map_view.select_at(game.garden_ui.map_view.screen_point(game.garden_ui.map_view.BUSINESS_POS*game.garden_ui.map_view.WORLD))
	check(game.page=="business_shop","shop building opens before first shop upgrade")
	game.open_level(1); await capture("light")
	check(game.board.puzzle==game.puzzle,"light board retains its playable model")
	game.open_match(1); await capture("match")
	check(game.match_view.model==game.match_model,"match board retains its playable model")
	game.queue_free(); await settle()
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(path+suffix): DirAccess.remove_absolute(path+suffix)
	print("Illustrated world checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
