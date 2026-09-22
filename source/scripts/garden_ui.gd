extends RefCounted
const Rules=preload("res://scripts/garden_rules.gd")
const Map=preload("res://scripts/garden_map.gd")
const Art=preload("res://scripts/match_art.gd")
const JACK=preload("res://assets/jack.png")
var game: Control
var map_view: Control
var slot:=-1
var repair_index:=-1
var pending:=-1
var category:=0
var message:=""
var tutorial_plant:=false
var replay:=false
var story_step:=0

func _init(host: Control) -> void: game=host
func words(ru: String,en: String) -> String: return game.words(ru,en)
func english() -> bool: return game.store.data.settings.language=="en"
func g() -> Dictionary: return game.store.data.garden
func title_of(item: Array) -> String: return item[1 if english() else 0]
func wallet() -> String: return words("Садовые монеты: ","Garden coins: ")+str(g().coins)

func save_view(value: Array) -> void:
	g().camera=value
	if not game.store.write():
		message=words("Не удалось сохранить. Проверьте свободное место.","Could not save. Check free storage.")

func make_map(height: int,interactive: bool=true) -> Control:
	var view=Map.new(); view.garden=g(); view.interactive=interactive
	view.custom_minimum_size.y=height; view.size_flags_vertical=Control.SIZE_EXPAND_FILL
	view.selected=slot; view.preview_item=pending
	game.root_box.add_child(view)
	if interactive:
		view.place_selected.connect(select_place); view.view_changed.connect(save_view)
	return view

func intro(start: int=-1) -> void:
	if start>=0: story_step=start
	else: story_step=int(g().intro_step)
	game.clear_page("intro")
	game.label(words("САД СВЕТА · ИСТОРИЯ ДЖЕКА","GARDEN OF LIGHT · JACK'S STORY"),22)
	game.label([words("Давай знакомиться","Meet Jack"),words("После ночной бури","After the storm"),words("Начнём с одного цветка","One flower at a time"),words("Первые цветы снова дома","The first flowers are home")][story_step],40)
	if story_step==1:
		make_map(430,false)
	else:
		var portrait:=TextureRect.new(); portrait.texture=JACK
		portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.custom_minimum_size.y=390; portrait.size_flags_vertical=Control.SIZE_EXPAND_FILL
		game.root_box.add_child(portrait)
	var ru=["Я Джек. Здесь я выращивал цветы и собирал букеты для наших соседей. Для каждого праздника находился свой цветок.","Ночью буря разрушила клумбы, повредила теплицу и закрыла путь к лавке. Но семена уцелели. Поможешь вернуть саду жизнь?","У меня осталось 50 садовых монет — хватит на первые космеи. Потом будем проходить уровни: каждое новое решение принесёт ещё 25 монет.","Посмотри, уже стало уютнее! Выбирай любой режим, зарабатывай монеты и возвращайся ко мне. Вместе мы снова откроем цветочную лавку."]
	var en=["I'm Jack. I grew flowers here and made bouquets for our neighbours. There was a flower for every celebration.","A night storm ruined the flowerbeds, damaged the greenhouse and blocked the stall. But the seeds survived. Will you help bring the garden back?","I saved 50 garden coins, enough for our first cosmos. Then we'll play levels: every new solution earns another 25 coins.","It already feels like home! Choose either mode, earn coins and come back. Together we'll open the flower stall again."]
	game.label(words(ru[story_step],en[story_step]),27)
	game.label("%d / 4" % (story_step+1),18,game.MUTED)
	game.button(words("Посмотреть сад","See the garden") if story_step==0 else words("Помочь Джеку","Help Jack") if story_step==1 else words("Посадить первые цветы","Plant the first flowers") if story_step==2 else words("К уровням","Choose a mode"),next_intro,null,true)
	game.button(words("Позже · в меню","Later · main menu"),finish_intro)

func next_intro() -> void:
	if story_step<2:
		story_step+=1
		if not replay: g().intro_step=story_step; game.store.write()
		intro(story_step)
	elif story_step==2:
		g().intro_done=true; g().intro_step=3
		game.store.write()
		if g().plots.is_empty():
			tutorial_plant=true; slot=0; pending=0; repair_index=-1
			g().camera=[Rules.plot_position(0).x*3200,Rules.plot_position(0).y*2400,.5]
			show()
		else: finish_intro()
	else: finish_intro()

func finish_intro() -> void:
	g().intro_done=true; g().intro_step=3; game.store.write()
	replay=false; game.show_home()

