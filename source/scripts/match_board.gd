extends Control
signal committed
signal animation_done(valid: bool)
signal sound_requested(kind: String)
const Art = preload("res://scripts/match_art.gd")
var style_cache: Dictionary = {}
const Model = preload("res://scripts/match_rules.gd")
var model: Model
var shown: Dictionary = {}
var busy := false
var reduced := false
var selected := -1
var hint_cells: Array = []
var press_index := -1
var press_position := Vector2.ZERO
var motion: Dictionary = {}
var blend := 1.0
var cascade := 0
var cursor := 0
var active_tool := -1
const PETALS = [Color("ff668e"),Color("ffc94f"),Color("ae7aff"),Color("41cfea"),Color("ff9654"),Color("87dd68")]

func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	shown = model.snapshot()
	resized.connect(queue_redraw)

func field_rect() -> Rect2:
	var side := minf(size.x-24,size.y-24)
	return Rect2((size-Vector2.ONE*side)/2,Vector2.ONE*side)

func tile_center(i: int) -> Vector2:
	var rect := field_rect()
	var cell := rect.size.x/model.n
	# Negative indices represent newly spawned flowers above the board.
	var y := floorf(float(i)/model.n)
	return rect.position+Vector2(posmod(i,model.n)+0.5,y+0.5)*cell

func at(position_value: Vector2) -> int:
	var rect := field_rect()
	if not rect.has_point(position_value): return -1
	var local := (position_value-rect.position)/(rect.size.x/model.n)
	return int(local.y)*model.n+int(local.x)

func _gui_input(event: InputEvent) -> void:
	if busy or model.won() or (model.moves <= 0 and active_tool < 0): return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			press_index = at(event.position)
			press_position = event.position
			grab_focus()
		elif press_index >= 0:
			var delta: Vector2 = event.position-press_position
			if active_tool>=0: choose(press_index)
			elif delta.length() > field_rect().size.x/model.n*0.28:
				var dest := press_index+(int(signf(delta.x)) if absf(delta.x)>absf(delta.y) else int(signf(delta.y))*model.n)
				if model.adjacent(press_index,dest): animate_move(press_index,dest)
			else: choose(press_index)
			press_index = -1
		accept_event()
	if event is InputEventKey and event.pressed:
		if event.keycode in [KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN]:
			var dx := -1 if event.keycode == KEY_LEFT else 1 if event.keycode == KEY_RIGHT else 0
			var dy := -1 if event.keycode == KEY_UP else 1 if event.keycode == KEY_DOWN else 0
			cursor = clampi(cursor/model.n+dy,0,model.n-1)*model.n+clampi(cursor%model.n+dx,0,model.n-1)
			queue_redraw(); accept_event()
		elif event.keycode in [KEY_ENTER,KEY_SPACE]: choose(cursor); accept_event()

func choose(i: int) -> void:
	if i < 0 or busy: return
	if active_tool>=0:
		var tool:=active_tool; active_tool=-1
		busy=true
		animate_frames(model.use_tool(tool,i))
		return
	if selected >= 0 and model.adjacent(selected,i): animate_move(selected,i)
	elif model.powers[i] != "": animate_move(i,-1)
	else:
		selected = -1 if selected == i else i
		queue_redraw()

func animate_move(a: int, b: int) -> void:
	if busy: return
	busy = true
	selected = -1; hint_cells.clear(); cascade = 0
	var valid: bool = model.play(a,b)
	animate_frames(valid)

