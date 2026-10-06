extends Control
signal selected(id: int)
signal entrance(kind: String)
const Rules=preload("res://scripts/estate_rules.gd")
var house:=false
var garden: Dictionary
var english:=false
var zoom:=2.5
var center:=Vector2(.5,.5)
var dragging:=false
var distance:=0.0
var picture: TextureRect
var material_map: ShaderMaterial
const WORLD=Vector2(4800,3200)

func _ready() -> void:
	clip_contents=true; mouse_filter=Control.MOUSE_FILTER_STOP
	picture=TextureRect.new(); picture.mouse_filter=Control.MOUSE_FILTER_IGNORE; picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; picture.show_behind_parent=true; add_child(picture)
	picture.texture=load("res://assets/"+("house" if house else "estate")+"-abandoned.png")
	material_map=ShaderMaterial.new(); material_map.shader=preload("res://scripts/estate_map.gdshader")
	material_map.set_shader_parameter("restored_map",load("res://assets/"+("house" if house else "estate")+"-restored.png")); picture.material=material_map
	resized.connect(refresh); refresh()

func points() -> Array: return Rules.HOUSE_POINTS if house else Rules.LAND_POINTS
func scale_value() -> float: return minf(size.x/WORLD.x,size.y/WORLD.y)*zoom
func screen(uv: Vector2) -> Vector2: return (uv-center)*WORLD*scale_value()+size/2
func focus_area(id: int) -> void:
	center=points()[clampi(id,0,23)]; zoom=4.0; refresh()
func magnify(factor: float) -> void: zoom=clampf(zoom*factor,1,8); refresh()
func refresh() -> void:
	if not is_instance_valid(picture): return
	var half:=size/(WORLD*scale_value()*2)
	center=Vector2(clampf(center.x,minf(.5,half.x),maxf(.5,1-half.x)),clampf(center.y,minf(.5,half.y),maxf(.5,1-half.y)))
	picture.position=screen(Vector2.ZERO); picture.size=WORLD*scale_value()
	var positions:=PackedVector2Array(points()); var weights:=PackedFloat32Array()
	for id in 24: weights.append(float(Rules.tier(garden,house,id))/3.0)
	material_map.set_shader_parameter("points",positions); material_map.set_shader_parameter("weights",weights)
	material_map.set_shader_parameter("house",house); queue_redraw()
	var central:=PackedFloat32Array()
	for id in [0,0,1,2,3,4]: central.append(1.0 if id in garden.repairs else 0.0)
	material_map.set_shader_parameter("central",central)
func _draw() -> void:
	for id in 24:
		if zoom<2.2 and id%4!=0: continue
		var at:=screen(points()[id])
		if not Rect2(Vector2.ZERO,size).grow(40).has_point(at): continue
		var t:=Rules.tier(garden,house,id)
		var ready: bool=t<3 and garden.earned.size()>=Rules.required(house,id,t+1)
		draw_circle(at,22,Color("fff3cf") if ready else Color("326451"),true,-1,true)
		draw_string(ThemeDB.fallback_font,at+Vector2(-8,8),"+" if zoom<2.2 else "✓" if t==3 else str(t+1),HORIZONTAL_ALIGNMENT_LEFT,-1,23,Color("285342") if ready else Color("fff5df"))
	if not house:
		for entry in [[Vector2(.405,.34),"Дом","Home"],[Vector2(.82,.32),"Огород","Nursery"],[Vector2(.365,.535),"Магазин","Shop"],[Vector2(.52,.46),"Старый сад","Old garden"]]:
			var p:=screen(entry[0]); draw_style_box(preload("res://scripts/garden_hud.gd").plate(Color("fff6dd"),14),Rect2(p-Vector2(78,24),Vector2(156,48)))
			draw_string(ThemeDB.fallback_font,p-Vector2(70,-8),entry[2 if english else 1],HORIZONTAL_ALIGNMENT_CENTER,140,24,Color("315445"))
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMagnifyGesture: magnify(event.factor); accept_event(); return
	if event is InputEventMouseButton:
		if event.pressed and event.button_index==MOUSE_BUTTON_WHEEL_UP: magnify(1.2)
		elif event.pressed and event.button_index==MOUSE_BUTTON_WHEEL_DOWN: magnify(1/1.2)
		elif event.button_index==MOUSE_BUTTON_LEFT:
			if event.pressed: dragging=true; distance=0
			elif dragging:
				dragging=false
				if distance<12: pick(event.position)
		accept_event()
	elif event is InputEventMouseMotion and dragging:
		distance+=event.relative.length(); center-=event.relative/(WORLD*scale_value()); refresh(); accept_event()
func pick(p: Vector2) -> void:
	if not house:
		var entries=[Vector2(.405,.34),Vector2(.82,.32),Vector2(.365,.535),Vector2(.52,.46)]
		for i in entries.size():
			if Rect2(screen(entries[i])-Vector2(80,28),Vector2(160,56)).has_point(p): entrance.emit(["house","nursery","shop","garden"][i]); return
	var nearest:=-1; var best:=48.0
	for id in 24:
		if zoom<2.2 and id%4!=0: continue
		var d:=screen(points()[id]).distance_to(p)
		if d<best: nearest=id; best=d
	if nearest>=0:
		if zoom<2.2: focus_area(nearest)
		else: selected.emit(nearest)
