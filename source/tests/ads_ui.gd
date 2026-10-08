extends "res://tests/estate_ui.gd"
class FakePlatform extends RefCounted:
	var events: Array=[]
	var paused:=false
	var available:=true
	var calls:=0
	func config() -> String: return JSON.stringify({"available":available,"language":"ru"})
	func state() -> String:
		var result:=JSON.stringify({"paused":paused,"events":events}); events=[]; return result
	func request(_kind: String,_token: String) -> bool: calls+=1; return available
	func gameplay(_value: bool) -> void: pass
func reward() -> void:
	var token: String=game.ads.request.token
	game.ads.bridge.events=[{"type":"reward","token":token},{"type":"reward","token":token},{"type":"closed","token":token}]
	game.ads.poll()
func run() -> void:
	root.size=Vector2i(320,568)
	game=Main.new(); game.store=Saves.new("user://ads-ui-"+str(OS.get_process_id())+".json"); root.add_child(game); game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); await settle()
	game.store.data.garden.intro_done=true; game.store.data.tutorial_seen=Guides.KEYS.duplicate()
	game.ads.enabled=true; game.ads.available=true; game.ads.language_set=true; game.ads.bridge=FakePlatform.new()
	preload("res://scripts/ad_rules.gd").ensure(game.store.data)
	for language in ["ru","en"]:
		game.store.data.settings.language=language; game.show_home(); game.ads.open_menu(); await settle(); await shot("ad-home-"+language)
		var coins: int=game.store.data.garden.coins
		game.ads.begin("coins"); reward(); check(game.store.data.garden.coins==coins+50,"duplicate SDK callback grants only once"); game.ads.close()
		game.open_level(1); game.restart(); game.ads.open_menu(); await settle(); await shot("ad-light-"+language)
		game.ads.begin("hint"); reward(); check(not game.puzzle.history.is_empty(),"ad hints apply real rotations"); game.ads.close()
		game.open_match(1); game.match_model.tools_left[0]=0; game.ads.open_menu(); await settle(); await shot("ad-match-"+language)
		game.ads.begin("hint"); reward(); check(game.match_model.tools_left[0]==1,"ad restores hammer"); game.ads.close()
	game.open_match(1); game.ads.open_menu(); game.ads.confirm_skip(); await settle(); await shot("ad-skip")
	game.ads.begin("skip"); reward(); await settle()
	check(game.store.data.match3.current==2 and game.page=="match","skip navigates next level")
	check(1 not in game.store.data.match3.completed,"skip is not a win")
	check(game.match_unlocked()==2,"next level selectable")
	game.ads.open_menu(); var before: int=game.store.data.garden.coins; game.ads.begin("coins")
	game.ads.bridge.events=[{"type":"closed","token":game.ads.request.token}]; game.ads.poll()
	check(game.store.data.garden.coins==before,"cancelled video has no reward"); game.ads.close()
	game.store.data.ad_state.pending=true; game.advance_match(); check(game.ads.bridge.calls>0 and not game.store.data.ad_state.pending,"transition consumes scheduled break")
	game.ads.bridge.events=[{"type":"closed","token":game.ads.request.token}]; game.ads.poll()
	# Pause/mute independently of ad callback; resume restores the previous setting.
	game.ads.bridge.paused=true; game.ads.poll(); check(paused and AudioServer.is_bus_mute(0),"platform pauses game and audio")
	game.ads.bridge.paused=false; game.ads.poll(); check(not paused,"platform resumes game")
	game.ads.available=false; game.ads.open_menu(); game.ads.begin("coins"); check(game.ads.request.is_empty(),"missing ad does not lock controls"); game.ads.close()
	game.store.path="user://missing-directory/ads.json"; game.ads.available=true; game.ads.open_menu(); before=game.store.data.garden.coins; game.ads.begin("coins"); reward()
	check(game.store.data.garden.coins==before and not game.ads.pending_error.is_empty(),"failed save rolls reward back with explanation")
	game.ads.close(); game.queue_free(); await settle()
	print("Ads UI checks=",checks," failures=",failures); quit(1 if failures else 0)
