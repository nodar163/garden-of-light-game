extends Control
## Draws a finished bouquet from the same flower art used by the puzzle.
const Art=preload("res://scripts/match_art.gd")
const WRAPS=[Color("edbb97"),Color("b7d5bb"),Color("d7c0dc")]
var flowers: Array=[]
var wrap_id:=0

func _draw() -> void:
	var c:=Vector2(size.x*.5,size.y*.56)
	var scale_value:=minf(size.x/330.0,size.y/220.0)
	draw_circle(c+Vector2(0,74)*scale_value,82*scale_value,Color(.07,.19,.14,.17))
	for i in 3:
		var x: float=float(i-1)*55.0*scale_value
		var head:=c+Vector2(x,-38 if i==1 else -12)*scale_value
		draw_line(c+Vector2(0,88)*scale_value,head+Vector2(0,16)*scale_value,Color("43865b"),7*scale_value,true)
		if i<flowers.size():
			Art.draw_icon(self,head,51*scale_value,int(flowers[i]))
		else:
			draw_circle(head,40*scale_value,Color("eff2df"))
			draw_arc(head,40*scale_value,0,TAU,32,Color("cbd6bd"),3*scale_value,true)
	var paper: Color=WRAPS[clampi(wrap_id,0,2)]
	var points:=PackedVector2Array([
		c+Vector2(-84,30)*scale_value,c+Vector2(-50,135)*scale_value,
		c+Vector2(0,155)*scale_value,c+Vector2(50,135)*scale_value,
		c+Vector2(84,30)*scale_value,c+Vector2(0,88)*scale_value])
	draw_colored_polygon(points,paper)
	draw_line(c+Vector2(-84,30)*scale_value,c+Vector2(0,88)*scale_value,Color(1,1,1,.6),3*scale_value,true)
	draw_line(c+Vector2(84,30)*scale_value,c+Vector2(0,88)*scale_value,Color(1,1,1,.6),3*scale_value,true)
	draw_line(c+Vector2(-34,119)*scale_value,c+Vector2(34,119)*scale_value,Color("fff3d3"),12*scale_value,true)
	draw_circle(c+Vector2(0,119)*scale_value,10*scale_value,Color("edc45e"))
