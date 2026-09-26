extends Control
const Rules = preload("res://scripts/puzzle.gd")
const Saves = preload("res://scripts/save_store.gd")
const Board = preload("res://scripts/board.gd")
const Sound = preload("res://scripts/sound.gd")
const MatchRules = preload("res://scripts/match_rules.gd")
const MatchBoard = preload("res://scripts/match_board.gd")
const MatchGoals = preload("res://scripts/match_goals.gd")
const GardenRules=preload("res://scripts/garden_rules.gd")
const GardenMap=preload("res://scripts/garden_map.gd")
const GardenUI=preload("res://scripts/garden_ui.gd")
const Tutorial=preload("res://scripts/tutorial.gd")
var garden_ui: RefCounted
var tutorial: RefCounted
var light_rewarded:=false
var match_rewarded:=false
var reward_garden_button: Button
var match_garden_button: Button
var match_model = MatchRules.new()
var match_levels: Array = []
var match_group := -1
var match_view: Control
var match_goals: Control
var match_moves: Label
var match_message: Label
var match_next: Button
var match_hint_button: Button
var match_restart_button: Button
var tool_buttons: Array=[]
var starter_button: Button
const LEVEL_COUNT := 250
const REGION_RU = ["Первые лучи", "Розовый рассвет", "Лавандовый склон", "Бирюзовый ручей", "Янтарная долина", "Сапфировый вечер", "Коралловая роща", "Серебряная луна", "Северное сияние", "Сад тысячи звёзд"]
const REGION_EN = ["First light", "Rose dawn", "Lavender hillside", "Turquoise stream", "Amber valley", "Sapphire evening", "Coral grove", "Silver moon", "Northern lights", "Garden of stars"]
var level_group := -1
var garden_section := 0
var store = Saves.new()
var puzzle = Rules.new()
var levels: Array = []
var page := "home"
var root_box: VBoxContainer
var shell: MarginContainer
var board: Control
var status: Label
var notice: Label
var hint_button: Button
var undo_button: Button
var next_button: Button
var sound: Node
var selected_hint := -1
var error_message := ""
const CREAM = Color("fff7dc")
const MUTED = Color("bde5cc")

func words(ru: String, en: String) -> String:
	return ru if store.data.settings.language == "ru" else en

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			store = Saves.new("user://capture-progress.json")
	store.load_data()
	var match_data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://match_levels/levels.json"))
	if match_data is Array and match_data.size() == 250:
		match_levels = match_data
	else:
		error_message = "Flower Cascade levels could not be loaded"
	for id in range(1, LEVEL_COUNT + 1):
		var file := FileAccess.open("res://levels/%02d.json" % id, FileAccess.READ)
		if file == null:
			error_message = "Missing level %d" % id
			break
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		if not parsed is Dictionary or Rules.validate(parsed) != "":
			error_message = "Invalid level %d" % id
			break
		levels.append(parsed)
	var theme_value := Theme.new()
	theme_value.default_font_size = 24
	theme = theme_value
	sound = Sound.new()
	add_child(sound)
	sound.configure(store.data.settings)
	garden_ui=GardenUI.new(self)
	tutorial=Tutorial.new(self)
	get_tree().auto_accept_quit = false
	resized.connect(_layout)
	if store.data.garden.intro_done: show_home()
	else: garden_ui.intro()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			open_level(4)
			await get_tree().create_timer(1.0).timeout
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(arg.trim_prefix("--capture="))
			get_tree().quit()

func _draw() -> void:
	var tint := Color("102f39")
	for band in 32:
		var t := float(band)/31
		draw_rect(Rect2(0, size.y*band/32, size.x, size.y/32+1), tint.lerp(Color("246954"), t))
	for i in 36:
		var p := Vector2(fposmod(i*137.3, size.x), fposmod(i*211.7, size.y))
		draw_circle(p, 1.2 + i%3, Color(0.84,1.0,0.78,0.16))
	for side in [-1, 1]:
		for leaf in 9:
			var p := Vector2(18 if side == -1 else size.x-18, size.y*(0.06+leaf*0.115))
			draw_set_transform(p, side*0.65, Vector2(0.5,1))
			draw_circle(Vector2.ZERO, 38, Color(0.26,0.71,0.51,0.12))
			draw_set_transform(Vector2.ZERO)

