extends RefCounted
const Story=preload("res://scripts/garden_story.gd")
const Journal=preload("res://scripts/garden_journal.gd")
const HUD=preload("res://scripts/garden_hud.gd")
const Rules=preload("res://scripts/garden_rules.gd")
const Map=preload("res://scripts/garden_map.gd")
const Farm=preload("res://scripts/garden_farm.gd")
const Business=preload("res://scripts/garden_farm_ui.gd")
var game: Control
var map_view: Control
var hud: RefCounted
var move_source:=-1
var slot:=-1
var repair_index:=-1
var pending:=-1
var category:=0
var message:=""
var replay:=false
var business: RefCounted
var requests: RefCounted
var estate: RefCounted
var journal_view: RefCounted

func _init(host: Control) -> void:
	game=host
	business=Business.new(self)
	estate=preload("res://scripts/estate_ui.gd").new(self)
	requests=preload("res://scripts/requests_ui.gd").new(self)
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
	var view=Map.new(); view.reduced=game.store.data.settings.reduce_motion; view.english=english(); view.garden=g(); view.interactive=interactive
	view.custom_minimum_size.y=height; view.size_flags_vertical=Control.SIZE_EXPAND_FILL
	view.selected=slot; view.preview_item=pending
	game.root_box.add_child(view)
	if interactive:
		view.place_selected.connect(select_place); view.view_changed.connect(save_view)
	return view

func intro(_start: int=-1) -> void:
	game.clear_page("prologue")
	var memory=preload("res://scripts/prologue.gd").new(); memory.host=game; memory.replay=replay or g().intro_done
	game.root_box.add_child(memory)

func home() -> void:
	move_source=-1
	Rules.sync(game.store.data)
	hud=HUD.new(game,"home"); map_view=hud.map
	map_view.nursery_selected.connect(business.nursery)
	map_view.shop_selected.connect(business.shop)
	map_view.house_selected.connect(func(): estate.enter("house"))
	map_view.estate_selected.connect(func(): estate.open(false))
	map_view.cat_selected.connect(func(): message=words("Джек: Это Персик. Любит тёплые дорожки и смотреть, как растут цветы.","Jack: This is Peaches. He loves warm paths and watching the flowers grow."); slot=-1; repair_index=-1; show())
	map_view.place_selected.connect(select_place)
	var row:=HBoxContainer.new(); row.add_theme_constant_override("separation",16); hud.content.add_child(row)
	HUD.face(row)
	var copy:=VBoxContainer.new(); copy.size_flags_horizontal=Control.SIZE_EXPAND_FILL; row.add_child(copy)
	HUD.text(copy,words("ДЖЕК · НАША СЛЕДУЮЩАЯ ЦЕЛЬ","JACK · OUR NEXT TASK"),18,HUD.SOFT)
	HUD.text(copy,task_title(),28)
	HUD.text(copy,task_detail(),20,HUD.SOFT)
	var progress:=ProgressBar.new(); progress.max_value=Story.STEPS.size() if Story.next(g())<Story.STEPS.size() else 2000; progress.value=g().story.claimed.size() if Story.next(g())<Story.STEPS.size() else Rules.Estate.progress(g()); progress.show_percentage=false; progress.custom_minimum_size.y=10
	progress.add_theme_stylebox_override("background",game.style(Color("dfe5cd"),Color("dfe5cd")))
	progress.add_theme_stylebox_override("fill",game.style(Color("67ac60"),Color("67ac60"))); copy.add_child(progress)
	game.button(words("К следующему шагу  ›","Take the next step  ›"),run_goal,hud.content,true)
	var light: bool=g().story.last_mode=="light"
	var id: int=game.unlocked() if light else game.match_unlocked()
	hud.play_button((words("Дорожки света","Light paths") if light else words("Цветочный каскад","Flower Cascade"))+words("\nИграть · уровень ","\nPlay · level ")+str(id),func(): game.open_level(id) if light else game.open_match(id))
	hud.nav([[words("Мой сад","My garden"),open_garden],[words("Режимы","Modes"),modes]])
	if not game.error_message.is_empty(): HUD.text(hud.content,game.error_message,20,Color("a53636"))
	if game.store.recovered: HUD.text(hud.content,words("Сохранение восстановлено из копии.","Save recovered from backup."),18)

