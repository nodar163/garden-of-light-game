extends Control
## Shared illustrated thumbnails without private 3D viewports.
const Art=preload("res://scripts/match_art.gd")
const JACK=preload("res://assets/jack.png")
const LILY=preload("res://assets/lily.png")
const DECOR=preload("res://assets/garden-decor.png")
const MAP=preload("res://assets/garden-restored.png")
var kind:="flower"
var variant:=0
var flowers: Array=[]
var wrap_id:=0
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
func fit() -> void: queue_redraw()
func _draw() -> void:
	var center:=size/2
	var radius:=minf(size.x,size.y)*.43
	if kind=="person":
		var texture: Texture2D=LILY if variant==4 else JACK
		var dimensions:=texture.get_size()*minf(size.x/texture.get_width(),size.y/texture.get_height())
		draw_texture_rect(texture,Rect2((size-dimensions)/2,dimensions),false)
	elif kind=="bouquet":
		var paper: Color=[Color("edbb97"),Color("b7d5bb"),Color("d7c0dc")][clampi(wrap_id,0,2)]
		draw_colored_polygon(PackedVector2Array([center+Vector2(-radius*.9,-radius*.15),center+Vector2(radius*.9,-radius*.15),center+Vector2(radius*.23,radius),center+Vector2(-radius*.23,radius)]),paper)
		for i in flowers.size():
			var offset:=Vector2((i-(flowers.size()-1)/2.0)*radius*.62,-radius*.2-abs(i-1)*radius*.10)
			Art.draw_icon(self,center+offset,radius*.62,int(flowers[i]))
		draw_line(center+Vector2(-radius*.29,radius*.65),center+Vector2(radius*.29,radius*.65),Color("fff0bd"),maxf(3,radius*.10),true)
	elif kind in ["flower","seed","sprout","bud"]: Art.draw_icon(self,center,radius,clampi(variant,0,5))
	elif kind in Art.POWERS: Art.draw_icon(self,center,radius,int(Art.POWERS[kind]))
	elif kind in ["ice","stone","vine","pot"]: Art.draw_obstacle(self,center,radius,["vine","ice","stone","pot"].find(kind))
	elif kind in ["house","shop","greenhouse","fountain"]:
		var zones: Array=preload("res://scripts/garden_restoration.gd").ZONES
		var zone: Vector4=zones[{"house":0,"fountain":2,"greenhouse":3,"shop":4}[kind]]
		draw_texture_rect_region(MAP,Rect2(Vector2.ZERO,size),Rect2(Vector2(zone.x,zone.y)*MAP.get_size(),Vector2(zone.z,zone.w)*MAP.get_size()))
	elif kind=="hammer":
		draw_line(center+Vector2(radius*.35,radius*.55),center+Vector2(-radius*.15,-radius*.3),Color("b48750"),radius*.23,true)
		draw_line(center+Vector2(-radius*.6,-radius*.15),center+Vector2(radius*.3,-radius*.65),Color("e2d7ac"),radius*.43,true)
	else:
		var id:=1 if kind=="lamp" else 0
		var cell:=Vector2(DECOR.get_width()/3.0,DECOR.get_height()/2.0)
		draw_texture_rect_region(DECOR,Rect2(center-Vector2.ONE*radius,Vector2.ONE*radius*2),Rect2(Vector2(id,0)*cell,cell))
