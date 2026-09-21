extends Control
const Rules = preload("res://scripts/puzzle.gd")
const Saves = preload("res://scripts/save_store.gd")
const Board = preload("res://scripts/board.gd")
const Sound = preload("res://scripts/sound.gd")
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
	get_tree().auto_accept_quit = false
	resized.connect(_layout)
	show_home()
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
	shell.add_theme_constant_override("margin_left", edge)
	shell.add_theme_constant_override("margin_right", edge)
	shell.add_theme_constant_override("margin_top", top)
	shell.add_theme_constant_override("margin_bottom", bottom)

func clear_page(name_value: String) -> void:
	page = name_value
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
	result.add_theme_color_override("font_color", color)
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
	var art = Board.new()
	art.decorative = true
	art.garden_count = store.data.completed.size()
	art.garden_offset = garden_section * 50
	art.completed = store.data.completed
	art.region = garden_section * 2
	art.reduced = store.data.settings.reduce_motion
	art.custom_minimum_size.y = height
	art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_box.add_child(art)

func show_home() -> void:
	clear_page("home")
	label(words("ТИХИЕ МГНОВЕНИЯ", "A QUIET MOMENT"), 18, MUTED)
	label(words("Сад света", "Garden of Light"), 62)
	label(words("Немного света. Немного тишины.", "A little light. A little stillness."), 24, MUTED)
	garden_view(420)
	if not error_message.is_empty():
		label(error_message, 20)
		return
	button(words("Продолжить", "Continue") + "  ›", func(): open_level(clampi(int(store.data.current),1,unlocked())), null, true)
	button(words("Выбрать полянку", "Choose a clearing"), show_levels)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	root_box.add_child(row)
	button(words("Мой сад", "My garden"), show_garden, row)
	button(words("Настройки", "Settings"), show_settings, row)
	label(words("250 полянок · 10 красочных областей", "250 clearings · 10 colourful regions"), 19, MUTED)
	if store.recovered:
		label(words("Сохранение восстановлено. Проверьте прогресс.", "Save recovered. Please check your progress."), 18)

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
	label(words("Каждое решение — новый цветок в саду.", "Every solution brings a new flower."), 23, MUTED)
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
	notice = label("", 18, MUTED)
	refresh()
	persist()

func on_tile(index: int) -> void:
	var before: int = puzzle.lit().size()
	if puzzle.turn(index):
		selected_hint = -1
		if puzzle.lit().size() > before:
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
		store.complete(id)
		status.text = words("Полянка ожила. Спасибо вам.", "This clearing is alive. Thank you.")
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
	clear_page("garden")
	header(words("Мой сад", "My garden"))
	label(words("Здесь остаётся ваш свет", "Your light stays here"), 40)
	label(words("Каждый цветок — маленькое открытие.", "Every flower is a little discovery."), 23, MUTED)
	garden_view(450)
	var navigation := HBoxContainer.new()
	root_box.add_child(navigation)
	button("‹", change_garden.bind(-1), navigation).disabled = garden_section == 0
	button(words("Уголок ", "Corner ") + "%d / 5" % (garden_section+1), func(): pass, navigation).mouse_filter = Control.MOUSE_FILTER_IGNORE
	button("›", change_garden.bind(1), navigation).disabled = garden_section == 4
	label(words("Вырастили цветов: ", "Flowers grown: ") + "%d / %d" % [store.data.completed.size(), LEVEL_COUNT], 28)
	if store.data.completed.size() == levels.size():
		label(words("Все полянки ожили. Спасибо за игру!", "Every clearing is alive. Thank you for playing!"), 24)
	button(words("К полянкам", "Back to the clearings"), show_levels, null, true)

func change_garden(direction: int) -> void:
	garden_section = clampi(garden_section + direction, 0, 4)
	show_garden()

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
