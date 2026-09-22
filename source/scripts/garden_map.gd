extends Control
signal place_selected(kind: String,index: int)
signal view_changed(camera: Array)
const Rules=preload("res://scripts/garden_rules.gd")
const Flowers=preload("res://scripts/match_art.gd")
const BACKGROUND=preload("res://assets/garden-world.png")
const DECOR=preload("res://assets/garden-decor.png")
const WORLD=Vector2(3200,2400)
var garden: Dictionary
var interactive:=true
var selected:=-1
var preview_item:=-1
var camera:=Vector2(1600,1400)
var zoom:=0.35
var dragging:=false
var distance:=0.0
var fit_pending:=false

func _ready() -> void:
	clip_contents=true
	focus_mode=Control.FOCUS_ALL if interactive else Control.FOCUS_NONE
	mouse_filter=Control.MOUSE_FILTER_STOP if interactive else Control.MOUSE_FILTER_IGNORE
	if interactive:
		camera=Vector2(garden.camera[0],garden.camera[1]); zoom=float(garden.camera[2])
	resized.connect(adjust)
	adjust()

func adjust() -> void:
	if not interactive or fit_pending: overview(false)
	clamp_camera(); queue_redraw()

func clamp_camera() -> void:
	var half:=size/(2*zoom)
	for axis in 2:
		camera[axis]=WORLD[axis]/2 if half[axis]>=WORLD[axis]/2 else clampf(camera[axis],half[axis],WORLD[axis]-half[axis])

func overview(notify: bool=true) -> void:
	if size.x<1 or size.y<1:
		fit_pending=true; return
	fit_pending=false
	zoom=maxf(.1,minf(size.x/WORLD.x,size.y/WORLD.y))
	camera=WORLD/2
	queue_redraw()
	if notify: changed()

func changed() -> void:
	clamp_camera(); queue_redraw()
	view_changed.emit([camera.x,camera.y,zoom])

func zoom_by(factor: float) -> void:
	zoom=clampf(zoom*factor,.18,.85); changed()

func focus_place(kind: String,index: int) -> void:
	camera=(Rules.plot_position(index) if kind=="plot" else Rules.REPAIR_POS[index])*WORLD
	zoom=.5; changed()

func screen_point(world: Vector2) -> Vector2:
	return (world-camera)*zoom+size/2

func _gui_input(event: InputEvent) -> void:
	if not interactive: return
	if event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_WHEEL_UP and event.pressed: zoom_by(1.15); accept_event()
		elif event.button_index==MOUSE_BUTTON_WHEEL_DOWN and event.pressed: zoom_by(1/1.15); accept_event()
		elif event.button_index==MOUSE_BUTTON_LEFT:
			if event.pressed: dragging=true; distance=0; grab_focus()
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

func _draw() -> void:
	if garden.is_empty(): return
	draw_rect(Rect2(Vector2.ZERO,size),Color("163d33"))
	draw_set_transform(size/2-camera*zoom,0,Vector2.ONE*zoom)
	draw_texture_rect(BACKGROUND,Rect2(Vector2.ZERO,WORLD),false)
	for slot in Rules.PLOT_COUNT:
		var p:=Rules.plot_position(slot)*WORLD
		var id:=int(garden.plots.get(str(slot),-1))
		var ghost:=slot==selected and preview_item>=0
		if ghost: id=preview_item
		draw_set_transform(size/2-camera*zoom+p*zoom,0,Vector2(1,.55)*zoom)
		draw_circle(Vector2.ZERO,74,Color("765339") if id>=0 else Color(0.3,.39,.16,.5),true,-1,true)
		draw_arc(Vector2.ZERO,76,0,TAU,24,Color("ffdd86") if slot==selected else Color(.91,.91,.62,.6),5 if slot==selected else 2,true)
		draw_set_transform(size/2-camera*zoom,0,Vector2.ONE*zoom)
		if id>=0 and id<6:
			for k in 5:
				var offset:=Vector2.from_angle(k*TAU/5)*33
				Flowers.draw_icon(self,p+offset-Vector2(0,20),35,int(Rules.ITEMS[id][3]),.7 if ghost else 1)
		elif id>=6: decor(p-Vector2(0,26),88,int(Rules.ITEMS[id][3]),.7 if ghost else 1)
		elif interactive:
			draw_string(ThemeDB.fallback_font,p+Vector2(-15,12),"+",HORIZONTAL_ALIGNMENT_LEFT,-1,42,Color("ffedb2"))
	for index in Rules.REPAIRS.size():
		var restored: bool=index in garden.repairs
		var p: Vector2=Rules.REPAIR_POS[index]*WORLD
		if index==0 and restored: continue
		decor(p,230 if index==2 else 190 if index==3 else 130,int(Rules.REPAIRS[index][5 if restored else 4]))
		if interactive and not restored:
			draw_circle(p+Vector2(0,100),28,Color("ffdc82"))
			draw_string(ThemeDB.fallback_font,p+Vector2(-10,113),str(index+1),HORIZONTAL_ALIGNMENT_LEFT,-1,34,Color("34523b"))
	draw_set_transform(Vector2.ZERO)
