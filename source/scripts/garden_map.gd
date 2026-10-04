extends Control
signal place_selected(kind: String,index: int)
signal view_changed(camera: Array)
signal cat_selected
signal nursery_selected
signal shop_selected
signal tapped
const Rules=preload("res://scripts/garden_rules.gd")
const WORLD=Vector2(3200,2400)
const NURSERY_POS=Vector2(.60,.27)
const BUSINESS_POS=Vector2(.375,.53)
const EXTRA_POS=[Vector2(.83,.42),Vector2(.35,.69)]
var garden: Dictionary
var english:=false
var interactive:=true
var editing:=true
var presentation:=false
var occluded_bottom:=0.0
var focus_index:=-1
var focus_kind:="plot"
var selected:=-1
var preview_item:=-1
var camera:=Vector2(1600,1400)
var zoom:=0.35
var dragging:=false
var distance:=0.0
var fit_pending:=false
var sorted_plots: Array=[]
var reduced:=false
var effects: Control
var camera_tween: Tween
var stage: Control
var models: Node3D
var model_nodes: Dictionary={}
var last_zoom: float=-1
var last_camera:=Vector2(-1,-1)
var last_size:=Vector2.ZERO

func _ready() -> void:
	clip_contents=true
	sorted_plots=range(Rules.PLOT_COUNT)
	sorted_plots.sort_custom(func(a,b): return Rules.plot_position(a).y<Rules.plot_position(b).y)
	stage=preload("res://scripts/scene_3d.gd").new(); add_child(stage); stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	models=Node3D.new(); stage.world.add_child(models)
	build_world()
	focus_mode=Control.FOCUS_ALL if interactive else Control.FOCUS_NONE
	mouse_filter=Control.MOUSE_FILTER_STOP if interactive else Control.MOUSE_FILTER_IGNORE
	if interactive:
		camera=Vector2(garden.camera[0],garden.camera[1]); zoom=float(garden.camera[2])
	if presentation: camera=WORLD*Vector2(.48,.41)
	resized.connect(adjust)
	adjust()

func adjust() -> void:
	if not interactive or fit_pending: overview(false)
	elif presentation: zoom=maxf(size.x/WORLD.x,size.y/WORLD.y)*1.14
	else: zoom=maxf(zoom,maxf(size.x/WORLD.x,size.y/WORLD.y))
	if focus_index>=0: center_focus()
	clamp_camera(); queue_redraw()

func clamp_camera() -> void:
	var half:=size/(2*zoom)
	camera.x=WORLD.x/2 if half.x>=WORLD.x/2 else clampf(camera.x,half.x,WORLD.x-half.x)
	var max_y:=WORLD.y-half.y+occluded_bottom/zoom
	camera.y=WORLD.y/2 if max_y<half.y else clampf(camera.y,half.y,max_y)

func overview(notify: bool=true) -> void:
	if size.x<1 or size.y<1:
		fit_pending=true; return
	fit_pending=false
	focus_index=-1
	zoom=maxf(size.x/WORLD.x,size.y/WORLD.y)*1.02 if interactive else maxf(.1,minf(size.x/WORLD.x,size.y/WORLD.y))
	camera=WORLD/2
	queue_redraw()
	if notify: changed()

func changed() -> void:
	clamp_camera(); queue_redraw()
	view_changed.emit([camera.x,camera.y,zoom])

