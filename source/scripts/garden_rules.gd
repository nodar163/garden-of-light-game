extends RefCounted
## All economy operations are deterministic, local and independent of the view.
const REWARD=25
const PLOT_COUNT=30
const ITEMS=[
	["Розовые космеи","Pink cosmos",50,0,0],
	["Золотые ромашки","Golden daisies",60,1,0],
	["Лавандовые анемоны","Purple anemones",80,2,3],
	["Бирюзовые незабудки","Blue forget-me-nots",90,3,6],
	["Оранжевые георгины","Orange dahlias",110,4,10],
	["Лаймовые хризантемы","Lime chrysanthemums",130,5,15],
	["Уютная скамейка","Cozy bench",150,0,3],
	["Тёплый фонарь","Warm lantern",100,1,2],
	["Домик для птиц","Birdhouse",160,2,8],
	["Ваза с розами","Rose urn",180,3,12],
	["Тележка подсолнухов","Sunflower cart",180,8,18],
	["Домик пчёл","Bee house",200,9,22],
	["Садовый зайчик","Garden rabbit",220,10,28],
	["Солнечные часы","Sundial",240,11,35]]
const REPAIRS=[
	["Расчистить вход","Clear the entrance",150,1,12,7],
	["Восстановить фонтан","Restore the fountain",300,3,13,4],
	["Починить теплицу","Repair the greenhouse",600,6,14,5],
	["Открыть цветочную лавку","Open the flower stall",900,10,15,6],
	["Устроить цветочную беседку","Build the flower pergola",1200,15,12,7]]
const REPAIR_POS=[Vector2(.50,.87),Vector2(.51,.47),Vector2(.82,.15),Vector2(.13,.69),Vector2(.13,.46)]

static func defaults() -> Dictionary:
	return {"version":1,"coins":50,"earned":[],"plots":{},"repairs":[],"orders":0,"intro_step":0,"intro_done":false,"camera":[1600.0,1400.0,0.35]}

static func valid(g: Variant) -> bool:
	if not g is Dictionary or g.get("version")!=1: return false
	for key in ["coins","orders","intro_step"]:
		if not typeof(g.get(key)) in [TYPE_INT,TYPE_FLOAT] or float(g[key])!=int(g[key]) or int(g[key])<0: return false
	if int(g.coins)>1000000 or int(g.orders)>50 or int(g.intro_step)>3: return false
	if not g.get("intro_done") is bool or not g.get("plots") is Dictionary or not g.get("earned") is Array or not g.get("repairs") is Array: return false
	if not g.get("camera") is Array or g.camera.size()!=3: return false
	for v in g.camera:
		if not typeof(v) in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(v)): return false
	if float(g.camera[2])<0.1 or float(g.camera[2])>2: return false
	for slot in g.plots:
		if not str(slot).is_valid_int() or int(slot)<0 or int(slot)>=PLOT_COUNT: return false
		var item=g.plots[slot]
		if not typeof(item) in [TYPE_INT,TYPE_FLOAT] or float(item)!=int(item) or int(item)<0 or int(item)>=ITEMS.size(): return false
	var seen: Dictionary={}
	for key in g.earned:
		if not key is String or seen.has(key): return false
		var parts=key.split(":")
		if parts.size()!=2 or parts[0] not in ["light","match"] or not parts[1].is_valid_int() or int(parts[1])<1 or int(parts[1])>250: return false
		seen[key]=true
	seen.clear()
	for value in g.repairs:
		if not typeof(value) in [TYPE_INT,TYPE_FLOAT] or float(value)!=int(value) or int(value)<0 or int(value)>=REPAIRS.size() or seen.has(int(value)): return false
		seen[int(value)]=true
	return true

static func sync(data: Dictionary) -> int:
	if not data.has("garden"): data.garden=defaults()
	var g: Dictionary=data.garden
	g.version=1
	for i in 3: g.camera[i]=float(g.camera[i])
	g.coins=int(g.coins); g.orders=int(g.orders); g.intro_step=int(g.intro_step)
	for slot in g.plots: g.plots[slot]=int(g.plots[slot])
	for i in g.repairs.size(): g.repairs[i]=int(g.repairs[i])
	var earned:=0
	for mode in ["light","match"]:
		var ids: Array=data.completed if mode=="light" else data.match3.completed
		for id in ids:
			var key: String=mode+":"+str(int(id))
			if int(id)>=1 and int(id)<=250 and key not in g.earned:
				g.earned.append(key); earned+=REWARD
	g.coins+=earned
	return earned

static func flowers(g: Dictionary) -> int:
	var count:=0
	for id in g.plots.values():
		if int(id)<6: count+=1
	return count

static func buy(g: Dictionary,slot: int,item: int) -> bool:
	if slot<0 or slot>=PLOT_COUNT or item<0 or item>=ITEMS.size() or g.earned.size()<ITEMS[item][4]: return false
	var current:=int(g.plots.get(str(slot),-1))
	if current==item: return false
	var refund:=int(ITEMS[current][2]) if current>=0 else 0
	if int(g.coins)+refund<int(ITEMS[item][2]): return false
	g.coins=int(g.coins)+refund-int(ITEMS[item][2]); g.plots[str(slot)]=item
	return true

static func remove(g: Dictionary,slot: int) -> bool:
	if not g.plots.has(str(slot)): return false
	g.coins+=int(ITEMS[int(g.plots[str(slot)])][2]); g.plots.erase(str(slot))
	return true

static func repair(g: Dictionary,index: int) -> bool:
	if index<0 or index>=REPAIRS.size() or index in g.repairs: return false
	if index>0 and index-1 not in g.repairs: return false
	if g.plots.size()<REPAIRS[index][3] or int(g.coins)<REPAIRS[index][2]: return false
	g.coins-=REPAIRS[index][2]; g.repairs.append(index)
	return true

static func order_ready(g: Dictionary) -> bool:
	return int(g.orders)<50 and flowers(g)>=3 and g.earned.size()>=(int(g.orders)+1)*10

static func deliver(g: Dictionary) -> bool:
	if not order_ready(g): return false
	g.orders+=1; g.coins+=40
	return true

static func next_empty(g: Dictionary) -> int:
	for slot in PLOT_COUNT:
		if not g.plots.has(str(slot)): return slot
	return 0

static func plot_position(slot: int) -> Vector2:
	# One continuous estate; every plot has a stable position across reloads.
	var x: float=[.29,.37,.45,.57,.65,.73][slot%6]
	var y:=0.34+(slot/6)*0.09
	return Vector2(x,y)

static func task(g: Dictionary,english: bool=false) -> String:
	if g.plots.is_empty(): return "Plant Jack's first flowers (50 coins)." if english else "Посади первые цветы Джека — 50 монет."
	for i in REPAIRS.size():
		if i not in g.repairs:
			return ("Next: %s. Plots: %d/%d · %d coins." if english else "Дальше: %s. Мест: %d/%d · %d монет.") % [REPAIRS[i][1 if english else 0],g.plots.size(),REPAIRS[i][3],REPAIRS[i][2]]
	return ("Your garden is alive! Decorate all 30 places: %d/30." if english else "Сад снова живёт! Укрась все 30 мест: %d/30.") % g.plots.size()
