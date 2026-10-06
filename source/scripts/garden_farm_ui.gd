extends RefCounted
## Nursery, working flower shop and the new story; uses the existing screen shell.
const Farm=preload("res://scripts/garden_farm.gd")
const Rules=preload("res://scripts/garden_rules.gd")
const HUD=preload("res://scripts/garden_hud.gd")
const Bouquet=preload("res://scripts/bouquet_view.gd")

const SCENES=[
	["Незваная гостья","An unexpected visitor",
	"У повреждённых ворот появляется Лилия. Она ушла, когда Джек потерял деньги, а теперь открывает филиал большой цветочной сети.\nЛилия: «Ты правда решил всё восстановить?»\nДжек: «Начну с этих трёх цветков. Остальное увидишь позже». Он ещё не знает, что делает это не только ради неё.",
	"Lily stops by the damaged gate. She left when Jack lost his money and now runs a branch of a flower chain.\nLily: ‘Are you really rebuilding all this?’\nJack: ‘I'll start with these three flowers. You'll see the rest later.’ He does not yet know he is doing this for more than her."],
	["Бабушкин дневник","Grandma's journal",
	"За старой дверью теплицы Джек находит записи бабушки. Рядом с каждым сортом — имя человека, которому он однажды принёс радость.\n«Лилия продавала цветы быстрее всех, — думает Джек, — но я научусь слышать тех, кто их покупает». Теперь каждый выращенный цветок может стать частью нового букета.",
	"Behind the greenhouse door, Jack finds Grandma's notes. Beside each variety is the name of someone it once made happy.\n‘Lily could sell flowers faster than anyone,’ he thinks, ‘but I will learn to listen to the people buying them.’ Every grown flower can become part of a new bouquet."],
	["Очередь у лавки","A line at the stall",
	"Анна просит цветы для мамы. Марк ищет букет для читального зала. У лавки Джека впервые после бури образуется очередь.\nЛилия: «Пара соседей — ещё не бизнес». Джек улыбается: «Для начала мне хватит пары счастливых соседей». Старые знакомые возвращаются уже с друзьями.",
	"Anna needs flowers for Mum. Mark wants a bouquet for the reading room. For the first time since the storm, a line forms at Jack's stall.\nLily: ‘A few neighbours are hardly a business.’ Jack smiles: ‘A few happy neighbours are a good start.’ They return with their friends."],
	["Магазин на углу","The corner flower shop",
	"В уже открытой лавке Джек оборудует собственную мастерскую. Доход от первых букетов помог купить всё необходимое.\nЛилия видит новую вывеску и впервые не находит колкости. Она замечает букет по рецепту бабушки: такой нельзя заказать в её сети.",
	"Jack equips his own workshop inside the open shop. Income from the first bouquets paid for everything he needed.\nLily sees the new sign and, for once, has no sharp reply. She notices a bouquet from Grandma's notes: her chain cannot make anything like it."],
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
	"The whole garden glows. Customer letters hang on the shop wall, and Grandma's journal is open to new pages.\nJack does not wait for a final prize: he opens the gate again the next morning. There is always room for one more flower and one more story."],
	["Семена в конверте", "Seeds in an envelope", "В бабушкином дневнике Джек находит конверт без названия сорта. Анна узнаёт почерк своего отца: он обменивался семенами с бабушкой. Джек оставляет лучшие цветы для соседей, а не для дорогой витрины.\nЛилия спрашивает: «Почему не поднять цену?» — «Сначала хочу узнать, что мы вырастили», — отвечает он.", "Jack finds an unnamed seed envelope in Grandma’s journal. Anna recognizes her father’s handwriting: he traded seeds with Grandma. Jack saves the best flowers for neighbours rather than an expensive display.\nLily asks why he will not raise the price. “First I want to know what we have grown,” he says."],
	["Букет без повода", "A bouquet for no occasion", "Марк заходит без заказа: библиотеку закрыли на ремонт, и он не знает, куда нести цветы. Джек предлагает поставить букет на столе у рабочих. На следующий день один из них возвращается за подарком жене.\nДжек записывает в дневник: «Иногда повод появляется после букета».", "Mark arrives without an order: the library is closed for repairs. Jack suggests leaving flowers on the workers’ table. The next day, one of them returns for a gift for his wife.\nJack writes: “Sometimes the occasion comes after the bouquet.”"],
	["Пустая витрина", "An empty display", "После удачного дня витрина опустела. Джек хочет немедленно засадить все грядки самым дорогим сортом. Лилия замечает, что покупатели просили разные букеты.\nОни перечитывают записи: одним важен аромат, другим стойкость. Джек решает выращивать несколько сортов и собирать букеты под человека.", "After a busy day, the display is empty. Jack wants to plant only the most expensive variety. Lily reminds him that customers asked for different bouquets.\nThey review their notes: some value fragrance, others freshness. Jack decides to grow a mix and make bouquets for the person."],
	["Свет в окнах", "Light in the windows", "В половине восстановленного сада Джек устраивает маленькую прогулку. Соседи узнают цветы, которые когда-то покупали у его бабушки. Лилия впервые приходит без делового предложения и просто помогает расставлять букеты.\nДжек понимает: сад уже стал местом, куда возвращаются.", "Halfway through the garden’s journey, Jack invites neighbours for a walk. They recognize flowers they once bought from Grandma. Lily comes without a business proposal and helps arrange bouquets.\nJack realizes the garden has become a place people return to."],
	["Не самый большой магазин", "Not the biggest shop", "Джеку предлагают превратить лавку в безликую торговую точку: больше одинаковых букетов, меньше времени на покупателей. Он смотрит на письма рядом с кассой и отказывается.\n«Я хочу хороший магазин, а не самый большой», — говорит Джек. Лилия не спорит. Она уже знает цену этому выбору.", "Jack is offered a deal: more identical bouquets and less time with customers. He looks at the letters beside the register and declines.\n“I want a good shop, not the biggest one,” he says. Lily does not argue. She understands the cost of that choice."],
	["Последняя страница", "The last page", "На последней странице дневника осталось пустое место. Джек вклеивает фотографию сада и оставляет рядом место для следующей. Работа почти закончена, но жизнь сада только начинается.\nСоседи готовят вечер открытия. Джек просит принести не подарки, а истории: кому помог самый первый букет?", "The journal’s last page has an empty space. Jack adds a garden photograph and leaves room for another. Restoration is almost finished, but the garden’s life is only beginning.\nNeighbours prepare an opening evening. Jack asks for stories, not gifts: who did the very first bouquet help?"]
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
	Farm.ensure(g())
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

