extends Control
## A safe practice board: it cannot access the save or spend anything.
signal practiced
const Art=preload("res://scripts/match_art.gd")
var section:="light"
var step:=0
var english:=false
var reduced:=false
var complete:=false
var selected:=false
var press_at:=Vector2.ZERO
var amount:=0.0
var animation: Tween
var caption: Label
func _ready() -> void:
	custom_minimum_size.y=145; mouse_filter=Control.MOUSE_FILTER_STOP; focus_mode=Control.FOCUS_ALL
	caption=Label.new(); caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; caption.add_theme_font_size_override("font_size",18); caption.add_theme_color_override("font_color",Color("355846")); caption.mouse_filter=Control.MOUSE_FILTER_IGNORE
	caption.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE); caption.offset_top=-30; add_child(caption)
	resized.connect(queue_redraw); reset(section,step)
func reset(key: String, page: int) -> void:
	if animation: animation.kill()
	section=key; step=page; complete=false; selected=false; amount=0; queue_redraw()
	if caption: caption.text=("Tap the highlighted example" if english else "Нажми на подсвеченный пример") if key in ["garden","light"] else ("Object > target: drag or tap both" if english else "Предмет > цель: перетащи или коснись обоих")
func source() -> Vector2: return Vector2(size.x*.23,57)
func target() -> Vector2: return Vector2(size.x*.77,57)
func perform() -> void:
	if complete: return
	complete=true; selected=false
	caption.text="Well done! No coins were spent." if english else "Получилось! Монеты не потрачены."
	if reduced: amount=1; queue_redraw()
	else:
		animation=create_tween()
		animation.tween_method(func(value: float): amount=value; queue_redraw(),0.0,1.0,.3)
	practiced.emit()
func _gui_input(event: InputEvent) -> void:
	if complete: return
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed:
			press_at=event.position; grab_focus()
			if section in ["garden","light"]: perform()
			elif selected and event.position.distance_to(target())<58: perform()
			elif event.position.distance_to(source())<58: selected=true; queue_redraw()
		elif selected and event.position.distance_to(target())<58: perform()
		accept_event()
	elif event is InputEventKey and event.pressed and event.keycode in [KEY_ENTER,KEY_SPACE]: perform(); accept_event()
func _draw() -> void:
	var a:=source(); var b:=target(); var c:=(a+b)/2
	draw_line(a,b,Color("b3c8a0"),3,true)
	draw_line(b-Vector2(12,9),b,Color("b3c8a0"),3,true); draw_line(b-Vector2(12,-9),b,Color("b3c8a0"),3,true)
	if section=="light":
		draw_circle(a,16,Color("f3c855")); Art.draw_icon(self,b,28,0)
		draw_line(c-Vector2(0,27).rotated(amount*PI/2),c+Vector2(0,27).rotated(amount*PI/2),Color("dfb556"),9,true)
	elif section=="garden":
		Art.draw_icon(self,a.lerp(b,amount),32,0); draw_arc(b,35,0,TAU,32,Color("85a871"),3,true)
	elif section=="match":
		Art.draw_icon(self,a.lerp(b,amount),29,0); Art.draw_icon(self,b.lerp(a,amount),29,1)
		Art.draw_icon(self,b+Vector2(-5,-40),20,0); Art.draw_icon(self,b+Vector2(-5,40),20,0)
	elif section=="nursery":
		draw_rect(Rect2(b-Vector2(38,20),Vector2(76,40)),Color("946745"))
		if step==0: draw_line(a-Vector2(0,25),a+Vector2(0,18),Color("997943"),7,true); draw_circle(a+Vector2(0,20),13,Color("a9bcb6"))
		elif step==1: Art.draw_icon(self,a.lerp(b,amount),26,0)
		else: draw_circle(a.lerp(b,amount),13,Color("68b7c7"))
		if complete: Art.draw_icon(self,b,26,0)
	else:
		if step==1: draw_colored_polygon(PackedVector2Array([a+Vector2(-24,-20),a+Vector2(24,-20),a+Vector2(0,26)]),Color("d6af7b"))
		else: Art.draw_icon(self,a.lerp(b,amount),30,0)
		draw_arc(b,36,0,TAU,32,Color("bd975b"),3,true)
	if not complete: draw_arc(c if section=="light" else b if selected else a,42,0,TAU,40,Color("e3b14a"),3,true)