func find_nursery() -> void:
	var point: Vector2=Map.NURSERY_POS*Map.WORLD
	g().camera=[point.x,point.y,.55]
	message=words("Коснись здания «Огород», чтобы войти.","Tap the Nursery building to enter.")
	move_source=-1; slot=-1; repair_index=-1; pending=-1; show()

func next_goal() -> Dictionary:
	var request_state: Dictionary=preload("res://scripts/garden_requests.gd").state(g())
	if request_state.ready: return {"action":"requests","title":words("Тебе письмо от покупателя","A customer wrote to you"),"detail":words("Узнай продолжение истории и забери 60 монет.","Read what happened next and collect 60 coins.")}
	# One actionable goal; optional stories remain available in the journal.
	if g().plots.is_empty() and g().coins<50: return {"action":"play","title":words("Монеты для первых цветов","Coins for our first flowers"),"detail":words("Новая победа даёт 25 монет. Космеи стоят 50.","A new win earns 25 coins. Cosmos cost 50.")}
	if g().plots.is_empty(): return {"action":"plant","title":words("Первый живой уголок","Our first living corner"),"detail":words("Посади космеи у дома за 50 монет.","Plant cosmos by the cottage for 50 coins.")}
	var chapter: int=Story.next(g())
	if chapter<Story.STEPS.size() and Story.ready(g(),chapter): return {"action":"journal","title":title_of(Story.STEPS[chapter]),"detail":words("Готово! Узнай, что изменилось в саду.","Done! See what changed in the garden.")}
	if Farm.can_enter(g(),"shop") and int(g().farm.orders_done)==0:
		var stock:=0
		for amount in g().farm.stock: stock+=int(amount)
		if stock>0: return {"action":"shop","title":words("Анна снова ждёт букет","Anna is waiting again"),"detail":words("Цветы уже на витрине. Собери и продай первый букет.","Flowers are on the display. Make and sell your first bouquet.")}
	if Farm.can_enter(g(),"nursery") and int(g().farm.orders_done)==0 and g().farm.stock.all(func(amount): return int(amount)==0):
		if g().farm.beds.is_empty(): return {"action":"nursery","title":words("Цветы для возвращения Анны","Flowers for Anna's return"),"detail":words("Посади бесплатные космеи в огороде.","Plant free cosmos in the nursery.")}
		for bed in g().farm.beds.values():
			if int(bed.growth)==3: return {"action":"nursery","title":words("Первый урожай готов","Our first harvest is ready"),"detail":words("Перенеси цветы с грядки в корзину.","Move the flowers from their bed into the basket.")}
			if not bed.get("watered",false): return {"action":"nursery","title":words("Поможем цветам вырасти","Help the flowers grow"),"detail":words("Полей грядку, затем проходи уровни.","Water the bed, then play levels.")}
	if chapter in [1,4] and not Story.ready(g(),chapter): return {"action":"play","title":title_of(Story.STEPS[chapter]),"detail":Story.STEPS[chapter][3 if english() else 2]}
	for id in Rules.REPAIRS.size():
		if id in g().repairs: continue
		var item: Array=Rules.REPAIRS[id]
		if g().plots.size()<int(item[3]) and g().coins<50: return {"action":"play","title":words("Монеты для новых цветов","Coins for new flowers"),"detail":words("Космеи стоят 50 монет. Новые уровни дают по 25.","Cosmos cost 50 coins. New levels earn 25 each.")}
		if g().plots.size()<int(item[3]): return {"action":"plant","title":words("Цветы вокруг будущей постройки","Flowers around our next building"),"detail":words("Посадок: %d/%d. Выбери ещё один уголок.","Plantings: %d/%d. Choose another corner.") % [g().plots.size(),int(item[3])]}
		if g().coins<int(item[2]): return {"action":"play","title":title_of(item),"detail":words("Нужно ещё %d монет. Новая победа даёт 25.","%d more coins needed. Each new win earns 25.") % (int(item[2])-int(g().coins))}
		return {"action":"repair","id":id,"title":title_of(item),"detail":words("Всё готово! Верни этому месту жизнь.","Everything is ready! Bring this place back to life.")}
	if int(g().farm.orders_done)==0: return {"action":"play","title":words("Вырастим первый букет","Grow our first bouquet"),"detail":words("Победы растят цветы — повторные тоже.","Wins grow flowers, including replayed levels.")}
	if Farm.story_ready(g(),Farm.next_story(g())): return {"action":"story","title":words("Джек и Лилия · новая глава","Jack and Lily · a new chapter"),"detail":words("Загляни в историю после проделанной работы.","See the next story after all your work.")}
	var best_need:=2001; var best_id:=-1; var inside:=false
	for home_space in [true,false]:
		for id in 24:
			var tier_value: int=Rules.Estate.tier(g(),home_space,id)
			if tier_value>=3: continue
			var need: int=Rules.Estate.required(home_space,id,tier_value+1)
			if need<best_need: best_need=need; best_id=id; inside=home_space
	if best_id>=0 and int(request_state.next)<8 and Farm.can_enter(g(),"shop"):
		var request: Array=preload("res://scripts/garden_requests.gd").REQUESTS[int(request_state.next)]
		if int(g().farm.stock[int(request[2])])>=int(request[3]): return {"action":"requests","title":words("Цветы для маленькой истории","Flowers for a little story"),"detail":words("Урожай готов. Собери букет, продай его и приблизь следующий ремонт.","Your harvest is ready. Make a bouquet, sell it and work toward your next repair.")}
	if best_id>=0:
		var price: int=Rules.Estate.price(Rules.Estate.tier(g(),inside,best_id)+1)
		return {"action":"estate" if Rules.Estate.progress(g())>=best_need and int(g().coins)>=price else "activities","id":best_id,"inside":inside,"title":Rules.Estate.name_of(inside,best_id,english()),"detail":words("Дом и усадьба: развитие %d/%d · ремонт %d монет.","Home and estate: development %d/%d · repair %d coins.") % [Rules.Estate.progress(g()),best_need,price]}
	return {"action":"journal","title":words("Сад, который создали мы","A garden we made together"),"detail":words("Открывай новые истории, сорта и украшения.","Discover new stories, flowers and decorations.")}

