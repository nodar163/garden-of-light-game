extends SceneTree

const Main=preload("res://scripts/main.gd")
const Saves=preload("res://scripts/save_store.gd")
const Garden=preload("res://scripts/garden_rules.gd")
const Farm=preload("res://scripts/garden_farm.gd")
var checks:=0
var failures:=0

func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1; printerr("FAIL: ",message)

func capture(name_value: String) -> void:
	await process_frame; await process_frame
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/farm-"+name_value+".png")

func _initialize() -> void:
	root.size=Vector2i(390,700)
	call_deferred("run")

func run() -> void:
	var game=Main.new(); game.store=Saves.new("user://farm-ui-"+str(OS.get_process_id())+".json")
	game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); root.add_child(game); await process_frame
	game.store.data.garden.intro_done=true
	game.store.data.tutorial_seen=["garden","light","match"]
	game.store.data.completed=range(1,61)
	Garden.sync(game.store.data)
	game.store.data.garden.coins=1500
	check(Farm.plant(game.store.data.garden,0,0),"starter flower can be planted")
	check(Farm.plant(game.store.data.garden,1,1),"second flower can be planted")
	game.open_level(1)
	var before_growth: int=int(game.store.data.garden.farm.beds["0"].growth)
	game.puzzle.rotations=game.puzzle.level.solution.duplicate()
	game.refresh(); game.persist()
	check(int(game.store.data.garden.farm.beds["0"].growth)==before_growth+1,"replayed light level grows flowers")
	game.refresh()
	check(int(game.store.data.garden.farm.beds["0"].growth)==before_growth+1,"same win never grows twice")
	for i in 3: Farm.grow(game.store.data.garden)
	game.garden_ui.business.nursery(); await capture("nursery-ru")
	check(game.page=="nursery","nursery opens")
	game.garden_ui.business.harvest_bed(0)
	check(game.store.data.garden.farm.stock[0]==2,"harvest action is saved")
	game.garden_ui.business.shop(); await capture("shop-ru")
	check(game.page=="business_shop","flower shop opens")
	game.garden_ui.business.change_pick(0,1)
	game.garden_ui.business.choose_wrap(1); await capture("bouquet-ru")
	game.garden_ui.business.sell_bouquet()
	check(game.store.data.garden.farm.orders_done==1,"UI sale saves order")
	check(game.page=="bouquet_result" and game.store.data.garden.farm.album.size()==1 and int(game.store.data.garden.farm.album[0].wrap)==1,"finished bouquet and wrapper appear in album")
	await capture("sale-result-ru")
	game.store.data.garden.repairs=[0,1,2,3]
	check(game.store.garden_transaction(func(data): return Farm.build_garden(data,0)),"seed pavilion saves through UI store")
	check(game.store.garden_transaction(func(data): return Farm.build_garden(data,1)),"bouquet workshop saves through UI store")
	game.store.data.garden.farm.shop_tier=1
	game.garden_ui.open_garden(); await capture("garden-buildings")
	check(game.page=="garden","garden with new buildings opens")
	game.garden_ui.map_view.camera=Vector2(2600,790); game.garden_ui.map_view.zoom=.62; game.garden_ui.map_view.queue_redraw(); await capture("garden-nursery-map")
	game.garden_ui.map_view.camera=Vector2(670,1740); game.garden_ui.map_view.zoom=.62; game.garden_ui.map_view.queue_redraw(); await capture("garden-shop-map")
	game.garden_ui.business.story(); await capture("story-ru")
	check(game.page=="lily_story","Lily story opens")
	game.garden_ui.business.scene(0); await capture("lily-scene")
	game.store.data.settings.language="en"
	game.garden_ui.business.nursery(); await capture("nursery-en")
	game.garden_ui.business.shop(); await capture("shop-en")
	var path: String=game.store.path
	game.queue_free(); await process_frame; await create_timer(.15).timeout
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(path+suffix): DirAccess.remove_absolute(path+suffix)
	print("Farm UI checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
