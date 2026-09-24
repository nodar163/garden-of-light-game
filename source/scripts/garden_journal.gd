extends RefCounted
const Story=preload("res://scripts/garden_story.gd")
const Rules=preload("res://scripts/garden_rules.gd")
const Map=preload("res://scripts/garden_map.gd")
var ui: RefCounted
var game: Control
func _init(owner_ui: RefCounted) -> void:
	ui=owner_ui; game=ui.game
func words(ru: String,en: String) -> String: return game.words(ru,en)
func begin(title: String) -> void:
	game.clear_page("journal"); game.header(title)
	var scroll:=ScrollContainer.new(); scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL; game.root_box.add_child(scroll)
	var body:=VBoxContainer.new(); body.size_flags_horizontal=Control.SIZE_EXPAND_FILL; body.add_theme_constant_override("separation",20); scroll.add_child(body); game.root_box=body
func show() -> void:
	Story.ensure(ui.g()); begin(words("ДНЕВНИК САДА","GARDEN JOURNAL"))
	var step: int=Story.next(ui.g())
	game.label(words("Возвращение в сад","Coming home"),36)
	game.label(words("Первая глава · цветы, открытые ворота, первый покупатель и вечерние огни.","Chapter one · flowers, open gates, our first customer and evening lights."),24)
	if step<Story.STEPS.size():
		game.label("%d / %d · " % [step+1,Story.STEPS.size()]+ui.title_of(Story.STEPS[step]),30)
		game.label(Story.STEPS[step][3 if ui.english() else 2],25)
		if Story.ready(ui.g(),step):
			game.button(words("Продолжить историю","Continue story"),func():
				if game.store.garden_transaction(func(data): return Story.claim(data,step)): scene(step)
				else: game.label(words("Не удалось сохранить. Попробуй ещё раз.","Could not save. Please try again."),22),null,true)
		else:
			game.button(words("Заказы друзей","Orders from friends") if step==3 else words("Восстановить сад","Restore the garden") if step in [0,2,5,6,7,8] else words("Выбрать уровень","Choose a level"),orders if step==3 else ui.open_shop if step==0 else ui.focus_task if step in [2,5,6,7,8] else ui.modes,null,true)
	game.button(words("Заказы и букеты","Orders and bouquets"),orders)
	game.button(words("Альбом цветов","Flower album"),album)
	for id in ui.g().story.claimed:
		game.label(ui.title_of(Story.STEPS[int(id)])+" · "+words("завершено","complete"),22)
		game.button(words("Вспомнить","Remember"),scene.bind(int(id)))
	game.button(words("Вернуться в сад","Back to garden"),ui.open_garden)
func scene(id: int) -> void:
	begin(words("ИСТОРИЯ ДЖЕКА","JACK'S STORY"))
	ui.make_map(380,false)
	game.label(ui.title_of(Story.STEPS[id]),34)
	game.label(Story.LINES[id][1 if ui.english() else 0],28)
	if id==4: game.label(words("Теперь можно свободно переключать день и вечер в саду.","You can now switch freely between day and evening in the garden."),23)
	game.button(words("Дальше","Continue"),show,null,true)
	game.button(words("Посмотреть сад","See the garden"),ui.open_garden)
func orders() -> void:
	begin(words("ЗАКАЗЫ ДРУЗЕЙ","ORDERS FROM FRIENDS"))
	game.label(words("Букет — маленькая история","Every bouquet tells a story"),32)
	game.label(words("Посади нужные сорта и проходи любые новые уровни. Цветы остаются в саду, спешить не нужно.","Plant the requested varieties and play new levels in either mode. Your flowers stay in the garden. No hurry."),23)
	for id in Story.CUSTOMERS.size():
		var order: Array=Story.CUSTOMERS[id]
		game.label(ui.title_of(order),28)
		game.label(order[6 if ui.english() else 5],23)
		var names: PackedStringArray=[]
		for flower in order[2]: names.append(ui.title_of(Rules.ITEMS[flower]))
		game.label(" + ".join(names),22)
		game.label(words("Уровни: %d/%d · награда %d монет","Levels: %d/%d · reward %d coins") % [mini(ui.g().earned.size(),order[3]),order[3],order[4]],22)
		var done: bool=id in ui.g().story.deliveries
		game.button(words("Букет доставлен","Bouquet delivered") if done else words("Собрать и подарить","Make and deliver"),func():
			if game.store.garden_transaction(func(data): return Story.deliver(data,id)):
				game.sound.play_match("win"); orders()
			else: game.label(words("Заказ не готов или не удалось сохранить.","Order not ready or could not save."),22),null,true).disabled=done or not Story.order_ready(ui.g(),id)
	game.button(words("Посадить цветы","Plant flowers"),ui.open_shop)
	game.button(words("Дневник","Journal"),show)
func album() -> void:
	begin(words("АЛЬБОМ ЦВЕТОВ","FLOWER ALBUM"))
	game.label(words("Истории в лепестках","Stories in petals"),34)
	for id in 6:
		var row:=HBoxContainer.new(); game.root_box.add_child(row)
		var art:=TextureRect.new(); art.texture=Map.bed_texture(id); art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED; art.custom_minimum_size=Vector2(130,130); row.add_child(art)
		var text:=Label.new(); text.text=ui.title_of(Rules.ITEMS[id])+"\n"+(words("Растёт в нашем саду","Growing in our garden") if id in ui.g().plots.values() else words("Посади этот сорт","Plant this variety")); text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; text.size_flags_horizontal=Control.SIZE_EXPAND_FILL; row.add_child(text)
	game.button(words("Выбрать цветы","Choose flowers"),ui.open_shop)
	game.button(words("Дневник","Journal"),show)
