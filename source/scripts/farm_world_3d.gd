extends Control
## Touchable nursery and shop rooms. Gesture actions commit before animations.
signal guidance_changed(value: String)
signal bed_selected(slot: int)
const Scene=preload("res://scripts/scene_3d.gd")
const Models=preload("res://scripts/models_3d.gd")
const Farm=preload("res://scripts/garden_farm.gd")
const BED_POS=[Vector3(-2.25,0,-2.8),Vector3(2.25,0,-2.8),Vector3(-2.25,0,-.4),Vector3(2.25,0,-.4),Vector3(-2.25,0,2),Vector3(2.25,0,2)]
const STOCK_POS=[Vector3(-3,0,-.6),Vector3(0,0,-.6),Vector3(3,0,-.6),Vector3(-3,0,1.35),Vector3(0,0,1.35),Vector3(3,0,1.35)]
const TOOL_POS=[Vector3(-3.2,0,4.5),Vector3(-1.3,0,4.5),Vector3(2.8,0,4.5)]
const DESK=Vector3(0,0,4.1)
const CASH=Vector3(-2.7,0,-3.45)
const PAPER_COLORS=[Color("edbb97"),Color("b7d5bb"),Color("d7c0dc")]
var game: Control
var mode:="nursery"
var stage: Control
var dynamic: Node3D
var dragged: MeshInstance3D
var drag_kind:=""
var drag_id:=-1
var press_position:=Vector2.ZERO
var pointer:=Vector2.ZERO
var moved:=false
var busy:=false
var selected_bed:=-1
var selected_item:=""
var selected_id:=-1
var message:=""
var customers: Array=[]
var keyboard_cursor:=0
var focus_marker: MeshInstance3D
var target_markers: Array=[]

func g() -> Dictionary: return game.store.data.garden
func words(ru: String,en: String) -> String: return game.words(ru,en)

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_STOP; focus_mode=Control.FOCUS_ALL
	stage=Scene.new(); add_child(stage); stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage.pose(Vector3(0,0,.7),14.2)
	stage.camera.position=Vector3(0,14,19.7); stage.camera.look_at(Vector3(0,0,.7))
	stage.sun.shadow_enabled=not game.store.data.settings.reduce_motion
	dynamic=Node3D.new(); stage.world.add_child(dynamic)
	build_room(); refresh()
	resized.connect(func(): if is_instance_valid(stage): stage.fit())