func _art(kind: String,height: int,variant: int=0) -> void:
	var image=preload("res://scripts/illustrated_preview.gd").new(); image.kind=kind; image.variant=variant
	image.custom_minimum_size.y=height; image.size_flags_horizontal=Control.SIZE_EXPAND_FILL; game.root_box.add_child(image)

func _text(value: String,font_size: int=24) -> void:
	HUD.text(game.root_box,value,font_size,Color("fff7dc"))

func nursery() -> void:
	place("nursery")

func place(kind: String) -> void:
	Farm.ensure(g())
	if not Farm.can_enter(g(),kind):
		garden_ui.select_place("repair",2 if kind=="nursery" else 3)
		return
	game.clear_page("nursery" if kind=="nursery" else "business_shop")
	var top:=HBoxContainer.new(); game.root_box.add_child(top)
	var back: Button=game.button(words("‹ Сад","‹ Garden"),garden_ui.open_garden,top)
	back.custom_minimum_size=Vector2(108,62); back.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN; back.size_flags_vertical=Control.SIZE_SHRINK_BEGIN; back.add_theme_font_size_override("font_size",23)
	var heading: Label=HUD.text(top,words("ОГОРОД","NURSERY") if kind=="nursery" else words("МАГАЗИН","SHOP"),28,Color("fff5d5"))
	heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL; heading.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	var money: Label=HUD.text(top,str(int(g().coins)),23,Color("ffdf8f")); money.vertical_alignment=VERTICAL_ALIGNMENT_CENTER; money.autowrap_mode=TextServer.AUTOWRAP_OFF
	var map=preload("res://scripts/farm_world.gd").new(); map.game=game; map.mode=kind
	map.size_flags_vertical=Control.SIZE_EXPAND_FILL; map.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var help:=HUD.card(game.root_box)
	var tip: Label=HUD.text(help,"",22)
	map.guidance_changed.connect(func(value): tip.text=value; money.text=str(int(g().coins)))
	game.root_box.add_child(map); game.root_box.move_child(map,1)
	var options:=HBoxContainer.new(); help.add_child(options)
	if kind=="nursery":
		var improve: Button=game.button(words("Выбери грядку","Select a bed"),func():
			if map.selected_bed>=0 and game.store.garden_transaction(func(data): return Farm.upgrade(data,map.selected_bed)):
				map.message=words("Грядка улучшена: урожай стал больше.","Bed upgraded: a bigger harvest."); map.refresh()
		,options)
		improve.add_theme_font_size_override("font_size",20); improve.custom_minimum_size.y=56; improve.disabled=true
		map.bed_selected.connect(func(id):
			var bed: Variant=g().farm.beds.get(str(id))
			improve.disabled=not bed is Dictionary or int(bed.tier)>=3 or int(g().coins)<90*int(bed.tier)
			improve.text=words("Улучшить · %d монет","Upgrade · %d coins") % (90*int(bed.tier)) if bed is Dictionary and int(bed.tier)<3 else words("Улучшено","Fully upgraded") if bed is Dictionary else words("Свободная грядка","Empty bed")
		)
	else:
		var improve: Button=game.button(words("Развитие","Upgrades"),upgrades,options); improve.add_theme_font_size_override("font_size",20); improve.custom_minimum_size.y=56
		var memories: Button=game.button(words("Альбом","Album"),album,options); memories.add_theme_font_size_override("font_size",20); memories.custom_minimum_size.y=56
	var play: Button=game.button(words("К уровням","Play levels"),garden_ui.modes,options,true); play.add_theme_font_size_override("font_size",20); play.custom_minimum_size.y=56
	game.tutorial.maybe_open(kind)

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
	place("shop")

