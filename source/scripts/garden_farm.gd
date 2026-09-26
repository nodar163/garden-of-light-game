extends RefCounted
## Productive nursery and flower-shop rules. Decorative plots remain independent.

const SPECIES = [
	["Розовые космеи", "Pink cosmos", 0, 0, 1, 3, 0, 0],
	["Золотые ромашки", "Golden daisies", 1, 1, 2, 2, 3, 65],
	["Лавандовые анемоны", "Purple anemones", 2, 2, 3, 1, 8, 85],
	["Бирюзовые незабудки", "Blue forget-me-nots", 3, 3, 1, 3, 14, 95],
	["Оранжевые георгины", "Orange dahlias", 4, 2, 2, 2, 22, 110],
	["Лаймовые хризантемы", "Lime chrysanthemums", 5, 3, 3, 1, 32, 125],
]
# name ru/en, desired quality (0 aroma, 1 freshness, 2 yield), caption ru/en
const CUSTOMERS = [
	["Анна · цветы для окна", "Anna · flowers for the window", 1, "Пусть букет долго радует маму.", "A bouquet Mum can enjoy for days."],
	["Марк · солнечная библиотека", "Mark · a sunny library", 2, "Нужно побольше цветков для читального зала.", "Plenty of flowers for the reading room."],
	["Лея · вечерний аромат", "Leah · evening fragrance", 0, "Хочу, чтобы веранда пахла летом.", "A scent of summer for the veranda."],
	["Мира · открытие школы", "Mira · school opening", 1, "Нежный букет, который простоит до конца недели.", "Gentle flowers that last through the week."],
	["Городская ярмарка", "The town flower fair", 2, "Яркая витрина для всех соседей.", "A bright display for every neighbour."],
	["Букет примирения", "A bouquet of forgiveness", 0, "Пусть цветы скажут то, на что не хватает слов.", "Let the flowers say what words cannot."],
	["Нина · первый школьный день", "Nina · first day of school", 1, "Небольшой букет для смелого начала.", "A small bouquet for a brave new start."],
	["Тим · открытие пекарни", "Tim · bakery opening", 0, "Хочу, чтобы у входа пахло летом.", "I want summer at the bakery door."],
	["София · подарок соседке", "Sofia · a gift for a neighbour", 2, "Пусть букет будет пышным и весёлым.", "Make it full and cheerful."],
	["Дедушка Илья · годовщина", "Ilya · an anniversary", 1, "Она хранит каждый подаренный цветок.", "She keeps every flower I give her."],
	["Местная больница", "The local hospital", 2, "Хватит ли цветов для всей стойки приёма?", "Can we brighten the whole reception desk?"],
	["Открытый сад", "The open garden", 0, "Букет для гостя, который заглянет впервые.", "A bouquet for someone visiting for the first time."],
]
const SHOP_PRICES = [600, 1000, 1500, 2200, 3000]
const SHOP_ORDERS = [4, 12, 25, 40, 60]
const BUILDINGS = [
	["Домик пчёл", "Bee house", 350, 2],
	["Букетный павильон", "Bouquet pavilion", 550, 3],
]

static func defaults() -> Dictionary:
	return {"version": 1, "beds": {}, "stock": [0, 0, 0, 0, 0, 0],
		"harvested": 0, "orders_done": 0, "reputation": 0,
		"shop_tier": 0, "buildings": [], "album": [], "story_seen": [], "lily_answer": "", "seen_guide": false}

static func ensure(g: Dictionary) -> void:
	if not g.has("farm"):
		g.farm = defaults()
		# Older decorative flowers become starter productive varieties once.
		for item in g.get("plots", {}).values():
			var species := int(item)
			if species >= 0 and species < SPECIES.size() and not g.farm.beds.has(str(species)):
				g.farm.beds[str(species)] = {"species": species, "tier": 1, "growth": 0}
	if not g.farm.has("buildings"): g.farm.buildings = []
	if not g.farm.has("album"): g.farm.album = []
	for key in ["version", "harvested", "orders_done", "reputation", "shop_tier"]:
		g.farm[key] = int(g.farm[key])
	for id in g.farm.stock.size(): g.farm.stock[id] = int(g.farm.stock[id])
	for bed in g.farm.beds.values():
		for key in ["species", "tier", "growth"]: bed[key] = int(bed[key])
	for i in g.farm.story_seen.size(): g.farm.story_seen[i] = int(g.farm.story_seen[i])
	for i in g.farm.buildings.size(): g.farm.buildings[i] = int(g.farm.buildings[i])

