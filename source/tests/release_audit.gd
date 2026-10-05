extends SceneTree
const Main=preload("res://scripts/main.gd")
const Saves=preload("res://scripts/save_store.gd")
const Guide=preload("res://scripts/tutorial.gd")
const Farm=preload("res://scripts/garden_farm.gd")
const Rules=preload("res://scripts/garden_rules.gd")
const Journal=preload("res://scripts/garden_journal.gd")
var checks:=0
var failures:=0
var game: Control
func check(ok: bool, what: String) -> void:
	checks+=1
	if not ok: failures+=1; printerr("FAIL: ",what)
func _initialize() -> void: call_deferred("run")
func buttons(node: Node) -> Array:
	var result: Array=[]
	if node is Button: result.append(node)
	for child in node.get_children(): result.append_array(buttons(child))
	return result
func settle() -> void:
	await process_frame; await process_frame; await process_frame
func scroll_child(node: Node) -> bool:
	var parent:=node.get_parent()
	while parent!=null:
		if parent is ScrollContainer: return true
		parent=parent.get_parent()
	return false
func run() -> void:
	game=Main.new(); game.store=Saves.new("user://release-audit-"+str(OS.get_process_id())+".json")
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(game.store.path+suffix): DirAccess.remove_absolute(game.store.path+suffix)
	root.add_child(game); game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); await settle()
	game.store.data.tutorial_seen=Guide.KEYS.duplicate()
	game.garden_ui.business.shop(); check(game.page=="garden","locked shop redirects to repair instead of bypass through story")
	game.garden_ui.business.nursery(); check(game.page=="garden","locked nursery redirects to repair")
	check(not Farm.can_enter(game.store.data.garden,"shop"),"fresh shop is locked")
	game.store.data.garden.farm.orders_done=5
	check(not Farm.can_enter(game.store.data.garden,"shop"),"sales cannot bypass building repair")
	var base: Dictionary=game.store.defaults(); base.tutorial_seen=Guide.KEYS.duplicate()
	base.garden.intro_done=true; base.completed=range(1,61); Rules.sync(base)
	base.garden.repairs=[0,1,2,3,4]; base.garden.coins=10000
	game.store.data=base.duplicate(true)
	game.garden_ui.business.shop(); check(game.page=="business_shop","repaired shop enters")
	game.garden_ui.business.nursery(); check(game.page=="nursery","repaired nursery enters")
	var routes: Dictionary={
		"home":game.show_home,"garden":game.garden_ui.open_garden,"modes":game.garden_ui.modes,"guides":game.garden_ui.guides,
		"levels":game.show_levels,"match levels":game.show_match_levels,"settings":game.show_settings,"licenses":game.show_licenses,"backup":game.show_backup,
		"journal":game.garden_ui.journal,"friends":func(): game.garden_ui.journal_controller().orders(),"flower album":func(): game.garden_ui.journal_controller().album(),
		"discoveries":func(): game.garden_ui.journal_controller().journey(),"story":game.garden_ui.business.story,"bouquet album":game.garden_ui.business.album,
		"upgrades":game.garden_ui.business.upgrades,"shop":game.garden_ui.business.shop,"nursery":game.garden_ui.business.nursery,
		"decorations":game.garden_ui.open_shop,"repair":func(): game.garden_ui.select_place("repair",0),"intro":func(): game.garden_ui.intro(0),"help":game.garden_ui.help,"match help":game.show_match_help}
	var clicked:=0
	for language in ["ru","en"]:
		base.settings.language=language
		for name_value in routes:
			game.store.data=base.duplicate(true); routes[name_value].call(); await settle()
			var count:=buttons(game.shell).size()
			check(count>0,"screen has navigation: "+name_value+" "+language)
			for index in count:
				game.store.data=base.duplicate(true); game.garden_ui.slot=-1; game.garden_ui.repair_index=-1; game.garden_ui.pending=-1
				routes[name_value].call(); await settle()
				var current:=buttons(game.shell)
				if index>=current.size(): continue
				var button: Button=current[index]
				check(not button.text.is_empty() or button.icon!=null,"button has a label: "+name_value)
				check(button.pressed.get_connections().size()>0,"button is connected: "+name_value+"/"+button.text)
				if button.is_visible_in_tree() and not scroll_child(button): check(game.get_global_rect().grow(2).encloses(button.get_global_rect()),"button fits screen: "+name_value+"/"+button.text)
				if not button.disabled:
					button.pressed.emit(); clicked+=1; await settle()
					check(Saves.valid(game.store.data),"button preserves save: "+name_value)
				# Dialogs opened by backup/reset are cancelled, never confirmed with arbitrary text.
				for child in game.get_children():
					if child is Window: child.queue_free()
	# Every guide in both languages, every step, practice never changes the economy.
	for language in ["ru","en"]:
		game.store.data=base.duplicate(true); game.store.data.settings.language=language
		for key in Guide.KEYS:
			game.tutorial.open(key); await settle()
			for page in game.tutorial.content().size():
				var before: Dictionary=game.store.data.garden.duplicate(true)
				game.tutorial.demo.perform(); await settle()
				check(before==game.store.data.garden,"practice cannot spend or award: "+key)
				check(game.get_global_rect().encloses(game.tutorial.next_button.get_global_rect()),"guide fits screen: "+key)
				game.tutorial.advance(); await settle()
	check(game.garden_ui.business.SCENES.size()==Farm.CHAPTER_ORDER.size(),"all 18 chapters have content")
	game.store.data=base.duplicate(true); game.set_language("en"); check(game.store.data.settings.language=="en","English selection")
	game.set_language("ru"); check(game.store.data.settings.language=="ru","Russian selection")
	var reloaded=Saves.new(game.store.path); reloaded.load_data(); check(reloaded.data.settings.language=="ru","language survives restart")
	print("Release audit checks=",checks," failures=",failures," menu button activations=",clicked)
	game.queue_free(); await settle(); await create_timer(.15).timeout; quit(1 if failures else 0)