func upgrades() -> void:
	_screen("business_upgrades",words("РАЗВИТИЕ МАГАЗИНА","SHOP UPGRADES"))
	_text(words("Этап %d/5 · Продано %d букетов","Stage %d/5 · %d bouquets sold") % [int(g().farm.shop_tier),int(g().farm.orders_done)],26)
	var tier: int=int(g().farm.shop_tier)
	if tier<Farm.SHOP_PRICES.size():
		var next:=HUD.card(game.root_box)
		HUD.text(next,words(["Оборудовать мастерскую","Расширить витрину","Праздничная вывеска","Мастерская открыток","Городская доставка"][tier],["Equip the workshop","Expand the display","Festival storefront","Card studio","Town deliveries"][tier]),27)
		HUD.text(next,words("Букеты %d/%d · %d монет","Bouquets %d/%d · %d coins") % [int(g().farm.orders_done),Farm.SHOP_ORDERS[tier],Farm.SHOP_PRICES[tier]],22)
		if tier>=3: HUD.text(next,words("+8 монет за каждый следующий букет","+8 coins for each later bouquet"),21)
		else: HUD.text(next,words("+4 монеты за каждый следующий букет","+4 coins for each later bouquet"),21)
		var buy: Button=game.button(words("Улучшить","Upgrade"),func():
			if game.store.garden_transaction(func(data): return Farm.build_shop(data)): upgrades()
		,next,true); buy.disabled=not Farm.shop_ready(g())
	for id in Farm.BUILDINGS.size():
		var panel:=HUD.card(game.root_box)
		HUD.text(panel,words(Farm.BUILDINGS[id][0],Farm.BUILDINGS[id][1]),26)
		HUD.text(panel,words("+1 цветок при сборе" if id==0 else "+5 монет за букет","+1 stem per harvest" if id==0 else "+5 coins per bouquet"),22)
		var buy: Button=game.button(words("Построено","Built") if id in g().farm.buildings else words("Построить · %d монет","Build · %d coins") % Farm.BUILDINGS[id][2],func():
			if game.store.garden_transaction(func(data): return Farm.build_garden(data,id)): upgrades()
		,panel); buy.disabled=not Farm.building_ready(g(),id)
	game.button(words("К букетному столу","Back to the bouquet table"),shop)
	game.tutorial.maybe_open("upgrades")

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
	if not game.store.garden_transaction(func(data): return Farm.arrange(data,id)): return
	bouquet_slots=g().farm.draft.flowers.duplicate()
	if game.sound!=null: game.sound.chime()
	shop()