func build_room() -> void:
	if mode=="nursery":
		stage.block(Vector3(0,-.3,.5),Vector3(10.7,.5,15.5),Color("a6c878"))
		stage.block(Vector3(0,-.035,1),Vector3(1.15,.035,12),Color("e1c696"))
		stage.block(Vector3(0,-.015,4.4),Vector3(9.6,.035,1.3),Color("e5ceaa"))
		stage.add("greenhouse",Vector3(0,0,-5.7),1.2)
		for i in 8:
			stage.add("tree",Vector3(-5 if i%2==0 else 5,0,-5.4+int(i/2)*3.4),.65,i)
		for s in [-1,1]:
			stage.block(Vector3(s*5.0,.45,.4),Vector3(.12,.14,14.6),Color("f0ddb6"))
			for i in 12: stage.block(Vector3(s*5,.36,-6.4+i*1.25),Vector3(.08,.72,.09),Color("f6e4c3"))
		for i in 6: stage.add("bed",BED_POS[i],1.4)
		stage.add("spade",TOOL_POS[0],1.1).rotation.z=-.22
		stage.add("watering",TOOL_POS[1],1.3)
		stage.add("basket",TOOL_POS[2],1.4)
		for i in 6: stage.add("seed",seed_pos(i),1.3,i)
		stage.title(words("Лопатка","Spade"),TOOL_POS[0]+Vector3(0,1.4,0),34)
		stage.title(words("Лейка","Water"),TOOL_POS[1]+Vector3(0,1.25,0),34)
	else:
		stage.block(Vector3(0,-.2,.5),Vector3(10.5,.4,15),Color("ffe5b6"))
		var flooring:=Models.new()
		for row in 15:
			for column in 10:
				flooring.box(Vector3(-4.7+column*1.04,.016,-6.5+row),Vector3(1.015,.035,.975),Color("eedbb7") if (row+column)%2==0 else Color("dfbb8b"))
		var tiles:=MeshInstance3D.new(); tiles.mesh=flooring.finish(); stage.world.add_child(tiles)
		stage.block(Vector3(0,1.45,-6.6),Vector3(10.6,2.9,.18),Color("83d4c3"))
		stage.block(Vector3(0,.52,-6.46),Vector3(10.5,.95,.10),Color("39a88f"))
		for y in [.10,1.05,2.82]: stage.block(Vector3(0,y,-6.35),Vector3(10.6,.10,.16),Color("ffdfa0"))
		for s in [-1,1]:
			stage.block(Vector3(s*5.2,.5,.1),Vector3(.13,1,13),Color("6abfa6"))
			stage.block(Vector3(s*5.2,1.03,.1),Vector3(.22,.10,13),Color("ffe6b2"))
		for x in [-3.5,3.5]:
			stage.block(Vector3(x,1.83,-6.40),Vector3(2.15,1.55,.12),Color("fff2d2"))
			stage.block(Vector3(x,1.85,-6.30),Vector3(1.85,1.26,.06),Color("75cfe1"))
			stage.block(Vector3(x-.38,1.94,-6.25),Vector3(.25,.98,.015),Color("b2eced"),).rotation.z=-.25
			stage.block(Vector3(x,1.85,-6.24),Vector3(.07,1.35,.08),Color("fff6d7"))
			stage.block(Vector3(x,1.85,-6.24),Vector3(1.94,.07,.08),Color("fff6d7"))
			stage.block(Vector3(x,1.04,-6.10),Vector3(2.4,.16,.40),Color("ffe2a8"))
			for side in [-1,1]:
				stage.block(Vector3(x+side*1.14,1.80,-6.24),Vector3(.24,1.54,.12),Color("ef8d87"))
				for j in 4: stage.block(Vector3(x+side*1.14,1.25+j*.33,-6.16),Vector3(.27,.10,.04),Color("ffb8a2"))
		stage.title(words("ЦВЕТЫ ДЖЕКА","JACK’S FLOWERS"),Vector3(0,2.30,-6.28),35)
		for side in [-1,1]:
			stage.add("pot",Vector3(side*4.7,0,-3.0),1.3)
			for j in 5: stage.add("flower",Vector3(side*4.7+sin(j*2)*.27,.65,-3+cos(j*2)*.27),1.1,j)
			stage.add("lamp",Vector3(side*4.6,.05,5.6),1.0)
		var rug:=Models.new()
		rug.box(Vector3(0,.04,2.8),Vector3(6.4,.05,1.0),Color("dc7fa5"))
		for side in [-1,1]: rug.box(Vector3(0,.073,2.8+side*.38),Vector3(6.1,.014,.04),Color("ffe1af"))
		var carpet:=MeshInstance3D.new(); carpet.mesh=rug.finish(); stage.world.add_child(carpet)
		stage.add("counter",CASH,.9); stage.add("cash",CASH+Vector3(.45,.95,-.1),1)
		for i in 3: customers.append(stage.add("person",queue_pos(i),1.1,(int(g().farm.orders_done)+i)%4))
		for i in 6: stage.add("shelf",STOCK_POS[i],1.25)
		stage.add("counter",DESK,1.75)
		stage.title(words("КАССА","CHECKOUT"),CASH+Vector3(0,1.65,.2),32)
		stage.title(words("Стол букетов","Bouquet table"),DESK+Vector3(0,.85,1.10),27)
		for i in 3:
			stage.block(paper_pos(i)+Vector3(0,.23,0),Vector3(.9,.07,.6),PAPER_COLORS[i])
			stage.title(words(["Крафт","Мята","Лаванда"][i],["Kraft","Mint","Lavender"][i]),paper_pos(i)+Vector3(0,.25,.5),23)
		stage.title(words("Бумага","Paper"),Vector3(3.6,1.0,3.9),32)
		stage.add("person",Vector3(-3.8,0,5.8),1.1,3)

