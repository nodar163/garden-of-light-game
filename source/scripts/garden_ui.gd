extends RefCounted
const Story=preload("res://scripts/garden_story.gd")
const Journal=preload("res://scripts/garden_journal.gd")
const HUD=preload("res://scripts/garden_hud.gd")
const Rules=preload("res://scripts/garden_rules.gd")
const Map=preload("res://scripts/garden_map.gd")
const Art=preload("res://scripts/match_art.gd")
const JACK=preload("res://assets/jack.png")
var game: Control
var map_view: Control
var hud: RefCounted
var move_source:=-1
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
	var view=Map.new(); view.reduced=game.store.data.settings.reduce_motion; view.garden=g(); view.interactive=interactive
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

func home() -> void:
	move_source=-1
	Rules.sync(game.store.data)
	hud=HUD.new(game,"home"); map_view=hud.map
	map_view.cat_selected.connect(func(): message=words("Джек: Это Персик. Любит тёплые дорожки и смотреть, как растут цветы.","Jack: This is Peaches. He loves warm paths and watching the flowers grow."); slot=-1; repair_index=-1; show())
	map_view.place_selected.connect(select_place)
	var row:=HBoxContainer.new(); row.add_theme_constant_override("separation",16); hud.content.add_child(row)
	HUD.face(row)
	var copy:=VBoxContainer.new(); copy.size_flags_horizontal=Control.SIZE_EXPAND_FILL; row.add_child(copy)
	HUD.text(copy,words("ДЖЕК · НАША СЛЕДУЮЩАЯ ЦЕЛЬ","JACK · OUR NEXT TASK"),18,HUD.SOFT)
	HUD.text(copy,task_title(),28)
	HUD.text(copy,task_detail(),20,HUD.SOFT)
	var progress:=ProgressBar.new(); progress.max_value=Story.STEPS.size() if Story.next(g())<Story.STEPS.size() else 500; progress.value=g().story.claimed.size() if Story.next(g())<Story.STEPS.size() else g().earned.size(); progress.show_percentage=false; progress.custom_minimum_size.y=10
	progress.add_theme_stylebox_override("background",game.style(Color("dfe5cd"),Color("dfe5cd")))
	progress.add_theme_stylebox_override("fill",game.style(Color("67ac60"),Color("67ac60"))); copy.add_child(progress)
	game.button(words("История сада  ›","Garden story  ›") if Story.next(g())<Story.STEPS.size() else words("Открытия сада  ›","Garden discoveries  ›"),journal,hud.content,true)
	var light: bool=g().story.last_mode=="light"
	var id: int=game.unlocked() if light else game.match_unlocked()
	hud.play_button((words("Дорожки света","Light paths") if light else words("Цветочный каскад","Flower Cascade"))+words("\nИграть · уровень ","\nPlay · level ")+str(id),func(): game.open_level(id) if light else game.open_match(id))
	hud.nav([[words("Мой сад","My garden"),open_garden],[words("Режимы","Modes"),modes],[words("Лавка","Shop"),open_shop]])
	if not game.error_message.is_empty(): HUD.text(hud.content,game.error_message,20,Color("a53636"))
	if game.store.recovered: HUD.text(hud.content,words("Сохранение восстановлено из копии.","Save recovered from backup."),18)

func task_title() -> String:
	var step: int=Story.next(g())
	if step<Story.STEPS.size(): return title_of(Story.STEPS[step])
	for id in Story.MILESTONES.size():
		if id not in g().story.milestones: return Story.MILESTONES[id][2 if english() else 1]
	return words("Сад, который создали мы","A garden we made together")

func task_detail() -> String:
	var step: int=Story.next(g())
	if step>=Story.STEPS.size():
		for id in Story.MILESTONES.size():
			if id not in g().story.milestones:
				var goal: int=int(Story.MILESTONES[id][0])
				return words("Награда готова — добавь её в сад.","Gift ready — add it to the garden.") if Story.milestone_ready(g(),id) else words("Новые уровни: %d/%d","New levels: %d/%d") % [g().earned.size(),goal]
		return words("Выбирай цветы, собирай букеты и украшай сад.","Choose flowers, make bouquets and decorate.")
	return words("Готово! Джек ждёт тебя.","Ready! Jack is waiting for you.") if Story.ready(g(),step) else Story.STEPS[step][3 if english() else 2]

func journal() -> void:
	if Story.next(g())>=Story.STEPS.size(): journey()
	else: Journal.new(self).show()

func open_shop() -> void:
	slot=Rules.next_empty(g()); pending=-1; repair_index=-1; shop()

func open_garden() -> void:
	move_source=-1; slot=-1; repair_index=-1; pending=-1; message=""; show()

