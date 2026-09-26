extends RefCounted
## Short, replayable guides for the three places a new player meets.
const KEYS=["garden","light","match"]
var host: Control
var layer: CanvasLayer
var heading: Label
var body: Label
var counter: Label
var next_button: Button
var section: String
var step:=0

func _init(game: Control) -> void: host=game

func words(ru: String,en: String) -> String: return host.words(ru,en)

static func seen(data: Dictionary,key: String) -> bool:
	return key in data.get("tutorial_seen",[])

func maybe_open(key: String) -> void:
	if not seen(host.store.data,key): open(key)

func open(key: String) -> void:
	if key not in KEYS: return
	if is_instance_valid(layer): layer.queue_free()
	section=key; step=0
	layer=CanvasLayer.new(); layer.layer=20; host.add_child(layer)
	var shade:=ColorRect.new(); shade.color=Color(0.04,0.14,0.13,0.78)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); shade.mouse_filter=Control.MOUSE_FILTER_STOP; layer.add_child(shade)
	var margin:=MarginContainer.new(); margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,20)
	margin.mouse_filter=Control.MOUSE_FILTER_IGNORE; layer.add_child(margin)
	var center:=CenterContainer.new(); center.mouse_filter=Control.MOUSE_FILTER_IGNORE; margin.add_child(center)
	var panel:=PanelContainer.new(); panel.custom_minimum_size.x=minf(420,host.size.x-40)
	var style: StyleBoxFlat=host.style(Color("fff9ea"),Color("d4bc87")); style.set_corner_radius_all(26)
	panel.add_theme_stylebox_override("panel",style); center.add_child(panel)
	var box:=VBoxContainer.new(); box.add_theme_constant_override("separation",16); panel.add_child(box)
	counter=Label.new(); counter.add_theme_font_size_override("font_size",18)
	counter.add_theme_color_override("font_color",Color("64896f")); box.add_child(counter)
	heading=Label.new(); heading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	heading.add_theme_font_size_override("font_size",31); heading.add_theme_color_override("font_color",Color("204f43")); box.add_child(heading)
	body=Label.new(); body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size",23); body.add_theme_color_override("font_color",Color("36554a")); box.add_child(body)
	var row:=HBoxContainer.new(); row.add_theme_constant_override("separation",10); box.add_child(row)
	var skip: Button=host.button(words("Пропустить","Skip"),finish,row)
	skip.add_theme_font_size_override("font_size",20)
	next_button=host.button("",advance,row,true)
	next_button.add_theme_font_size_override("font_size",20)
	for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
		next_button.add_theme_color_override(state,Color("234c3d"))
	show_step(); next_button.grab_focus()

func content() -> Array:
	match section:
		"garden": return [
			[words("Зачем нужен сад?","Why restore the garden?"),words("Джек восстанавливает сад после бури. За первый успех на каждом уровне ты получаешь 25 монет. Баланс — наверху справа.","Jack is rebuilding after the storm. Each level's first win earns 25 coins. Your balance is at the top right.")],
			[words("Исследуй и укрась","Explore and decorate"),words("Проведи пальцем по саду. Нажми светлый кружок на свободном месте, чтобы выбрать цветок или украшение. «К цели» покажет следующую задачу.","Drag the garden. Tap a light circle on an empty spot to choose a flower or decoration. Next task points to your next goal.")],
			[words("Куда нажимать дальше?","Where to go next?"),words("Внизу: «Участки» перемещает по карте, «Фото» убирает кнопки для снимка, «Заказы» показывает букеты соседям, «Играть» открывает оба режима.","At the bottom: Areas jumps around the map, Photo hides controls for a screenshot, Orders shows bouquets, Play opens both modes.")]]
		"light": return [
			[words("Соедини свет и цветы","Connect light to flowers"),words("Нажимай на дорожки: каждое касание поворачивает участок на четверть оборота. Проведи свет от фонаря ко всем цветам.","Tap a path to rotate it a quarter turn. Carry light from the lamp to every flower.")],
			[words("Как понять, что получилось?","How do you win?"),words("Свет идёт только между совпавшими выходами. Под полем видно, сколько цветов освещено. Когда светятся все — уровень готов. Таймера нет.","Light travels only through matching openings. Below the board you can see how many flowers are lit. Light them all to win. There is no timer.")],
			[words("Если нужна помощь","If you need help"),words("«Отмена» возвращает ход, «Заново» начинает уровень сначала, «Подсказка» выделяет один участок. Победа впервые приносит 25 монет в сад.","Undo takes back a move, Restart resets the level, and Hint highlights one path. Your first win earns 25 coins for the garden.")]]
		_: return [
			[words("Собери цветочный каскад","Make a flower cascade"),words("Поменяй два соседних цветка свайпом или двумя касаниями. Три одинаковых в ряд исчезнут, а новые упадут сверху.","Swap neighbouring flowers by swiping or tapping both. Three matching flowers disappear and new ones fall from above.")],
			[words("Следи за целью и ходами","Watch the goal and moves"),words("Над полем показано, какие цветы собрать и сколько росы убрать. Под целью — оставшиеся ходы. Выполни все задачи до их окончания.","Above the board you can see which flowers to collect and how much dew to clear. The move counter is below the goal. Finish before moves run out.")],
			[words("Усилители и помощь","Power-ups and help"),words("Собирай четыре и больше цветка или квадрат 2×2, чтобы получить усилители. Инструменты находятся под полем; «Подсказка» покажет ход. Повторные попытки бесплатны.","Match four or more flowers, or a 2×2 square, to create power-ups. Tools sit below the board; Hint shows a move. Retries are free.")]]

func show_step() -> void:
	var pages:=content()
	counter.text=words("ПРОСТОЕ ОБУЧЕНИЕ · %d / %d","QUICK GUIDE · %d / %d") % [step+1,pages.size()]
	heading.text=pages[step][0]; body.text=pages[step][1]
	next_button.text=words("Понятно — играть","Got it — play") if step==pages.size()-1 else words("Далее  ›","Next  ›")

func advance() -> void:
	if step+1>=content().size(): finish(); return
	step+=1; show_step()

func finish() -> void:
	var seen_keys: Array=host.store.data.get("tutorial_seen",[])
	if section not in seen_keys:
		seen_keys.append(section); host.store.data.tutorial_seen=seen_keys
		if not host.store.write(): push_error(host.store.last_error)
	if is_instance_valid(layer): layer.queue_free()