func task_title() -> String: return next_goal().title
func task_detail() -> String: return next_goal().detail
func run_goal() -> void:
	var goal:=next_goal()
	match goal.action:
		"requests": requests.show()
		"activities": requests.activities()
		"plant": open_shop()
		"play":
			var light: bool=g().story.last_mode=="light"
			if game.store.data.completed.size()==1000: light=false
			elif game.store.data.match3.completed.size()==1000: light=true
			game.open_level(game.unlocked()) if light else game.open_match(game.match_unlocked())
		"estate": estate.house=goal.inside; estate.details(goal.id)
		"nursery": find_nursery()
		"shop":
			move_source=-1; slot=-1; repair_index=-1; pending=-1
			message=words("Коснись открытой лавки, чтобы собрать букет.","Tap the open shop to make a bouquet."); show(); map_view.focus_place("repair",3)
		"repair": select_place("repair",int(goal.id)); map_view.focus_place("repair",int(goal.id))
		"story": business.story()
		_: journal()

func journal() -> void:
	if Story.next(g())>=Story.STEPS.size(): journey()
	else: journal_controller().show()

func journal_controller() -> RefCounted:
	if journal_view==null: journal_view=Journal.new(self)
	return journal_view

func open_shop() -> void:
	slot=Rules.next_empty(g()); pending=-1; repair_index=-1; shop()

func open_garden() -> void:
	move_source=-1; slot=-1; repair_index=-1; pending=-1; message=""; estate.open(false)

