extends RefCounted
## Additive chapter state: old purchases, rewards and saves remain valid.
const STEPS=[
	["Первый цветущий уголок","The first flowerbed","Посади любые цветы у домика.","Plant flowers by the cottage."],
	["Дорога домой","The path home","Пройди 3 новых уровня в любом режиме.","Complete 3 new levels in either mode."],
	["Снова открыто","Open again","Восстанови вход в сад.","Restore the garden entrance."],
	["Букет для Анны","A bouquet for Anna","Выполни первый заказ в разделе «Букеты».","Complete your first order in Bouquets."],
	["Первый вечер","Our first evening","Пройди 12 уровней. Зажжём огни вместе.","Complete 12 levels. Let's light the garden."],
	["Вода возвращается","Water returns","Восстанови фонтан и выбери оформление.","Restore the fountain and choose its style."],
	["Бабушкин дневник","Grandma's journal","Восстанови теплицу: там сохранились записи о цветах.","Restore the greenhouse and discover the flower journal."],
	["Лавка для друзей","A shop for friends","Восстанови лавку Джека.","Restore Jack's flower stall."],
	["Место для встречи","A place to gather","Восстанови беседку для соседей.","Restore the pergola for our neighbours."]]
const LINES=[
	["Джек: Космеи пережили бурю. С них и начнётся наш новый сад.","Jack: The cosmos survived the storm. Our new garden starts here."],
	["Джек: Тропинка уже видна! Анна обещала зайти, когда откроем ворота.","Jack: We can see the path again! Anna will visit when the gates open."],
	["Анна: Я так рада видеть тебя, Джек. Соберёшь маме розово-золотой букет?","Anna: I'm so glad to see you, Jack. Could you make Mum a pink and gold bouquet?"],
	["Анна: Мама поставила букет у окна. Теперь у неё дома кусочек твоего сада!","Anna: Mum put the bouquet by her window. A little piece of your garden!"],
	["Джек: Бабушка говорила, что у каждого цветка есть свой свет. Посмотри, как тихо здесь вечером.","Jack: Grandma said every flower has its own light. Look how peaceful the evening is."],
	["Джек: Слышишь воду? Теперь птицам снова есть где купаться.","Jack: Hear the water? The birds have their bathing place back."],
	["Джек: Здесь бабушкин дневник! Рядом с каждым сортом — история человека, которому она дарила цветы.","Jack: Grandma's journal! Beside each flower is the story of someone she gave it to."],
	["Марк: Твоя лавка снова открыта! Мне нужен солнечный букет для нашей маленькой библиотеки.","Mark: Your shop is open again! I need a sunny bouquet for our little library."],
	["Джек: Теперь это место встреч. Спасибо, что вернул саду не только цветы, но и друзей.","Jack: A meeting place again. Thank you for bringing back our flowers and our friends."]]
const MILESTONES=[
 [25,"Домик для птиц","Birdhouse", "Птицы снова навещают сад.","Birds return to the garden.",2,Vector2(.44,.35)],
 [50,"Тёплые фонари","Warm lanterns","Дорожки светятся после заката.","The paths glow after sunset.",1,Vector2(.53,.63)],
 [100,"Аллея роз","Rose walk","У розовой дорожки появились новые цветы.","New blooms line the rose walk.",3,Vector2(.22,.39)],
 [150,"Тележка Джека","Jack's cart","Джек отвозит букеты соседям.","Jack delivers bouquets to our neighbours.",8,Vector2(.37,.72)],
 [200,"Уголок пчёл","Bee corner","В сад снова прилетели пчёлы.","Bees have found the garden again.",9,Vector2(.72,.39)],
 [300,"Прудовый гость","Pond visitor","У пруда поселился садовый зайчик.","A garden rabbit visits the pond.",10,Vector2(.66,.72)],
 [400,"Солнечные часы","Sundial","Теперь каждый час напоминает о пути, который мы прошли.","Each hour reminds us how far we have come.",11,Vector2(.19,.65)],
 [500,"Сад тысячи огней","Garden of a thousand lights","Весь сад цветёт. Джек приглашает друзей на вечер цветов.","The whole garden blooms. Jack invites friends to a flower evening.",1,Vector2(.48,.78)]]

