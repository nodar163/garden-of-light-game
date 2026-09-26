extends RefCounted
## Nursery, working flower shop and the new story; uses the existing screen shell.
const Farm=preload("res://scripts/garden_farm.gd")
const Rules=preload("res://scripts/garden_rules.gd")
const Map=preload("res://scripts/garden_map.gd")
const HUD=preload("res://scripts/garden_hud.gd")
const NURSERY=preload("res://assets/flower-nursery.png")
const SHOP=preload("res://assets/jack-shop.png")
const LILY=preload("res://assets/lily.png")
const JACK=preload("res://assets/jack.png")

const SCENES=[
	["Незваная гостья","An unexpected visitor",
	"Лилия: «Красиво, Джек. Но красотой за аренду не заплатишь». Она ушла, когда у Джека не осталось денег, а теперь открывает филиал большой цветочной сети.\nДжек: «Тогда посмотри, что я здесь построю». Он ещё не знает, что делает это не только ради неё.",
	"Lily: ‘Lovely, Jack. But beauty won't pay the rent.’ She left when Jack lost his money; now she is opening a branch of a flower chain.\nJack: ‘Then watch what I build here.’ He does not yet know he is doing it for more than her."],
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
	"The garden glows and new customers wait in the shop. Lily asks Jack to start over.\nJack: ‘I'm glad you came back and told the truth. But I didn't build this shop and garden to earn your approval.’ What comes next is his choice — and the player's."]
]

var game: Control
var garden_ui: RefCounted
var picked: Array=[0,0,0,0,0,0]
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
	_text(words("Витрина Джека · этап %d/3 · репутация %d","Jack's display · stage %d/3 · reputation %d") % [int(g().farm.shop_tier),int(g().farm.reputation)],24)
	if 3 not in g().repairs: _text(words("Пока работаем из лавки. Восстанови её в саду, чтобы строить магазин.","For now we work from the stall. Restore it in the garden to build the shop."),21)
	var order: Array=Farm.order(g())
	var panel:=HUD.card(game.root_box)
	HUD.text(panel,words("ПОКУПАТЕЛЬ","CUSTOMER"),19,HUD.SOFT)
	HUD.text(panel,order[1 if english() else 0],29)
	HUD.text(panel,order[4 if english() else 3],21,HUD.SOFT)
	HUD.text(panel,words("Выбери до 3 цветов из корзины. Покупатель ценит: ","Choose up to 3 stems. This customer values: ")+words(["аромат","стойкость","пышность"][int(order[2])],["scent","freshness","fullness"][int(order[2])]),20,HUD.SOFT)
	for id in Farm.SPECIES.size():
		if not g().farm.beds.has(str(id)) and int(g().farm.stock[id])<=0: continue
		var row:=HBoxContainer.new(); row.add_theme_constant_override("separation",10); panel.add_child(row)
		var flower:=TextureRect.new(); flower.texture=Map.bed_texture(id); flower.custom_minimum_size=Vector2(52,60); flower.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; flower.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED; row.add_child(flower)
		var name:=HUD.text(row,words(Farm.SPECIES[id][0],Farm.SPECIES[id][1])+"\n"+words("В корзине: %d","In basket: %d") % int(g().farm.stock[id]),17); name.size_flags_horizontal=Control.SIZE_EXPAND_FILL; name.custom_minimum_size.x=94
		var minus: Button=game.button("−",change_pick.bind(id,-1),row); minus.custom_minimum_size=Vector2(44,56); minus.size_flags_horizontal=Control.SIZE_SHRINK_END; minus.disabled=int(picked[id])<=0
		var count_label:=HUD.text(row,str(picked[id]),20); count_label.custom_minimum_size.x=18
		var plus: Button=game.button("+",change_pick.bind(id,1),row); plus.custom_minimum_size=Vector2(44,56); plus.size_flags_horizontal=Control.SIZE_SHRINK_END; plus.disabled=int(picked[id])>=int(g().farm.stock[id]) or _picked_total()>=3
	var preview: Dictionary=Farm.bouquet(g(),picked)
	if preview.get("valid",false):
		HUD.text(panel,words("Букет: %d монет · репутация +%d","Bouquet: %d coins · reputation +%d") % [int(preview.coins),int(preview.reputation)],23)
	else: HUD.text(panel,words("Собери хотя бы один цветок в огороде.","Harvest at least one flower in the nursery."),21,HUD.SOFT)
	var sell_button: Button=game.button(words("Продать букет","Sell bouquet"),sell_bouquet,panel,true)
	sell_button.disabled=not preview.get("valid",false)
	var tier: int=int(g().farm.shop_tier)
	if tier<3:
		var next:=HUD.card(game.root_box)
		HUD.text(next,words("СЛЕДУЮЩЕЕ УЛУЧШЕНИЕ","NEXT SHOP UPGRADE"),19,HUD.SOFT)
		HUD.text(next,words(["Открыть магазин","Расширить витрину","Праздничная вывеска"][tier],["Open the shop","Expand the display","Festival storefront"][tier]),27)
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
	game.button(words("В огород","To the nursery"),nursery)
	game.button(words("В сад","Back to the garden"),garden_ui.open_garden)

func _picked_total() -> int:
	var count:=0
	for amount in picked: count+=int(amount)
	return count

func change_pick(id: int,delta: int) -> void:
	picked[id]=clampi(int(picked[id])+delta,0,int(g().farm.stock[id]))
	shop()

func sell_bouquet() -> void:
	if game.store.garden_transaction(func(data): return Farm.sell(data,picked)):
		picked=[0,0,0,0,0,0]
		message=words("Покупатель доволен! Магазин становится известнее.","A happy customer! The shop is becoming known.")
		game.sound.play_match("win")
	else: message=words("Цветов в корзине не хватило. Проверь букет.","Check your basket before selling.")
	shop()

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
	_text(words("Когда сад начал оживать, вернулась Лилия. Джек строит своё дело — и постепенно понимает, ради кого он старается.","Lily returned as the garden came back to life. Jack builds his business and learns who he is really doing it for."),23)
	for id in SCENES.size():
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
		0: return words("Восстанови вход и фонтан в саду.","Restore the gate and fountain.")
		1: return words("Восстанови теплицу.","Restore the greenhouse.")
		2: return words("Открой лавку и продай 2 букета.","Open the stall and sell 2 bouquets.")
		3: return words("Открой настоящий магазин.","Open the real flower shop.")
		4: return words("Расширь витрину магазина.","Expand the shop display.")
		_: return words("Заверши праздничное оформление магазина.","Complete the festival storefront.")

func scene(id: int) -> void:
	if id<0 or id>=SCENES.size() or (id not in g().farm.story_seen and not Farm.story_ready(g(),id)): return
	_screen("lily_scene",SCENES[id][1 if english() else 0])
	_art(LILY if id in [0,2,4,5] else JACK,360)
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