func modes() -> void:
	move_source=-1
	hud=HUD.new(game,"garden_modes"); map_view=hud.map
	HUD.text(hud.content,words("Выбери игру","Choose a game"),32)
	HUD.text(hud.content,words("Первая победа на уровне даёт 25 монет для сада.","A level's first win earns 25 garden coins."),21,HUD.SOFT)
	for mode in 2:
		var divider:=HSeparator.new(); hud.content.add_child(divider)
		var match_mode: bool=mode==0
		var title: String=words("Цветочный каскад","Flower Cascade") if match_mode else words("Дорожки света","Light paths")
		var done: int=game.store.data.match3.completed.size() if match_mode else game.store.data.completed.size()
		var row:=HBoxContainer.new(); row.add_theme_constant_override("separation",16); hud.content.add_child(row)
		var icon=preload("res://scripts/illustrated_preview.gd").new(); icon.variant=0 if match_mode else 1; icon.custom_minimum_size=Vector2(72,72); row.add_child(icon)
		var copy:=VBoxContainer.new(); copy.size_flags_horizontal=Control.SIZE_EXPAND_FILL; row.add_child(copy)
		HUD.text(copy,title,29)
		HUD.text(copy,words("Меняй цветы, собирай три в ряд.","Swap flowers and match three.") if match_mode else words("Поворачивай дорожки к цветам.","Turn paths towards flowers."),20,HUD.SOFT)
		HUD.text(copy,words("Пройдено: %d / 1000","Completed: %d / 1000") % done,19,HUD.SOFT)
		var buttons:=HBoxContainer.new(); hud.content.add_child(buttons)
		var play: Callable=func(): game.open_match(game.match_unlocked())
		var levels: Callable=game.show_match_levels
		if not match_mode: play=func(): game.open_level(game.unlocked()); levels=game.show_levels
		game.button(words("Играть · %d","Play · %d") % (game.match_unlocked() if match_mode else game.unlocked()),play,buttons,true)
		game.button(words("Все уровни","All levels"),levels,buttons)
	hud.nav([[words("В сад","Garden"),show],[words("Обучение","Guides"),guides]])

func guides() -> void:
	game.clear_page("guides")
	game.header(words("Обучение","Guides"))
	game.label(words("Посмотри короткие подсказки ещё раз","Replay a quick guide"),29)
	game.label(words("Джек объяснит и покажет безопасный пример.","Jack explains with a safe practice example."),21,game.MUTED)
	game.spacer()
	game.button(words("Мой сад — карта и покупки","My garden — map and purchases"),func(): game.tutorial.open("garden"))
	game.button(words("Дорожки света — как соединять","Light paths — how to connect"),func(): game.tutorial.open("light"))
	game.button(words("Цветочный каскад — как собирать","Flower Cascade — how to match"),func(): game.tutorial.open("match"))
	game.button(words("Огород — посадка и урожай","Nursery — planting and harvest"),func(): game.tutorial.open("nursery"))
	game.button(words("Магазин — букет и покупатель","Shop — bouquets and customers"),func(): game.tutorial.open("shop"))
	game.button(words("К выбору игры","Back to games"),modes)