const CUSTOMERS=[
	["Анна · мамин день рождения","Anna · Mum's birthday",[0,1],8,50,"Мама любит розовое и золотое.","Mum loves pink and gold."],
	["Марк · букет для библиотеки","Mark · library flowers",[1,4],18,65,"Пусть у книжной полки будет солнечно.","A little sunshine beside the books."],
	["Лея · вечер на веранде","Leah · an evening outside",[2,3],28,80,"Лавандовые и голубые цветы напомнят о лете.","Purple and blue flowers to remember summer."]]

static func ensure(g: Dictionary) -> void:
	if not g.has("story"): g.story={"claimed":[],"deliveries":[],"styles":{},"evening":false,"last_mode":"match","milestones":[]}
	if not g.story.has("milestones"): g.story.milestones=[]

static func valid(s: Variant) -> bool:
	if not s is Dictionary or (s.has("milestones") and not s.milestones is Array) or not s.get("claimed") is Array or not s.get("deliveries") is Array or not s.get("styles") is Dictionary or not s.get("evening") is bool or s.get("last_mode") not in ["light","match"]: return false
	for pair in [[s.claimed,STEPS.size()],[s.deliveries,CUSTOMERS.size()],[s.get("milestones",[]),MILESTONES.size()]]:
		var seen: Dictionary={}
		for id in pair[0]:
			if not typeof(id) in [TYPE_INT,TYPE_FLOAT] or float(id)!=int(id) or int(id)<0 or int(id)>=pair[1] or seen.has(int(id)): return false
			seen[int(id)]=true
	for key in s.styles:
		var v: Variant=s.styles[key]
		if not str(key).is_valid_int() or int(key)<0 or int(key)>4 or not typeof(v) in [TYPE_INT,TYPE_FLOAT] or float(v)!=int(v) or int(v)<0 or int(v)>2: return false
	return true

static func ready(g: Dictionary,id: int) -> bool:
	ensure(g)
	match id:
		0:
			for item in g.plots.values():
				if int(item)<6: return true
			return false
		1: return g.earned.size()>=3
		2: return 0 in g.repairs
		3: return 0 in g.story.deliveries
		4: return g.earned.size()>=12
		_: return id-4 in g.repairs

static func next(g: Dictionary) -> int:
	ensure(g)
	for i in STEPS.size():
		if i not in g.story.claimed: return i
	return STEPS.size()

static func claim(g: Dictionary,id: int) -> bool:
	if id!=next(g) or id>=STEPS.size() or not ready(g,id): return false
	g.story.claimed.append(id)
	if id==4: g.story.evening=true
	return true

static func order_ready(g: Dictionary,id: int) -> bool:
	ensure(g)
	if id<0 or id>=CUSTOMERS.size() or id in g.story.deliveries or g.earned.size()<CUSTOMERS[id][3]: return false
	for flower in CUSTOMERS[id][2]:
		if flower not in g.plots.values(): return false
	return true

static func deliver(g: Dictionary,id: int) -> bool:
	if not order_ready(g,id): return false
	g.story.deliveries.append(id); g.coins+=CUSTOMERS[id][4]
	return true

static func style(g: Dictionary,id: int,value: int) -> bool:
	ensure(g)
	if id not in g.repairs or value<0 or value>2: return false
	g.story.styles[str(id)]=value
	return true

static func milestone_ready(g: Dictionary,id: int) -> bool:
	ensure(g)
	return id>=0 and id<MILESTONES.size() and id not in g.story.milestones and g.earned.size()>=MILESTONES[id][0]

static func milestone_claim(g: Dictionary,id: int) -> bool:
	if not milestone_ready(g,id): return false
	g.story.milestones.append(id)
	return true
