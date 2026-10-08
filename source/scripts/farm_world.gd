extends "res://scripts/farm_world_3d.gd"
## Keeps the tested transaction rules, replaces room rendering and picking entirely.
const NURSERY=preload("res://assets/nursery-interior.png")
const SHOP=preload("res://assets/shop-interior.png")
const Art=preload("res://scripts/match_art.gd")
const Stem=preload("res://scripts/stem_art.gd")
const Preview=preload("res://scripts/illustrated_preview.gd")
const CUSTOMERS=preload("res://assets/shop-customers.png")
const CUSTOMER_LOOKS=[0,1,2,0,3,1,0,3,2,3,1,2]
const QUEUE=[Vector2(.42,.335),Vector2(.66,.322),Vector2(.88,.309),Vector2(1.14,.302)]
var feedback_point:=Vector2.ZERO
var feedback_amount:=0.0
var queue_offset:=0.0
var labels: Control

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_STOP; focus_mode=Control.FOCUS_ALL; clip_contents=true
	labels=Control.new(); labels.mouse_filter=Control.MOUSE_FILTER_IGNORE; add_child(labels)
	resized.connect(refresh); refresh()

func room_rect() -> Rect2:
	# Fill available width; crop unused scenery at the top and bottom on shorter phones.
	var dimensions:=Vector2(size.x,size.x*1.5)
	return Rect2(Vector2(0,(size.y-dimensions.y)*.5),dimensions)

func point(uv: Vector2) -> Vector2: return room_rect().position+uv*room_rect().size

func projected(at: Vector3) -> Vector2:
	if mode=="nursery":
		if at.z>5.8: return point(Vector2(.14+(at.x+4.15)/1.66*.144,.858))
		if at.z>3.5:
			return point(Vector2(.24 if at.x<-2 else .38 if at.x<1 else .75,.744))
		return point(Vector2(.28 if at.x<0 else .75,.31+(at.z+2.8)/2.4*.103))
	if at.z<-2: return point(Vector2(.27,.275))
	if at.x>3.5 and at.z>3: return point(Vector2(.85,.638+(at.z-3.3)/1.05*.04))
	if at.z>3: return point(Vector2(.50+at.x*.09,.705))
	return point(Vector2(.325+at.x/3*.17,.354+(at.z+.6)/1.95*.088)+Vector2(.17,0))

func near(position_value: Vector2, at: Vector3, radius: float=.85) -> bool:
	if mode=="shop" and at.z<-2 and position_value.distance_to(point(QUEUE[0]-Vector2(0,.055)))<size.x*.10: return true
	var delta:=position_value-projected(at)
	var r:=maxf(22,size.x*.065*radius)
	return delta.length()<r

func badge(value: String, at: Vector2, width: float=80) -> void:
	var label:=Label.new(); label.text=value; label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size",maxi(15,int(size.x*.032)))
	label.add_theme_color_override("font_color",Color("fff8e5"))
	label.add_theme_color_override("font_shadow_color",Color("183a29")); label.add_theme_constant_override("shadow_offset_x",1); label.add_theme_constant_override("shadow_offset_y",2)
	label.position=at-Vector2(width/2,0); label.size=Vector2(width,25); label.mouse_filter=Control.MOUSE_FILTER_IGNORE; labels.add_child(label)