func show() -> void:
	Rules.sync(game.store.data)
	game.clear_page("garden")
	game.header(words("Сад Джека","Jack's garden"))
	game.label(wallet(),28)
	game.label(Rules.task(g(),english()),23,game.MUTED)
	map_view=make_map(450)
	var zoom_row:=HBoxContainer.new(); game.root_box.add_child(zoom_row)
	game.button("−",func(): map_view.zoom_by(1/1.3),zoom_row)
	game.button(words("Обзор","Overview"),func(): map_view.overview(),zoom_row)
	game.button("+",func(): map_view.zoom_by(1.3),zoom_row)
	game.button(words("К цели","Next task"),focus_task,zoom_row)
	game.label(words("Потяни карту. Нажми на место «+» или на постройку.","Drag the map. Tap a + place or a building."),18,game.MUTED)
	if pending>=0: show_preview()
	elif repair_index>=0: show_repair()
	elif slot>=0:
		var item:=int(g().plots.get(str(slot),-1))
		game.label((words("Место ","Place ")+str(slot+1))+": "+(title_of(Rules.ITEMS[item]) if item>=0 else words("свободно","empty")),23)
		var row:=HBoxContainer.new(); game.root_box.add_child(row)
		game.button(words("Изменить","Change") if item>=0 else words("Выбрать цветы и декор","Choose flowers and decor"),shop,row,true)
		if item>=0: game.button(words("Убрать · вернуть ","Remove · refund ")+str(Rules.ITEMS[item][2]),remove_item,row)
	else:
		game.button(words("Посадить цветы или поставить украшение","Plant flowers or add a decoration"),func(): slot=Rules.next_empty(g()); shop(),null,true)
	var row:=HBoxContainer.new(); game.root_box.add_child(row)
	game.button(words("Играть · +25 монет","Play · +25 coins"),game.show_home,row,true)
	game.button(words("Заказы и помощь","Orders and help"),help,row)
	if not message.is_empty(): game.label(message,20,game.MUTED)

func focus_task() -> void:
	if g().plots.is_empty(): select_place("plot",0); map_view.focus_place("plot",0); return
	for i in Rules.REPAIRS.size():
		if i not in g().repairs:
			select_place("repair",i); map_view.focus_place("repair",i); return
	select_place("plot",Rules.next_empty(g())); map_view.focus_place("plot",slot)

func select_place(kind: String,index: int) -> void:
	pending=-1; message=""
	slot=index if kind=="plot" else -1
	repair_index=index if kind=="repair" else -1
	show()

func shop() -> void:
	if slot<0: slot=Rules.next_empty(g())
	pending=-1
	game.clear_page("garden_shop"); game.header(words("Цветы и украшения","Flowers and decorations"))
	game.label(wallet(),30)
	game.label(words("Место %d. Сначала примерка, затем покупка.","Place %d. Preview first, then buy.") % (slot+1),22,game.MUTED)
	var row:=HBoxContainer.new(); game.root_box.add_child(row)
	game.button(words("Цветы","Flowers"),func(): category=0; shop(),row,category==0)
	game.button(words("Украшения","Decorations"),func(): category=1; shop(),row,category==1)
	var scroll:=ScrollContainer.new(); scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	game.root_box.add_child(scroll)
	var grid:=GridContainer.new(); grid.columns=2; grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation",12); grid.add_theme_constant_override("v_separation",12)
	scroll.add_child(grid)
	for id in Rules.ITEMS.size():
		if (id<6)!=(category==0): continue
		var item: Array=Rules.ITEMS[id]
		var unlocked: bool=g().earned.size()>=item[4]
		var card:=VBoxContainer.new(); card.size_flags_horizontal=Control.SIZE_EXPAND_FILL; grid.add_child(card)
		var art:=TextureRect.new(); art.texture=Art.icon(item[3]) if id<6 else Map.decor_texture(item[3])
		art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.custom_minimum_size=Vector2(0,140); card.add_child(art)
		var choose: Button=game.button(title_of(item)+"\n"+(str(item[2])+words(" монет"," coins") if unlocked else words("Нужно уровней: ","Levels needed: ")+str(item[4])),preview.bind(id),card)
		choose.add_theme_font_size_override("font_size",20); choose.custom_minimum_size.y=92; choose.disabled=not unlocked
	game.button(words("Назад в сад","Back to the garden"),show)

func preview(id: int) -> void:
	pending=id; repair_index=-1
	var pos:=Rules.plot_position(slot)*Vector2(3200,2400)
	g().camera=[pos.x,pos.y,.5]
	show()

