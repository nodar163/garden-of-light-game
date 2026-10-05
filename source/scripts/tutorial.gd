extends RefCounted
## Short, replayable guides for the three places a new player meets.
const KEYS=["garden","light","match","nursery","shop","journal","upgrades","album","settings","levels","story","backup"]
var demo: Control
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

func dismiss() -> void:
	if is_instance_valid(layer): layer.queue_free()
	layer=null

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
	var box:=VBoxContainer.new(); box.add_theme_constant_override("separation",10); panel.add_child(box)
	var portrait:=TextureRect.new(); portrait.texture=preload("res://assets/jack.png"); portrait.custom_minimum_size=Vector2(64,76); portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED; box.add_child(portrait)
	counter=Label.new(); counter.add_theme_font_size_override("font_size",18)
	counter.add_theme_color_override("font_color",Color("64896f")); box.add_child(counter)
	heading=Label.new(); heading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	heading.add_theme_font_size_override("font_size",25); heading.add_theme_color_override("font_color",Color("204f43")); box.add_child(heading)
	body=Label.new(); body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size",20); body.add_theme_color_override("font_color",Color("36554a")); box.add_child(body)
	demo=preload("res://scripts/tutorial_demo.gd").new(); demo.english=host.store.data.settings.language=="en"; demo.reduced=host.store.data.settings.reduce_motion; box.add_child(demo)
	var row:=HBoxContainer.new(); row.add_theme_constant_override("separation",10); box.add_child(row)
	var skip: Button=host.button(words("Пропустить","Skip"),finish,row)
	skip.add_theme_font_size_override("font_size",20)
	next_button=host.button("",advance,row,true)
	next_button.add_theme_font_size_override("font_size",20)
	for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
		next_button.add_theme_color_override(state,Color("234c3d"))
	show_step(); next_button.grab_focus()

