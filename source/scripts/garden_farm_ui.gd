extends RefCounted
## Nursery, working flower shop and the new story; uses the existing screen shell.
const Farm=preload("res://scripts/garden_farm.gd")
const Rules=preload("res://scripts/garden_rules.gd")
const Map=preload("res://scripts/garden_map.gd")
const Art=preload("res://scripts/match_art.gd")
const HUD=preload("res://scripts/garden_hud.gd")
const Bouquet=preload("res://scripts/bouquet_view.gd")
const NURSERY=preload("res://assets/flower-nursery.png")
const SHOP=preload("res://assets/jack-shop.png")
const LILY=preload("res://assets/lily.png")
const JACK=preload("res://assets/jack.png")

const SCENES=[
	["Незваная гостья","An unexpected visitor",
	"У повреждённых ворот появляется Лилия. Она ушла, когда Джек потерял деньги, а теперь открывает филиал большой цветочной сети.\nЛилия: «Ты правда решил всё восстановить?»\nДжек: «Начну с этих трёх цветков. Остальное увидишь позже». Он ещё не знает, что делает это не только ради неё.",
	"Lily stops by the damaged gate. She left when Jack lost his money and now runs a branch of a flower chain.\nLily: ‘Are you really rebuilding all this?’\nJack: ‘I'll start with these three flowers. You'll see the rest later.’ He does not yet know he is doing this for more than her."],
	["Бабушкин дневник","Grandma's journal",
	"За старой дверью теплицы Джек находит записи бабушки. Рядом с каждым сортом — имя человека, которому он однажды принёс радость.\n«Лилия продавала цветы быстрее всех, — думает Джек, — но я научусь слышать тех, кто их покупает». Теперь каждый выращенный цветок может стать частью нового букета.",
	"Behind the greenhouse door, Jack finds Grandma's notes. Beside each variety is the name of someone it once made happy.\n‘Lily could sell flowers faster than anyone,’ he thinks, ‘but I will learn to listen to the people buying them.’ Every grown flower can become part of a new bouquet."],
	["Очередь у лавки","A line at the stall",
	"Анна просит цветы для мамы. Марк ищет букет для читального зала. У лавки Джека впервые образуется очередь.\nЛилия: «Пара соседей — ещё не бизнес». Джек улыбается: «Для начала мне хватит пары счастливых соседей». Старые знакомые возвращаются уже с друзьями.",
	"Anna needs flowers for Mum. Mark wants a bouquet for the reading room. For the first time, a line forms at Jack's stall.\nLily: ‘A few neighbours are hardly a business.’ Jack smiles: ‘A few happy neighbours are a good start.’ They return with their friends."],
	["Магазин на углу","The corner flower shop",
	"На месте пустого помещения Джек открывает настоящий цветочный магазин. Каждая проданная корзина помогла поставить ещё один камень.\nЛилия видит новую вывеску и впервые не находит колкости. Она замечает букет по рецепту бабушки: такой нельзя заказать в её сети.",
	"Jack opens a real flower shop in the empty building. Every basket he sold helped lay another stone.\nLily sees the new sign and, for once, has no sharp reply. She notices a bouquet from Grandma's notes: her chain cannot make anything like it."],
	["Городская выставка","The town flower fair",
	"На выставке цветам Джека достаётся лучшее место. Лилия могла бы забрать редкий сорт для своей сети, но возвращает Джеку бабушкину запись о нём.\n«Я тогда испугалась бедности и поступила жестоко», — говорит она. Джек принимает помощь, но не позволяет чужому страху снова решать за него.",
	"Jack's flowers get the best spot at the fair. Lily could take a rare variety for her chain, but returns Grandma's notes about it to Jack.\n‘I was afraid of being poor, and I treated you cruelly,’ she says. Jack accepts her help without letting her fear decide his future."],
	["Имя на вывеске","The name above the door",
	"В саду горят огни, а в магазине ждут новые покупатели. Лилия просит Джека начать всё сначала.\nДжек: «Я рад, что ты вернулась и сказала правду. Но магазин и сад я построил не для того, чтобы заслужить твоё одобрение». Ответ о будущем отношений остаётся за ним — и за игроком.",
	"The garden glows and new customers wait in the shop. Lily asks Jack to start over.\nJack: ‘I'm glad you came back and told the truth. But I didn't build this shop and garden to earn your approval.’ What comes next is his choice — and the player's."],
	["Письма из города","Letters from town",
	"После открытия магазина Джеку пишут люди, которые ещё не были в саду. Одна открытка говорит: «Ваш букет помог мне помириться с сестрой».\nДжек ставит её рядом с бабушкиным дневником: теперь у сада есть истории нового поколения.",
	"After the shop opens, letters arrive from people who have never visited the garden. One says: ‘Your bouquet helped me make peace with my sister.’\nJack puts it beside Grandma's journal. The garden has stories of a new generation."],
	["Аллея памяти","The memory walk",
	"На новой аллее Джек высаживает цветы в честь бабушки. Лилия предлагает дорогую вывеску, но он выбирает таблички с именами людей из её дневника.\nПосетители задерживаются, читают истории и рассказывают свои.",
	"Jack plants the new walk in Grandma's memory. Lily offers an expensive sign, but he chooses small plaques with names from her journal.\nVisitors stop, read the stories and share their own."],
	["Первый выезд","The first delivery",
	"Джек нагружает тележку букетами для библиотеки и школы. Персик пытается забраться в корзину.\nЛилия помогает довезти последний заказ. Джек благодарит её — без обещаний и без старой обиды в голосе.",
	"Jack loads his cart with bouquets for the library and school. Peaches tries to climb into the basket.\nLily helps deliver the last order. Jack thanks her, with no promises and no bitterness."],
	["Пчёлы и соседи","Bees and neighbours",
	"У домика пчёл собираются соседи: кто-то приносит семена, кто-то помогает ухаживать за клумбами. Джек впервые понимает, что дело растёт не только благодаря продажам.\n«Это уже и их сад», — говорит он Лилии.",
	"Neighbours gather by the bee house. Some bring seeds; others help tend the beds. Jack realizes that sales are not the only reason his work is growing.\n‘It's their garden now, too,’ he tells Lily."],
	["Вечер открытых дверей","Open garden evening",
	"Джек оставляет магазин открытым допоздна и приглашает покупателей увидеть, где выросли их цветы. Лилия приходит как гостья и помогает подписать букеты.\nКаким бы ни был прежний ответ Джека, они умеют говорить друг с другом честно.",
	"Jack keeps the shop open late and invites customers to see where their flowers grew. Lily visits as a guest and helps label the bouquets.\nWhatever Jack chose earlier, they can now speak honestly."],
	["Сад тысячи огней","A thousand garden lights",
	"Весь сад сияет. На стене магазина висят письма покупателей, а бабушкин дневник открыт для новых записей.\nДжек не ждёт окончательной награды: он открывает ворота на следующее утро. Здесь всегда найдётся место ещё для одного цветка и ещё одной истории.",
	"The whole garden glows. Customer letters hang on the shop wall, and Grandma's journal is open to new pages.\nJack does not wait for a final prize: he opens the gate again the next morning. There is always room for one more flower and one more story."]
]