func _layout() -> void:
	queue_redraw()
	if shell == null:
		return
	var edge := maxi(24, int((size.x-660)/2))
	var top := 30
	var bottom := 28
	if OS.get_name() == "Android":
		var safe := DisplayServer.get_display_safe_area()
		var physical := DisplayServer.screen_get_size()
		if physical.y > 0:
			top += int(safe.position.y * size.y / physical.y)
			bottom += int((physical.y-safe.end.y) * size.y / physical.y)
	if page in ["home","garden","garden_modes","garden_shop","garden_photo"]: edge=0; top=0; bottom=0
	shell.add_theme_constant_override("margin_left", edge)
	shell.add_theme_constant_override("margin_right", edge)
	shell.add_theme_constant_override("margin_top", top)
	shell.add_theme_constant_override("margin_bottom", bottom)

func clear_page(name_value: String) -> void:
	page = name_value
	if sound != null: sound.set_home(name_value == "home")
	board = null
	if shell != null:
		remove_child(shell)
		shell.queue_free()
	shell = MarginContainer.new()
	shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shell)
	root_box = VBoxContainer.new()
	root_box.add_theme_constant_override("separation", 16)
	shell.add_child(root_box)
	_layout()

func label(text_value: String, font_size: int = 24, color: Color = CREAM) -> Label:
	var result := Label.new()
	result.text = text_value
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", (Color("244c42") if color==CREAM else Color("68816a")) if page in ["home","garden","garden_modes","garden_shop"] else color)
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_box.add_child(result)
	return result

func style(color: Color, border: Color) -> StyleBoxFlat:
	var result := StyleBoxFlat.new()
	result.bg_color = color
	result.border_color = border
	result.set_border_width_all(1)
	result.set_corner_radius_all(20)
	result.content_margin_left = 14
	result.content_margin_right = 14
	return result

func button(text_value: String, action: Callable, parent: Node = null, primary: bool = false) -> Button:
	var result := Button.new()
	result.text = text_value
	result.custom_minimum_size.y = 70
	result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	result.add_theme_font_size_override("font_size", 24)
	result.add_theme_color_override("font_color", Color("23352a") if primary else CREAM)
	result.add_theme_color_override("font_hover_color", Color("23352a") if primary else CREAM)
	result.add_theme_color_override("font_pressed_color", Color("23352a") if primary else CREAM)
	result.add_theme_stylebox_override("normal", style(Color("ffdc82") if primary else Color("286556"), Color("bda775") if primary else Color("549981")))
	result.add_theme_stylebox_override("hover", style(Color("f4deb0") if primary else Color("388371"), Color("c0ae7d")))
	result.add_theme_stylebox_override("pressed", style(Color("c9af79") if primary else Color("304d38"), Color("ddc58d")))
	result.add_theme_stylebox_override("disabled", style(Color("204b43"), Color("293e31")))
	result.add_theme_stylebox_override("focus", style(Color(0,0,0,0), Color("f4d99a")))
	result.pressed.connect(action)
	(parent if parent != null else root_box).add_child(result)
	return result

func spacer() -> void:
	var space := Control.new()
	space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_box.add_child(space)

func header(text_value: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	root_box.add_child(row)
	var back := button(words("‹ Назад", "‹ Back"), show_home, row)
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var title := Label.new()
	title.text = text_value
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", MUTED)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)

func garden_view(height: int) -> void:
	GardenRules.sync(store.data)
	var art=GardenMap.new()
	art.garden=store.data.garden
	art.interactive=false
	art.custom_minimum_size.y = height
	art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_box.add_child(art)

func show_home() -> void:
	garden_ui.home()

func unlocked() -> int:
	var highest := 1
	for id in range(1, levels.size()+1):
		if id not in store.data.completed:
			break
		highest = mini(id+1, levels.size())
	return highest

func show_levels() -> void:
	clear_page("levels")
	header(words("Полянки", "Clearings"))
	label(words("Путешествие по саду", "A garden journey"), 40)
	label(words("Каждый новый уровень — 25 монет для сада.", "Every new level earns 25 garden coins."), 23, MUTED)
	if level_group < 0:
		level_group = (int(store.data.current)-1)/25
	label(words(REGION_RU[level_group], REGION_EN[level_group]), 28)
	var navigation := HBoxContainer.new()
	root_box.add_child(navigation)
	button("‹", select_group.bind(-1), navigation).disabled = level_group == 0
	button("%d–%d / %d" % [level_group*25+1, (level_group+1)*25, LEVEL_COUNT], func(): pass, navigation).mouse_filter = Control.MOUSE_FILTER_IGNORE
	button("›", select_group.bind(1), navigation).disabled = level_group == 9
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_box.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)
	for id in range(level_group*25+1, mini((level_group+1)*25+1, levels.size()+1)):
		var text_value := "%02d" % id
		if id in store.data.completed:
			text_value += "  +"
		elif id > unlocked():
			text_value += "  ·"
		var item := button(text_value, open_level.bind(id), grid)
		item.custom_minimum_size.y = 92
		item.disabled = id > unlocked()
	label(words("Следующая полянка откроется после цветения.", "The next clearing opens when every flower blooms."), 22, MUTED)