func content() -> Array:
	if section in ["nursery","shop"]:
		var pages: Array=[
			["Подготовим землю","Prepare the soil","Я Джек. Перетащи лопатку на пустую грядку. Можно коснуться лопатки, затем земли. Попробуй ниже — это безопасный пример.","I'm Jack. Drag the spade onto an empty bed, or tap the spade and then the soil. Try the safe example below."],
			["Выберем семена","Choose seeds","Перенеси цветок из нижнего ряда на подготовленную землю. Первые космеи бесплатны; цена остальных указана под семенами.","Move a flower from the bottom row onto prepared soil. Cosmos seeds are free; other prices appear below the seeds."],
			["Полив и урожай","Water and harvest","Лейка ускоряет рост один раз за урожай. Новые победы тоже растят цветы. На стадии 3/3 перенеси грядку в корзину, затем зайди в магазин.","Water once per harvest to speed growth. New level wins also grow flowers. At 3/3, move the bed to the basket, then visit the shop."]
		] if section=="nursery" else [
			["Цветы на стол","Flowers on the table","Я Джек. На витрине лежит твой урожай. Перенеси на стол до трёх цветков. Над покупателем написано, что ему нравится.","I'm Jack. Your harvest is on the display. Move up to three flowers onto the table. The customer's favourite quality is shown above them."],
			["Завернём букет","Wrap the bouquet","Справа от стола три рулона бумаги. Перенеси выбранный рулон на цветы. Чтобы вернуть отдельный цветок, перенеси его со стола на витрину.","Three paper rolls sit to the right. Move one onto the flowers. To return a loose flower, move it from the table back to the display."],
			["Первый покупатель","Your first customer","Перенеси готовый букет к кассе или первому покупателю. Получишь монеты; следующий подойдёт сам. Если цветы закончились — вернись в огород.","Move the wrapped bouquet to checkout or the first customer. You'll earn coins and the queue will advance. Grow more in the nursery when stock runs out."]]
		var result: Array=[]
		for page in pages: result.append([words(page[0],page[1]),words(page[2],page[3])])
		return result
	if section not in ["garden","light","match"]:
		var tips: Dictionary={
			"journal":["История и цель","Story and goal","Здесь я показываю ближайшую задачу. Выполни условие и нажми «Продолжить историю». Заказы друзей — подарки из декоративного сада; урожай продаётся отдельно в магазине.","I show your next goal here. Meet its condition and continue the story. Friends' gifts use decorative garden varieties; harvest is sold separately in the shop."],
			"upgrades":["Развиваем лавку","Grow the shop","На карточке показаны цена и нужное число продаж. Улучшения увеличивают доход. Если кнопка недоступна, сначала выполни указанное условие.","Each card shows its price and required sales. Upgrades increase income. If a button is disabled, meet the listed condition first."],
			"album":["Наши букеты","Our bouquets","Здесь хранятся последние 12 проданных букетов. Пока альбом пуст, вырасти цветы и обслужи первого покупателя.","Your last 12 sold bouquets appear here. If the album is empty, grow flowers and serve your first customer."],
			"settings":["Как тебе удобно","Make yourself at home","Выбери Русский или English. Музыка и звуки отключаются отдельно. Можно уменьшить анимации. Сохрани резервную копию, прежде чем менять устройство.","Choose Русский or English. Music and sounds have separate switches. You can reduce animations. Keep a backup before changing devices."],
			"levels":["Наше путешествие","Our journey","Уровни открываются по очереди. Выбирай доступный номер; пройденные можно повторять. Монеты даются за первую победу. Для роста цветов можно заново решить пройденный уровень.","Levels unlock in order. Pick an available number or replay an earlier level. Coins are awarded on the first win. Solving a level again also grows your flowers."],
			"story":["Джек и Лилия","Jack and Lily","Новые сцены открываются за ремонт, продажи и уровни. Под закрытой сценой написано условие. Уже прочитанные главы можно перечитать; выбор Джека сохраняется.","Repairs, sales and levels unlock scenes. Locked scenes show their requirements. Replay completed chapters any time; Jack's choice is saved."],
			"backup":["Сохраним наш сад","Keep our garden safe","Скопируй весь текст в заметки. На другом устройстве вставь его сюда и подтверди восстановление. Копия заменит прогресс, поэтому сохраняй свежую версию.","Copy all the text to your notes. On another device, paste it here and confirm restoring. A backup replaces progress, so keep a recent copy."]}
		var tip: Array=tips[section]
		return [[words(tip[0],tip[1]),words(tip[2],tip[3])]]
	match section:
		"garden": return [
			[words("Зачем нужен сад?","Why restore the garden?"),words("Джек восстанавливает сад после бури. За первый успех на каждом уровне ты получаешь 25 монет. Баланс — наверху справа.","Jack is rebuilding after the storm. Each level's first win earns 25 coins. Your balance is at the top right.")],
			[words("Исследуй и укрась","Explore and decorate"),words("Проведи пальцем по саду. Нажми светлый кружок на свободном месте, чтобы выбрать цветок или украшение. «К цели» покажет следующую задачу.","Drag the garden. Tap a light circle on an empty spot to choose a flower or decoration. Next task points to your next goal.")],
			[words("Куда нажимать дальше?","Where to go next?"),words("Коснись здания «Огород»: там сажают, поливают и собирают цветы. В здании «Магазин» перетаскивай их на стол, заверни в бумагу и отдай покупателю у кассы. «Режимы» открывает обе игры.","Tap the Nursery building to plant, water and harvest. In the Shop, drag flowers onto the table, wrap them and give the bouquet to the customer at checkout. Modes opens both games.")]]
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
	demo.visible=section in ["garden","light","match","nursery","shop"]
	demo.reset(section,step)
	counter.text=words("ДЖЕК ПОМОЖЕТ · %d / %d","JACK’S GUIDE · %d / %d") % [step+1,pages.size()]
	heading.text=pages[step][0]; body.text=pages[step][1]
	next_button.text=words("Понятно — играть","Got it — play") if step==pages.size()-1 else words("Далее  ›","Next  ›")

func advance() -> void:
	if step+1>=content().size(): finish(); return
	step+=1; show_step()

func finish() -> void:
	var previous: Array=host.store.data.get("tutorial_seen",[]).duplicate()
	var seen_keys: Array=previous.duplicate()
	if section not in seen_keys:
		seen_keys.append(section); host.store.data.tutorial_seen=seen_keys
		if not host.store.write(): host.store.data.tutorial_seen=previous; push_error(host.store.last_error)
	dismiss()