func seed_pos(id: int) -> Vector3: return Vector3(-4.15+id*1.66,0,6.35)
func paper_pos(id: int) -> Vector3: return Vector3(3.8,0,3.3+id*1.05)
func draft_pos(id: int) -> Vector3: return DESK+Vector3((id-1)*.95,1.85,-.12)
func queue_pos(id: int) -> Vector3: return CASH+Vector3(0,0,-1.4) if id==0 else Vector3(.4+(id-1)*2.0,0,-5.0+(id-1)*.4)

func refresh() -> void:
	for child in dynamic.get_children(): dynamic.remove_child(child); child.queue_free()
	Farm.ensure(g())
	if mode=="nursery":
		for i in 6:
			var bed: Variant=g().farm.beds.get(str(i))
			var pos: Vector3=BED_POS[i]
			if bed is Dictionary:
				var growth: int=int(bed.growth)
				for j in 3:
					var flower:=Models.instance("flower" if growth==3 else "bud" if growth==2 else "sprout",int(bed.species),pos+Vector3((j-1)*.70,.35,0),.6+growth*.22)
					if growth==0: flower.scale=Vector3(.20,.3,.20)
					dynamic.add_child(flower)
				var caption: String=words("Собрать","Harvest") if growth==3 else words("Рост %d/3","Growth %d/3") % growth
				add_label(caption,pos+Vector3(0,1.35,.65),43)
				if bed.watered and growth<3: add_label(words("Полито","Watered"),pos+Vector3(0,.4,-.8),28)
			else:
				if i in g().farm.prepared: dynamic.add_child(Models.instance("bed",1,pos+Vector3(0,.02,0),1.4))
				add_label(words("Семена сюда","Plant here") if i in g().farm.prepared else words("Земля","Soil"),pos+Vector3(0,.4,.65),40)
		var stock:=0
		for amount in g().farm.stock: stock+=int(amount)
		add_label(words("Корзина · %d","Basket · %d") % stock,TOOL_POS[2]+Vector3(0,1.5,0),34)
		for i in 6:
			var unlocked: bool=g().earned.size()>=int(Farm.SPECIES[i][6])
			add_label(str(int(Farm.SPECIES[i][7])) if unlocked else words("%d побед","%d wins") % Farm.SPECIES[i][6],seed_pos(i)+Vector3(0,.98,.5),24)
	else:
		var counts: Array=Farm.draft_counts(g())
		for i in 6:
			var stock: int=int(g().farm.stock[i])-int(counts[i])
			for j in mini(3,maxi(0,stock)):
				var flower:=Models.instance("flower",i,STOCK_POS[i]+Vector3((j-1)*.4,1.06,0),.85); dynamic.add_child(flower)
			var short_names: Array=["Космеи","Ромашки","Анемоны","Незабудки","Георгины","Хризантемы"] if game.store.data.settings.language=="ru" else ["Cosmos","Daisies","Anemones","Bluebells","Dahlias","Mums"]
			add_label(short_names[i]+" · "+str(stock),STOCK_POS[i]+Vector3(0,.85,.68),19)
		var flowers: Array=g().farm.draft.flowers
		if g().farm.draft.wrapped:
			var bouquet:=make_bouquet(flowers,int(g().farm.draft.wrap)); bouquet.position=DESK+Vector3(0,1.8,0); dynamic.add_child(bouquet)
		else:
			for i in 3:
				var pos:=draft_pos(i)
				if i<flowers.size(): dynamic.add_child(Models.instance("flower",int(flowers[i]),pos,1.25))
				else:
					var b:=Models.new(); b.cylinder(Vector3.ZERO,.36,.025,Color("e9d5b0")); var circle:=MeshInstance3D.new(); circle.mesh=b.finish(); circle.position=pos-Vector3(0,.12,0); dynamic.add_child(circle)
		var customer: Array=Farm.order(g())
		add_label(str(customer[1 if game.store.data.settings.language=="en" else 0]).split(" · ")[0],Vector3(0,1.3,-2.1),28)
		var quality: int=int(customer[2])
		add_label(words(["Любит аромат","Любит стойкость","Любит пышность"][quality],["Loves fragrance","Loves freshness","Loves fullness"][quality]),Vector3(0,.7,-2.0),24)
		var result: Dictionary=Farm.bouquet(g(),counts)

	update_guidance()

