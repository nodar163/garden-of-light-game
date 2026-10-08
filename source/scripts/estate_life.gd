extends Control
## An isolated low-frequency overlay; the large map itself stays cached at rest.
const PEOPLE=preload("res://assets/shop-customers.png")
const CAT=preload("res://assets/garden-cat.svg")
var map: Control
var reduced:=false
var elapsed:=0.0
var clock:=0.0
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE; set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); set_process(not reduced)
func _process(delta: float) -> void:
	if not is_visible_in_tree(): return
	elapsed+=minf(delta,.1); clock+=delta
	if clock>.05: clock=0; queue_redraw()
func _draw() -> void:
	if not is_instance_valid(map): return
	var scale: float=map.scale_value()
	if map.house:
		if map.Rules.tier(map.garden,true,0)>=2:
			var p: Vector2=map.screen(Vector2(.165,.285))
			draw_texture_rect(CAT,Rect2(p-Vector2(70,65)*scale,Vector2(140,95)*scale*(1+sin(elapsed*1.3)*.015)),false)
		return
	if 3 in map.garden.repairs:
		var path: Array=[Vector2(.50,.65),Vector2(.445,.59),Vector2(.39,.565)]
		for i in 3:
			var phase:=fmod(elapsed*.035+i*.31,2.0); var t:=phase if phase<=1 else 2-phase
			var at: Vector2=path[0].lerp(path[1],t*2) if t<.5 else path[1].lerp(path[2],(t-.5)*2)
			var p: Vector2=map.screen(at); var dimensions:=Vector2(140,210)*scale; var cell:=PEOPLE.get_size()/2
			draw_texture_rect_region(PEOPLE,Rect2(p-Vector2(dimensions.x/2,dimensions.y),dimensions),Rect2(Vector2(i%2,i/2)*cell,cell))
	for i in 3:
		var at:=Vector2(.62+sin(elapsed*.3+i)*.025,.48+cos(elapsed*.2+i)*.018)
		var p: Vector2=map.screen(at)
		for side in [-1,1]: draw_circle(p+Vector2(side*(4+sin(elapsed*4)*2),0),4,Color("ffd7a1"))

	if map.Rules.complete(map.garden):
		var at: Vector2=map.screen(Vector2(.49,.765))
		var star:=PackedVector2Array()
		for i in 10: star.append(at+Vector2.from_angle(-PI/2+i*PI/5)*(90 if i%2==0 else 43)*scale)
		draw_colored_polygon(star,Color("ffda71"))
		draw_arc(at,115*scale,.2,PI-.2,28,Color("edba4d"),maxf(2,10*scale),true)