var game: Control
var garden_ui: RefCounted
var bouquet_slots: Array=[]
var wrap_id:=0
var last_sale: Dictionary={}
var message: String=""

func _init(owner_ui: RefCounted) -> void:
	garden_ui=owner_ui
	game=owner_ui.game

func words(ru: String,en: String) -> String: return game.words(ru,en)
func english() -> bool: return game.store.data.settings.language=="en"
func g() -> Dictionary: return game.store.data.garden

func _screen(name_value: String,title: String) -> void:
	game.clear_page(name_value)
	game.header(title)
	var scroll:=ScrollContainer.new()
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	game.root_box.add_child(scroll)
	var body:=VBoxContainer.new()
	body.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	body.custom_minimum_size.x=maxf(0,game.size.x-48)
	body.add_theme_constant_override("separation",16)
	scroll.add_child(body)
	game.root_box=body

func _art(texture: Texture2D,height: int) -> void:
	var image:=TextureRect.new()
	image.texture=texture
	image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.custom_minimum_size.y=height
	image.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	image.mouse_filter=Control.MOUSE_FILTER_IGNORE
	game.root_box.add_child(image)

func _text(value: String,font_size: int=24) -> void:
	HUD.text(game.root_box,value,font_size,Color("fff7dc"))

func nursery() -> void:
	Farm.ensure(g())
	_screen("nursery",words("ОГОРОД ДЖЕКА","JACK'S NURSERY"))
	_art(NURSERY,250)
	_text(words("Здесь растут цветы для букетов. Сад вокруг остаётся местом для красоты и новых построек.","Grow flowers for bouquets here. The garden outside remains a place to decorate and restore."),23)
	if not g().farm.seen_guide:
		var guide:=HUD.card(game.root_box)
		HUD.text(guide,words("КАК УХАЖИВАТЬ","HOW TO GROW"),27)
		HUD.text(guide,words("1. Посади сорт в свободную клумбу.\n2. Любая победа, даже повторная, продвинет рост. Через три победы цветы готовы.\n3. Собери их и отнеси в магазин. Улучшение клумбы увеличивает урожай.","1. Plant a variety in a free bed.\n2. Any win, including a replay, grows it. Flowers are ready after three wins.\n3. Harvest and take them to the shop. Upgrades raise the yield."),22,HUD.SOFT)
		game.button(words("Понятно","Got it"),func(): if game.store.garden_transaction(func(data): data.farm.seen_guide=true; return true): nursery(),guide,true)
	_text(words("Корзина: %d цветков · Продано букетов: %d","Basket: %d stems · Bouquets sold: %d") % [_stock_total(),g().farm.orders_done],23)
	var grid:=GridContainer.new(); grid.columns=2; grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL; grid.custom_minimum_size.x=maxf(0,game.get_viewport_rect().size.x-64); grid.add_theme_constant_override("h_separation",12); grid.add_theme_constant_override("v_separation",12); game.root_box.add_child(grid)
	for id in Farm.SPECIES.size():
		var spec: Array=Farm.SPECIES[id]
		var card:=HUD.card(grid); card.get_parent().size_flags_horizontal=Control.SIZE_EXPAND_FILL
		var flower:=TextureRect.new(); flower.texture=Map.bed_texture(id); flower.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; flower.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED; flower.custom_minimum_size=Vector2(0,126); card.add_child(flower)
		HUD.text(card,spec[1 if english() else 0],22)
		var bed: Variant=g().farm.beds.get(str(id))
		if bed is Dictionary:
			var stage: int=int(bed.growth)
			var stage_ru: Array=["Семя", "Росток", "Бутон", "Цветёт"]
			var stage_en: Array=["Seed", "Sprout", "Bud", "Blooming"]
			HUD.text(card,words(stage_ru[stage],stage_en[stage])+" · %d/3" % stage,19,HUD.SOFT)
			var growth:=ProgressBar.new(); growth.max_value=3; growth.value=stage; growth.show_percentage=false; growth.custom_minimum_size.y=10
			growth.add_theme_stylebox_override("background",game.style(Color("d8e0c9"),Color("d8e0c9")))
			growth.add_theme_stylebox_override("fill",game.style(Color("70b962"),Color("70b962")))
			card.add_child(growth)
			HUD.text(card,words("За сбор: %d","Harvest: %d") % (int(bed.tier)+1+(1 if 0 in g().farm.buildings else 0)),18,HUD.SOFT)
			HUD.text(card,words("В корзине: %d","In basket: %d") % int(g().farm.stock[id]),19,HUD.SOFT)
			var harvest: Button=game.button(words("Собрать цветы","Harvest flowers"),harvest_bed.bind(id),card,int(bed.growth)>=3)
			harvest.disabled=int(bed.growth)<3
			if int(bed.tier)<3:
				var upgrade: Button=game.button(words("Улучшить · %d монет","Upgrade · %d coins") % (90*int(bed.tier)),upgrade_bed.bind(id),card)
				upgrade.disabled=int(g().coins)<90*int(bed.tier)
		else:
			HUD.text(card,words("Свободная клумба","Empty flowerbed"),19,HUD.SOFT)
			var plant: Button=game.button(words("Посадить · %d","Plant · %d") % int(spec[7]),plant_bed.bind(id),card,true)
			plant.disabled=g().earned.size()<int(spec[6]) or int(g().coins)<int(spec[7])
			if g().earned.size()<int(spec[6]): HUD.text(card,words("Откроется после %d побед","Unlocks after %d wins") % int(spec[6]),17,HUD.SOFT)
		HUD.text(card,words("Аромат %d · Стойкость %d · Урожай %d","Scent %d · Freshness %d · Yield %d") % [int(spec[3]),int(spec[4]),int(spec[5])],17,HUD.SOFT)
	if not message.is_empty(): _text(message,21)
	game.button(words("В цветочный магазин","Visit the flower shop"),shop,null,true)
	game.button(words("Вернуться в сад","Back to the garden"),garden_ui.open_garden)