func add_label(value: String, at: Vector3, font_size: int) -> void:
	var label: Label3D=stage.title(value,at,font_size)
	stage.world.remove_child(label); dynamic.add_child(label)

func make_bouquet(flowers: Array, paper: int) -> MeshInstance3D:
	var b:=Models.new()
	b.cylinder(Vector3(0,.2,0),.1,.68,PAPER_COLORS[paper],.42)
	b.cylinder(Vector3(0,-.04,0),.13,.12,Color("f5d679"))
	for i in flowers.size(): b.part(Models.mesh("flower",int(flowers[i])),Vector3((i-1)*.26,.3,0),Vector3.ONE*.7,Color.WHITE)
	var result:=MeshInstance3D.new(); result.mesh=b.finish(); return result

func update_guidance() -> void:
	var text_value: String=message
	if text_value.is_empty():
		if mode=="nursery":
			var ready:=false; var dry:=false
			for bed in g().farm.beds.values():
				ready=ready or int(bed.growth)>=3; dry=dry or (not bed.watered and int(bed.growth)<3)
			text_value=words("Перетащи цветущую грядку в корзину.","Drag a blooming bed into the basket.") if ready else words("Перетащи лейку на грядку: полив ускоряет рост.","Drag the watering can onto a bed to help it grow.") if dry else words("Лопатка → земля, семена → грядка. Победы в уровнях растят цветы.","Spade → soil, seeds → bed. Level wins grow your flowers.")
		else:
			var flowers: Array=g().farm.draft.flowers
			text_value=words("Перетащи готовый букет покупателю у кассы.","Drag the finished bouquet to the customer at checkout.") if g().farm.draft.wrapped else words("Перетащи бумагу на цветы, чтобы завернуть букет.","Drag wrapping paper over the flowers to wrap them.") if not flowers.is_empty() else words("Перетащи цветы из витрин на букетный стол — до трёх цветков.","Drag flowers from the displays onto the bouquet table — up to three stems.")
	guidance_changed.emit(text_value)

func near(point: Vector2, at: Vector3, radius: float=.85) -> bool:
	var center: Vector2=stage.project(at+Vector3(0,.45,0))
	var edge: Vector2=stage.project(at+Vector3(radius,.45,0))
	return center.distance_to(point)<maxf(26,center.distance_to(edge))

func source_at(point: Vector2) -> Array:
	var candidates: Array=[]
	if mode=="nursery":
		for i in 2: candidates.append(["spade" if i==0 else "watering",i,TOOL_POS[i],.9])
		for i in 6: candidates.append(["seed",i,seed_pos(i),.75])
		for i in 6: candidates.append(["bed",i,BED_POS[i],1.4])
	else:
		if g().farm.draft.wrapped and near(point,DESK+Vector3(0,1.8,0),1.3): return ["bouquet",0]
		for i in g().farm.draft.flowers.size(): candidates.append(["draft",i,draft_pos(i),.55])
		for i in 3: candidates.append(["paper",i,paper_pos(i),.7])
		for i in 6: candidates.append(["flower",i,STOCK_POS[i]+Vector3(0,.9,0),1.0])
	var closest: Array=[]; var distance_value:=INF
	for candidate in candidates:
		var at: Vector3=candidate[2]
		if not near(point,at,float(candidate[3])): continue
		var distance_to_point: float=stage.project(at+Vector3(0,.45,0)).distance_to(point)
		if distance_to_point<distance_value:
			distance_value=distance_to_point; closest=[candidate[0],candidate[1]]
	return closest

