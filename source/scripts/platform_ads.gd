extends Node
const Rules=preload("res://scripts/ad_rules.gd")
var game: Control
var bridge: Variant
var enabled:=false
var available:=false
var request: Dictionary={}
var after_ad: Callable
var layer: Control
var text: Label
var elapsed:=0.0
var paused_by_platform:=false
var was_muted:=false
var language_set:=false
var pending_error:=""
func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	if OS.has_feature("web") and JavaScriptBridge.eval("typeof window.JackPlatform !== 'undefined'",true):
		bridge=JavaScriptBridge.get_interface("JackPlatform")
	if bridge==null: set_process(false); return
	var config: Variant=JSON.parse_string(str(bridge.config()))
	enabled=config is Dictionary and config.get("enabled",false)
	if enabled:
		Rules.ensure(game.store.data); call_deferred("announce")
func announce() -> void:
	bridge.ready(); poll()
func _process(delta: float) -> void:
	elapsed+=delta
	if elapsed<.1: return
	elapsed=0; poll()
func poll() -> void:
	if bridge==null: return
	var config: Dictionary=JSON.parse_string(str(bridge.config()))
	available=config.available
	if available and not language_set:
		language_set=true
		# First platform session only; explicit later settings remain authoritative.
		if not game.store.data.get("platform_language_set",false):
			game.store.data.settings.language="ru" if config.language=="ru" else "en"
			game.store.data.platform_language_set=true; game.store.write()
			if game.page=="home": game.show_home()
			elif game.page=="prologue": game.garden_ui.intro()
	var state: Dictionary=JSON.parse_string(str(bridge.state()))
	if bool(state.paused)!=paused_by_platform:
		paused_by_platform=state.paused
		if paused_by_platform:
			was_muted=AudioServer.is_bus_mute(0); AudioServer.set_bus_mute(0,true)
		else: AudioServer.set_bus_mute(0,was_muted)
		game.get_tree().paused=paused_by_platform
	for event in state.events:
		if event.get("token","")!=request.get("token","-"): continue
		if event.type=="reward": grant()
		elif event.type=="closed":
			var rewarded: bool=request.get("granted",false)
			request={}
			if after_ad.is_valid():
				var action:=after_ad; after_ad=Callable(); action.call()
			elif is_instance_valid(text):
				text.text=pending_error if not pending_error.is_empty() else game.words("Награда получена. Спасибо!","Reward received. Thank you!") if rewarded else game.words("Просмотр не засчитан. Награда не выдана; можно продолжать играть.","Viewing was not completed. No reward was granted; you can keep playing.")
	bridge.gameplay(game.page in ["play","match","nursery","shop","prologue"] and not is_instance_valid(layer))
func close() -> void:
	if not request.is_empty(): return
	if is_instance_valid(layer): layer.queue_free()
	layer=null; text=null
	if game.page=="home": game.show_home()
func open_menu() -> void:
	if not enabled or not request.is_empty(): return
	close()
	layer=Control.new(); layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); layer.z_index=200; game.add_child(layer)
	var background:=Panel.new(); background.add_theme_stylebox_override("panel",game.style(Color("103d32"),Color("103d32"))); layer.add_child(background); background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin:=MarginContainer.new(); layer.add_child(margin); margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,24)
	var scroll:=ScrollContainer.new(); margin.add_child(scroll)
	var box:=VBoxContainer.new(); box.size_flags_horizontal=Control.SIZE_EXPAND_FILL; box.add_theme_constant_override("separation",22); scroll.add_child(box)
	text=Label.new(); text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; text.add_theme_font_size_override("font_size",28); text.text=game.words("Помощь Джека\nНаграда — после полного просмотра рекламы. Бесплатные подсказки и повторы доступны на поле.","Jack's help\nRewards require a completed ad view. Free hints and retries remain on the board."); box.add_child(text)
	game.button(game.words("Реклама · 50 монет","Ad · 50 coins"),begin.bind("coins"),box,true)
	if game.page in ["play","match"]:
		var winning: bool=game.puzzle.won() if game.page=="play" else game.match_model.won()
		var busy: bool=game.page=="match" and game.match_view.busy
		if not winning and not busy:
			if game.page=="play": game.button(game.words("Реклама · исправить 3 дорожки","Ad · fix 3 paths"),begin.bind("hint"),box)
			elif game.match_model.moves>0 and int(game.match_model.tools_left[0])==0: game.button(game.words("Реклама · подсказка и молоточек","Ad · hint and hammer"),begin.bind("hint"),box)
			var mode: String="light" if game.page=="play" else "match"
			var id: int=int(game.puzzle.level.id) if mode=="light" else int(game.match_model.level.id)
			var done: Array=game.store.data.completed if mode=="light" else game.store.data.match3.completed
			if id<1000 and id not in done and not Rules.skipped(game.store.data,mode,id): game.button(game.words("Реклама · пропустить уровень","Ad · skip this level"),confirm_skip,box)
	var copy:=Label.new(); copy.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; copy.add_theme_font_size_override("font_size",24); copy.text=game.words("Пропуск открывает следующий уровень, но не даёт 25 монет и не считается победой. Вернуться к уровню можно всегда.","Skipping unlocks the next level without 25 coins or a win. You can return to it anytime."); box.add_child(copy)
	game.button(game.words("Вернуться в игру","Return to game"),close,box)