static func valid(value: Variant) -> bool:
	if not value is Dictionary or value.get("version") != 1: return false
	if not value.get("beds") is Dictionary or not value.get("stock") is Array or value.stock.size() != SPECIES.size(): return false
	if not value.get("story_seen") is Array or not value.get("buildings") is Array or not value.get("seen_guide") is bool: return false
	if value.has("album") and not value.album is Array: return false
	for key in ["harvested", "orders_done", "reputation", "shop_tier"]:
		if not typeof(value.get(key)) in [TYPE_INT, TYPE_FLOAT] or int(value[key]) < 0 or float(value[key]) != int(value[key]): return false
	if int(value.shop_tier) > SHOP_PRICES.size() or int(value.orders_done) > 100000 or int(value.reputation) > 1000000: return false
	if value.get("lily_answer") not in ["", "distance", "friends", "perhaps"]: return false
	for stock in value.stock:
		if not typeof(stock) in [TYPE_INT, TYPE_FLOAT] or float(stock) != int(stock) or int(stock) < 0 or int(stock) > 999: return false
	for slot in value.beds:
		if not str(slot).is_valid_int() or int(slot) < 0 or int(slot) >= SPECIES.size(): return false
		var bed: Variant = value.beds[slot]
		if not bed is Dictionary or int(bed.get("species", -1)) < 0 or int(bed.get("species", -1)) >= SPECIES.size(): return false
		if int(bed.get("tier", -1)) < 1 or int(bed.get("tier", -1)) > 3 or int(bed.get("growth", -1)) < 0 or int(bed.get("growth", -1)) > 3: return false
	for scene in value.story_seen:
		if not typeof(scene) in [TYPE_INT, TYPE_FLOAT] or int(scene) < 0 or int(scene) > 11: return false
	var built: Dictionary = {}
	for item in value.buildings:
		if not typeof(item) in [TYPE_INT, TYPE_FLOAT] or float(item) != int(item) or int(item) < 0 or int(item) >= BUILDINGS.size() or built.has(int(item)): return false
		built[int(item)] = true
	var saved_album: Array=value.get("album",[])
	if saved_album.size() > 12: return false
	for entry in saved_album:
		if not entry is Dictionary or not entry.get("flowers") is Array or entry.flowers.size()<1 or entry.flowers.size()>3: return false
		if not typeof(entry.get("wrap")) in [TYPE_INT,TYPE_FLOAT] or int(entry.wrap)<0 or int(entry.wrap)>2: return false
		if not typeof(entry.get("customer")) in [TYPE_INT,TYPE_FLOAT] or int(entry.customer)<0 or int(entry.customer)>=CUSTOMERS.size(): return false
		if not typeof(entry.get("coins")) in [TYPE_INT,TYPE_FLOAT] or int(entry.coins)<0 or int(entry.coins)>1000: return false
		for flower in entry.flowers:
			if not typeof(flower) in [TYPE_INT,TYPE_FLOAT] or int(flower)<0 or int(flower)>=SPECIES.size(): return false
	return true

static func building_ready(g: Dictionary, id: int) -> bool:
	ensure(g)
	if id < 0 or id >= BUILDINGS.size() or id in g.farm.buildings: return false
	return int(BUILDINGS[id][3]) in g.repairs and int(g.coins) >= int(BUILDINGS[id][2])

static func build_garden(g: Dictionary, id: int) -> bool:
	if not building_ready(g, id): return false
	g.coins -= int(BUILDINGS[id][2])
	g.farm.buildings.append(id)
	return true

static func plant(g: Dictionary, slot: int, species: int) -> bool:
	ensure(g)
	if slot < 0 or slot >= 6 or species < 0 or species >= SPECIES.size(): return false
	if g.farm.beds.has(str(slot)) or g.earned.size() < int(SPECIES[species][6]): return false
	var cost: int = int(SPECIES[species][7])
	if int(g.coins) < cost: return false
	g.coins -= cost
	g.farm.beds[str(slot)] = {"species": species, "tier": 1, "growth": 0}
	return true

static func upgrade(g: Dictionary, slot: int) -> bool:
	ensure(g)
	var bed: Variant = g.farm.beds.get(str(slot))
	if not bed is Dictionary or int(bed.tier) >= 3: return false
	var cost: int = 90 * int(bed.tier)
	if int(g.coins) < cost: return false
	g.coins -= cost
	bed.tier += 1
	return true

static func grow(g: Dictionary) -> void:
	ensure(g)
	for bed in g.farm.beds.values():
		bed.growth = mini(3, int(bed.growth) + 1)

