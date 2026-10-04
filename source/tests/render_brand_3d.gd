extends SceneTree
const Scene=preload("res://scripts/scene_3d.gd")
func _initialize() -> void: call_deferred("run")

func compose(extent: Vector2i, icon: bool=false) -> Control:
	root.size=extent
	var scene=Scene.new(); scene.size=extent; root.add_child(scene)
	scene.resolution_scale=1.5; scene.fit()
	scene.block(Vector3(0,-.3,0),Vector3(14,.5,16),Color("a6c887"))
	scene.block(Vector3(0,-.02,0),Vector3(1.8,.06,14),Color("efd8af"))
	scene.add("house",Vector3(-2.4,0,-3.0),1.25)
	scene.add("pergola",Vector3(2.7,0,-1.9),1.1)
	scene.add("fountain",Vector3(0,0,-3.3),.8)
	for i in 10: scene.add("tree",Vector3(-4.7 if i%2==0 else 4.7,0,-4.0+int(i/2)*2.1),.85,i)
	for i in 18: scene.add("flower",Vector3(-1.6-(i%3)*.8 if i%2==0 else 1.6+(i%3)*.8,.1,-2+int(i/6)*2.5),1.4,i%6)
	var jack: MeshInstance3D=scene.add("person",Vector3(0,0,1.4),2.2,4)
	jack.rotation.y=-.2
	scene.add("basket",Vector3(1.0,0,1.8),1.05)
	for i in 3: scene.add("flower",Vector3(.8+i*.2,.5,1.8),.8,i)
	scene.camera.size=4.6 if icon else 9.7
	scene.camera.position=Vector3(.1,5.4,7.8) if icon else Vector3(0,13.6,13.8)
	scene.camera.look_at(Vector3(0,1.7,1.4) if icon else Vector3(0,.8,.2),Vector3.UP)
	if not icon:
		var title:=Label.new(); title.text="САД\nДЖЕКА"; title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; title.add_theme_font_size_override("font_size",76)
		title.add_theme_color_override("font_color",Color("fff0ba")); title.add_theme_color_override("font_outline_color",Color("315c49")); title.add_theme_constant_override("outline_size",12)
		title.position=Vector2(0,80); title.size=Vector2(extent.x,220); root.add_child(title)
		var copy:=Label.new(); copy.text="История начинается с одного цветка"; copy.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; copy.add_theme_font_size_override("font_size",28); copy.add_theme_color_override("font_color",Color("fff5d3")); copy.add_theme_color_override("font_outline_color",Color("315c49")); copy.add_theme_constant_override("outline_size",6); copy.position=Vector2(0,1110); copy.size.x=extent.x; root.add_child(copy)
	return scene

func run() -> void:
	var scene:=compose(Vector2i(720,1280))
	for i in 15: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://assets/jack-garden-splash.png")
	for child in root.get_children(): child.queue_free()
	await process_frame
	scene=compose(Vector2i(512,512),true)
	for i in 15: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://assets/jack-garden-icon.png")
	print("3D loading artwork rendered from models")
	scene.queue_free(); await process_frame; quit()
