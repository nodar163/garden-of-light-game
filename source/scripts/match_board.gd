extends Control
signal committed
signal animation_done(valid: bool)
signal sound_requested(kind: String)
var style_cache: Dictionary = {}
static var floor_cache: Dictionary={}
var floor_texture: Texture2D
var volume: Control
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
	volume=preload("res://scripts/volume_board.gd").new(); add_child(volume); volume.initialize(model.n)
	resized.connect(fit_volume); fit_volume()

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

func fit_volume() -> void:
	if volume==null: return
	var rect:=field_rect(); volume.position=rect.position; volume.size=rect.size
	volume.fit(); queue_redraw()

func _draw() -> void:
	if not shown.is_empty() and is_instance_valid(volume): volume.sync_match(model,shown,motion,blend,selected,hint_cells)