func refresh() -> void:
	if labels==null: return
	for child in labels.get_children(): labels.remove_child(child); child.queue_free()
	Farm.ensure(g())
	if mode=="nursery":
		for i in 6:
			var bed: Variant=g().farm.beds.get(str(i))
			var caption:=words("Земля","Soil")
			if bed is Dictionary: caption=words("Собрать","Harvest") if int(bed.growth)==3 else words("Рост %d/3","Growth %d/3") % int(bed.growth)
			elif i in g().farm.prepared: caption=words("Посадить","Plant")
			badge(caption,projected(BED_POS[i])+Vector2(0,size.x*.032),size.x*.32)
			var unlocked: bool=Farm.Estate.progress(g())>=int(Farm.SPECIES[i][6])
			badge(str(int(Farm.SPECIES[i][7])) if unlocked else words("%d разв.","%d points") % int(Farm.SPECIES[i][6]),projected(seed_pos(i))+Vector2(0,size.x*.023),size.x*.14)
		for i in 3: badge(words(["Лопатка","Лейка","Корзина"][i],["Spade","Water","Basket"][i]),projected(TOOL_POS[i])+Vector2(0,size.x*.075),size.x*.23)
	else:
		var counts: Array=Farm.draft_counts(g())
		for i in 6: badge(str(int(g().farm.stock[i])-int(counts[i])),projected(STOCK_POS[i])+Vector2(0,size.x*.035),size.x*.13)
		badge(words("Касса","Checkout"),projected(CASH)+Vector2(0,size.x*.035),size.x*.28)
		var offer: Dictionary=Farm.bouquet(g(),counts)
		badge(words("Букет · %d монет","Bouquet · %d coins") % int(offer.coins) if offer.get("valid",false) else words("Букетный стол","Bouquet table"),projected(DESK)+Vector2(0,size.x*.08),size.x*.48)
		var customer: Array=Farm.order(g())
		badge(str(customer[1 if game.store.data.settings.language=="en" else 0]).split(" · ")[0],point(Vector2(.61,.065)),size.x*.42)
		badge(words(["Любит аромат","Любит стойкость","Любит пышность"][int(customer[2])],["Loves fragrance","Loves freshness","Loves fullness"][int(customer[2])]),point(Vector2(.61,.097)),size.x*.48)
		if g().farm.draft.wrapped:
			var visual:=Preview.new(); visual.kind="bouquet"; visual.flowers=g().farm.draft.flowers; visual.wrap_id=int(g().farm.draft.wrap)
			visual.size=Vector2.ONE*size.x*.23; visual.position=projected(DESK)-visual.size/2; labels.add_child(visual)
	if mode=="shop":
		badge(words("Секатор +8","Trim +8"),point(Vector2(.17,.672)),size.x*.25)
		badge(words("Бант +8","Bow +8"),point(Vector2(.17,.777)),size.x*.23)
		badge(words("Бумага: ","Paper: ")+words(["крафт","мята","лаванда"][int(g().farm.orders_done)%3],["kraft","mint","lavender"][int(g().farm.orders_done)%3])+" +6",point(Vector2(.61,.128)),size.x*.48)
	else: badge(words("Компост · %d","Compost · %d") % (5-Farm.Estate.room_rank(g(),1)),point(Vector2(.55,.81)),size.x*.23)
	update_guidance(); queue_redraw()

func _draw() -> void:
	draw_texture_rect(NURSERY if mode=="nursery" else SHOP,room_rect(),false)
	if mode=="nursery":
		for i in 6:
			var at:=projected(BED_POS[i]); var bed: Variant=g().farm.beds.get(str(i))
			if bed is Dictionary:
				var growth:=int(bed.growth)
				for j in 3:
					var p:=at+Vector2((j-1)*size.x*.058,-size.x*.025)
					if growth>0: Stem.draw(self,p,size.x*(.012+growth*.006),int(bed.species))
					else: draw_circle(p,3,Color("bada8b"))
				if bed.watered: draw_circle(at+Vector2(size.x*.115,0),4,Color("86e3e9"))
			elif i in g().farm.prepared: draw_arc(at, size.x*.07,0,TAU,32,Color("ead398"),2,true)
		for i in 6: Art.draw_icon(self,projected(seed_pos(i))-Vector2(0,size.x*.025),size.x*.045,i)
	else:
		var counts: Array=Farm.draft_counts(g())
		for i in 6:
			var amount:=int(g().farm.stock[i])-int(counts[i])
			if amount>0: Stem.draw(self,projected(STOCK_POS[i])+Vector2(0,size.x*.012),size.x*.043,i)
		if not g().farm.draft.wrapped:
			for i in 3:
				if i<g().farm.draft.flowers.size(): Stem.draw(self,projected(draft_pos(i)),size.x*.046,int(g().farm.draft.flowers[i]),g().farm.draft.get("trimmed",false))
				else: draw_arc(projected(draft_pos(i)),size.x*.032,0,TAU,32,Color("ffedbf"),2,true)
		for i in 3:
			draw_customer(int(g().farm.orders_done)+i,QUEUE[i].lerp(QUEUE[i+1],queue_offset))
		if queue_offset>0:
			draw_customer(int(g().farm.orders_done)-1,QUEUE[0].lerp(Vector2(1.04,.305),1-queue_offset),minf(1,queue_offset*3))
	if mode=="shop":
		Stem.shears(self,point(Vector2(.17,.64)),size.x*.039)
		draw_bow(point(Vector2(.17,.74)),size.x*.043)
		if g().farm.draft.get("tied",false): draw_bow(projected(DESK)+Vector2(0,size.x*.05),size.x*.035)
	else:
		var p:=point(Vector2(.55,.744)); draw_style_box(preload("res://scripts/garden_hud.gd").plate(Color("947151"),12),Rect2(p-Vector2(23,30),Vector2(46,60)))
		draw_line(p+Vector2(0,18),p-Vector2(0,16),Color("c5e79b"),4,true)
	if not selected_item.is_empty() or not drag_kind.is_empty():
		var kind:=selected_item if not selected_item.is_empty() else drag_kind
		var destinations: Array=[]
		if kind in ["spade","watering","seed","compost"]: destinations=BED_POS
		elif kind=="bed": destinations=[TOOL_POS[2]]
		elif kind=="bouquet": destinations=[CASH]
		elif kind=="draft": destinations=STOCK_POS
		else: destinations=[DESK]
		for at in destinations: draw_arc(projected(at),size.x*.065,0,TAU,40,Color("ffe19a"),3,true)
	if moved and not drag_kind.is_empty():
		if drag_kind in ["flower","seed","bed","draft"]:
			var species:=drag_id
			if drag_kind=="bed" and g().farm.beds.has(str(drag_id)): species=int(g().farm.beds[str(drag_id)].species)
			elif drag_kind=="draft": species=int(g().farm.draft.flowers[drag_id])
			Stem.draw(self,pointer,size.x*.055,species)
		else: draw_arc(pointer,size.x*.055,0,TAU,32,Color("fff0bc"),4,true)
	if feedback_amount>0: draw_arc(feedback_point,size.x*.1*(1-feedback_amount*.6),0,TAU,32,Color(1,.9,.6,feedback_amount),3,true)
	if has_focus() and keyboard_cursor>0:
		var targets:=keyboard_targets(); draw_arc(projected(targets[keyboard_cursor%targets.size()]),size.x*.055,0,TAU,32,Color.WHITE,3,true)