func _gui_input(event: InputEvent) -> void:
	if busy: return
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed:
			grab_focus(); press_position=event.position; pointer=event.position; moved=false
			if not selected_item.is_empty():
				perform_drop(selected_item,selected_id,event.position); selected_item=""; selected_id=-1; clear_targets(); accept_event(); return
			var source: Array=source_at(event.position)
			if not source.is_empty(): start_drag(str(source[0]),int(source[1]))
		elif not drag_kind.is_empty():
			var kind: String=drag_kind; var id: int=drag_id
			cancel_drag()
			if moved: perform_drop(kind,id,event.position)
			elif kind=="bed":
				selected_bed=id; bed_selected.emit(id); message=bed_description(id)
				var bed: Variant=g().farm.beds.get(str(id))
				if bed is Dictionary and int(bed.growth)>=3:
					selected_item="bed"; selected_id=id; message=words("Коснись корзины, чтобы собрать цветы.","Tap the basket to harvest these flowers.")
					show_targets("bed")
				update_guidance()
			else:
				selected_item=kind; selected_id=id; message=words("Теперь коснись места назначения или перетащи предмет.","Now tap the destination, or drag the item.")
				if kind in ["seed","flower"]:
					var spec: Array=Farm.SPECIES[id]
					message=words(spec[0],spec[1])+words(" · Аромат %d · Стойкость %d · Пышность %d"," · Scent %d · Freshness %d · Fullness %d") % [spec[3],spec[4],spec[5]]
				show_targets(kind)
				update_guidance()
		accept_event()
	elif event is InputEventMouseMotion and not drag_kind.is_empty():
		pointer=event.position; moved=moved or pointer.distance_to(press_position)>8
		if is_instance_valid(dragged): dragged.position=stage.ground_at(pointer,1.8)
		accept_event()
	elif event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
		cancel_drag(); selected_item=""; message=""; update_guidance(); accept_event()
	elif event is InputEventKey and event.pressed:
		var targets: Array=keyboard_targets()
		if event.keycode in [KEY_LEFT,KEY_UP,KEY_RIGHT,KEY_DOWN]:
			keyboard_cursor=posmod(keyboard_cursor+(-1 if event.keycode in [KEY_LEFT,KEY_UP] else 1),targets.size())
			if not is_instance_valid(focus_marker):
				var b:=Models.new(); var torus:=TorusMesh.new(); torus.inner_radius=.43; torus.outer_radius=.49; torus.rings=24; torus.ring_segments=6; b.part(torus,Vector3.ZERO,Vector3.ONE,Color("ffe391"))
				focus_marker=MeshInstance3D.new(); focus_marker.mesh=b.finish(); stage.world.add_child(focus_marker)
			focus_marker.position=targets[keyboard_cursor]+Vector3(0,.1,0); accept_event()
		elif event.keycode in [KEY_ENTER,KEY_SPACE]:
			var press:=InputEventMouseButton.new(); press.button_index=MOUSE_BUTTON_LEFT; press.position=stage.project(targets[keyboard_cursor]+Vector3(0,.45,0)); press.pressed=true
			_gui_input(press); press.pressed=false; _gui_input(press); accept_event()

func keyboard_targets() -> Array:
	var targets: Array=[]
	if mode=="nursery":
		for point in TOOL_POS: targets.append(point)
		for i in 6: targets.append(seed_pos(i))
		for point in BED_POS: targets.append(point)
	else:
		for point in STOCK_POS: targets.append(point+Vector3(0,.9,0))
		for i in 3: targets.append(paper_pos(i))
		for i in 3: targets.append(draft_pos(i))
		targets.append(CASH+Vector3(0,.6,-.5))
	return targets

func start_drag(kind: String, id: int) -> void:
	drag_kind=kind; drag_id=id
	var variant: int=id; var model_kind: String=kind
	if kind=="bed":
		var bed: Variant=g().farm.beds.get(str(id))
		if not bed is Dictionary or int(bed.growth)<3: return
		model_kind="flower"; variant=int(bed.species)
	if kind=="draft": model_kind="flower"; variant=int(g().farm.draft.flowers[id])
	if kind=="flower" and int(g().farm.stock[id])<=int(Farm.draft_counts(g())[id]): message=words("Этот сорт закончился — вырасти ещё в огороде.","This variety is sold out — grow more in the nursery."); update_guidance(); return
	if kind=="bouquet": dragged=make_bouquet(g().farm.draft.flowers,int(g().farm.draft.wrap)); stage.world.add_child(dragged)
	elif kind=="paper": dragged=stage.block(Vector3.ZERO,Vector3(1,.06,.7),PAPER_COLORS[id])
	else: dragged=stage.add(model_kind,Vector3.ZERO,1.2,variant)
	dragged.position=stage.ground_at(pointer,1.8)
	show_targets(kind)