func modes() -> void:
	move_source=-1
	hud=HUD.new(game,"garden_modes"); map_view=hud.map
	HUD.text(hud.content,words("Как сыграем сегодня?","What shall we play?"),32)
	HUD.text(hud.content,words("Оба режима приносят монеты в один сад.","Both modes earn coins for the same garden."),22,HUD.SOFT)
	for mode in 2:
		var match_mode: bool=mode==0
		var title: String=words("Цветочный каскад","Flower Cascade") if match_mode else words("Дорожки света","Light paths")
		var done: int=game.store.data.match3.completed.size() if match_mode else game.store.data.completed.size()
		var row:=HBoxContainer.new(); row.add_theme_constant_override("separation",20); hud.content.add_child(row)
		var icon:=TextureRect.new(); icon.texture=Art.icon(0 if match_mode else 1); icon.custom_minimum_size=Vector2(88,88); icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED; row.add_child(icon)
		var copy:=VBoxContainer.new(); copy.size_flags_horizontal=Control.SIZE_EXPAND_FILL; row.add_child(copy)
		HUD.text(copy,title,29)
		HUD.text(copy,words("Три в ряд · ","Match 3 · ") if match_mode else words("Соедини свет · ","Connect light · "),21,HUD.SOFT)
		HUD.text(copy,words("Пройдено %d из 250","Completed %d of 250") % done,20,HUD.SOFT)
		var buttons:=HBoxContainer.new(); hud.content.add_child(buttons)
		var play: Callable=func(): game.open_match(game.match_unlocked())
		var levels: Callable=game.show_match_levels
		if not match_mode: play=func(): game.open_level(game.unlocked()); levels=game.show_levels
		game.button(words("Продолжить","Continue"),play,buttons,true)
		game.button(words("Все уровни","All levels"),levels,buttons)
	hud.nav([[words("В сад","Garden"),show],[words("Главная","Home"),game.show_home]])

func show() -> void:
	Rules.sync(game.store.data)
	hud=HUD.new(game,"garden"); map_view=hud.map
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
		HUD.text(hud.content,words("Потяни сад пальцем, чтобы осмотреть его.","Drag to explore your garden."),21,HUD.SOFT)
		var row:=HBoxContainer.new(); hud.content.add_child(row)
		game.button(words("К цели","Next task"),focus_task,row,true)
		game.button(words("Оформить","Decorate"),open_shop,row)
		game.button(words("День / вечер","Day / evening"),toggle_evening,row)
	if move_source>=0: game.button(words("Отменить перенос","Cancel move"),func(): move_source=-1; message=""; show())
	if not message.is_empty(): game.label(message,20)
	hud.nav([[words("Участки","Areas"),areas],[words("Букеты","Bouquets"),help],[words("Играть","Play"),modes]])

func areas() -> void:
	var popup:=PopupMenu.new(); game.add_child(popup)
	var names: Array=[words("У домика","Cottage garden"),words("Розовая аллея","Rose walk"),words("Солнечная поляна","Sunny meadow"),words("Тихий уголок","Quiet corner"),words("У пруда","Pond garden")]
	popup.add_theme_font_size_override("font_size",28); popup.add_theme_constant_override("v_separation",24)
	for i in names.size(): popup.add_item(names[i],i)
	popup.id_pressed.connect(func(id): slot=-1; repair_index=-1; pending=-1; show(); map_view.focus_place("plot",id*6))
	popup.popup_hide.connect(popup.queue_free); popup.popup_centered(Vector2i(550,430))

func focus_task() -> void:
	if g().plots.is_empty(): select_place("plot",0); map_view.focus_place("plot",0); return
	for i in Rules.REPAIRS.size():
		if i not in g().repairs:
			select_place("repair",i); map_view.focus_place("repair",i); return
	select_place("plot",Rules.next_empty(g())); map_view.focus_place("plot",slot)

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
		var art:=TextureRect.new(); art.texture=Map.bed_texture(item[3]) if id<6 else Map.decor_texture(item[3])
		art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.custom_minimum_size=Vector2(0,140); card.add_child(art)
		var choose: Button=game.button(title_of(item)+"\n"+(str(item[2])+words(" монет"," coins") if unlocked else words("Нужно уровней: ","Levels needed: ")+str(item[4])),preview.bind(id),card)
		choose.add_theme_font_size_override("font_size",20); choose.custom_minimum_size.y=92; choose.disabled=not unlocked
	game.button(words("Назад в сад","Back to the garden"),show)

func preview(id: int) -> void:
	pending=id; repair_index=-1; message=""
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
	var row:=HBoxContainer.new(); row.add_theme_constant_override("separation",18); game.root_box.add_child(row)
	var art:=TextureRect.new(); art.texture=Map.decor_texture(int(item[5])); art.custom_minimum_size=Vector2(140,140); art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED; row.add_child(art)
	if repair_index==0:
		var gate:=AtlasTexture.new(); gate.atlas=Map.BACKGROUND
		var extent:=Vector2(Map.BACKGROUND.get_width(),Map.BACKGROUND.get_height())
		gate.region=Rect2(extent*Vector2(.40,.70),extent*Vector2(.20,.20)); art.texture=gate
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

func restore() -> void:
	if game.store.garden_transaction(func(data): return Rules.repair(data,repair_index)):
		message=words("Джек: «Ещё один уголок снова стал нашим!»","Jack: “Another part of the garden is ours again!”")
		game.sound.play_match("win")
	else: message=words("Не удалось сохранить восстановление.","Could not save the restoration.")
	show()
	if not game.store.data.settings.reduce_motion:
		map_view.modulate.a=.55
		map_view.create_tween().tween_property(map_view,"modulate:a",1.0,.45)

func help() -> void:
	game.clear_page("garden_help"); game.header(words("Лавка Джека","Jack's flower stall"))
	game.label(wallet(),30)
	game.label(words("Букеты для соседей","Bouquets for neighbours"),35)
	game.button(words("Заказы друзей","Orders from friends"),func(): Journal.new(self).orders(),null,true)
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
	Journal.new(self).journey()