func select_group(direction: int) -> void:
	level_group = clampi(level_group + direction, 0, 9)
	show_levels()

func open_level(id: int) -> void:
	GardenRules.Story.ensure(store.data.garden)
	store.data.garden.story.last_mode="light"
	light_rewarded=false
	if id < 1 or id > levels.size():
		return
	store.data.current = id
	puzzle.setup(levels[id-1], store.data.boards.get(str(id), []))
	selected_hint = -1
	clear_page("play")
	header(words("ПОЛЯНКА ", "CLEARING ") + "%02d / %d" % [id, LEVEL_COUNT])
	var chapter := (id - 1) / 25
	label(words(REGION_RU[chapter], REGION_EN[chapter]), 34)
	var lessons_ru := ["Коснитесь дорожки, чтобы повернуть её к цветку.", "Свет проходит только по соединённым дорожкам.", "Осветите каждый цветок. Спешить некуда."]
	var lessons_en := ["Tap a path to turn it towards the flower.", "Light travels only through connected paths.", "Light every flower. Take your time."]
	label(words(lessons_ru[id-1], lessons_en[id-1]) if id <= 3 else words("Поворачивайте дорожки и соединяйте свет с цветами.", "Turn the paths to bring light to the flowers."), 23, MUTED)
	board = Board.new()
	board.puzzle = puzzle
	board.region = chapter
	board.reduced = store.data.settings.reduce_motion
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board.custom_minimum_size.y = 360
	board.tile_pressed.connect(on_tile)
	root_box.add_child(board)
	status = label("", 25)
	status.custom_minimum_size.y = 44
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	root_box.add_child(row)
	undo_button = button(words("Отмена", "Undo"), undo, row)
	button(words("Заново", "Restart"), restart, row)
	hint_button = button(words("Подсказка", "Hint"), hint, row)
	next_button = button("", advance, null, true)
	reward_garden_button=button(words("Улучшить сад", "Improve the garden"),show_garden)
	notice = label("", 18, MUTED)
	refresh()
	persist()
	tutorial.maybe_open("light")

func on_tile(index: int) -> void:
	if puzzle.turn(index):
		selected_hint = -1
		sound.chime()
		refresh()
		persist()

func undo() -> void:
	if puzzle.undo():
		selected_hint = -1
		refresh()
		persist()

func restart() -> void:
	puzzle.restart()
	selected_hint = -1
	refresh()
	persist()

func hint() -> void:
	if selected_hint >= 0:
		puzzle.apply_hint(selected_hint)
		selected_hint = -1
		sound.chime()
	else:
		selected_hint = puzzle.hint_index()
	refresh()
	persist()

