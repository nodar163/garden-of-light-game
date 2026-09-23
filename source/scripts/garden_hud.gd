extends RefCounted
## Floating controls over the actual garden, shared by home and editing.
const Map=preload("res://scripts/garden_map.gd")
const JACK=preload("res://assets/jack.png")
const INK=Color("244c42")
const SOFT=Color("68816a")
var game: Control
var map: Control
var content: VBoxContainer
var footer: VBoxContainer
var controls: VBoxContainer

static func plate(color: Color=Color("fff8e8"),radius: int=28) -> StyleBoxFlat:
	var s:=StyleBoxFlat.new(); s.bg_color=color; s.set_corner_radius_all(radius)
	s.border_color=Color("d4b978"); s.set_border_width_all(2)
	s.shadow_color=Color(0.06,.17,.13,.28); s.shadow_size=9; s.shadow_offset=Vector2(0,5)
	s.set_content_margin_all(20)
	return s

static func text(parent: Node,value: String,font: int=24,color: Color=INK) -> Label:
	var l:=Label.new(); l.text=value; l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size",font); l.add_theme_color_override("font_color",color)
	l.mouse_filter=Control.MOUSE_FILTER_IGNORE; parent.add_child(l); return l

static func card(parent: Node) -> VBoxContainer:
	var p:=PanelContainer.new(); p.add_theme_stylebox_override("panel",plate())
	parent.add_child(p); var box:=VBoxContainer.new(); box.add_theme_constant_override("separation",12); p.add_child(box)
	return box

static func face(parent: Node) -> void:
	var t:=AtlasTexture.new(); t.atlas=JACK
	var extent:=Vector2(JACK.get_width(),JACK.get_height())
	t.region=Rect2(extent*Vector2(.21,.025),extent*Vector2(.57,.42))
	var v:=TextureRect.new(); v.texture=t; v.custom_minimum_size=Vector2(92,112)
	v.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; v.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	v.mouse_filter=Control.MOUSE_FILTER_IGNORE; parent.add_child(v)

func _init(host: Control,screen: String) -> void:
	game=host; game.clear_page(screen)
	game.shell.remove_child(game.root_box); game.root_box.queue_free()
	var stage:=Control.new(); stage.mouse_filter=Control.MOUSE_FILTER_IGNORE; game.shell.add_child(stage)
	map=Map.new(); map.garden=game.store.data.garden; map.interactive=true
	map.editing=screen=="garden"; map.presentation=screen!="garden"
	stage.add_child(map); map.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin:=MarginContainer.new(); margin.mouse_filter=Control.MOUSE_FILTER_IGNORE; stage.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,24)
	var stack:=VBoxContainer.new(); stack.mouse_filter=Control.MOUSE_FILTER_IGNORE; stack.add_theme_constant_override("separation",16); margin.add_child(stack)
	var top:=HBoxContainer.new(); top.mouse_filter=Control.MOUSE_FILTER_IGNORE; top.add_theme_constant_override("separation",12); stack.add_child(top)
	if screen!="home":
		var back: Button=game.button("‹",game.show_home,top); back.custom_minimum_size=Vector2(76,76); back.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN; back.size_flags_vertical=Control.SIZE_SHRINK_BEGIN; back.add_theme_font_size_override("font_size",40)
	var brand:=VBoxContainer.new(); brand.mouse_filter=Control.MOUSE_FILTER_IGNORE; brand.size_flags_horizontal=Control.SIZE_EXPAND_FILL; top.add_child(brand)
	var heading: String=game.words("САД СВЕТА","GARDEN OF LIGHT") if screen=="home" else game.words("РЕЖИМЫ","GAME MODES") if screen=="garden_modes" else game.words("ЛАВКА","FLOWER SHOP") if screen=="garden_shop" else game.words("МОЙ САД","MY GARDEN")
	var name_label:=text(brand,heading,30,Color("fff9dd"))
	name_label.add_theme_color_override("font_outline_color",Color("234939")); name_label.add_theme_constant_override("outline_size",8)
	var subtitle:=text(brand,game.words("История Джека","Jack's story"),20,Color("fff9dd"))
	subtitle.add_theme_color_override("font_outline_color",Color("234939")); subtitle.add_theme_constant_override("outline_size",5)
	var money:=PanelContainer.new(); money.add_theme_stylebox_override("panel",plate(Color("fff0bd"),24)); money.custom_minimum_size=Vector2(142,76); money.size_flags_vertical=Control.SIZE_SHRINK_BEGIN; top.add_child(money)
	var balance:=text(money,"● "+str(game.store.data.garden.coins),28,Color("896019")); balance.autowrap_mode=TextServer.AUTOWRAP_OFF
	var settings: Button=game.button("☼",game.show_settings,top); settings.tooltip_text=game.words("Настройки","Settings"); settings.custom_minimum_size=Vector2(76,76); settings.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN; settings.size_flags_vertical=Control.SIZE_SHRINK_BEGIN; settings.add_theme_font_size_override("font_size",36)
	var space:=Control.new(); space.mouse_filter=Control.MOUSE_FILTER_IGNORE; space.size_flags_vertical=Control.SIZE_EXPAND_FILL; stack.add_child(space)
	var control_row:=HBoxContainer.new(); control_row.mouse_filter=Control.MOUSE_FILTER_IGNORE; stack.add_child(control_row)
	var empty:=Control.new(); empty.mouse_filter=Control.MOUSE_FILTER_IGNORE; empty.size_flags_horizontal=Control.SIZE_EXPAND_FILL; control_row.add_child(empty)
	controls=VBoxContainer.new(); controls.add_theme_constant_override("separation",10); control_row.add_child(controls)
	if screen=="garden":
		for item in [["+",func(): map.zoom_by(1.3)],["⌖",func(): map.overview()],["−",func(): map.zoom_by(1/1.3)]]:
			var b: Button=game.button(item[0],item[1],controls); b.custom_minimum_size=Vector2(76,76)
			b.tooltip_text=game.words("Центр сада","Garden centre") if item[0]=="⌖" else game.words("Масштаб","Zoom")
	footer=VBoxContainer.new(); footer.add_theme_constant_override("separation",12); stack.add_child(footer)
	content=card(footer); game.root_box=content
	footer.resized.connect(sync_map_frame)

func sync_map_frame() -> void:
	if not is_instance_valid(map) or not is_instance_valid(footer): return
	map.occluded_bottom=maxf(0,map.size.y-(footer.get_global_rect().position.y-map.get_global_rect().position.y))
	map.adjust()

func play_button(title: String,action: Callable) -> Button:
	var b: Button=game.button(title,action,footer,true); b.custom_minimum_size.y=100
	b.add_theme_font_size_override("font_size",30)
	for state in ["normal","hover","pressed"]:
		var s:=plate(Color("62b64a") if state=="normal" else Color("75c75b") if state=="hover" else Color("4b963c"),28)
		s.border_color=Color("c6ed81"); s.set_border_width_all(3); b.add_theme_stylebox_override(state,s)
	for state in ["font_color","font_hover_color","font_pressed_color"]: b.add_theme_color_override(state,Color.WHITE)
	b.add_theme_color_override("font_outline_color",Color("367030")); b.add_theme_constant_override("outline_size",4)
	return b

func nav(items: Array) -> void:
	var row:=HBoxContainer.new(); row.add_theme_constant_override("separation",12); footer.add_child(row)
	for item in items:
		var b: Button=game.button(item[0],item[1],row)
		b.custom_minimum_size.y=76; b.add_theme_font_size_override("font_size",23)

