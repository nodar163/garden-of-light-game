extends RefCounted
const FLOWERS=preload("res://assets/cut-flowers.png")
## One shared texture for all cut flowers; no per-frame mesh or curve allocations.
static func draw(canvas: CanvasItem,base: Vector2,radius: float,species: int,trimmed: bool=false) -> void:
	var cell:=FLOWERS.get_size()/Vector2(3,2)
	var crop:=0.87 if trimmed else 1.0
	var source:=Rect2(Vector2(posmod(species,3),clampi(species,0,5)/3)*cell,cell*Vector2(1,crop))
	canvas.draw_texture_rect_region(FLOWERS,Rect2(base-Vector2(radius,radius*2),Vector2(radius*2,radius*3*crop)),source,Color.WHITE,false,true)

static func shears(canvas: CanvasItem,p: Vector2,r: float) -> void:
	for side in [-1,1]:
		canvas.draw_arc(p+Vector2(side*r*.43,r*.35),r*.24,0,TAU,20,Color("f0be6e"),maxf(3,r*.16),true)
		canvas.draw_line(p+Vector2(side*r*.33,r*.18),p+Vector2(-side*r*.4,-r*.7),Color("e2eee2"),maxf(3,r*.13),true)
	canvas.draw_circle(p,r*.10,Color("657e73"))