func _stock_total() -> int:
	var total:=0
	for amount in g().farm.stock: total+=int(amount)
	return total

func plant_bed(id: int) -> void:
	message=words("Новый сорт посажен!","A new variety is planted!") if game.store.garden_transaction(func(data): return Farm.plant(data,id,id)) else words("Пока не хватает монет или побед.","More coins or wins are needed.")
	nursery()

func upgrade_bed(id: int) -> void:
	message=words("Клумба стала урожайнее.","The bed will yield more flowers.") if game.store.garden_transaction(func(data): return Farm.upgrade(data,id)) else words("Улучшение пока недоступно.","Upgrade is not available yet.")
	nursery()

func harvest_bed(id: int) -> void:
	message=words("Цветы собраны. Загляни в магазин!","Flowers harvested. Visit the shop!") if game.store.garden_transaction(func(data): return Farm.harvest(data,id)>0) else words("Цветы ещё растут.","These flowers are still growing.")
	if game.sound != null: game.sound.play_match("win")
	nursery()

func shop() -> void:
	Farm.ensure(g())
	_screen("business_shop",words("ЦВЕТОЧНЫЙ МАГАЗИН","FLOWER SHOP"))
	_art(Map.decor_texture(6) if int(g().farm.shop_tier)==0 else SHOP,240)
	_text(words("Витрина Джека · этап %d/5 · репутация %d","Jack's display · stage %d/5 · reputation %d") % [int(g().farm.shop_tier),int(g().farm.reputation)],24)
	if 3 not in g().repairs: _text(words("Пока работаем из лавки. Восстанови её в саду, чтобы строить магазин.","For now we work from the stall. Restore it in the garden to build the shop."),21)
	var order: Array=Farm.order(g())
	var panel:=HUD.card(game.root_box)
	HUD.text(panel,words("ПОКУПАТЕЛЬ","CUSTOMER"),19,HUD.SOFT)
	HUD.text(panel,order[1 if english() else 0],29)
	HUD.text(panel,order[4 if english() else 3],21,HUD.SOFT)
	HUD.text(panel,words("Коснись цветков и составь букет. Покупатель ценит: ","Tap flowers to arrange a bouquet. This customer values: ")+words(["аромат","стойкость","пышность"][int(order[2])],["scent","freshness","fullness"][int(order[2])]),20,HUD.SOFT)
	var preview_art:=Bouquet.new(); preview_art.flowers=bouquet_slots.duplicate(); preview_art.wrap_id=wrap_id; preview_art.custom_minimum_size.y=230; preview_art.mouse_filter=Control.MOUSE_FILTER_IGNORE; panel.add_child(preview_art)
	var slots:=HBoxContainer.new(); slots.add_theme_constant_override("separation",8); panel.add_child(slots)
	for position in 3:
		var occupied: bool=position<bouquet_slots.size()
		var slot_button: Button=game.button(words("Убрать %d","Remove %d") % (position+1) if occupied else words("Место %d","Slot %d") % (position+1),remove_slot.bind(position),slots)
		slot_button.custom_minimum_size.y=48; slot_button.add_theme_font_size_override("font_size",17); slot_button.disabled=not occupied
	HUD.text(panel,words("ЦВЕТЫ В КОРЗИНЕ","FLOWERS IN YOUR BASKET"),18,HUD.SOFT)
	var choices:=GridContainer.new(); choices.columns=2; panel.add_child(choices)
	for id in Farm.SPECIES.size():
		if not g().farm.beds.has(str(id)) and int(g().farm.stock[id])<=0: continue
		var names_ru: Array=["Космеи","Ромашки","Анемоны","Незабудки","Георгины","Хризантемы"]
		var names_en: Array=["Cosmos","Daisies","Anemones","Forget-me-nots","Dahlias","Chrysanthemums"]
		var pick_button: Button=game.button(words(names_ru[id],names_en[id])+" · "+str(int(g().farm.stock[id])-bouquet_slots.count(id)),add_flower.bind(id),choices)
		pick_button.icon=Art.icon(id); pick_button.expand_icon=true; pick_button.add_theme_constant_override("icon_max_width",48); pick_button.custom_minimum_size.y=74; pick_button.add_theme_font_size_override("font_size",18)
		pick_button.disabled=bouquet_slots.size()>=3 or bouquet_slots.count(id)>=int(g().farm.stock[id])
	HUD.text(panel,words("БУМАГА ДЛЯ БУКЕТА","BOUQUET WRAP"),18,HUD.SOFT)
	var wraps:=HBoxContainer.new(); wraps.add_theme_constant_override("separation",8); panel.add_child(wraps)
	for id in 3:
		var wrap_button: Button=game.button(words(["Крафт","Мята","Лаванда"][id],["Kraft","Mint","Lavender"][id])+(" ✓" if wrap_id==id else ""),choose_wrap.bind(id),wraps)
		wrap_button.custom_minimum_size.y=54; wrap_button.add_theme_font_size_override("font_size",18)
	var preview: Dictionary=Farm.bouquet(g(),_picked_counts())
	if preview.get("valid",false):
		HUD.text(panel,words("Букет: %d монет · репутация +%d","Bouquet: %d coins · reputation +%d") % [int(preview.coins),int(preview.reputation)],23)
	else: HUD.text(panel,words("Собери хотя бы один цветок в огороде.","Harvest at least one flower in the nursery."),21,HUD.SOFT)
	var sell_button: Button=game.button(words("Продать букет","Sell bouquet"),sell_bouquet,panel,true)
	sell_button.disabled=not preview.get("valid",false)
	var tier: int=int(g().farm.shop_tier)
	if tier<Farm.SHOP_PRICES.size():
		var next:=HUD.card(game.root_box)
		HUD.text(next,words("СЛЕДУЮЩЕЕ УЛУЧШЕНИЕ","NEXT SHOP UPGRADE"),19,HUD.SOFT)
		HUD.text(next,words(["Открыть магазин","Расширить витрину","Праздничная вывеска","Мастерская открыток","Городская доставка"][tier],["Open the shop","Expand the display","Festival storefront","Card studio","Town deliveries"][tier]),27)
		if tier>=3: HUD.text(next,words("Каждый следующий букет принесёт ещё +8 монет.","Each later bouquet earns another 8 coins."),19,HUD.SOFT)
		HUD.text(next,words("Букеты: %d/%d · цена: %d монет","Bouquets: %d/%d · price: %d coins") % [mini(int(g().farm.orders_done),Farm.SHOP_ORDERS[tier]),Farm.SHOP_ORDERS[tier],Farm.SHOP_PRICES[tier]],20,HUD.SOFT)
		var build: Button=game.button(words("Улучшить магазин","Upgrade the shop"),build_shop,next,true)
		build.disabled=not Farm.shop_ready(g())
	else: _text(words("Магазин сияет! Заказы и сорта продолжают расти вместе с ним.","The shop shines! Orders and varieties can keep growing."),22)
	var buildings:=HUD.card(game.root_box)
	HUD.text(buildings,words("НОВЫЕ МЕСТА В САДУ","NEW PLACES IN THE GARDEN"),20,HUD.SOFT)
	for id in Farm.BUILDINGS.size():
		var item: Array=Farm.BUILDINGS[id]
		HUD.text(buildings,words(item[0],item[1]),24)
		HUD.text(buildings,words("+1 цветок при каждом сборе" if id==0 else "+5 монет за каждый букет","+1 stem from every harvest" if id==0 else "+5 coins for every bouquet"),18,HUD.SOFT)
		if id in g().farm.buildings:
			HUD.text(buildings,words("Построено — найди на карте сада","Built — find it on the garden map"),19,HUD.SOFT)
		else:
			HUD.text(buildings,words("После ремонта: %s · %d монет","After restoring: %s · %d coins") % [words(Rules.REPAIRS[int(item[3])][0],Rules.REPAIRS[int(item[3])][1]),int(item[2])],18,HUD.SOFT)
			var button: Button=game.button(words("Построить","Build"),build_garden.bind(id),buildings)
			button.disabled=not Farm.building_ready(g(),id)
	if not message.is_empty(): _text(message,21)
	game.button(words("К сюжетным главам","Story chapters"),story)
	game.button(words("Альбом букетов","Bouquet album"),album)
	game.button(words("В огород","To the nursery"),nursery)
	game.button(words("В сад","Back to the garden"),garden_ui.open_garden)

