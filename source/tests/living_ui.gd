extends "res://tests/estate_ui.gd"
func run() -> void:
	root.size=Vector2i(320,568)
	game=Main.new(); game.store=Saves.new("user://living-ui-"+str(OS.get_process_id())+".json"); root.add_child(game); game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); await settle()
	game.store.data.garden.intro_done=true; game.store.data.garden.repairs=[0,1,2,3,4]; game.store.data.tutorial_seen=Guides.KEYS.duplicate()
	preload("res://scripts/garden_farm.gd").ensure(game.store.data.garden)
	game.store.data.garden.estate={"house:0":3}; game.store.data.garden.farm.stock=[3,3,3,3,3,3]
	for language in ["ru","en"]:
		game.store.data.settings.language=language
		game.garden_ui.requests.activities(); await settle(); buttons(game); await shot("activities-"+language)
		game.garden_ui.requests.show(); await settle(); buttons(game); await shot("requests-"+language)
		game.store.data.garden.requests={"next":0,"ready":true}; game.garden_ui.requests.show(); await settle(); buttons(game); await shot("reply-"+language)
		game.store.data.garden.requests={"next":8,"ready":false}; game.garden_ui.requests.show(); await settle(); buttons(game)
		game.garden_ui.requests.letter(7); await settle(); buttons(game)
		game.garden_ui.estate.house=true; game.garden_ui.estate.details(0); await settle(); buttons(game); await shot("styles-"+language)
		game.garden_ui.business.shop(); await settle(); buttons(game); await shot("living-shop-"+language)
	for style in [1,2]:
		game.store.data.garden.estate_styles={"house:0":style}
		game.garden_ui.estate.open(true); await settle(); game.garden_ui.estate.map.focus_area(0); await settle(); await shot("house-style-"+str(style))
	game.garden_ui.estate.open(false); await settle()
	check(game.garden_ui.estate.map.life.is_processing(),"visitors animate")
	game.store.data.settings.reduce_motion=true; game.garden_ui.estate.open(false); await settle()
	check(not game.garden_ui.estate.map.life.is_processing(),"reduced motion disables visitors")
	game.tutorial.open("living_garden"); await settle(); buttons(game.tutorial.layer); await shot("living-guide")
	game.queue_free(); await settle(); print("Living UI checks=",checks," failures=",failures); quit(1 if failures else 0)
