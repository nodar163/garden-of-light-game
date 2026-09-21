extends Control
signal tile_pressed(index: int)
const Art = preload("res://scripts/match_art.gd")
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
const PALETTES = [Color("56ab77"), Color("b37893"), Color("8d80bf"), Color("51a8a8"), Color("b99a59"), Color("6f8bb5"), Color("b77f72"), Color("809cab"), Color("59b69d"), Color("9583bc")]
const GOLD = Color("ffe294")
const LEAF = Color("77d9a2")

func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	resized.connect(queue_redraw)

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

func rounded(rect: Rect2, color: Color, radius: int, border: Color = Color.TRANSPARENT) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.border_color = border
	style.set_border_width_all(1)
	draw_style_box(style, rect)

func flower(center: Vector2, radius: float, amount: float, variant: int = 0) -> void:
	var green := Color("63c58d")
	draw_line(center + Vector2(0, radius * 0.1), center + Vector2(0, radius * 1.45), green, radius * 0.14, true)
	for sign_value in [-1, 1]:
		var leaf_center := center + Vector2(sign_value * radius * 0.32, radius)
		draw_set_transform(leaf_center, sign_value * -0.55, Vector2(1, 0.46))
		draw_circle(Vector2.ZERO, radius * 0.49, green)
		draw_line(Vector2(-radius*0.33,0), Vector2(radius*0.34,0), Color("b4efab"), maxf(1,radius*0.045), true)
		draw_set_transform(Vector2.ZERO)
	if amount > 0.01:
		Art.draw_icon(self,center,radius*(0.45+amount*0.95),[1,0,2,3,4][variant%5],amount)
	else:
		draw_circle(center,radius*0.3,[Color("d7a637"),Color("d95c82"),Color("8967cc"),Color("269bb3"),Color("d98740")][variant%5])

func _draw() -> void:
	var rect := field_rect()
	if decorative:
		_draw_garden(rect)
		return
	if puzzle == null:
		return
	var n: int = int(puzzle.level.size)
	var cell := rect.size.x / n
	var tint: Color = PALETTES[region % PALETTES.size()]
	rounded(rect.grow(12), Color("102f30"), 30, Color("73bca2"))
	rounded(rect.grow(6), Color("296252"), 26, Color("3f8c70"))
	for i in n*n:
		var pos := rect.position + Vector2(i % n, i / n) * cell
		var center := pos + Vector2.ONE * cell / 2
		var kind: String = puzzle.level.cells[i]
		var active: float = blooms.get(i, 0.0)
		rounded(Rect2(pos + Vector2(4,7), Vector2.ONE*(cell-8)), Color("123e36"), 16)
		var tile_color := Color("28644c").lerp(tint, 0.34 + active*0.18)
		rounded(Rect2(pos + Vector2.ONE*4, Vector2.ONE*(cell-10)), tile_color if kind != "empty" else tile_color.darkened(0.14), 16, tint.lightened(0.1))
		draw_line(pos+Vector2(17,7),pos+Vector2(cell-19,7),Color(tint.lightened(0.45),0.4),1.5,true)
		for speck in 5:
			var seed_pos := pos + Vector2(0.16 + fposmod(sin(i*17+speck*8)*43,0.7), 0.15 + fposmod(cos(i*9+speck*7)*31,0.7))*cell
			draw_circle(seed_pos, cell*0.012, Color(0.69,0.9,0.65,0.17))
		if i == hint:
			rounded(Rect2(pos + Vector2.ONE*6, Vector2.ONE*(cell-12)), Color(0.9,0.75,0.4,0.06), 17, GOLD)
		if kind == "empty":
			for k in 3:
				var p := center + Vector2((k-1)*12, sin(i+k)*15)
				draw_line(p, p + Vector2(-4,-9), Color("74b982"), 2, true)
				if k == 1:
					flower(p + Vector2(0,-8), cell*0.055, 1.0, i)
			continue
		var ports := Rules.mask(kind, int(puzzle.rotations[i]))
		for d in 4:
			if ports & (1 << d):
				var end := center + Vector2(Rules.STEPS[d]) * cell * 0.5
				draw_line(center, end, Color("0c211c"), cell * 0.17, true)
				draw_line(center, end, Color("97bda0").lerp(GOLD, active), cell * 0.085, true)
				draw_line(center, end, Color("bdd4b3").lerp(Color("fff8dc"), active), cell * 0.025, true)
				if active > 0:
					draw_line(center, end, Color(1,0.86,0.5,0.06*active), cell*0.26, true)
					var travel := 0.5 if reduced else fposmod(phase*0.3+i*0.17,1.0)
					draw_circle(center.lerp(end,travel),cell*0.026,Color("fffde4"))
		if kind == "plant":
			flower(center, cell * 0.25, active, i)
		elif kind == "source":
			draw_circle(center+Vector2(0,cell*0.035),cell*0.255,Color("173d36"))
			draw_circle(center, cell*0.31, Color(1,0.8,0.4,0.055))
			draw_circle(center, cell*0.23, Color("b89d60"))
			draw_circle(center, cell*0.185, Color("20392d"))
			draw_circle(center, cell*0.11, GOLD)
			for ray in 8:
				var angle := ray*TAU/8
				draw_line(center+Vector2.from_angle(angle)*cell*0.27, center+Vector2.from_angle(angle)*cell*0.33, GOLD, 2, true)
			draw_arc(center, cell*0.28, -PI*0.85, -PI*0.15, 24, GOLD, 2, true)
		else:
			draw_circle(center, cell*0.063, Color("97bda0").lerp(GOLD, active))
	# Fireflies stay outside touch targets.
	if not reduced:
		for k in 5:
			var p := rect.position + Vector2((0.12+k*0.19)*rect.size.x, 7 + sin(phase*0.6+k*2)*7)
			draw_circle(p, 2, Color(0.95,0.85,0.57,0.25+0.15*sin(phase+k)))

