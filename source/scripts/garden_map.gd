extends Control
signal place_selected(kind: String,index: int)
signal view_changed(camera: Array)
signal cat_selected
const Rules=preload("res://scripts/garden_rules.gd")
const Flowers=preload("res://scripts/match_art.gd")
const BACKGROUND=preload("res://assets/garden-world.png")
const BEDS=preload("res://assets/garden-beds.png")
const DECOR=preload("res://assets/garden-decor.png")
const WORLD=Vector2(3200,2400)
var garden: Dictionary
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

func _ready() -> void:
	clip_contents=true
	sorted_plots=range(Rules.PLOT_COUNT)
	sorted_plots.sort_custom(func(a,b): return Rules.plot_position(a).y<Rules.plot_position(b).y)
	effects=preload("res://scripts/garden_life.gd").new(); effects.map=self; effects.reduced=reduced; add_child(effects)
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
	return (world-camera)*zoom+size/2

func _gui_input(event: InputEvent) -> void:
	if not interactive: return
	if event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_WHEEL_UP and event.pressed: zoom_by(1.15); accept_event()
		elif event.button_index==MOUSE_BUTTON_WHEEL_DOWN and event.pressed: zoom_by(1/1.15); accept_event()
		elif event.button_index==MOUSE_BUTTON_LEFT:
			if event.pressed:
				if camera_tween: camera_tween.kill()
				dragging=true; distance=0; focus_index=-1; grab_focus()
			elif dragging:
				dragging=false; changed()
				if distance<12: select_at(event.position)
			accept_event()
	elif event is InputEventMouseMotion and dragging:
		distance+=event.relative.length(); camera-=event.relative/zoom
		clamp_camera(); queue_redraw(); accept_event()
	elif event is InputEventKey and event.pressed:
		if event.keycode in [KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN]:
			camera+=Vector2(-180 if event.keycode==KEY_LEFT else 180 if event.keycode==KEY_RIGHT else 0,-180 if event.keycode==KEY_UP else 180 if event.keycode==KEY_DOWN else 0)
			changed(); accept_event()

func select_at(point: Vector2) -> void:
	if screen_point(Vector2(1520,790)).distance_to(point)<maxf(28,70*zoom):
		cat_selected.emit(); return
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

static func decor_texture(index: int) -> AtlasTexture:
	var result:=AtlasTexture.new(); result.atlas=DECOR
	var unit:=DECOR.get_width()/4.0
	result.region=Rect2(Vector2(index%4,index/4)*unit,Vector2.ONE*unit)
	result.filter_clip=true
	return result

func decor(center: Vector2,radius: float,index: int,alpha: float=1) -> void:
	var unit:=DECOR.get_width()/4.0
	draw_texture_rect_region(DECOR,Rect2(center-Vector2.ONE*radius,Vector2.ONE*radius*2),Rect2(Vector2(index%4,index/4)*unit,Vector2.ONE*unit),Color(1,1,1,alpha),false,true)

static func bed_texture(index: int) -> AtlasTexture:
	var result:=AtlasTexture.new(); result.atlas=BEDS
	var unit:=Vector2(BEDS.get_width()/3.0,BEDS.get_height()/2.0)
	result.region=Rect2(Vector2(index%3,index/3)*unit,unit); result.filter_clip=true
	return result

func visible_area() -> int:
	if selected>=0: return selected/6
	var center:=camera-Vector2(0,(occluded_bottom-100)/2/zoom)
	var nearest:=0
	var distance_to_center:=INF
	for slot in Rules.PLOT_COUNT:
		var distance_value: float=(Rules.plot_position(slot)*WORLD).distance_squared_to(center)
		if distance_value<distance_to_center: nearest=slot; distance_to_center=distance_value
	return nearest/6

