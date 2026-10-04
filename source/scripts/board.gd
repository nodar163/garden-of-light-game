extends Control
signal tile_pressed(index: int)
const Rules = preload("res://scripts/puzzle.gd")
var puzzle: RefCounted
var hint := -1
var reduced := false
var phase := 0.0
var blooms: Dictionary = {}
var decorative := false
var garden_count := 0
var garden_offset := 0
var completed: Array = []
var region := 0
var volume: Control
const PALETTES = [Color("56ab77"), Color("b37893"), Color("8d80bf"), Color("51a8a8"), Color("b99a59"), Color("6f8bb5"), Color("b77f72"), Color("809cab"), Color("59b69d"), Color("9583bc")]
const GOLD = Color("ffe294")
const LEAF = Color("77d9a2")

func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	volume=preload("res://scripts/volume_board.gd").new(); add_child(volume)
	volume.initialize(int(puzzle.level.size) if puzzle!=null else 7,true)
	resized.connect(fit_volume); fit_volume()

func _process(delta: float) -> void:
	phase += delta
	if puzzle != null:
		var reached: Array = puzzle.lit()
		for i in puzzle.level.cells.size():
			var target := 1.0 if i in reached else 0.0
			blooms[i] = target if reduced else move_toward(float(blooms.get(i, 0.0)), target, delta * 2.5)
	queue_redraw()

func field_rect() -> Rect2:
	var side := minf(size.x - 24, size.y - 24)
	return Rect2((size - Vector2.ONE * side) / 2, Vector2.ONE * side)

func _gui_input(event: InputEvent) -> void:
	if decorative or puzzle == null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var rect := field_rect()
		if rect.has_point(event.position):
			var pos: Vector2 = (event.position - rect.position) / (rect.size.x / int(puzzle.level.size))
			tile_pressed.emit(int(pos.y) * int(puzzle.level.size) + int(pos.x))
			accept_event()

func fit_volume() -> void:
	if volume==null: return
	var rect:=field_rect(); volume.position=rect.position; volume.size=rect.size
	volume.fit(); queue_redraw()

func _draw() -> void:
	if puzzle!=null and is_instance_valid(volume): volume.sync_light(puzzle,blooms,hint)
