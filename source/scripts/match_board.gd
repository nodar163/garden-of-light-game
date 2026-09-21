extends Control
signal committed
signal animation_done(valid: bool)
signal sound_requested(kind: String)
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
	if busy or model.won() or model.moves <= 0: return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			press_index = at(event.position)
			press_position = event.position
			grab_focus()
		elif press_index >= 0:
			var delta: Vector2 = event.position-press_position
			if delta.length() > field_rect().size.x/model.n*0.28:
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
	if i < 0: return
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
	# Save the settled model before any animation, including when leaving mid-cascade.
	committed.emit()
	for event in model.frames:
		motion = event
		shown = event
		blend = 0
		var duration := 0.0
		match event.kind:
			"swap": duration = 0.17; sound_requested.emit("swap")
			"clear":
				duration = 0.22; cascade += 1
				sound_requested.emit("power" if not event.activated.is_empty() else "match")
			"fall": duration = 0.3
			"shuffle": duration = 0.3
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
	var style := StyleBoxFlat.new()
	style.bg_color = color; style.border_color = border
	style.set_border_width_all(2); style.set_corner_radius_all(radius)
	draw_style_box(style,rect)

func blossom(center: Vector2, radius: float, color_index: int, power: String = "", opacity: float = 1.0) -> void:
	if radius < 0.3: return
	var color: Color = PETALS[color_index]
	draw_circle(center+Vector2(0,radius*0.15),radius*0.92,Color(0.01,0.07,0.08,0.25*opacity),true,-1.0,true)
	for side in [-1,1]:
		draw_set_transform(center+Vector2(side*radius*0.56,radius*0.54),side*-0.55,Vector2(1,0.42))
		draw_circle(Vector2.ZERO,radius*0.46,Color(Color("3cbd7d"),opacity),true,-1.0,true)
		draw_line(Vector2(-radius*0.28,0),Vector2(radius*0.28,0),Color(Color("b8f6a6"),opacity),1.5,true)
		draw_set_transform(Vector2.ZERO)
	var count: int = [5,8,6,4,7,9][color_index]
	for k in count:
		var angle := TAU*k/count-PI/2
		var p := center+Vector2.from_angle(angle)*radius*0.47
		draw_set_transform(p,angle,Vector2(1,0.72 if color_index != 3 else 0.95))
		draw_circle(Vector2.ZERO,radius*0.52,Color(color.darkened(0.27),opacity),true,-1.0,true)
		draw_circle(Vector2(-radius*0.045,-radius*0.055),radius*0.46,Color(color,opacity),true,-1.0,true)
		draw_circle(Vector2(-radius*0.06,-radius*0.1),radius*0.32,Color(color.lightened(0.22),opacity),true,-1.0,true)
		draw_arc(Vector2(-radius*0.03,-radius*0.08),radius*0.31,PI*1.1,PI*1.8,12,Color(1,1,1,0.48*opacity),radius*0.045,true)
		draw_set_transform(Vector2.ZERO)
	draw_circle(center,radius*0.3,Color(Color("ac681f"),opacity),true,-1.0,true)
	draw_circle(center-Vector2(0,radius*0.045),radius*0.25,Color(Color("ffe78a"),opacity),true,-1.0,true)
	for k in 6:
		draw_circle(center+Vector2.from_angle(k*TAU/6)*radius*0.14,radius*0.032,Color(Color("b88735"),opacity),true,-1.0,true)
	if power != "":
		draw_circle(center,radius*0.62,Color(0.08,0.13,0.24,0.86*opacity),true,-1.0,true)
		draw_arc(center,radius*0.63,0,TAU,36,Color(Color("fff4be"),opacity),radius*0.06,true)
		match power:
			"row","column":
				var direction := Vector2.RIGHT if power == "row" else Vector2.DOWN
				draw_line(center-direction*radius*0.4,center+direction*radius*0.4,Color("fff7da"),radius*0.12,true)
				for side in [-1,1]:
					var p: Vector2 = center+direction*side*radius*0.42
					draw_line(p,p-direction.rotated(0.7)*side*radius*0.22,Color("fff7da"),radius*0.08,true)
					draw_line(p,p-direction.rotated(-0.7)*side*radius*0.22,Color("fff7da"),radius*0.08,true)
			"burst":
				var star := PackedVector2Array()
				for k in 12: star.append(center+Vector2.from_angle(k*TAU/12-PI/2)*radius*(0.48 if k%2==0 else 0.22))
				draw_colored_polygon(star,Color("ffda8d"))
			"bee":
				for side in [-1,1]:
					draw_circle(center+Vector2(side*radius*0.21,-radius*0.08),radius*0.23,Color("f7c0ff"),true,-1.0,true)
					draw_circle(center+Vector2(side*radius*0.15,radius*0.18),radius*0.16,Color("ffc473"),true,-1.0,true)
				draw_line(center-Vector2(0,radius*0.3),center+Vector2(0,radius*0.35),Color("fff9dc"),radius*0.09,true)
			"rainbow":
				for k in 6: draw_arc(center,radius*(0.49-k*0.055),PI,TAU,20,PETALS[k],radius*0.07,true)
				draw_circle(center+Vector2(0,radius*0.2),radius*0.1,Color("ffffff"),true,-1.0,true)

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
					for side in [-1,1]: draw_circle(spot+Vector2(side*6,0),7,Color("ffd2fb"),true,-1.0,true)
				"rainbow":
					for k in 6: draw_arc(p,cell*(0.35+blend*1.2+k*0.07),0,TAU,48,Color(PETALS[k],1-blend),3,true)
