extends Control
const Models=preload("res://scripts/models_3d.gd")
var viewport: SubViewport
var world: Node3D
var camera: Camera3D
var sun: DirectionalLight3D
var resolution_scale:=1.0

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	viewport=SubViewport.new(); viewport.own_world_3d=true; viewport.transparent_bg=false
	viewport.msaa_3d=Viewport.MSAA_2X
	viewport.render_target_update_mode=SubViewport.UPDATE_WHEN_VISIBLE
	add_child(viewport)
	var image:=TextureRect.new(); image.texture=viewport.get_texture(); image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; image.stretch_mode=TextureRect.STRETCH_SCALE; image.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(image); image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	world=Node3D.new(); viewport.add_child(world)
	var environment:=WorldEnvironment.new(); var env:=Environment.new()
	env.background_mode=Environment.BG_COLOR; env.background_color=Color("c5e2dc")
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color=Color("d9e8ff"); env.ambient_light_energy=.42
	env.tonemap_mode=Environment.TONE_MAPPER_LINEAR
	environment.environment=env; world.add_child(environment)
	sun=DirectionalLight3D.new(); sun.rotation_degrees=Vector3(-65,-35,0); sun.light_color=Color("fff0e0"); sun.light_energy=.72
	sun.shadow_opacity=.55; sun.shadow_enabled=true; sun.directional_shadow_mode=DirectionalLight3D.SHADOW_ORTHOGONAL; sun.shadow_bias=.05
	world.add_child(sun)
	var fill:=DirectionalLight3D.new(); fill.rotation_degrees=Vector3(-30,145,0); fill.light_color=Color("ceeaff"); fill.light_energy=.18; world.add_child(fill)
	camera=Camera3D.new(); camera.projection=Camera3D.PROJECTION_ORTHOGONAL; camera.size=10; camera.near=.1; camera.far=100; world.add_child(camera)
	pose(Vector3.ZERO,10)
	resized.connect(fit); fit()

func fit() -> void:
	if viewport==null: return
	var factor: float=minf(1.0,900.0/maxf(size.x,size.y))*resolution_scale
	viewport.size=Vector2i(maxi(1,int(size.x*factor)),maxi(1,int(size.y*factor)))

func pose(target: Vector3, extent: float, overhead: bool=false) -> void:
	camera.size=extent
	camera.position=target+Vector3(0,22,.01) if overhead else target+Vector3(0,18,14)
	camera.look_at(target,Vector3.FORWARD if overhead else Vector3.UP)

func project(point: Vector3) -> Vector2:
	return camera.unproject_position(point)*size/Vector2(viewport.size)

func ground_at(point: Vector2, height: float=0) -> Vector3:
	var p:=point*Vector2(viewport.size)/Vector2(maxf(1,size.x),maxf(1,size.y))
	var origin:=camera.project_ray_origin(p); var direction:=camera.project_ray_normal(p)
	if absf(direction.y)<.0001: return Vector3(origin.x,height,origin.z)
	return origin+direction*((height-origin.y)/direction.y)

func add(kind: String, at: Vector3, scale_value: float=1, variant: int=0) -> MeshInstance3D:
	var node:=Models.instance(kind,variant,at,scale_value); world.add_child(node); return node

func block(at: Vector3, dimensions: Vector3, color: Color) -> MeshInstance3D:
	var b:=Models.new(); b.box(Vector3.ZERO,dimensions,color)
	var node:=MeshInstance3D.new(); node.mesh=b.finish(); node.position=at; world.add_child(node); return node

func title(value: String, at: Vector3, font_size: int=42) -> Label3D:
	var label:=Label3D.new(); label.text=value; label.font_size=font_size; label.pixel_size=.012
	label.position=at; label.billboard=BaseMaterial3D.BILLBOARD_ENABLED; label.modulate=Color("245c58"); label.outline_modulate=Color("fff1d1"); label.outline_size=3; label.no_depth_test=true
	world.add_child(label); return label
