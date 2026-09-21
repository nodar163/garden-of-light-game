extends RefCounted
## One shared GPU atlas: no per-frame petal geometry or texture allocation.
const ATLAS = preload("res://assets/flowers-atlas.png")
const OBSTACLES = preload("res://assets/obstacles-atlas.png")
const POWERS = {"burst":6,"bee":7,"row":8,"column":9,"rainbow":10}
static func icon(index: int) -> AtlasTexture:
	var texture:=AtlasTexture.new()
	texture.atlas=ATLAS
	var cell:=ATLAS.get_width()/4.0
	texture.region=Rect2(Vector2(index%4,index/4)*cell,Vector2.ONE*cell)
	texture.filter_clip=true
	return texture
static func draw_icon(canvas: CanvasItem, center: Vector2, radius: float, index: int, opacity: float=1.0) -> void:
	var cell:=ATLAS.get_width()/4.0
	canvas.draw_texture_rect_region(ATLAS,Rect2(center-Vector2.ONE*radius,Vector2.ONE*radius*2),Rect2(Vector2(index%4,index/4)*cell,Vector2.ONE*cell),Color(1,1,1,opacity),false,true)

static func draw_obstacle(canvas: CanvasItem, center: Vector2, radius: float, index: int) -> void:
	var cell:=OBSTACLES.get_width()/2.0
	canvas.draw_texture_rect_region(OBSTACLES,Rect2(center-Vector2.ONE*radius,Vector2.ONE*radius*2),Rect2(Vector2(index%2,index/2)*cell,Vector2.ONE*cell),Color.WHITE,false,true)