func zoom_by(factor: float) -> void:
	focus_index=-1
	var target: float=clampf(zoom*factor,maxf(.18,maxf(size.x/WORLD.x,size.y/WORLD.y)),1.05)
	if camera_tween: camera_tween.kill()
	if reduced: zoom=target; changed(); return
	camera_tween=create_tween()
	camera_tween.tween_method(func(value: float): zoom=value; clamp_camera(); queue_redraw(),zoom,target,.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	camera_tween.tween_callback(changed)

func focus_place(kind: String,index: int) -> void:
	focus_kind=kind; focus_index=index
	zoom=maxf(.65,maxf(size.x/WORLD.x,size.y/WORLD.y)); center_focus(); changed()

func center_focus() -> void:
	camera=(Rules.plot_position(focus_index) if focus_kind=="plot" else Rules.REPAIR_POS[focus_index])*WORLD
	camera.y+=(occluded_bottom-100)/2/zoom

func screen_point(world: Vector2) -> Vector2:
	if is_instance_valid(stage) and stage.camera!=null: return stage.project(Vector3(world.x/100,0,world.y/100))
	return (world-camera)*zoom+size/2

func _gui_input(event: InputEvent) -> void:
	if not interactive: return
	if event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_WHEEL_UP and event.pressed: zoom_by(1.15); accept_event()
		elif event.button_index==MOUSE_BUTTON_WHEEL_DOWN and event.pressed: zoom_by(1/1.15); accept_event()
		elif event.button_index==MOUSE_BUTTON_LEFT:
			if event.pressed:
				if camera_tween: camera_tween.kill()
				dragging=true; distance=0; focus_index=-1; grab_focus(); tapped.emit()
			elif dragging:
				dragging=false; changed()
				if distance<12: select_at(event.position)
			accept_event()
	elif event is InputEventMouseMotion and dragging:
		distance+=event.relative.length()
		if stage.size.x<1 or stage.size.y<1: camera-=event.relative/maxf(.1,zoom)
		else:
			var current: Vector3=stage.ground_at(event.position)
			var previous: Vector3=stage.ground_at(event.position-event.relative)
			camera-=Vector2(current.x-previous.x,current.z-previous.z)*100
		clamp_camera(); queue_redraw(); accept_event()
	elif event is InputEventKey and event.pressed:
		if event.keycode in [KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN]:
			camera+=Vector2(-180 if event.keycode==KEY_LEFT else 180 if event.keycode==KEY_RIGHT else 0,-180 if event.keycode==KEY_UP else 180 if event.keycode==KEY_DOWN else 0)
			changed(); accept_event()

func select_at(point: Vector2) -> void:
	if screen_point(Vector2(1520,790)).distance_to(point)<maxf(28,70*zoom):
		cat_selected.emit(); return
	if screen_point(NURSERY_POS*WORLD).distance_to(point)<maxf(56,165*zoom):
		nursery_selected.emit(); return
	if screen_point(BUSINESS_POS*WORLD).distance_to(point)<maxf(58,210*zoom):
		shop_selected.emit(); return
	for id in EXTRA_POS.size():
		if id in garden.get("farm",{}).get("buildings",[]) and screen_point(EXTRA_POS[id]*WORLD).distance_to(point)<maxf(50,125*zoom):
			if id==0: nursery_selected.emit()
			else: shop_selected.emit()
			return
	var nearest:=-1
	var best:=maxf(28,76*zoom)
	for slot in Rules.PLOT_COUNT:
		var d:=screen_point(Rules.plot_position(slot)*WORLD).distance_to(point)
		if d<best: nearest=slot; best=d
	if nearest>=0:
		place_selected.emit("plot",nearest); return
	for index in Rules.REPAIRS.size():
		if screen_point(Rules.REPAIR_POS[index]*WORLD).distance_to(point)<maxf(40,180*zoom):
			place_selected.emit("repair",index); return

func visible_area() -> int:
	if selected>=0: return selected/6
	var center:=camera-Vector2(0,(occluded_bottom-100)/2/zoom)
	var nearest:=0
	var distance_to_center:=INF
	for slot in Rules.PLOT_COUNT:
		var distance_value: float=(Rules.plot_position(slot)*WORLD).distance_squared_to(center)
		if distance_value<distance_to_center: nearest=slot; distance_to_center=distance_value
	return nearest/6

func _process(_delta: float) -> void:
	if not is_instance_valid(stage) or stage.camera==null: return
	if last_zoom!=zoom or last_camera!=camera or last_size!=size:
		stage.pose(Vector3(camera.x/100,0,camera.y/100),maxf(4,size.y/maxf(.1,zoom)/100))
		stage.camera.position=Vector3(camera.x/100,18,camera.y/100+22); stage.camera.look_at(Vector3(camera.x/100,0,camera.y/100))
		last_zoom=zoom; last_camera=camera; last_size=size

func build_world() -> void:
	var Models=preload("res://scripts/models_3d.gd")
	stage.block(Vector3(16,-.45,12),Vector3(36,.8,28),Color("8eb977"))
	stage.block(Vector3(16,-.02,12),Vector3(1.6,.06,22),Color("e1c99a"))
	stage.block(Vector3(16,-.01,10),Vector3(26,.05,1.4),Color("e8d5b1"))
	var scenery=Models.new()
	for i in 20:
		var point:=Vector3(3.5+fposmod(i*7.31,25.0),-.09,3+fposmod(i*4.17,18.0))
		scenery.ball(point,Vector3(3.5,.13,2.7),Color("99be7b") if i%2==0 else Color("a6c783"))
	for i in 30:
		var point:=Vector3(15.25 if i%2==0 else 16.75,.045,1+i*.72)
		scenery.ball(point,Vector3(.23,.09,.18),Color("d3c5a5"))
	for i in 14:
		var point:=Vector3(7+fposmod(i*3.81,18),.11,4+fposmod(i*5.34,15))
		if point.distance_to(Vector3(16,0,10))<2.5: continue
		for j in 3: scenery.ball(point+Vector3((j-1)*.22,.25,0),Vector3(.6,.55,.7),Color("82ad68"))
	scenery.cylinder(Vector3(24,.02,17),1.6,.05,Color("72bdc9"))
	for i in 16:
		var a:=i*TAU/16
		scenery.ball(Vector3(24+sin(a)*1.64,.04,17+cos(a)*1.64),Vector3(.33,.18,.32),Color("d3d3b3"))
	for side in [-1,1]:
		for i in 17:
			scenery.box(Vector3(16+side*.88,.04,1.5+i*1.25),Vector3(.14,.13,1.18),Color("c8b58c"))
	for i in 25:
		var point:=Vector3(4+fposmod(i*5.83,25),0,2+fposmod(i*3.77,20))
		if absf(point.x-16)<1.5 or absf(point.z-10)<1.3: continue
		for side in [-1,1]: scenery.ball(point+Vector3(side*.12,.08,0),Vector3(.06,.3,.2),Color("59a750"),Vector3(0,.5,side*.35))
	var detail:=MeshInstance3D.new(); detail.mesh=scenery.finish(); stage.world.add_child(detail)
	for i in 16:
		var point:=Vector3(6+fposmod(i*7.27,21.0),0,3+fposmod(i*5.77,18.0))
		if absf(point.x-16)<1.5: continue
		stage.add("flower" if 0 in garden.repairs else "bud",point,.50,i%6)
	for i in 24:
		var x: float=.7 if i%2==0 else 31.3
		var tree: MeshInstance3D=stage.add("tree",Vector3(x,0,1+int(i/2)*2),1.0+(i%3)*.12,i)
	for i in 15:
		stage.add("tree",Vector3(1+i*2.1,0,.2),.8,i)
		stage.add("tree",Vector3(1+i*2.1,0,23.8),.9,i)
	stage.add("house",Vector3(10,0,5),1.5)
	var nursery: Vector2=NURSERY_POS*WORLD/100
	stage.add("greenhouse",Vector3(nursery.x,0,nursery.y),1.35)
	stage.title("NURSERY" if english else "ОГОРОД",Vector3(nursery.x,3.4,nursery.y),42)
	var shop: Vector2=BUSINESS_POS*WORLD/100
	stage.add("shop",Vector3(shop.x,0,shop.y),1.35,int(garden.get("farm",{}).get("shop_tier",0)))
	stage.title("SHOP" if english else "МАГАЗИН",Vector3(shop.x,3.6,shop.y),42)
	for i in Rules.REPAIRS.size():
		var point: Vector2=Rules.REPAIR_POS[i]*WORLD/100
		var restored: bool=i in garden.repairs
		var kind: String=["gate","fountain","greenhouse","shop","pergola"][i]
		stage.add(kind,Vector3(point.x,0,point.y),1.2 if restored else .85)
		if not restored: stage.title("!",Vector3(point.x,1.7,point.y),72)
	for id in garden.get("farm",{}).get("buildings",[]):
		var point: Vector2=EXTRA_POS[int(id)]*WORLD/100
		stage.add("house" if int(id)==0 else "counter",Vector3(point.x,0,point.y),.85)
	for slot in Rules.PLOT_COUNT:
		var point: Vector2=Rules.plot_position(slot)*WORLD/100
		var id: int=int(garden.plots.get(str(slot),-1))
		if slot==selected and preview_item>=0: id=preview_item
		if id>=0:
			if id<6:
				stage.add("bed",Vector3(point.x,0,point.y),.8)
				for j in 3: stage.add("flower",Vector3(point.x+(j-1)*.45,.25,point.y),1.25,id)
			else: stage.add(["bench","lamp","birdhouse","urn","cart","hive","rabbit","sundial"][id-6],Vector3(point.x,0,point.y),.85)
		elif editing:
			var b=Models.new(); b.cylinder(Vector3.ZERO,.48,.05,Color("c9d79e"))
			var empty:=MeshInstance3D.new(); empty.mesh=b.finish(); empty.position=Vector3(point.x,.02,point.y); stage.world.add_child(empty)
	for id in garden.get("story",{}).get("milestones",[]):
		var gift: Array=Rules.Story.MILESTONES[int(id)]
		var point: Vector2=gift[6]*WORLD/100
		stage.add("fountain" if int(id)%3==0 else "bench" if int(id)%3==1 else "lamp",Vector3(point.x,0,point.y),.65)
	var cat=Models.new()
	cat.ball(Vector3(0,.22,0),Vector3(.65,.45,.42),Color("dbb07c")); cat.ball(Vector3(-.23,.43,0),Vector3(.33,.33,.33),Color("e3bc88"))
	for side in [-1,1]: cat.cylinder(Vector3(-.23,.63,side*.10),.08,.17,Color("e3bc88"),0)
	var cat_model:=MeshInstance3D.new(); cat_model.mesh=cat.finish(); cat_model.position=Vector3(15.2,0,7.9); stage.world.add_child(cat_model)
	if garden.get("story",{}).get("evening",false):
		stage.sun.light_color=Color("bcaed8"); stage.sun.light_energy=.5
	stage.sun.shadow_enabled=not reduced

func _draw() -> void:
	pass
