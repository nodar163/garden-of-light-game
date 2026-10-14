extends SceneTree
const Main=preload("res://scripts/main.gd")
const Saves=preload("res://scripts/save_store.gd")
const Farm=preload("res://scripts/garden_farm.gd")
var game: Control
var canvas: SubViewport
const DEST="res://artifacts/google-play"
func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(DEST); canvas=SubViewport.new(); canvas.size=Vector2i(720,1280); canvas.render_target_update_mode=SubViewport.UPDATE_ALWAYS; root.add_child(canvas); call_deferred("run")
func shot(name_value: String) -> void:
	for i in 5: await process_frame
	await RenderingServer.frame_post_draw
	var image:=canvas.get_texture().get_image(); image.convert(Image.FORMAT_RGBA8 if name_value=="icon-512" else Image.FORMAT_RGB8); image.save_png(DEST+"/"+name_value+".png")
func run() -> void:
	game=Main.new(); game.store=Saves.new("user://play-assets-"+str(OS.get_process_id())+".json"); canvas.add_child(game); game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await process_frame
	game.store.data.garden.intro_done=true; game.store.data.tutorial_seen=preload("res://scripts/tutorial.gd").KEYS.duplicate()
	game.store.data.completed=range(1,61); game.store.data.match3.completed=range(1,61); Saves.Garden.sync(game.store.data)
	var g: Dictionary=game.store.data.garden; g.repairs=[0,1,2,3,4]; Farm.ensure(g)
	for id in 12: Saves.Garden.buy(g,id,id%6)
	g.farm.stock=[8,8,8,8,8,8]
	for slot in 6:
		Farm.plant(g,slot,slot%3)
		if g.farm.beds.has(str(slot)): g.farm.beds[str(slot)].growth=3 if slot%2==0 else 2
	for language in ["ru","en"]:
		game.store.data.settings.language=language
		game.show_home(); await shot("01-garden-"+language)
		game.open_match(18); await shot("02-cascade-"+language)
		game.open_level(18); await shot("03-light-"+language)
		game.garden_ui.business.shop(); await shot("04-shop-"+language)
		game.garden_ui.business.nursery(); await shot("05-nursery-"+language)
		game.show_settings(); await shot("settings-"+language)
		preload("res://scripts/privacy_ui.gd").show(game); await shot("privacy-"+language)
	game.queue_free(); await process_frame; await process_frame
	# Reuse the established icon without introducing a different brand.
	canvas.size=Vector2i(512,512)
	var icon:=TextureRect.new(); icon.texture=load("res://assets/jack-garden-icon.png"); icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; icon.stretch_mode=TextureRect.STRETCH_SCALE; canvas.add_child(icon); icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await shot("icon-512"); icon.queue_free(); await process_frame
	# Code-composed promotional panel using the game's own map and portrait.
	canvas.size=Vector2i(1024,500)
	var panel:=Control.new(); canvas.add_child(panel); panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg:=TextureRect.new(); bg.texture=load("res://assets/garden-restored.png"); bg.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; bg.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED; panel.add_child(bg); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var veil:=ColorRect.new(); veil.color=Color(.025,.14,.10,.75); veil.position=Vector2(0,0); veil.size=Vector2(660,500); panel.add_child(veil)
	var portrait:=TextureRect.new(); portrait.texture=load("res://assets/jack.png"); portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED; portrait.position=Vector2(680,30); portrait.size=Vector2(310,440); panel.add_child(portrait)
	var heading:=Label.new(); heading.position=Vector2(55,105); heading.size=Vector2(600,140); heading.add_theme_font_size_override("font_size",78); heading.add_theme_color_override("font_color",Color("ffe6a1")); panel.add_child(heading)
	var sub:=Label.new(); sub.position=Vector2(60,245); sub.size=Vector2(570,150); sub.add_theme_font_size_override("font_size",32); sub.add_theme_color_override("font_color",Color("fff8e9")); panel.add_child(sub)
	for language in ["ru","en"]:
		heading.text="Сад Джека" if language=="ru" else "Jack's Garden"
		sub.text="Выращивай цветы.\nСобирай букеты.\nВозвращай саду жизнь." if language=="ru" else "Grow flowers.\nMake bouquets.\nBring the garden back to life."
		await shot("feature-1024x500-"+language)
	FileAccess.open(DEST+"/privacy-ru.txt",FileAccess.WRITE).store_string(preload("res://scripts/privacy_ui.gd").RU)
	FileAccess.open(DEST+"/privacy-en.txt",FileAccess.WRITE).store_string(preload("res://scripts/privacy_ui.gd").EN)
	print("Play assets generated from game views and existing original artwork."); quit()