func refresh() -> void:
	var victory: bool = puzzle.won()
	var id: int = int(puzzle.level.id)
	if victory:
		if store.complete(id): light_rewarded=true
		status.text=words("Полянка ожила!", "The clearing is alive!")+(words(" +25 садовых монет."," +25 garden coins.") if light_rewarded else words(" Эта награда уже получена."," This reward was already collected."))
	else:
		var count := 0
		for i in puzzle.lit():
			if puzzle.level.cells[i] == "plant":
				count += 1
		status.text = words("Цветы в свете: ", "Flowers in the light: ") + "%d / %d" % [count, puzzle.level.cells.count("plant")]
	board.hint = selected_hint
	undo_button.disabled = puzzle.history.is_empty()
	hint_button.disabled = victory
	hint_button.text = words("Применить", "Apply") if selected_hint >= 0 else words("Подсказка", "Hint")
	next_button.visible = victory
	reward_garden_button.visible=victory
	reward_garden_button.text=words("Улучшить сад · ","Improve garden · ")+str(store.data.garden.coins)+words(" монет"," coins")
	next_button.text = words("В мой сад", "Visit my garden") if id == levels.size() else words("Следующая полянка  ›", "Next clearing  ›")
	notice.text = words("Один возможный путь. Нажмите «Применить».", "One possible solution. Tap Apply.") if selected_hint >= 0 else words("Без таймера. В вашем темпе.", "No timer. At your own pace.")

func advance() -> void:
	var id: int = int(puzzle.level.id)
	if id < levels.size():
		open_level(id+1)
	else:
		show_garden()

func persist() -> void:
	if puzzle.level != null and not puzzle.level.is_empty():
		store.data.boards[str(int(puzzle.level.id))] = puzzle.rotations.duplicate()
	if not store.write():
		push_error(store.last_error)
		if is_instance_valid(notice) and page == "play":
			notice.text = words("Не удалось сохранить прогресс. Проверьте свободное место.", "Could not save. Please check free storage.")

func show_garden() -> void:
	garden_ui.open_garden()

func show_settings() -> void:
	clear_page("settings")
	header(words("Настройки", "Settings"))
	label(words("Как вам спокойно", "Make yourself at home"), 40)
	spacer()
	for setting in [["music", words("Музыка", "Music")], ["sound", words("Звуки", "Sounds")], ["reduce_motion", words("Меньше анимаций", "Reduced motion")]]:
		var key: String = setting[0]
		button(setting[1] + "  ·  " + (words("Вкл", "On") if store.data.settings[key] else words("Выкл", "Off")), toggle.bind(key))
	button("Язык / Language  ·  " + ("Русский" if store.data.settings.language == "ru" else "English"), func():
		store.data.settings.language = "en" if store.data.settings.language == "ru" else "ru"
		persist()
		show_settings())
	spacer()
	label(words("Игра не собирает данные и не подключается к сети. Прогресс хранится только на устройстве.", "No data collection or network connection. Progress stays on this device."), 22, MUTED)
	label(words("При удалении приложения прогресс может быть потерян.", "Uninstalling the app may remove your progress."), 18, MUTED)
	button(words("История Джека", "Jack's story"),func(): garden_ui.replay=true; garden_ui.intro(0))
	button(words("Резервная копия", "Save backup"),show_backup)
	button(words("Лицензии", "Licenses"), show_licenses)

func toggle(key: String) -> void:
	store.data.settings[key] = not store.data.settings[key]
	sound.configure(store.data.settings)
	persist()
	show_settings()

func show_licenses() -> void:
	clear_page("licenses")
	header(words("Лицензии", "Licenses"))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_box.add_child(scroll)
	var content := Label.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_theme_font_size_override("font_size", 18)
	content.text = "Garden of Light — original vector artwork and synthesized audio.\n\nGodot Engine\n" + Engine.get_license_text() + "\n\nThird-party notices\n"
	for item in Engine.get_copyright_info():
		content.text += str(item) + "\n\n"
	for name_value in Engine.get_license_info():
		content.text += name_value + "\n" + Engine.get_license_info()[name_value] + "\n\n"
	scroll.add_child(content)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		persist()
		get_tree().quit()
	elif what == NOTIFICATION_APPLICATION_PAUSED:
		persist()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if page != "home":
			show_home()
		else:
			persist()
			get_tree().quit()

func match_unlocked() -> int:
	var result := 1
	for id in range(1,251):
		if id not in store.data.match3.completed: break
		result = mini(id+1,250)
	return result