func _picked_total() -> int:
	return bouquet_slots.size()

func _picked_counts() -> Array:
	var counts: Array=[0,0,0,0,0,0]
	for id in bouquet_slots: counts[int(id)]+=1
	return counts

func change_pick(id: int,delta: int) -> void:
	if delta>0: add_flower(id)
	elif delta<0:
		var at: int=bouquet_slots.find(id)
		if at>=0: remove_slot(at)

func add_flower(id: int) -> void:
	if id<0 or id>=Farm.SPECIES.size() or bouquet_slots.size()>=3 or bouquet_slots.count(id)>=int(g().farm.stock[id]): return
	bouquet_slots.append(id)
	if game.sound!=null: game.sound.chime()
	shop()

func remove_slot(position: int) -> void:
	if position<0 or position>=bouquet_slots.size(): return
	bouquet_slots.remove_at(position)
	shop()

func choose_wrap(id: int) -> void:
	if id<0 or id>2: return
	wrap_id=id
	shop()

func sell_bouquet() -> void:
	if game.store.garden_transaction(func(data): return Farm.sell(data,_picked_counts(),bouquet_slots,wrap_id)):
		last_sale=g().farm.album.back().duplicate(true)
		bouquet_slots.clear()
		if game.sound!=null: game.sound.play_match("win")
		sale_result()
	else:
		message=words("Цветов в корзине не хватило. Проверь букет.","Check your basket before selling.")
		shop()