static func harvest(g: Dictionary, slot: int) -> int:
	ensure(g)
	var bed: Variant = g.farm.beds.get(str(slot))
	if not bed is Dictionary or int(bed.growth) < 3: return 0
	var species: int = int(bed.species)
	var amount: int = mini(int(bed.tier) + 1 + (1 if 0 in g.farm.buildings else 0), 999 - int(g.farm.stock[species]))
	if amount <= 0: return 0
	g.farm.stock[species] += amount
	g.farm.harvested += amount
	bed.growth = 0
	return amount

static func order(g: Dictionary) -> Array:
	ensure(g)
	return CUSTOMERS[int(g.farm.orders_done) % CUSTOMERS.size()]

static func bouquet(g: Dictionary, picked: Array) -> Dictionary:
	ensure(g)
	if picked.size() != SPECIES.size(): return {"valid": false}
	var count := 0
	var quality_points := 0
	var diversity := 0
	for id in SPECIES.size():
		var amount: int = int(picked[id])
		if amount < 0 or amount > int(g.farm.stock[id]): return {"valid": false}
		count += amount
		if amount > 0:
			diversity += 1
			quality_points += amount * int(SPECIES[id][3 + int(order(g)[2])])
	if count < 1 or count > 3: return {"valid": false}
	var quality: int = roundi(float(quality_points) / count)
	var coins: int = 25 + 8 * count + 6 * quality + 5 * maxi(0, diversity - 1) + (5 if 1 in g.farm.buildings else 0) + (8 if int(g.farm.shop_tier)>=4 else 0) + (8 if int(g.farm.shop_tier)>=5 else 0)
	return {"valid": true, "quality": quality, "coins": coins, "reputation": 2 if quality >= 2 else 1}

static func sell(g: Dictionary, picked: Array, flowers: Array=[], wrap: int=0) -> bool:
	var result := bouquet(g, picked)
	if not result.get("valid", false) or wrap<0 or wrap>2: return false
	var composition: Array=flowers.duplicate()
	if composition.is_empty():
		for id in SPECIES.size():
			for amount in int(picked[id]): composition.append(id)
	if composition.size()>3: return false
	var counts: Array=[0,0,0,0,0,0]
	for id in composition:
		if not typeof(id) in [TYPE_INT,TYPE_FLOAT] or int(id)<0 or int(id)>=SPECIES.size(): return false
		counts[int(id)]+=1
	if counts!=picked: return false
	var customer_id: int=int(g.farm.orders_done) % CUSTOMERS.size()
	for id in SPECIES.size():
		g.farm.stock[id] -= int(picked[id])
	g.coins += int(result.coins)
	g.farm.reputation += int(result.reputation)
	g.farm.orders_done += 1
	g.farm.album.append({"flowers":composition,"wrap":wrap,"customer":customer_id,"coins":int(result.coins)})
	if g.farm.album.size()>12: g.farm.album.pop_front()
	return true

static func shop_ready(g: Dictionary) -> bool:
	ensure(g)
	var tier: int = int(g.farm.shop_tier)
	return tier < SHOP_PRICES.size() and 3 in g.repairs and int(g.farm.orders_done) >= SHOP_ORDERS[tier] and int(g.coins) >= SHOP_PRICES[tier]

static func build_shop(g: Dictionary) -> bool:
	if not shop_ready(g): return false
	var tier: int = int(g.farm.shop_tier)
	g.coins -= SHOP_PRICES[tier]
	g.farm.shop_tier += 1
	return true

static func story_ready(g: Dictionary, id: int) -> bool:
	ensure(g)
	if id < 0 or id > 11 or id in g.farm.story_seen or id != g.farm.story_seen.size(): return false
	match id:
		0: return g.get("earned",[]).size() >= 3 or 0 in g.repairs
		1: return 2 in g.repairs
		2: return 3 in g.repairs and int(g.farm.orders_done) >= 2
		3: return int(g.farm.shop_tier) >= 1
		4: return int(g.farm.shop_tier) >= 2
		5: return int(g.farm.shop_tier) >= 3
		6: return g.earned.size() >= 50
		7: return g.earned.size() >= 100
		8: return g.earned.size() >= 150
		9: return g.earned.size() >= 200
		10: return g.earned.size() >= 300
		11: return g.earned.size() >= 500
	return false

static func claim_story(g: Dictionary, id: int) -> bool:
	if not story_ready(g, id): return false
	g.farm.story_seen.append(id)
	return true