func show_match_levels() -> void:
	clear_page("match_levels")
	header(words("Цветочный каскад", "Flower Cascade"))
	label(words("Соберите свой букет", "Gather a bouquet"),36)
	label(words("Три цветка в ряд — и сад расцветает.", "Match three flowers and let the garden bloom."),22,MUTED)
	button(words("Продолжить · уровень ", "Continue · level ")+str(store.data.match3.current),open_match.bind(int(store.data.match3.current)),null,true)
	if match_group < 0: match_group = (int(store.data.match3.current)-1)/25
	var nav := HBoxContainer.new()
	root_box.add_child(nav)
	button("‹", match_page.bind(-1),nav).disabled = match_group == 0
	button("%d–%d / 250" % [match_group*25+1,(match_group+1)*25],func(): pass,nav).mouse_filter=Control.MOUSE_FILTER_IGNORE
	button("›", match_page.bind(1),nav).disabled = match_group == 9
	label(words(REGION_RU[match_group],REGION_EN[match_group]),26)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_box.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns=5; grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation",12); grid.add_theme_constant_override("v_separation",12)
	scroll.add_child(grid)
	for id in range(match_group*25+1,(match_group+1)*25+1):
		var text_value := str(id)+(" +" if id in store.data.match3.completed else "")
		var item := button(text_value,open_match.bind(id),grid)
		item.custom_minimum_size.y=88; item.disabled=id>match_unlocked()
	label(words("Букетов собрано: ", "Bouquets completed: ")+"%d / 250" % store.data.match3.completed.size(),22,MUTED)
	button(words("Как играть и усилители", "How to play and power-ups"),show_match_help)

func match_page(direction: int) -> void:
	match_group=clampi(match_group+direction,0,9)
	show_match_levels()

func show_match_help() -> void:
	clear_page("match_help")
	header(words("Как играть", "How to play"))
	label(words("Цветочный каскад", "Flower Cascade"),36)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	root_box.add_child(scroll)
	var text_value := Label.new()
	text_value.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	text_value.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	text_value.add_theme_font_size_override("font_size",25)
	text_value.text=words("Меняйте соседние цветы свайпом или двумя касаниями. Собирайте ряды из трёх и больше.\n\nЦели: собрать нужные цветы и убрать всю голубую росу. Совпадение или усилитель снимает один слой росы под цветком. Двойная рамка — два слоя.\n\n4 в ряд → луч очищает ряд или столбец.\nКвадрат 2×2 → бабочка помогает убрать росу или собрать нужный цветок.\nТ- или Г-форма → цветочный взрыв.\n5 в ряд → радуга собирает один цвет.\n\nКоснитесь усилителя или поменяйте его с соседом. Два усилителя вместе дают более сильный эффект.\n\nХоды ограничены. Неверный обмен не тратит ход. Попытки и подсказки бесплатны. Если ходов нет на поле, цветы перемешаются автоматически.\n\nПрепятствия: лианы удерживают цветок; лёд тает от совпадений рядом; камни разбиваются только усилителями; горшок требует совпадения цвета его цветка рядом. Цифра — слои.\n\nИнструменты под полем: молоточек, ряд, столбец, перемешивание — по одному на попытку, без расхода хода. «Старт +» даёт один усилитель перед первым ходом.\n\nДве бомбы — большой взрыв; две бабочки — три цели; бабочка переносит луч или бомбу; радуга превращает самый частый цвет в усилители.\n\nНа клавиатуре: стрелки — выбор, Enter — отметить цветок и соседнюю клетку.","Swipe adjacent flowers or tap two neighbours. Match three or more.\n\nGoals: collect the requested flowers and clear all blue dew. Matches and power-ups remove one layer beneath a flower. A double outline means two layers.\n\n4 in a line → a beam clears a row or column.\n2×2 square → a butterfly targets dew or a needed flower.\nT or L shape → a flower burst.\n5 in a line → a rainbow gathers one colour.\n\nTap a power-up or swap it with a neighbour. Combine two power-ups for a stronger effect.\n\nMoves are limited. Invalid swaps cost no moves. Retries and hints are free. A board without moves shuffles automatically.\n\nObstacles: vines hold flowers; ice melts beside matches; stones need power-ups; pots need a matching flower colour beside them. Numbers show layers.\n\nTools below the board: hammer, row, column and shuffle, one each per attempt, no move spent. Start + places one power-up before your first move.\n\nTwo bombs make a large blast; two butterflies hit three targets; butterflies carry bombs or rockets; rainbow converts the most common colour to power-ups.\n\nKeyboard: arrows to move, Enter to select a flower and its neighbour.")
	scroll.add_child(text_value)
	button(words("К букетам", "Back to bouquets"),show_match_levels,null,true)