func show() -> void:
	Rules.sync(game.store.data)
	hud=HUD.new(game,"garden"); map_view=hud.map
	map_view.nursery_selected.connect(business.nursery)
	map_view.shop_selected.connect(business.shop)
	map_view.house_selected.connect(func(): estate.enter("house"))
	map_view.estate_selected.connect(func(): estate.open(false))
	map_view.selected=slot; map_view.preview_item=pending
	map_view.cat_selected.connect(func(): message=words("Джек: Это Персик. Любит тёплые дорожки и смотреть, как растут цветы.","Jack: This is Peaches. He loves warm paths and watching the flowers grow."); slot=-1; repair_index=-1; show())
	map_view.place_selected.connect(select_place); map_view.view_changed.connect(save_view)
	if pending>=0:
		map_view.focus_place("plot",slot)
		show_preview()
	elif repair_index>=0:
		map_view.focus_place("repair",repair_index)
		show_repair()
	elif slot>=0:
		map_view.focus_place("plot",slot)
		var item:=int(g().plots.get(str(slot),-1))
		game.label(title_of(Rules.ITEMS[item]) if item>=0 else words("Здесь будет красиво","A lovely spot for flowers"),29)
		var row:=HBoxContainer.new(); game.root_box.add_child(row)
		game.button(words("Изменить","Change") if item>=0 else words("Выбрать цветы","Choose flowers"),shop,row,true)
		if item>=0:
			game.button(words("Перенести","Move"),func(): move_source=slot; slot=-1; message=words("Выбери место. Если оно занято, растения поменяются местами.","Choose a place. Occupied places will swap."); show(),row)
			game.button(words("Убрать · +","Remove · +")+str(Rules.ITEMS[item][2]),remove_item)
	else:
		HUD.text(hud.content,task_title(),29)
		HUD.text(hud.content,words("Потяни карту. Коснись здания магазина или огорода, чтобы войти.","Drag the map. Tap the shop or nursery building to enter."),21,HUD.SOFT)
		var row:=HBoxContainer.new(); hud.content.add_child(row)
		game.button(words("К цели","Next task"),focus_task,row,true)
		game.button(words("Оформить","Decorate"),open_shop,row)
		game.button(words("День / вечер","Day / evening"),toggle_evening,row)
	if move_source>=0: game.button(words("Отменить перенос","Cancel move"),func(): move_source=-1; message=""; show())
	if not message.is_empty(): game.label(message,20)
	hud.nav([[words("Режимы","Modes"),modes],[words("Ещё","More"),more_menu]])
	game.tutorial.maybe_open("garden")

func more_menu() -> void:
	var popup:=PopupMenu.new(); game.add_child(popup)
	popup.add_theme_font_size_override("font_size",28); popup.add_theme_constant_override("v_separation",70)
	for title in [words("Участки сада","Garden areas"),words("Фото сада","Garden photo"),words("Старые заказы","Old orders"),words("История Джека и Лилии","Jack and Lily's story")]: popup.add_item(title)
	popup.id_pressed.connect(_more_option)
	popup.popup_hide.connect(popup.queue_free)
	popup.popup_centered(Vector2i(540,430))

func _more_option(id: int) -> void:
	match id:
		0: areas()
		1: photo()
		2: help()
		3: business.story()

func areas() -> void:
	var popup:=PopupMenu.new(); game.add_child(popup)
	var names: Array=[words("У домика","Cottage garden"),words("Розовая аллея","Rose walk"),words("Солнечная поляна","Sunny meadow"),words("Тихий уголок","Quiet corner"),words("У пруда","Pond garden")]
	popup.add_theme_font_size_override("font_size",28); popup.add_theme_constant_override("v_separation",70)
	for i in names.size(): popup.add_item(names[i],i)
	popup.id_pressed.connect(func(id): slot=-1; repair_index=-1; pending=-1; show(); map_view.focus_place("plot",id*6))
	popup.popup_hide.connect(popup.queue_free); popup.popup_centered(Vector2i(550,430))

func focus_task() -> void:
	if g().plots.is_empty(): select_place("plot",0); map_view.focus_place("plot",0); return
	for i in Rules.REPAIRS.size():
		if i not in g().repairs:
			select_place("repair",i); map_view.focus_place("repair",i); return
	var next_slot: int=Rules.next_empty(g())
	if g().plots.size()>=Rules.PLOT_COUNT: message=words("Сад заполнен. Можно переставлять украшения или собирать букеты.","The garden is full. Rearrange decorations or make bouquets."); show(); return
	select_place("plot",next_slot); map_view.focus_place("plot",slot)

func select_place(kind: String,index: int) -> void:
	if move_source>=0:
		if kind!="plot": return
		message=words("Место изменено.","Place changed.") if game.store.garden_transaction(func(data): return Rules.move(data,move_source,index)) else words("Изменение не сохранено.","Change was not saved.")
		move_source=-1; slot=index; repair_index=-1; show(); return
	pending=-1; message=""
	slot=index if kind=="plot" else -1
	repair_index=index if kind=="repair" else -1
	show()