func remove_slot(position: int) -> void:
	if not game.store.garden_transaction(func(data): return Farm.return_flower(data,position)): return
	bouquet_slots=g().farm.draft.flowers.duplicate()
	shop()

func choose_wrap(id: int) -> void:
	if not game.store.garden_transaction(func(data): return Farm.wrap_bouquet(data,id)): return
	wrap_id=id
	shop()

func sell_bouquet() -> void:
	if game.store.garden_transaction(func(data): return Farm.serve(data)):
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
	game.tutorial.maybe_open("album")

func build_shop() -> void:
	message=words("Новая часть магазина открыта!","A new part of the shop is open!") if game.store.garden_transaction(func(data): return Farm.build_shop(data)) else words("Пока нужно больше букетов или монет.","More bouquets or coins are needed.")
	shop()

func build_garden(id: int) -> void:
	message=words("Новая постройка появилась в саду!","A new building has appeared in the garden!") if game.store.garden_transaction(func(data): return Farm.build_garden(data,id)) else words("Сначала восстанови сад и накопи монеты.","Restore the garden and save more coins first.")
	shop()

func story() -> void:
	Farm.ensure(g())
	_screen("lily_story",words("ДЖЕК И ЛИЛИЯ","JACK AND LILY"))
	_art("person",280,4)
	_text(words("Лилия вернулась, когда Джек только начал восстанавливать сад. Дальнейшие главы открываются вместе с садом, огородом и магазином.","Lily returned as Jack began restoring the garden. New chapters open as the garden, nursery and shop grow."),23)
	for id in Farm.CHAPTER_ORDER:
		if id not in g().farm.story_seen and id!=Farm.next_story(g()): continue
		var card:=HUD.card(game.root_box)
		HUD.text(card,SCENES[id][1 if english() else 0],25)
		var seen: bool=id in g().farm.story_seen
		if seen or Farm.story_ready(g(),id):
			game.button(words("Вспомнить сцену","Replay scene") if seen else words("Смотреть новую сцену","Watch new scene"),scene.bind(id),card,not seen)
		else:
			HUD.text(card,_requirement(id),19,HUD.SOFT)
	game.button(words("Найти магазин в саду","Find the shop in the garden"),func():
		garden_ui.open_garden(); garden_ui.map_view.focus_place("repair",3))
	game.button(words("В сад","Back to the garden"),garden_ui.open_garden)
	game.tutorial.maybe_open("story")

func _requirement(id: int) -> String:
	match id:
		0: return words("Пройди 3 уровня или восстанови вход.","Complete 3 levels or restore the gate.")
		1: return words("Восстанови теплицу.","Restore the greenhouse.")
		2: return words("Открой лавку и продай 2 букета.","Open the stall and sell 2 bouquets.")
		3: return words("Купи первое улучшение «Оборудовать мастерскую» в магазине.","Buy the first shop upgrade: Equip the workshop.")
		4: return words("Расширь витрину магазина.","Expand the shop display.")
		5: return words("Заверши праздничное оформление магазина.","Complete the festival storefront.")
		_: return words("Пройди %d уровней в любых режимах.","Complete %d levels in either mode.") % ([50,100,150,200,300,500][id-6] if id<12 else [75,125,175,250,375,450][id-12])

func scene(id: int) -> void:
	if id<0 or id>=SCENES.size() or (id not in g().farm.story_seen and not Farm.story_ready(g(),id)): return
	_screen("lily_scene",SCENES[id][1 if english() else 0])
	_art("person",360,4 if id in [0,2,4,5,8,10] else 0)
	_text(SCENES[id][3 if english() else 2],27)
	if id in [10,11,16,17] and not g().farm.lily_answer.is_empty():
		var ending: Dictionary={"distance":words("Джек сохраняет выбранную дистанцию. Лилия уважает его решение; сад остаётся его собственным делом.","Jack keeps the distance he chose. Lily respects his decision; the garden remains his own work."),"friends":words("Джек и Лилия начинают с дружбы: помогают друг другу, не торопя события.","Jack and Lily begin with friendship, helping each other without rushing."),"perhaps":words("Джек замечает, как Лилия держит слово. Доверие возвращается поступками, а не обещаниями.","Jack notices Lily keeping her word. Trust returns through actions, not promises.")}
		_text(ending[g().farm.lily_answer],23)
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
