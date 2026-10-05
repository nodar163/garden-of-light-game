extends SceneTree
const Map=preload("res://scripts/garden_map.gd")
const Rules=preload("res://scripts/garden_rules.gd")
const Restoration=preload("res://scripts/garden_restoration.gd")
var checks:=0
var failures:=0
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures+=1; printerr("FAIL: ",message)
func _initialize() -> void:
	root.size=Vector2i(1536,1024); call_deferred("run")
func frame(g: Dictionary, name_value: String) -> Image:
	var map=Map.new(); map.garden=g; map.interactive=false; map.editing=false; map.reduced=true
	root.add_child(map); map.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	var result:=root.get_texture().get_image()
	result.save_png("res://artifacts/garden-"+name_value+".png")
	map.queue_free(); await process_frame
	return result
func sample(image: Image, point: Vector2) -> Color:
	return image.get_pixel(int(point.x*image.get_width()),int(point.y*image.get_height()))
func run() -> void:
	root.content_scale_size=Vector2i(1536,1024); root.size=Vector2i(1536,1024)
	await process_frame
	var g:=Rules.defaults(); Rules.Story.ensure(g); Rules.Farm.ensure(g)
	var saved:=g.duplicate(true)
	check(Restoration.weights(g)==PackedFloat32Array([0,0,0,0,0,0]),"new garden has no completed visual repair")
	var before: Image=await frame(g,"abandoned-full")
	check(g==saved,"drawing never changes coins, inventory or progress")
	g.coins=10000
	for i in 15: g.plots[str(i)]=0
	var points: Array=[Vector2(.28,.17),Vector2(.52,.48),Vector2(.79,.23),Vector2(.21,.63),Vector2(.88,.62)]
	for id in 5:
		check(Rules.repair(g,id),"repair %d completes with existing economy" % id)
		# Keep comparison scenes free of player decorations.
		var presentation: Dictionary=g.duplicate(true); presentation.plots={}
		var after: Image=await frame(presentation,"repair-"+str(id+1))
		check(sample(before,points[id])!=sample(after,points[id]),"repair %d visibly changes its landmark" % id)
		if id==1:
			check(sample(before,points[3])==sample(after,points[3]),"fountain restoration does not fix the shop")
		check(not Rules.repair(g,id),"duplicate repair does not charge twice")
	var json_copy: Dictionary=JSON.parse_string(JSON.stringify(g))
	check(Restoration.weights(json_copy)==PackedFloat32Array([1,1,1,1,1,1]),"completed repairs survive JSON load")
	print("Restoration checks=",checks," failures=",failures)
	quit(1 if failures else 0)