func show_targets(kind: String) -> void:
	clear_targets()
	var points: Array=[]
	if kind in ["seed","watering","spade"]:
		for point in BED_POS: points.append(point+Vector3(0,.33,0))
	elif kind=="bed": points.append(TOOL_POS[2]+Vector3(0,.15,0))
	elif kind in ["paper","flower"]: points.append(DESK+Vector3(0,1.80,0))
	elif kind=="bouquet": points.append(CASH+Vector3(0,1.04,0))
	elif kind=="draft":
		for point in STOCK_POS: points.append(point+Vector3(0,1.13,0))
	for point in points: target_markers.append(stage.add("focus",point))

func clear_targets() -> void:
	for node in target_markers: node.queue_free()
	target_markers.clear()

func cancel_drag() -> void:
	if is_instance_valid(dragged): dragged.queue_free()
	dragged=null; drag_kind=""; drag_id=-1
	clear_targets()

func perform_drop(kind: String, id: int, point: Vector2) -> bool:
	message=""
	var success:=false
	var target:=-1
	if mode=="nursery":
		for i in 6:
			if near(point,BED_POS[i],1.4): target=i; break
		if kind=="spade" and target>=0:
			if g().farm.beds.has(str(target)):
				if int(g().farm.beds[str(target)].growth)>=3: message=words("Сначала собери созревшие цветы в корзину.","Harvest the blooming flowers first.")
				else: confirm_replant(target); return false
			else: success=game.store.garden_transaction(func(data): return Farm.prepare(data,target))
		elif kind=="watering" and target>=0: success=game.store.garden_transaction(func(data): return Farm.water(data,target))
		elif kind=="seed" and target>=0:
			if g().farm.beds.has(str(target)): message=words("Эта грядка занята. Для смены сорта используй лопатку.","This bed is occupied. Use the spade to change its variety.")
			elif target not in g().farm.prepared: message=words("Сначала подготовь землю лопаткой.","Prepare the soil with the spade first.")
			elif g().earned.size()<int(Farm.SPECIES[id][6]): message=words("Этот сорт откроется после %d побед.","This variety unlocks after %d wins.") % int(Farm.SPECIES[id][6])
			elif int(g().coins)<int(Farm.SPECIES[id][7]): message=words("На семена нужно %d монет. Новые уровни дают монеты.","Seeds cost %d coins. New levels earn coins.") % int(Farm.SPECIES[id][7])
			else: success=game.store.garden_transaction(func(data): return Farm.plant(data,target,id))
		elif kind=="bed" and near(point,TOOL_POS[2],1.2):
			success=game.store.garden_transaction(func(data): return Farm.harvest(data,id)>0)
			if success: message=words("Цветы в корзине! Отнеси их в магазин через сад.","Flowers collected! Visit the shop through the garden.")
	else:
		if kind=="flower" and near(point,DESK+Vector3(0,1.7,0),2):
			var position_value: int=-1
			for i in g().farm.draft.flowers.size():
				if near(point,draft_pos(i),.6): position_value=i
			success=game.store.garden_transaction(func(data): return Farm.arrange(data,id,position_value))
		elif kind=="draft":
			for i in 6:
				if near(point,STOCK_POS[i]+Vector3(0,.9,0),1.1): success=game.store.garden_transaction(func(data): return Farm.return_flower(data,id)); break
		elif kind=="paper" and near(point,DESK+Vector3(0,1.7,0),2): success=game.store.garden_transaction(func(data): return Farm.wrap_bouquet(data,id))
		elif kind=="bouquet" and near(point,CASH+Vector3(0,.6,-.5),1.5):
			success=game.store.garden_transaction(func(data): return Farm.serve(data))
			if success: message=words("Спасибо за букет! +%d монет. Следующий покупатель ждёт.","Thank you! +%d coins. The next customer is waiting.") % int(g().farm.album.back().coins)
	if success:
		if game.sound!=null: game.sound.play_match("win" if kind in ["bouquet","bed"] else "swap")
		animate_feedback(point,kind)
		if kind=="bouquet": advance_queue()
	elif message.is_empty():
		if mode=="nursery" and target>=0:
			message=words("Эта земля уже подготовлена — возьми семена.","The soil is ready — choose seeds.") if kind=="spade" else words("Полив — один раз за урожай. Пройди ещё уровень, чтобы цветы выросли.","Water once per harvest. Win another level to grow the flowers.") if kind=="watering" else words("Проверь цену и число побед для этого сорта.","Check the price and wins needed for this variety.")
		elif kind=="bed": message=words("Цветы ещё растут. Полей их или пройди уровни.","Flowers are still growing. Water them or win levels.")
	refresh()
	return success