func _draw_garden(rect: Rect2) -> void:
	var center := rect.get_center()
	var tint: Color = PALETTES[region % PALETTES.size()]
	# Hanging lanterns and leafy arches frame the island.
	for side in [-1,1]:
		var origin := center + Vector2(side*rect.size.x*0.35,-rect.size.x*0.2)
		draw_line(origin+Vector2(0,-55),origin+Vector2(0,10),Color("80b394"),2,true)
		for glow in 3:
			draw_circle(origin+Vector2(0,15),19-glow*4,Color(1,0.83,0.43,0.04))
		rounded(Rect2(origin+Vector2(-8,3),Vector2(16,23)),Color("ffda85"),5,Color("fff3c9"))
		draw_line(origin+Vector2(-4,6),origin+Vector2(-4,22),Color("fff9dd"),2,true)
	draw_set_transform(center + Vector2(0,40), 0, Vector2(1,0.62))
	draw_circle(Vector2.ZERO, rect.size.x*0.46, Color("12342e"))
	draw_circle(Vector2(0,-12), rect.size.x*0.44, tint.darkened(0.28))
	draw_circle(Vector2(0,-18), rect.size.x*0.37, tint)
	# A small reflecting pool, visible between the surrounding flower beds.
	draw_circle(Vector2(0,-20),rect.size.x*0.1,Color("94bfa3"))
	draw_circle(Vector2(0,-22),rect.size.x*0.083,Color("287e96"))
	draw_circle(Vector2(-6,-28),rect.size.x*0.064,Color("4db8bf"))
	for ripple in 3:
		draw_arc(Vector2(0,-22),rect.size.x*(0.025+ripple*0.018),0.2,2.7,24,Color(0.8,1,1,0.45),1.5,true)
	draw_set_transform(Vector2.ZERO)
	for stone in 22:
		var a := stone*2.39996
		var p := center + Vector2(cos(a),sin(a)*0.6)*rect.size.x*0.42 + Vector2(0,28)
		draw_circle(p, rect.size.x*0.025, Color("88b69a"))
		draw_circle(p+Vector2(-2,-2), rect.size.x*0.017, Color("bfd0ab"))
		if stone%3 == 0:
			flower(p+Vector2(0,-7),rect.size.x*0.014,1.0,stone+region)
	for blade in 70:
		var a := blade*2.39996
		var r := sqrt(float(blade+1)/70)*rect.size.x*0.37
		var p := center + Vector2(cos(a)*r,sin(a)*r*0.6+20)
		draw_line(p,p+Vector2(-3,-7),Color(tint.lightened(0.45),0.45),1.3,true)
	for i in 50:
		var angle := i * 2.39996
		var distance := (0.12+sqrt(float(i+1)/50)*0.23) * rect.size.x
		var p := center + Vector2(cos(angle)*distance, sin(angle)*distance*0.6 + 20)
		flower(p, rect.size.x*0.025, 1.0 if (i+garden_offset+1) in completed else 0.0, i+region)
	for k in 14:
		var a := k*2.39996
		var p := center + Vector2(cos(a), sin(a)*0.6)*rect.size.x*0.4
		draw_circle(p, 3, Color("8a9470"))
	if not reduced:
		for butterfly in 3:
			var p := center+Vector2(sin(phase*0.22+butterfly*2)*rect.size.x*0.3,-rect.size.x*0.2+cos(phase*0.3+butterfly)*18)
			var wing := 3+absf(sin(phase*2+butterfly))*4
			draw_circle(p+Vector2(-wing,0),wing,Color("ffbdc9"))
			draw_circle(p+Vector2(wing,0),wing,Color("ffdf9d"))
			draw_line(p-Vector2(0,3),p+Vector2(0,4),Color("694b70"),2,true)