func open_match(id: int) -> void:
	GardenRules.Story.ensure(store.data.garden)
	store.data.garden.story.last_mode="match"
	match_rewarded=false
	if id < 1 or id > match_levels.size() or id > match_unlocked(): return
	store.data.match3.current=id
	match_model.setup(match_levels[id-1],store.data.match3.boards.get(str(id),{}))
	clear_page("match")
	header(words("КАСКАД ", "CASCADE ")+"%d / 250" % id)
	label(words(REGION_RU[(id-1)/25],REGION_EN[(id-1)/25]),32)
	match_goals=MatchGoals.new()
	match_goals.model=match_model
	match_goals.custom_minimum_size.y=82
	root_box.add_child(match_goals)
	match_moves=label("",26)
	match_view=MatchBoard.new()
	match_view.model=match_model
	match_view.reduced=store.data.settings.reduce_motion
	match_view.size_flags_vertical=Control.SIZE_EXPAND_FILL
	match_view.custom_minimum_size.y=360
	match_view.committed.connect(save_match)
	match_view.animation_done.connect(match_finished)
	match_view.sound_requested.connect(sound.play_match)
	root_box.add_child(match_view)
	tool_buttons.clear()
	var tools_row:=HBoxContainer.new()
	tools_row.add_theme_constant_override("separation",8)
	root_box.add_child(tools_row)
	for k in 4:
		var item:=button("1",select_match_tool.bind(k),tools_row)
		item.icon=MatchBoard.Art.icon(11+k)
		item.expand_icon=true
		item.add_theme_constant_override("icon_max_width",42)
		item.custom_minimum_size=Vector2(0,60)
		item.tooltip_text=words(["Молоточек: убрать клетку","Горизонтальный луч","Вертикальный луч","Перемешать цветы"][k],["Hammer: clear one tile","Clear a row","Clear a column","Shuffle flowers"][k])
		tool_buttons.append(item)
	starter_button=button(words("Старт +","Start +"),show_starter,tools_row)
	starter_button.add_theme_font_size_override("font_size",18)
	starter_button.custom_minimum_size=Vector2(0,60)
	match_message=label("",21,MUTED)
	match_message.custom_minimum_size.y=54
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",12)
	root_box.add_child(row)
	match_hint_button=button(words("Подсказка", "Hint"),match_hint,row)
	match_restart_button=button(words("Заново", "Retry"),restart_match,row)
	button(words("Уровни", "Levels"),show_match_levels,row)
	match_next=button(words("Следующий букет  ›", "Next bouquet  ›"),advance_match,null,true)
	match_garden_button=button(words("Улучшить сад", "Improve the garden"),show_garden)
	refresh_match()
	save_match()
	tutorial.maybe_open("match")

func refresh_match() -> void:
	if page != "match": return
	for k in tool_buttons.size():
		tool_buttons[k].text=str(match_model.tools_left[k])
		tool_buttons[k].disabled=match_view.busy or match_model.won() or int(match_model.tools_left[k])<=0
	starter_button.disabled=match_view.busy or match_model.starter_used or match_model.moves!=int(match_model.level.moves) or match_model.won()
	match_goals.queue_redraw()
	match_moves.text=words("Ходов осталось: ","Moves left: ")+str(match_model.moves)
	var victory: bool=match_model.won()
	match_next.visible=victory
	match_garden_button.visible=victory
	match_garden_button.text=words("Улучшить сад · ","Improve garden · ")+str(store.data.garden.coins)+words(" монет"," coins")
	match_next.text=words("Все букеты собраны!", "All bouquets complete!") if int(match_model.level.id)==250 else words("Следующий букет  ›", "Next bouquet  ›")
	match_hint_button.disabled=match_view.busy or victory or match_model.moves<=0
	match_restart_button.disabled=match_view.busy
	if victory: match_message.text=words("Прекрасный букет!", "A lovely bouquet!")+(words(" +25 садовых монет."," +25 garden coins.") if match_rewarded else words(" Награда уже получена."," Reward already collected."))
	elif match_model.moves<=0: match_message.text=words("Ходы закончились. Попробуйте ещё — это бесплатно.","Out of moves. Try again — every retry is free.")
	elif int(match_model.level.id)<=3: match_message.text=words("Свайп или два касания: соедините 3 цветка одного вида.","Swipe or tap two neighbours to match 3 flowers.")
	else: match_message.text=words("Собирайте букеты, соединяйте усилители.","Gather bouquets and combine power-ups.")