func sale_result() -> void:
	if last_sale.is_empty(): shop(); return
	_screen("bouquet_result",words("БУКЕТ ГОТОВ","BOUQUET COMPLETE"))
	var visual:=Bouquet.new(); visual.flowers=last_sale.flowers; visual.wrap_id=int(last_sale.wrap); visual.custom_minimum_size.y=330; game.root_box.add_child(visual)
	var customer: Array=Farm.CUSTOMERS[int(last_sale.customer)]
	_text(words("Букет для ","Bouquet for ")+words(customer[0],customer[1]),27)
	_text(words("Покупатель доволен. Этот букет останется в альбоме.","The customer is delighted. This bouquet will stay in your album."),22)
	_text(words("+%d монет · репутация растёт","+%d coins · your reputation grows") % int(last_sale.coins),24)
	game.button(words("Следующий заказ","Next order"),shop,null,true)
	game.button(words("Мой альбом","My album"),album)

func album() -> void:
	_screen("bouquet_album",words("АЛЬБОМ БУКЕТОВ","BOUQUET ALBUM"))
	_text(words("Здесь живут двенадцать последних букетов и истории их покупателей.","Your twelve latest bouquets and the people who received them live here."),22)
	if g().farm.album.is_empty(): _text(words("Первый букет ещё впереди.","Your first bouquet is still ahead."),23)
	for index in range(g().farm.album.size()-1,-1,-1):
		var entry: Dictionary=g().farm.album[index]
		var card:=HUD.card(game.root_box)
		var visual:=Bouquet.new(); visual.flowers=entry.flowers; visual.wrap_id=int(entry.wrap); visual.custom_minimum_size.y=190; card.add_child(visual)
		var customer: Array=Farm.CUSTOMERS[int(entry.customer)]
		HUD.text(card,words(customer[0],customer[1]),22)
	game.button(words("К заказам","To orders"),shop,null,true)