func source_at(position_value: Vector2) -> Array:
	if mode=="shop":
		if position_value.distance_to(point(Vector2(.17,.64)))<size.x*.055: return ["trim",0]
		if position_value.distance_to(point(Vector2(.17,.74)))<size.x*.055: return ["ribbon",0]
	elif position_value.distance_to(point(Vector2(.55,.744)))<size.x*.06: return ["compost",0]
	var candidates: Array=[]
	if mode=="nursery":
		for i in 2: candidates.append(["spade" if i==0 else "watering",i,TOOL_POS[i],.9])
		for i in 6: candidates.append(["seed",i,seed_pos(i),.75]); candidates.append(["bed",i,BED_POS[i],1.4])
	else:
		if g().farm.draft.wrapped and near(position_value,DESK,1.5): return ["bouquet",0]
		for i in g().farm.draft.flowers.size(): candidates.append(["draft",i,draft_pos(i),.65])
		for i in 3: candidates.append(["paper",i,paper_pos(i),.75])
		for i in 6: candidates.append(["flower",i,STOCK_POS[i],1.0])
	var best: Array=[]; var distance_value:=INF
	for candidate in candidates:
		var d:=position_value.distance_to(projected(candidate[2]))
		if near(position_value,candidate[2],candidate[3]) and d<distance_value: best=[candidate[0],candidate[1]]; distance_value=d
	return best

func _gui_input(event: InputEvent) -> void:
	if busy: return
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed:
			grab_focus(); pointer=event.position; press_position=pointer; moved=false
			if not selected_item.is_empty():
				perform_drop(selected_item,selected_id,pointer); selected_item=""; queue_redraw(); accept_event(); return
			var source:=source_at(pointer)
			if not source.is_empty(): drag_kind=str(source[0]); drag_id=int(source[1]); queue_redraw()
		elif not drag_kind.is_empty():
			var kind:=drag_kind; var id:=drag_id; drag_kind=""
			if moved: perform_drop(kind,id,event.position)
			elif kind=="bed":
				selected_bed=id; bed_selected.emit(id); message=bed_description(id)
				if g().farm.beds.has(str(id)) and int(g().farm.beds[str(id)].growth)==3: selected_item=kind; selected_id=id; message=words("Коснись корзины для сбора.","Tap the basket to harvest.")
			else:
				selected_item=kind; selected_id=id; message=words("Теперь коснись подсвеченного места.","Now tap the highlighted destination.")
				if kind in ["seed","flower"]:
					var spec: Array=Farm.SPECIES[id]
					message=words(spec[0],spec[1])+words(" · Аромат %d · Стойкость %d · Пышность %d. Теперь выбери место."," · Fragrance %d · Freshness %d · Fullness %d. Now choose a destination.") % [spec[3],spec[4],spec[5]]
			update_guidance(); queue_redraw()
		accept_event()
	elif event is InputEventMouseMotion and not drag_kind.is_empty(): pointer=event.position; moved=moved or pointer.distance_to(press_position)>8; queue_redraw(); accept_event()
	elif event is InputEventKey and event.pressed:
		var targets:=keyboard_targets()
		if event.keycode==KEY_ESCAPE: selected_item=""; drag_kind=""; message=""; update_guidance(); queue_redraw(); accept_event()
		elif event.keycode in [KEY_LEFT,KEY_UP,KEY_RIGHT,KEY_DOWN]: keyboard_cursor=posmod(keyboard_cursor+(-1 if event.keycode in [KEY_LEFT,KEY_UP] else 1),targets.size()); queue_redraw(); accept_event()
		elif event.keycode in [KEY_ENTER,KEY_SPACE]:
			var press:=InputEventMouseButton.new(); press.button_index=MOUSE_BUTTON_LEFT; press.position=projected(targets[keyboard_cursor]); press.pressed=true
			_gui_input(press); press.pressed=false; _gui_input(press); accept_event()