func save_match() -> void:
	if match_model.level == null: return
	var id: int=int(match_model.level.id)
	store.data.match3.boards[str(id)]=match_model.snapshot()
	if match_model.won() and id not in store.data.match3.completed:
		store.data.match3.completed.append(id); match_rewarded=true
	GardenRules.sync(store.data)
	if not store.write():
		push_error(store.last_error)
		if page == "match": match_message.text=words("Не удалось сохранить. Проверьте свободное место.","Could not save. Check free storage.")
	if page == "match":
		match_hint_button.disabled=match_view.busy or match_model.won() or match_model.moves<=0
		match_restart_button.disabled=match_view.busy

func match_finished(valid: bool) -> void:
	refresh_match()
	if match_model.won(): sound.play_match("win")
	elif not valid: match_message.text=words("Здесь нет совпадения. Ход сохранён.","No match there. No move was spent.")

func match_hint() -> void:
	if match_view.busy: return
	match_view.active_tool=-1
	match_view.hint_cells=match_model.suggest()
	match_view.queue_redraw()
	match_message.text=words("Выделен доступный ход. Попробуйте его.","A possible move is highlighted. Try it.")

func restart_match() -> void:
	if match_view.busy: return
	var id: int=int(match_model.level.id)
	store.data.match3.boards.erase(str(id))
	open_match(id)

func advance_match() -> void:
	var id: int=int(match_model.level.id)
	if id<250: open_match(id+1)
	else: show_match_levels()

func select_match_tool(kind: int) -> void:
	if match_view.busy or match_model.won() or int(match_model.tools_left[kind])<=0: return
	if kind==3:
		match_view.busy=true
		match_view.animate_frames(match_model.use_tool(kind,0))
	else:
		match_view.active_tool=kind
		match_message.text=words("Коснитесь клетки. Инструмент не тратит ход.","Tap a tile. The tool costs no move.")

func show_starter() -> void:
	if starter_button.disabled: return
	var menu:=PopupMenu.new()
	add_child(menu)
	menu.add_theme_font_size_override("font_size",32)
	menu.add_theme_constant_override("v_separation",42)
	menu.min_size=Vector2i(360,270)
	for i in 3:
		menu.add_item(words(["Луч","Бомба","Радуга"][i],["Rocket","Bomb","Rainbow"][i]),i)
	menu.id_pressed.connect(func(i):
		if match_model.start_booster(["row","burst","rainbow"][i]):
			match_view.shown=match_model.snapshot(); match_view.queue_redraw()
			save_match(); refresh_match())
	menu.popup_hide.connect(menu.queue_free)
	menu.popup_centered(Vector2i(360,270))

func show_backup() -> void:
	clear_page("backup"); header(words("КОПИЯ ПРОГРЕССА","PROGRESS BACKUP"))
	label(words("Сохрани этот текст в файле или заметках. Для восстановления вставь текст своей копии сюда.","Keep this text in a file or notes. Paste your backup here to restore it."),24)
	var field:=TextEdit.new(); field.text=JSON.stringify(store.data); field.size_flags_vertical=Control.SIZE_EXPAND_FILL; field.wrap_mode=TextEdit.LINE_WRAPPING_BOUNDARY; root_box.add_child(field)
	button(words("Выделить копию","Select backup"),func(): field.grab_focus(); field.select_all())
	var feedback:=label("",22)
	button(words("Восстановить из текста","Restore from text"),func():
		var dialog:=ConfirmationDialog.new(); dialog.dialog_text=words("Текущий прогресс будет заменён этой копией. Продолжить?","This backup will replace your current progress. Continue?"); add_child(dialog)
		dialog.confirmed.connect(func():
			if store.import_copy(field.text): sound.configure(store.data.settings); show_home()
			else: feedback.text=words("Копия повреждена или не сохранена. Текущий прогресс сохранён.","Invalid backup or save failed. Current progress is safe."))
		dialog.visibility_changed.connect(func():
			if not dialog.visible: dialog.queue_free())
		dialog.popup_centered(Vector2i(540,220)))