func build_shop() -> void:
	message=words("Новая часть магазина открыта!","A new part of the shop is open!") if game.store.garden_transaction(func(data): return Farm.build_shop(data)) else words("Пока нужно больше букетов или монет.","More bouquets or coins are needed.")
	shop()

func build_garden(id: int) -> void:
	message=words("Новая постройка появилась в саду!","A new building has appeared in the garden!") if game.store.garden_transaction(func(data): return Farm.build_garden(data,id)) else words("Сначала восстанови сад и накопи монеты.","Restore the garden and save more coins first.")
	shop()

func story() -> void:
	Farm.ensure(g())
	_screen("lily_story",words("ДЖЕК И ЛИЛИЯ","JACK AND LILY"))
	_art(LILY,280)
	_text(words("Лилия вернулась, когда Джек только начал восстанавливать сад. Дальнейшие главы открываются вместе с садом, огородом и магазином.","Lily returned as Jack began restoring the garden. New chapters open as the garden, nursery and shop grow."),23)
	for id in SCENES.size():
		if id > g().farm.story_seen.size(): break
		var card:=HUD.card(game.root_box)
		HUD.text(card,SCENES[id][1 if english() else 0],25)
		var seen: bool=id in g().farm.story_seen
		if seen or Farm.story_ready(g(),id):
			game.button(words("Вспомнить сцену","Replay scene") if seen else words("Смотреть новую сцену","Watch new scene"),scene.bind(id),card,not seen)
		else:
			HUD.text(card,_requirement(id),19,HUD.SOFT)
	game.button(words("В магазин","To the shop"),shop)
	game.button(words("В сад","Back to the garden"),garden_ui.open_garden)