func show_preview() -> void:
	var item: Array=Rules.ITEMS[pending]
	var old:=int(g().plots.get(str(slot),-1))
	var refund:=int(Rules.ITEMS[old][2]) if old>=0 else 0
	game.label(title_of(item)+words(" · цена "," · price ")+str(item[2])+(words(" · возврат "," · refund ")+str(refund) if refund>0 else ""),23)
	var row:=HBoxContainer.new(); game.root_box.add_child(row)
	game.button(words("Посадить","Plant") if pending<6 else words("Поставить","Place"),purchase,row,true).disabled=int(g().coins)+refund<int(item[2]) or old==pending
	game.button(words("Отмена","Cancel"),func(): pending=-1; show(),row)
	if int(g().coins)+refund<int(item[2]): game.label(words("Не хватает монет. Новый уровень принесёт 25.","Not enough coins. A new level earns 25."),20)

func purchase() -> void:
	if pending<0: return
	if not game.store.garden_transaction(func(data): return Rules.buy(data,slot,pending)):
		message=words("Покупка не сохранена. Монеты не списаны.","Purchase was not saved. No coins charged."); show(); return
	pending=-1; message=words("Джек: «Как красиво! Сад снова оживает». ","Jack: “Beautiful! The garden is coming back to life.”")
	game.sound.play_match("match")
	if tutorial_plant: tutorial_plant=false; intro(3)
	else: show()

func remove_item() -> void:
	if game.store.garden_transaction(func(data): return Rules.remove(data,slot)):
		message=words("Монеты возвращены полностью.","All coins refunded.")
	else: message=words("Не удалось сохранить изменение.","Could not save the change.")
	show()

func show_repair() -> void:
	var item: Array=Rules.REPAIRS[repair_index]
	game.label(title_of(item),26)
	if repair_index in g().repairs:
		game.label(words("Уже восстановлено. Спасибо!","Already restored. Thank you!"),22)
	else:
		var ready: bool=(repair_index==0 or repair_index-1 in g().repairs) and g().plots.size()>=item[3]
		game.label(words("Нужно занятых мест: %d/%d. Предыдущая постройка должна быть готова.","Occupied places: %d/%d. Finish the previous building first.") % [g().plots.size(),item[3]],19,game.MUTED)
		game.button(words("Восстановить · ","Restore · ")+str(item[2])+words(" монет"," coins"),restore,null,true).disabled=not ready or int(g().coins)<item[2]

func restore() -> void:
	if game.store.garden_transaction(func(data): return Rules.repair(data,repair_index)):
		message=words("Джек: «Ещё один уголок снова стал нашим!»","Jack: “Another part of the garden is ours again!”")
		game.sound.play_match("win")
	else: message=words("Не удалось сохранить восстановление.","Could not save the restoration.")
	show()

func help() -> void:
	game.clear_page("garden_help"); game.header(words("Лавка Джека","Jack's flower stall"))
	game.label(wallet(),30)
	game.label(words("Букеты для соседей","Bouquets for neighbours"),35)
	game.label(words("Каждые 10 новых уровней и 3 клумбы позволяют продать один букет за 40 монет. Цветы остаются расти в саду. Ожидания нет.","Every 10 new levels and 3 flowerbeds let Jack sell one bouquet for 40 coins. The flowers stay in your garden. No waiting."),24)
	game.label(words("Клумбы: %d/3 · уровни: %d/%d","Flowerbeds: %d/3 · levels: %d/%d") % [Rules.flowers(g()),g().earned.size(),(int(g().orders)+1)*10],24)
	game.button(words("Продать букет · +40 монет","Sell bouquet · +40 coins"),sell_order,null,true).disabled=not Rules.order_ready(g())
	game.label(words("Как устроен сад","How the garden works"),30)
	game.label(words("• Перетаскивай карту, меняй масштаб кнопками + и −.\n• Нажми свободное место, выбери предмет и примерь его. До подтверждения монеты не тратятся.\n• Изменение или удаление покупки возвращает её полную цену.\n• Новые уровни обоих режимов дают по 25 монет один раз. За прежний прогресс монеты уже начислены.\n• Кнопка «К цели» покажет следующую постройку.\n• Всё сохраняется на этом устройстве. Не очищай данные сайта.","• Drag the map and zoom with + and −.\n• Tap an empty place, choose an item and preview it. No coins spent until confirmation.\n• Replacing or removing an item refunds its full price.\n• New levels in either mode earn 25 coins once. Previous progress has already been rewarded.\n• Next task shows the next building.\n• Everything is saved on this device. Avoid clearing site data."),22,game.MUTED)
	game.spacer(); game.button(words("В сад","Back to garden"),show)

func sell_order() -> void:
	if game.store.garden_transaction(func(data): return Rules.deliver(data)): message=words("Букет продан. +40 монет!","Bouquet sold. +40 coins!")
	else: message=words("Заказ пока недоступен или не сохранён.","Order unavailable or could not be saved.")
	show()
