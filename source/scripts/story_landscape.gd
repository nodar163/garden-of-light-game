extends Control
## Illustrated memory and a short storm; no flashing or indefinite animation.
const BEFORE=preload("res://assets/garden-restored.png")
const AFTER=preload("res://assets/garden-abandoned.png")
var ruined:=false
var storm:=false
var reduced:=false
var elapsed:=0.0
func _ready() -> void:
	mouse_filter=MOUSE_FILTER_IGNORE; clip_contents=true
	resized.connect(queue_redraw)
	set_process(storm and not reduced)
	if reduced and storm: elapsed=4.0
func _process(delta: float) -> void:
	elapsed=minf(4.0,elapsed+delta); queue_redraw()
	if elapsed>=4: set_process(false)
func _draw() -> void:
	if size.x<=0 or size.y<=0: return
	var dimensions:=BEFORE.get_size()*maxf(size.x/BEFORE.get_width(),size.y/BEFORE.get_height())
	var rect:=Rect2((size-dimensions)/2,dimensions)
	draw_texture_rect(AFTER if ruined else BEFORE,rect,false)
	if storm:
		draw_texture_rect(AFTER,rect,false,Color(1,1,1,clampf((elapsed-1.0)/2,0,1)))
		draw_rect(Rect2(Vector2.ZERO,size),Color(.025,.075,.12,.28))
		if not reduced and elapsed<4:
			for i in 45:
				var at:=Vector2(fposmod(i*83.0-elapsed*95,size.x),fposmod(i*137.0+elapsed*490,size.y))
				draw_line(at,at+Vector2(-12,33),Color(.8,.88,.95,.38),2,true)