func _requirement(id: int) -> String:
	match id:
		0: return words("Пройди 3 уровня или восстанови вход.","Complete 3 levels or restore the gate.")
		1: return words("Восстанови теплицу.","Restore the greenhouse.")
		2: return words("Открой лавку и продай 2 букета.","Open the stall and sell 2 bouquets.")
		3: return words("Открой настоящий магазин.","Open the real flower shop.")
		4: return words("Расширь витрину магазина.","Expand the shop display.")
		5: return words("Заверши праздничное оформление магазина.","Complete the festival storefront.")
		_: return words("Пройди %d уровней в любых режимах.","Complete %d levels in either mode.") % [50,100,150,200,300,500][id-6]

func scene(id: int) -> void:
	if id<0 or id>=SCENES.size() or (id not in g().farm.story_seen and not Farm.story_ready(g(),id)): return
	_screen("lily_scene",SCENES[id][1 if english() else 0])
	_art(LILY if id in [0,2,4,5,8,10] else JACK if id in [1,3,6,7] else NURSERY,360)
	_text(SCENES[id][3 if english() else 2],27)
	if id==5 and id not in g().farm.story_seen:
		_text(words("Что ответит Джек?","What will Jack say?"),25)
		for choice in [["distance",words("Мне нужно идти своим путём","I need my own path")],["friends",words("Начнём с дружбы","Let's begin as friends")],["perhaps",words("Доверие придётся вернуть","Trust takes time")]]:
			game.button(choice[1],answer_lily.bind(id,choice[0]))
	else:
		game.button(words("Продолжить","Continue"),func():
			if id not in g().farm.story_seen:
				if not game.store.garden_transaction(func(data): return Farm.claim_story(data,id)):
					return
			story(),null,true)
	game.button(words("Позже","Later"),story)

func answer_lily(id: int,answer: String) -> void:
	if game.store.garden_transaction(func(data):
		if not Farm.claim_story(data,id): return false
		data.farm.lily_answer=answer
		return true): story()