func advance_queue() -> void:
	busy=true; queue_offset=1
	var tween:=create_tween()
	tween.tween_method(func(value: float): queue_offset=value; queue_redraw(),1.0,0.0,.01 if game.store.data.settings.reduce_motion else .45)
	tween.tween_callback(func(): busy=false)

func update_guidance() -> void:
	if message.is_empty():
		if mode=="shop" and g().farm.draft.flowers.is_empty():
			var total:=0
			for amount_value in g().farm.stock: total+=int(amount_value)
			if total==0:
				guidance_changed.emit(words("Витрина пуста. Вернись в сад, зайди в огород и собери урожай в корзину.","The display is empty. Return to the garden, enter the nursery and harvest into the basket.")); return
		if mode=="nursery" and not g().farm.beds.is_empty():
			var waiting:=true
			for bed in g().farm.beds.values(): waiting=waiting and bool(bed.watered) and int(bed.growth)<3
			if waiting:
				guidance_changed.emit(words("Цветы политы. Нажми «К уровням»: новая победа приблизит урожай. Можно заново решить пройденный уровень.","Flowers are watered. Play levels to grow them toward harvest. You can solve an earlier level again.")); return
	super.update_guidance()

func draw_customer(order_id: int, uv: Vector2, opacity: float=1) -> void:
	var id: int=CUSTOMER_LOOKS[posmod(order_id,CUSTOMER_LOOKS.size())]
	var cell:=CUSTOMERS.get_size()/2
	var dimensions:=Vector2(size.x*.235,size.x*.3525)
	var feet:=point(uv)
	draw_set_transform(feet,0,Vector2(1,.3)); draw_circle(Vector2.ZERO,size.x*.033,Color(0.12,.10,.06,.18*opacity)); draw_set_transform(Vector2.ZERO)
	draw_texture_rect_region(CUSTOMERS,Rect2(feet-Vector2(dimensions.x/2,dimensions.y),dimensions),Rect2(Vector2(id%2,id/2)*cell,cell),Color(1,1,1,opacity),false,true)

func animate_feedback(at: Vector2, _kind: String) -> void:
	if game.store.data.settings.reduce_motion: return
	feedback_point=at; feedback_amount=1
	create_tween().tween_method(func(value: float): feedback_amount=value; queue_redraw(),1.0,0.0,.4)

func draw_bow(p: Vector2,r: float) -> void:
	for side in [-1,1]:
		draw_colored_polygon(PackedVector2Array([p,p+Vector2(side*r,-r*.6),p+Vector2(side*r,r*.4)]),Color("ef95ac"))
		draw_line(p,p+Vector2(side*r*.55,r),Color("cf6388"),r*.3,true)
	draw_circle(p,r*.2,Color("ffe0d0"))

func perform_drop(kind: String,id: int,at: Vector2) -> bool:
	if kind in ["trim","ribbon"]:
		var ok: bool=near(at,DESK,2) and game.store.garden_transaction(func(data): return Farm.finish_bouquet(data,kind))
		message=words("Стебли подрезаны: +8 монет к букету.","Stems trimmed: +8 coins.") if ok and kind=="trim" else words("Красивый бант: +8 монет к букету.","A lovely bow: +8 coins.") if ok else words("Секатор — до бумаги. Бант — после упаковки. Перенеси инструмент на стол.","Trim before wrapping; add a bow after wrapping. Move the tool to the table.")
		if ok: animate_feedback(at,kind)
		refresh(); return ok
	if kind=="compost":
		for slot in 6:
			if near(at,BED_POS[slot],1.4):
				var ok: bool=game.store.garden_transaction(func(data): return Farm.cultivate(data,slot))
				message=words("Почва подкормлена: +1 цветок при сборе.","Soil fed: +1 flower at harvest.") if ok else words("Подкорми растущие цветы один раз за урожай. Нужно %d монет.","Feed growing flowers once per harvest. Requires %d coins.") % (5-Farm.Estate.room_rank(g(),1))
				refresh(); return ok
		return false
	return super.perform_drop(kind,id,at)
