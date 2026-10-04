extends Control
var model: RefCounted
var icons: Array=[]

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	for c in 6:
		if int(model.level.targets[c])>0:
			var icon=preload("res://scripts/model_preview.gd").new(); icon.variant=c; icon.size=Vector2(56,56); add_child(icon); icons.append(icon)
	if model.level.dew.any(func(d): return int(d)>0):
		var icon=preload("res://scripts/model_preview.gd").new(); icon.kind="ice"; icon.size=Vector2(56,56); add_child(icon); icons.append(icon)
	if model.obstacles.any(func(d): return int(d)>0):
		var icon=preload("res://scripts/model_preview.gd").new(); icon.kind="stone"; icon.size=Vector2(56,56); add_child(icon); icons.append(icon)
	resized.connect(queue_redraw)

func _gui_input(_event: InputEvent) -> void:
	pass

func _draw() -> void:
	if model == null: return
	var goals: Array=[]
	for c in 6:
		if int(model.level.targets[c])>0: goals.append(c)
	var has_dew: bool=model.level.dew.any(func(d): return int(d)>0)
	var has_obstacles: bool=model.obstacles.any(func(d): return int(d)>0)
	var total:=goals.size()+(1 if has_dew else 0)+(1 if has_obstacles else 0)
	var width:=minf(150,size.x/maxi(1,total))
	var start:=(size.x-width*total)/2
	var font:=ThemeDB.fallback_font
	for j in icons.size(): icons[j].position=Vector2(start+width*(j+.5)-28,0)
	for j in goals.size():
		var c: int=goals[j]
		var p:=Vector2(start+width*(j+0.5),28)

		var text_value:="%d / %d" % [mini(int(model.collected[c]),int(model.level.targets[c])),int(model.level.targets[c])]
		draw_string(font,Vector2(p.x-font.get_string_size(text_value,HORIZONTAL_ALIGNMENT_LEFT,-1,21).x/2,76),text_value,HORIZONTAL_ALIGNMENT_LEFT,-1,21,Color("fff4d3"))
	if has_dew:
		var p:=Vector2(start+width*(goals.size()+0.5),28)
		var left:=0
		for d in model.dew: left+=int(d)
		var text_value:=str(left)
		draw_string(font,Vector2(p.x-font.get_string_size(text_value,HORIZONTAL_ALIGNMENT_LEFT,-1,21).x/2,76),text_value,HORIZONTAL_ALIGNMENT_LEFT,-1,21,Color("e1fbff"))
	if has_obstacles:
		var p:=Vector2(start+width*(total-0.5),28)

		var left:=0
		for hp in model.layers: left+=int(hp)
		var text_value:=str(left)
		draw_string(font,Vector2(p.x-font.get_string_size(text_value,HORIZONTAL_ALIGNMENT_LEFT,-1,21).x/2,76),text_value,HORIZONTAL_ALIGNMENT_LEFT,-1,21,Color("fff4d3"))