func shop() -> void:
	if slot<0: slot=Rules.next_empty(g())
	pending=-1
	hud=HUD.new(game,"garden_shop"); map_view=hud.map
	HUD.text(hud.content,words("Цветы и украшения","Flowers and decorations"),30)
	game.label(words("Место %d. Сначала примерка, затем покупка.","Place %d. Preview first, then buy.") % (slot+1),22,game.MUTED)
	var row:=HBoxContainer.new(); game.root_box.add_child(row)
	game.button(words("Цветы","Flowers"),func(): category=0; shop(),row,category==0)
	game.button(words("Украшения","Decorations"),func(): category=1; shop(),row,category==1)
	var scroll:=ScrollContainer.new(); scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL; scroll.custom_minimum_size.y=600
	game.root_box.add_child(scroll)
	var grid:=GridContainer.new(); grid.columns=2; grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation",12); grid.add_theme_constant_override("v_separation",12)
	scroll.add_child(grid)
	for id in Rules.ITEMS.size():
		if (id<6)!=(category==0): continue
		var item: Array=Rules.ITEMS[id]
		var unlocked: bool=g().earned.size()>=item[4]
		var card:=VBoxContainer.new(); card.size_flags_horizontal=Control.SIZE_EXPAND_FILL; grid.add_child(card)
		var art=preload("res://scripts/illustrated_preview.gd").new(); art.kind="flower" if id<6 else "bench" if id==6 else "lamp" if id==7 else "house"; art.variant=int(item[3]) if id<6 else 0
		art.custom_minimum_size=Vector2(0,140); card.add_child(art)
		var choose: Button=game.button(title_of(item)+"\n"+(str(item[2])+words(" монет"," coins") if unlocked else words("Нужно уровней: ","Levels needed: ")+str(item[4])),preview.bind(id),card)
		choose.add_theme_font_size_override("font_size",20); choose.custom_minimum_size.y=92; choose.disabled=not unlocked
	game.button(words("Назад в сад","Back to the garden"),show)

func preview(id: int) -> void:
	pending=id; repair_index=-1; message=""
	var pos:=Rules.plot_position(slot)*Map.WORLD
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
	show()

func remove_item() -> void:
	if game.store.garden_transaction(func(data): return Rules.remove(data,slot)):
		message=words("Монеты возвращены полностью.","All coins refunded.")
	else: message=words("Не удалось сохранить изменение.","Could not save the change.")
	show()

func show_repair() -> void:
	var item: Array=Rules.REPAIRS[repair_index]
	var row:=HBoxContainer.new(); row.add_theme_constant_override("separation",18); game.root_box.add_child(row)
	var art:=TextureRect.new()
	var atlas:=AtlasTexture.new(); atlas.atlas=Map.RESTORED
	var zone: Vector4=Map.Restoration.ZONES[[0,2,3,4,5][repair_index]]
	atlas.region=Rect2(Vector2(zone.x,zone.y)*Map.RESTORED.get_size(),Vector2(zone.z,zone.w)*Map.RESTORED.get_size())
	art.texture=atlas; art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.custom_minimum_size=Vector2(140,140); art.mouse_filter=Control.MOUSE_FILTER_IGNORE; row.add_child(art)
	var copy:=VBoxContainer.new(); copy.size_flags_horizontal=Control.SIZE_EXPAND_FILL; row.add_child(copy)
	HUD.text(copy,title_of(item),28)
	if repair_index in g().repairs:
		HUD.text(copy,words("Восстановлено! Выбери оформление бесплатно.","Restored! Choose a free style."),22,HUD.SOFT)
		var styles:=HBoxContainer.new(); game.root_box.add_child(styles)
		for choice in 3:
			var names: Array=[words("Луговой","Meadow"),words("Романтика","Romantic"),words("Солнечный","Sunny")]
			game.button(names[choice],func():
				if not game.store.garden_transaction(func(data): return Story.style(data,repair_index,choice)): message=words("Не удалось сохранить.","Could not save.")
				show(),styles,int(g().story.styles.get(str(repair_index),0))==choice)
	else:
		var ready: bool=(repair_index==0 or repair_index-1 in g().repairs) and g().plots.size()>=item[3]
		HUD.text(copy,words("Так будет выглядеть наш следующий шаг.","This is what we are working towards."),21,HUD.SOFT)
		var missing: int=maxi(0,int(item[2])-int(g().coins))
		if not ready:
			HUD.text(copy,words("Нужно посадок: %d/%d и предыдущая постройка.","Places needed: %d/%d and the previous building.") % [mini(g().plots.size(),item[3]),item[3]],20,HUD.SOFT)
		elif missing>0:
			HUD.text(copy,words("Не хватает %d монет — ещё %d новых уровней.","%d more coins — %d new levels.") % [missing,ceili(missing/25.0)],20,HUD.SOFT)
		else: HUD.text(copy,words("Всё готово. Вернём ему красоту!","All ready. Let's bring it back!"),21,HUD.SOFT)
		game.button(words("Восстановить · ","Restore · ")+str(item[2])+words(" монет"," coins"),restore,null,true).disabled=not ready or missing>0
		if repair_index>0 and repair_index-1 not in g().repairs:
			game.button(words("Сначала: ","First: ")+title_of(Rules.REPAIRS[repair_index-1]),focus_task)
		elif g().plots.size()<int(item[3]):
			game.button(words("Выбрать недостающие посадки","Choose the missing plantings"),open_shop)
		elif missing>0:
			game.button(words("Заработать монеты в уровнях","Earn coins in levels"),modes)