func _draw() -> void:
	if garden.is_empty(): return
	draw_rect(Rect2(Vector2.ZERO,size),Color("254b32"))
	draw_set_transform(size/2-camera*zoom,0,Vector2.ONE*zoom)
	draw_texture_rect(BACKGROUND,Rect2(Vector2.ZERO,WORLD),false)
	var active_zone: int=visible_area()
	for slot in sorted_plots:
		var p: Vector2=Rules.plot_position(slot)*WORLD
		if not Rect2(Vector2.ZERO,size).grow(220*zoom).has_point(screen_point(p)): continue
		var id:=int(garden.plots.get(str(slot),-1))
		var ghost: bool=slot==selected and preview_item>=0
		if ghost: id=preview_item
		if slot==selected:
			draw_set_transform(size/2-camera*zoom+p*zoom,0,Vector2(1,.5)*zoom)
			draw_circle(Vector2.ZERO,115,Color(1,.87,.5,.25))
			draw_arc(Vector2.ZERO,114,0,TAU,40,Color("fff1a6"),5,true)
			draw_set_transform(size/2-camera*zoom,0,Vector2.ONE*zoom)
		if id>=0 and id<6:
			var unit:=Vector2(BEDS.get_width()/3.0,BEDS.get_height()/2.0)
			draw_texture_rect_region(BEDS,Rect2(p-Vector2(115,170),Vector2.ONE*230),Rect2(Vector2(id%3,id/3)*unit,unit),Color(1,1,1,.72 if ghost else 1),false,true)
		elif id>=6: decor(p-Vector2(0,58),110,int(Rules.ITEMS[id][3]),.72 if ghost else 1)
		elif interactive and editing and slot/6==active_zone:
			draw_circle(p,32,Color(.13,.29,.20,.28),true,-1,true)
			draw_arc(p,32,0,TAU,24,Color("fff1b9"),3,true)
			draw_line(p-Vector2(12,0),p+Vector2(12,0),Color("fff8dc"),4,true)
			draw_line(p-Vector2(0,12),p+Vector2(0,12),Color("fff8dc"),4,true)
	# Commemorative landmarks are part of the world, independent of paid plots.
	for id in garden.get("story",{}).get("milestones",[]):
		var gift: Array=Rules.Story.MILESTONES[int(id)]
		var place: Vector2=gift[6]*WORLD
		if Rect2(Vector2.ZERO,size).grow(150*zoom).has_point(screen_point(place)):
			decor(place-Vector2(0,55),90,int(gift[5]))
	var next_repair: int=-1
	for i in Rules.REPAIRS.size():
		if i not in garden.repairs: next_repair=i; break
	for index in Rules.REPAIRS.size():
		var restored: bool=index in garden.repairs
		var p: Vector2=Rules.REPAIR_POS[index]*WORLD
		if restored:
			var choice: int=int(garden.get("story",{}).get("styles",{}).get(str(index),0))
			var color: Color=[Color("b8b5ff"),Color("ff94c0"),Color("ffe590")][choice]
			for side in [-1,1]:
				var pos:=p+Vector2(side*145,20)
				decor(pos,52,3 if choice==1 else 8 if choice==2 else 2)
				draw_arc(pos+Vector2(0,22),48,0,PI,16,color,4,true)
		if index==0 and restored: continue
		decor(p-Vector2(0,70),270 if index==2 else 210 if index==3 else 170 if index==1 else 145,int(Rules.REPAIRS[index][5 if restored else 4]))
		if interactive and index==next_repair:
			var pin:=p+Vector2(0,76)
			draw_circle(pin+Vector2(0,6),35,Color(.1,.22,.1,.3),true,-1,true)
			draw_circle(pin,34,Color("fff3c7"),true,-1,true)
			draw_arc(pin,34,0,TAU,28,Color("cf9e43"),4,true)
			draw_string(ThemeDB.fallback_font,pin+Vector2(-7,13),"!",HORIZONTAL_ALIGNMENT_LEFT,-1,40,Color("846025"))
	draw_set_transform(Vector2.ZERO)
	if garden.get("story",{}).get("evening",false):
		draw_rect(Rect2(Vector2.ZERO,size),Color(.06,.10,.25,.40))
	# Lightweight top shade keeps floating labels legible, without a full-screen filter.
	if interactive:
		for i in 12:
			draw_rect(Rect2(0,i*14,size.x,15),Color(.04,.16,.12,.32*(1-float(i)/12)))