func confirm_replant(slot: int) -> void:
	busy=true
	var dialog:=ConfirmationDialog.new(); dialog.title=words("Освободить грядку?","Clear this bed?")
	dialog.dialog_text=words("Этот посев будет убран. Земля останется подготовленной для нового сорта; собранные цветы в корзине сохранятся.","This planting will be removed. The soil stays prepared for another variety; flowers already in your basket are kept.")
	dialog.get_label().autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	dialog.ok_button_text=words("Убрать посев","Clear planting"); dialog.cancel_button_text=words("Оставить","Keep it")
	for target in [dialog.get_ok_button(),dialog.get_cancel_button()]: target.custom_minimum_size=Vector2(160,100)
	dialog.confirmed.connect(func():
		if game.store.garden_transaction(func(data): return Farm.uproot(data,slot)):
			message=words("Земля готова для нового сорта.","The soil is ready for another variety."); refresh(); bed_selected.emit(slot)
	)
	dialog.canceled.connect(func(): busy=false)
	dialog.visibility_changed.connect(func(): if not dialog.visible: busy=false; dialog.queue_free())
	add_child(dialog); dialog.popup_centered(Vector2i(mini(580,int(game.size.x-48)),270))

func advance_queue() -> void:
	busy=true
	var leaving: MeshInstance3D=customers.pop_front()
	var tween:=create_tween(); tween.set_parallel(true)
	var duration:=.01 if game.store.data.settings.reduce_motion else .65
	tween.tween_property(leaving,"position",Vector3(5.6,0,3.5),duration).set_trans(Tween.TRANS_SINE)
	for i in customers.size(): tween.tween_property(customers[i],"position",queue_pos(i),duration).set_trans(Tween.TRANS_SINE)
	tween.chain().tween_callback(func():
		leaving.queue_free()
		customers.append(stage.add("person",queue_pos(2),1.1,(int(g().farm.orders_done)+2)%4))
		busy=false
	)

func animate_feedback(point: Vector2, kind: String) -> void:
	if game.store.data.settings.reduce_motion: return
	var object_kind: String="flower" if kind in ["bed","bouquet","seed"] else "ice" if kind=="watering" else "seed"
	var feedback: MeshInstance3D=stage.add(object_kind,stage.ground_at(point,.8),.6,0)
	var destination: Vector3=feedback.position+Vector3(0,1.2,0)
	var tween:=create_tween(); tween.set_parallel(true)
	tween.tween_property(feedback,"position",destination,.42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(feedback,"scale",Vector3.ONE*.01,.42)
	tween.chain().tween_callback(feedback.queue_free)

func bed_description(id: int) -> String:
	var bed: Variant=g().farm.beds.get(str(id))
	if not bed is Dictionary: return words("Перетащи сюда лопатку, затем пакет семян.","Drag the spade here, then a seed packet.")
	var spec: Array=Farm.SPECIES[int(bed.species)]
	return words(spec[0],spec[1])+words(" · Аромат %d · Стойкость %d · Урожай %d"," · Scent %d · Freshness %d · Yield %d") % [spec[3],spec[4],spec[5]]
