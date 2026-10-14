extends "res://tests/estate_ui.gd"
func run() -> void:
	root.size=Vector2i(320,568)
	game=Main.new(); game.store=Saves.new("user://play-release-ui-"+str(OS.get_process_id())+".json"); root.add_child(game); game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); await settle()
	game.store.data.garden.intro_done=true; game.store.data.tutorial_seen=Guides.KEYS.duplicate()
	for language in ["ru","en"]:
		game.store.data.settings.language=language; game.show_settings(); await settle()
		var scroll: ScrollContainer=game.shell.get_child(0)
		check(scroll is ScrollContainer,"settings can scroll")
		scroll.scroll_vertical=int(scroll.get_v_scroll_bar().max_value); await settle()
		var last: Control=game.root_box.get_child(game.root_box.get_child_count()-1)
		check(game.get_global_rect().encloses(last.get_global_rect()),"last settings action reachable")
		preload("res://scripts/privacy_ui.gd").show(game); await settle()
		check(game.page=="privacy","offline privacy screen opens")
		var content: Label=game.root_box.get_child(1).get_child(0)
		check(content.text.contains("e8582010@gmail.com"),"published support address present")
		check(content.text.length()>1000,"full privacy policy included")
	game.queue_free(); await settle(); print("Play release UI checks=",checks," failures=",failures); quit(1 if failures else 0)