func confirm_skip() -> void:
	text.text=game.words("Пропустить этот уровень? Победа и её награда останутся для самостоятельного прохождения.","Skip this level? Its win and reward remain available when you solve it yourself.")
	# The user must press the explicit confirmation; simply opening help never starts an ad.
	var parent:=text.get_parent()
	for child in parent.get_children():
		if child is Button: child.queue_free()
	game.button(game.words("Да · посмотреть рекламу","Yes · watch an ad"),begin.bind("skip"),parent,true)
	game.button(game.words("Отмена","Cancel"),open_menu,parent)
func begin(kind: String) -> void:
	if not request.is_empty(): return
	if not available:
		text.text=game.words("Реклама сейчас недоступна. Продолжай играть бесплатно.","Ads are unavailable right now. Keep playing for free."); return
	var mode: String="light" if game.page=="play" else "match"
	var id: int=int(game.puzzle.level.id) if game.page=="play" else int(game.match_model.level.id) if game.page=="match" else 0
	var token:=str(Time.get_unix_time_from_system())+":"+str(Time.get_ticks_usec())
	request={"token":token,"kind":kind,"mode":mode,"id":id,"granted":false}; pending_error=""
	if not bridge.request(kind,token):
		request={}; text.text=game.words("Реклама недоступна. Попробуй позже.","Ad unavailable. Please try later.")
func grant() -> void:
	if request.is_empty() or request.granted: return
	var previous: Dictionary=game.store.data.duplicate(true)
	if not Rules.claim(game.store.data,request.token,request.kind,request.mode,request.id): return
	var old_rotations: Array=game.puzzle.rotations.duplicate()
	var old_history: Array=game.puzzle.history.duplicate(true)
	var old_tools: Array=game.match_model.tools_left.duplicate()
	if request.kind=="hint":
		if request.mode=="light":
			for i in 3:
				var index: int=game.puzzle.hint_index()
				if index<0: break
				game.puzzle.apply_hint(index)
			game.store.data.boards[str(request.id)]=game.puzzle.rotations.duplicate()
		else:
			game.match_model.tools_left[0]=mini(1,int(game.match_model.tools_left[0])+1)
			game.store.data.match3.boards[str(request.id)]=game.match_model.snapshot()
	if not game.store.write():
		game.store.data=previous; game.puzzle.rotations=old_rotations; game.puzzle.history=old_history; game.match_model.tools_left=old_tools
		pending_error=game.words("Не удалось сохранить награду. Проверь свободное место.","Could not save your reward. Check free storage."); return
	request.granted=true
	if request.kind=="skip":
		# Capture immutable values, since the callback clears request first.
		var target: int=mini(1000,int(request.id)+1); var light: bool=request.mode=="light"
		after_ad=func(): close(); game.open_level(target) if light else game.open_match(target)
	elif request.kind=="hint":
		if request.mode=="light": game.selected_hint=-1; game.refresh(); game.persist()
		else: game.match_hint(); game.refresh_match()
func record(mode: String,id: int) -> void:
	if enabled: Rules.won(game.store.data,mode,id)
func transition(action: Callable) -> void:
	if not enabled or not game.store.data.get("ad_state",{}).get("pending",false): action.call(); return
	if not request.is_empty(): return
	game.store.data.ad_state.pending=false
	if not game.store.write(): game.store.data.ad_state.pending=true; action.call(); return
	var token: String="inter:"+str(Time.get_ticks_usec())
	request={"token":token,"kind":"interstitial","granted":false}; after_ad=action
	if not available or not bridge.request("interstitial",token): request={}; after_ad=Callable(); action.call()
