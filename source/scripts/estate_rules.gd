extends RefCounted
## Stable IDs and optional save fields preserve all previously purchased repairs.
const ROOMS_RU=["Гостиная","Кухня","Зимний сад","Спальня","Библиотека","Мастерская"]
const ROOMS_EN=["Living room","Kitchen","Conservatory","Bedroom","Library","Studio"]
const AREAS_RU=["Яблоневый склон","Розовые террасы","Большая оранжерея","Пасека","Озеро","Площадь праздников"]
const AREAS_EN=["Apple hillside","Rose terraces","Grand conservatory","Apiary","Lake","Festival square"]
const HOUSE_RU=[["Диван","Камин и дверь","Чайный столик","Ковёр"],["Плита","Раковина","Обеденный стол","Шкафчики"],["Остекление","Стол садовника","Стеллаж","Мозаичный пол"],["Кровать","Гардероб","Комод","Сундук"],["Книжные полки","Кресло","Письменный стол","Паркет"],["Витрина ваз","Рабочий стол","Мольберт","Цветочные полки"]]
const HOUSE_EN=[["Sofa","Fireplace and door","Tea table","Rug"],["Cooker","Sink","Dining table","Cupboards"],["Glazing","Potting bench","Shelves","Mosaic floor"],["Bed","Wardrobe","Dresser","Chest"],["Bookshelves","Armchair","Writing desk","Parquet"],["Vase cabinet","Work table","Easel","Flower shelves"]]
const LAND_RU=[["Яблони","Шпалеры","Грядки","Каменная тропа"],["Обсерватория","Розовая арка","Террасы","Лестница"],["Стеклянная крыша","Двери","Коллекция растений","Ограда"],["Мастерская","Ульи","Рабочий двор","Изгородь"],["Мост","Причал","Лодка","Домик у воды"],["Павильоны","Площадь","Фонтан","Гирлянды"]]
const LAND_EN=[["Apple trees","Trellises","Beds","Stone path"],["Observatory","Rose arch","Terraces","Steps"],["Glass roof","Doors","Plant collection","Fence"],["Workshop","Beehives","Work yard","Hedge"],["Bridge","Pier","Boat","Boathouse"],["Pavilions","Square","Fountain","Garlands"]]
const HOUSE_POINTS=[Vector2(.16,.29),Vector2(.29,.19),Vector2(.245,.315),Vector2(.255,.365),Vector2(.465,.22),Vector2(.53,.25),Vector2(.51,.35),Vector2(.585,.19),Vector2(.79,.17),Vector2(.77,.31),Vector2(.88,.35),Vector2(.79,.41),Vector2(.185,.565),Vector2(.125,.47),Vector2(.06,.585),Vector2(.185,.68),Vector2(.435,.52),Vector2(.44,.635),Vector2(.525,.69),Vector2(.40,.755),Vector2(.73,.55),Vector2(.76,.66),Vector2(.866,.66),Vector2(.89,.535)]
const LAND_POINTS=[Vector2(.11,.11),Vector2(.225,.14),Vector2(.175,.23),Vector2(.27,.265),Vector2(.63,.075),Vector2(.515,.095),Vector2(.51,.19),Vector2(.595,.245),Vector2(.795,.22),Vector2(.77,.315),Vector2(.855,.31),Vector2(.865,.40),Vector2(.135,.485),Vector2(.11,.585),Vector2(.205,.55),Vector2(.205,.66),Vector2(.80,.575),Vector2(.825,.765),Vector2(.9,.72),Vector2(.725,.86),Vector2(.325,.76),Vector2(.46,.80),Vector2(.49,.765),Vector2(.575,.86)]

static func key(house: bool,id: int) -> String: return ("house:" if house else "land:")+str(id)
static func tier(g: Dictionary,house: bool,id: int) -> int: return int(g.get("estate",{}).get(key(house,id),0))
static func required(house: bool,id: int,next_tier: int) -> int:
	# Alternating branches: 144 meaningful stages distributed across 2000 first wins.
	return ceili(float((next_tier-1)*48+id*2+(1 if house else 2))*2000.0/144.0)
static func price(next_tier: int) -> int: return [0,100,180,260][clampi(next_tier,0,3)]
static func valid(value: Variant) -> bool:
	if not value is Dictionary: return false
	for k in value:
		var parts:=str(k).split(":")
		if parts.size()!=2 or parts[0] not in ["house","land"] or not parts[1].is_valid_int() or str(int(parts[1]))!=parts[1] or int(parts[1])<0 or int(parts[1])>=24: return false
		var v: Variant=value[k]
		if not typeof(v) in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(v)) or float(v)!=int(v) or int(v)<1 or int(v)>3: return false
	return true
static func upgrade(g: Dictionary,house: bool,id: int) -> bool:
	if id<0 or id>=24 or 0 not in g.repairs: return false
	var next:=tier(g,house,id)+1
	if next>3 or progress(g)<required(house,id,next) or int(g.coins)<price(next): return false
	if not g.has("estate"): g.estate={}
	g.coins-=price(next); g.estate[key(house,id)]=next; return true
static func complete(g: Dictionary) -> bool:
	for house in [false,true]:
		for id in 24:
			if tier(g,house,id)<3: return false
	return g.earned.size()==2000
static func name_of(house: bool,id: int,en: bool) -> String:
	return (HOUSE_EN if en else HOUSE_RU)[id/4][id%4] if house else (LAND_EN if en else LAND_RU)[id/4][id%4]

static func progress(g: Dictionary) -> int:
	var farm: Dictionary=g.get("farm",{})
	return mini(2000,g.earned.size()+int(farm.get("orders_done",0))*3+int(farm.get("harvested",0))/2)

static func room_rank(g: Dictionary,room: int) -> int:
	var stages:=0
	for id in range(room*4,room*4+4): stages+=tier(g,true,id)
	return stages/4

static func benefit(g: Dictionary,room: int,en: bool) -> String:
	var rank:=room_rank(g,room)
	var ru=["Гостиная: +%d монет за букет","Кухня: компост дешевле на %d монет","Зимний сад: +%d цветков за урожай","Спальня: +%d монет за сбор урожая","Библиотека: +%d монет за любимую бумагу","Мастерская: +%d монет за секатор и бант"]
	var eng=["Lounge: +%d coins per bouquet","Kitchen: compost costs %d coins less","Conservatory: +%d flowers per harvest","Bedroom: +%d coins per harvest","Library: +%d coins for preferred paper","Studio: +%d coins for trimming and a bow"]
	return (eng if en else ru)[room] % (rank if room in [1,2] else rank*2)

static func choose(g: Dictionary,house: bool,id: int,style: int) -> bool:
	if id<0 or id>=24 or style<0 or style>2 or tier(g,house,id)<3: return false
	if not g.has("estate_styles"): g.estate_styles={}
	g.estate_styles[key(house,id)]=style; return true

static func styles_valid(value: Variant) -> bool:
	if not value is Dictionary: return false
	var shifted: Dictionary={}
	for k in value:
		if not typeof(value[k]) in [TYPE_INT,TYPE_FLOAT] or float(value[k])!=int(value[k]): return false
		shifted[k]=int(value[k])+1
	return valid(shifted)
