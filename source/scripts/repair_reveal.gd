extends Control
const Map=preload("res://scripts/garden_map.gd")
var host: Control
var repair_id:=0
func _ready() -> void:
	size_flags_vertical=SIZE_EXPAND_FILL
	var box:=VBoxContainer.new(); box.set_anchors_and_offsets_preset(PRESET_FULL_RECT); box.add_theme_constant_override("separation",16); add_child(box)
	var zone: Vector4=Map.Restoration.ZONES[[0,2,3,4,5][repair_id]]
	for state in 2:
		var title:=Label.new(); title.text=host.words("БЫЛО","BEFORE") if state==0 else host.words("СТАЛО · благодаря тебе","AFTER · thanks to you"); title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; box.add_child(title)
		var art:=TextureRect.new(); var atlas:=AtlasTexture.new(); atlas.atlas=Map.BACKGROUND if state==0 else Map.RESTORED
		atlas.region=Rect2(Vector2(zone.x,zone.y)*atlas.atlas.get_size(),Vector2(zone.z,zone.w)*atlas.atlas.get_size())
		art.texture=atlas; art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED; art.size_flags_vertical=SIZE_EXPAND_FILL; box.add_child(art)
		if state==1 and not host.store.data.settings.reduce_motion:
			art.modulate.a=.15; art.create_tween().tween_property(art,"modulate:a",1.0,.65)
	var line:=Label.new(); line.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; line.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; line.add_theme_font_size_override("font_size",26)
	var ru: Array=["Джек: «Снова можно встречать гостей. Анна, мы возвращаемся!»","Джек: «Слышишь воду? Теперь и птицам есть куда вернуться».","Джек: «Теплица спасена. Здесь вырастут цветы для нашего следующего букета».","Анна: «Я знала, что ты откроешься снова. Соберёшь букет для мамы?»","Джек: «Теперь у нас есть место для всех, кто помог саду ожить». "]
	var en: Array=["Jack: ‘We can welcome people again. Anna, we're coming back!’","Jack: ‘Hear the water? The birds have a home again.’","Jack: ‘The greenhouse is saved. Our next bouquet will grow here.’","Anna: ‘I knew you would open again. Will you make a bouquet for Mum?’","Jack: ‘A place for everyone who helped our garden grow again.’"]
	line.text=host.words(ru[repair_id],en[repair_id]); box.add_child(line)
	host.button(host.words("Увидеть в саду","See it in the garden"),func():
		host.garden_ui.open_garden(); host.garden_ui.map_view.focus_place("repair",repair_id),box,true)
	host.button(host.words("Следующая цель","Next task"),host.show_home,box)