func restore() -> void:
	if not game.store.garden_transaction(func(data): return Rules.repair(data,repair_index)):
		message=words("Не удалось сохранить восстановление.","Could not save the restoration."); show(); return
	game.sound.play_match("win")
	game.clear_page("repair_reveal")
	game.label(words("ЕЩЁ ОДИН УГОЛОК ОЖИЛ","ANOTHER CORNER RESTORED"),30)
	var reveal=preload("res://scripts/repair_reveal.gd").new(); reveal.host=game; reveal.repair_id=repair_index
	game.root_box.add_child(reveal)

func help() -> void:
	game.clear_page("garden_help"); game.header(words("Лавка Джека","Jack's flower stall"))
	game.label(wallet(),30)
	game.label(words("Букеты для соседей","Bouquets for neighbours"),35)
	game.button(words("Заказы друзей","Orders from friends"),func(): journal_controller().orders(),null,true)
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

func toggle_evening() -> void:
	if 4 not in g().story.claimed:
		message=words("Вечер откроется в истории после 12 уровней и первого заказа.","Evening unlocks in the story after 12 levels and your first order."); show(); return
	if not game.store.garden_transaction(func(data): data.story.evening=not data.story.evening; return true): message=words("Не удалось сохранить.","Could not save.")
	show()

func journey() -> void:
	journal_controller().journey()

func photo() -> void:
	game.clear_page("garden_photo")
	var stage:=Control.new(); stage.size_flags_vertical=Control.SIZE_EXPAND_FILL; game.root_box.add_child(stage)
	var scene:=Map.new(); scene.garden=g(); scene.interactive=true; scene.editing=false; scene.reduced=game.store.data.settings.reduce_motion
	stage.add_child(scene); scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scene.view_changed.connect(save_view)
	var back: Button=game.button(words("‹ Вернуться","‹ Back"),open_garden,stage)
	back.position=Vector2(20,20); back.custom_minimum_size=Vector2(180,64)
	var hint:=Label.new(); hint.text=words("Кнопка исчезнет. Нажми на сад, чтобы вернуть её. Сделай снимок экрана на телефоне.","The button will hide. Tap the garden to bring it back. Take a screenshot on your phone.")
	hint.add_theme_font_size_override("font_size",20); hint.add_theme_color_override("font_color",Color.WHITE)
	hint.add_theme_color_override("font_outline_color",Color("234939")); hint.add_theme_constant_override("outline_size",5)
	hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; hint.position=Vector2(20,88); hint.size=Vector2(300,110); hint.mouse_filter=Control.MOUSE_FILTER_IGNORE; stage.add_child(hint)
	var hide:=Timer.new(); hide.one_shot=true; hide.wait_time=3.0; stage.add_child(hide)
	hide.timeout.connect(func(): if is_instance_valid(back): back.visible=false; hint.visible=false)
	scene.tapped.connect(func(): back.visible=true; hint.visible=true; hide.start())
	hide.start()
