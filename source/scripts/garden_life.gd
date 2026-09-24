extends Control
## Only this small overlay animates. The landscape's draw commands stay cached.
const CAT=preload("res://assets/garden-cat.svg")
var map: Control
var reduced:=false
var elapsed:=0.0
var accumulator:=0.0
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	set_process(not reduced)
func _process(delta: float) -> void:
	if not is_visible_in_tree(): return
	elapsed+=minf(delta,.05)
	accumulator+=delta
	if accumulator>=1.0/30.0:
		accumulator=0; queue_redraw()
func _draw() -> void:
	if not is_instance_valid(map): return
	var evening: bool=map.garden.get("story",{}).get("evening",false)
	if evening:
		for i in 12:
			var p: Vector2=map.screen_point(Vector2(950+(i%4)*350,700+(i/4)*490)+Vector2(sin(elapsed*.4+i)*24,cos(elapsed*.5+i)*18))
			if not Rect2(Vector2.ZERO,map.size).grow(30).has_point(p): continue
			draw_circle(p,14*map.zoom,Color(1,.79,.3,.10))
			draw_circle(p,5*map.zoom,Color(1,.90,.55,.9))
	var cat_pos: Vector2=map.screen_point(Vector2(1520+sin(elapsed*.18)*35,790))
	draw_texture_rect(CAT,Rect2(cat_pos-Vector2(60,70)*map.zoom,Vector2(120,96)*map.zoom),false)
	# Water glints at the restored fountain: a few arcs, no full-scene shader.
	if 1 in map.garden.repairs:
		var p: Vector2=map.screen_point(map.Rules.REPAIR_POS[1]*map.WORLD+Vector2(0,-55))
		for i in 3:
			var phase:=fmod(elapsed*.45+i*.33,1.0)
			draw_set_transform(p,0,Vector2(1,.42)*map.zoom)
			draw_arc(Vector2.ZERO,25+phase*48,0,TAU,20,Color(.7,.94,1,(1-phase)*.65),2,true)
	draw_set_transform(Vector2.ZERO)