func animate_frames(valid: bool) -> void:
	# Save the settled model before any animation, including when leaving mid-cascade.
	committed.emit()
	for event in model.frames:
		motion = event
		shown = event
		blend = 0
		var duration := 0.0
		match event.kind:
			"swap": duration = 0.14; sound_requested.emit("swap")
			"clear":
				duration = 0.18; cascade += 1
				sound_requested.emit("power" if not event.activated.is_empty() else "match")
			"fall": duration = 0.22
			"shuffle": duration = 0.22
		if duration > 0 and not reduced:
			var tween := create_tween()
			tween.tween_method(func(t: float): blend=t; queue_redraw(),0.0,1.0,duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			await tween.finished
		else: blend = 1.0
	shown = model.snapshot()
	motion = {}; busy = false
	queue_redraw()
	animation_done.emit(valid)

func box(rect: Rect2, color: Color, border: Color, radius: int) -> void:
	var key:=str(color)+str(border)+str(radius)
	if not style_cache.has(key):
		var created:=StyleBoxFlat.new()
		created.bg_color=color; created.border_color=border
		created.set_border_width_all(2); created.set_corner_radius_all(radius)
		style_cache[key]=created
	var style: StyleBoxFlat=style_cache[key]
	draw_style_box(style,rect)

func blossom(center: Vector2, radius: float, color_index: int, power: String = "", opacity: float = 1.0) -> void:
	if radius < 0.3: return
	Art.draw_icon(self,center,radius*1.14,int(Art.POWERS.get(power,color_index)),opacity)

func _draw() -> void:
	if shown.is_empty(): return
	var rect := field_rect()
	var cell := rect.size.x/model.n
	box(rect.grow(10),Color("142e46"),Color("e1c986"),28)
	box(rect.grow(4),Color("295365"),Color("5e9b98"),24)
	for i in model.n*model.n:
		var p := tile_center(i)
		box(Rect2(p-Vector2.ONE*(cell/2-2),Vector2.ONE*(cell-4)),Color("326d70") if (i+i/model.n)%2==0 else Color("2e626b"),Color(0.5,0.85,0.8,0.12),10)
		if int(shown.dew[i]) > 0:
			box(Rect2(p-Vector2.ONE*(cell/2-4),Vector2.ONE*(cell-8)),Color(0.37,0.79,0.91,0.23),Color("98e4f2"),10)
			if int(shown.dew[i]) > 1: draw_arc(p,cell*0.39,0,TAU,24,Color("d0fbff"),2,true)
		if i == selected or i in hint_cells or (has_focus() and i == cursor):
			box(Rect2(p-Vector2.ONE*(cell/2-3),Vector2.ONE*(cell-6)),Color(1,0.85,0.3,0.13),Color("ffe999"),11)
	# Clip falling pieces to the board so they never cover the goals.
	draw_set_transform(Vector2.ZERO)
	for i in model.n*model.n:
		if int(shown.cells[i]) < 0: continue
		var p := tile_center(i)
		var scale_value := 1.0
		var alpha := 1.0
		var kind: String = motion.get("kind","")
		if kind == "swap":
			if i == motion.a: p = tile_center(motion.b).lerp(p,blend)
			if i == motion.b: p = tile_center(motion.a).lerp(p,blend)
		elif kind == "fall":
			p = tile_center(int(motion.from[i])).lerp(p,blend)
		elif kind == "clear" and i in motion.hit:
			scale_value = 1+sin(blend*PI)*0.12-blend*0.85
			alpha = 1-blend
		elif kind == "shuffle": alpha = blend
		if p.y-cell*0.37 < rect.position.y: continue
		blossom(p,cell*0.38*scale_value,int(shown.cells[i]),shown.powers[i],alpha)
		if kind == "clear" and i in motion.hit:
			for k in 5:
				var spark := p+Vector2.from_angle(k*TAU/5+i)*cell*blend*0.6
				if rect.has_point(spark): draw_circle(spark,cell*0.036*(1-blend),Color(PETALS[int(shown.cells[i])],1-blend),true,-1.0,true)
	for i in model.n*model.n:
		var hp:=int(shown.get("layers",model.layers)[i])
		if hp<=0: continue
		var p:=tile_center(i)
		var kind:=int(model.obstacles[i])
		Art.draw_obstacle(self,p,cell*0.47,kind-1)
		if kind==4: Art.draw_icon(self,p+Vector2(0,cell*0.13),cell*0.16,int(shown.cells[i]))
		if hp>1:
			draw_circle(p+Vector2(cell*.3,-cell*.3),cell*.13,Color("fff3cf"))
			draw_string(ThemeDB.fallback_font,p+Vector2(cell*.25,-cell*.24),str(hp),HORIZONTAL_ALIGNMENT_LEFT,-1,int(cell*.2),Color("263751"))
	if motion.get("kind","") == "clear":
		for effect in motion.get("effects",[]):
			var p:=tile_center(int(effect.at))
			var glow:=Color(1,0.93,0.67,sin(blend*PI)*0.8)
			match effect.power:
				"row": draw_line(Vector2(rect.position.x,p.y),Vector2(rect.end.x,p.y),glow,cell*(0.05+0.12*sin(blend*PI)),true)
				"column": draw_line(Vector2(p.x,rect.position.y),Vector2(p.x,rect.end.y),glow,cell*(0.05+0.12*sin(blend*PI)),true)
				"burst":
					draw_arc(p,cell*(0.2+blend*1.8),0,TAU,48,glow,5*(1-blend)+1,true)
				"bee":
					var dest:=tile_center(int(effect.target))
					var spot:=p.lerp(dest,blend)+Vector2(0,-sin(blend*PI)*cell*0.6)
					Art.draw_icon(self,spot,cell*0.4,7,1-blend*0.35)
				"rainbow":
					for k in 6: draw_arc(p,cell*(0.35+blend*1.2+k*0.07),0,TAU,48,Color(PETALS[k],1-blend),3,true)
