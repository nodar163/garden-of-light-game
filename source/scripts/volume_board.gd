extends "res://scripts/scene_3d.gd"
const Rules=preload("res://scripts/puzzle.gd")
static var path_meshes: Dictionary={}
var cells: Array=[]
var pieces: Array=[]
var covers: Array=[]
var piece_keys: Array=[]
var tracks: Array=[]
var n:=0
var effect_nodes: Array=[]
var effect_key:=""

func initialize(count: int, light_paths: bool=false) -> void:
	n=count; sun.shadow_enabled=true
	pose(Vector3.ZERO,n+.35,true)
	camera.position=Vector3(0,18,5); camera.look_at(Vector3.ZERO,Vector3.UP)
	block(Vector3(0,-.22,0),Vector3(n+.25,.32,n+.25),Color("406c65"))
	for i in n*n:
		var at:=Vector3(i%n-(n-1)/2.0,0,int(i/n)-(n-1)/2.0)
		var base:=block(at,Vector3(.94,.12,.94),Color("78a990") if light_paths else Color("699ba6"))
		cells.append(base)
		var root:=Node3D.new(); root.position=at; world.add_child(root); pieces.append(root); piece_keys.append("")
		var cover:=MeshInstance3D.new(); cover.position=at+Vector3(0,.35,0); world.add_child(cover); covers.append(cover)
		var track:=MeshInstance3D.new(); track.position=at+Vector3(0,.10,0); world.add_child(track); tracks.append(track)

func set_piece(i: int, kind: String, id: int=0) -> void:
	var key:=kind+str(id)
	if piece_keys[i]==key: return
	piece_keys[i]=key
	for child in pieces[i].get_children(): pieces[i].remove_child(child); child.queue_free()
	if not kind.is_empty(): pieces[i].add_child(Models.instance(kind,id))

static func path_mesh(kind: String, lit: bool) -> ArrayMesh:
	var key:=kind+str(lit)
	if path_meshes.has(key): return path_meshes[key]
	var b:=Models.new()
	var mask: int=Rules.mask(kind,0)
	for d in 4:
		if not mask & (1<<d): continue
		var step: Vector2i=Rules.STEPS[d]
		b.box(Vector3(step.x*.24,.025,step.y*.24),Vector3(.13 if step.x==0 else .52,.065,.13 if step.y==0 else .52),Color("ffdc82") if lit else Color("456052"))
	b.ball(Vector3(0,.055,0),Vector3(.20,.10,.20),Color("ffe8aa") if lit else Color("adc4a4"))
	path_meshes[key]=b.finish(); return path_meshes[key]

func sync_light(puzzle: RefCounted, blooms: Dictionary, hint: int) -> void:
	for i in n*n:
		var kind: String=puzzle.level.cells[i]
		var amount: float=float(blooms.get(i,0))
		tracks[i].mesh=path_mesh(kind,amount>.5)
		tracks[i].rotation.y=lerp_angle(tracks[i].rotation.y,float(puzzle.rotations[i])*PI/2,.32)
		set_piece(i,"flower" if kind=="plant" else "lamp" if kind=="source" else "",i%6)
		if kind=="plant": pieces[i].scale=Vector3.ONE*(.35+amount*.55)
		elif kind=="source": pieces[i].scale=Vector3.ONE*.43
		cells[i].scale.y=1.65 if i==hint else 1.0

func sync_match(model: RefCounted, shown: Dictionary, motion: Dictionary, blend: float, selected: int, hints: Array) -> void:
	var kind: String=motion.get("kind","")
	for i in n*n:
		var color_id: int=int(shown.cells[i])
		var power: String=shown.powers[i]
		set_piece(i,power if not power.is_empty() else "flower" if color_id>=0 else "",color_id if power.is_empty() else 0)
		var target:=Vector3(i%n-(n-1)/2.0,.1,int(i/n)-(n-1)/2.0)
		var visible_value: bool=color_id>=0
		var scale_value:=.85
		if kind=="swap":
			var origin: int=int(motion.b) if i==int(motion.a) else int(motion.a) if i==int(motion.b) else i
			var from:=Vector3(posmod(origin,n)-(n-1)/2.0,.1,floorf(float(origin)/n)-(n-1)/2.0)
			target=from.lerp(target,blend)
		elif kind=="fall":
			var origin: int=int(motion.from[i])
			target=Vector3(posmod(origin,n)-(n-1)/2.0,.1,floorf(float(origin)/n)-(n-1)/2.0).lerp(target,blend)
		elif kind=="clear" and i in motion.hit: scale_value*=maxf(.01,1-blend)
		elif kind=="shuffle": scale_value*=maxf(.01,blend)
		pieces[i].position=target; pieces[i].scale=Vector3.ONE*scale_value
		pieces[i].visible=visible_value and target.z>=-(n/2.0)
		var hp: int=int(shown.get("layers",model.layers)[i])
		covers[i].visible=hp>0
		if hp>0:
			covers[i].mesh=Models.mesh(["vine","ice","stone","pot"][int(model.obstacles[i])-1])
			covers[i].scale=Vector3.ONE*(.78 if hp==1 else .92)
		cells[i].position.y=.07 if i==selected or i in hints else 0
		tracks[i].visible=int(shown.dew[i])>0
		if tracks[i].visible:
			tracks[i].mesh=Models.mesh("ice"); tracks[i].scale=Vector3(.85,.06,.85)
	sync_effects(motion,blend)

func sync_effects(motion: Dictionary, blend: float) -> void:
	var effects: Array=motion.get("effects",[]) if motion.get("kind","")=="clear" else []
	var key:=JSON.stringify(effects)
	if key!=effect_key:
		effect_key=key
		for node in effect_nodes: node.queue_free()
		effect_nodes.clear()
		for effect in effects:
			var node: MeshInstance3D=Models.instance("bee" if effect.power=="bee" else "rainbow" if effect.power=="rainbow" else "burst")
			if effect.power in ["row","column"]:
				var b:=Models.new(); b.box(Vector3.ZERO,Vector3(n,.05,.10) if effect.power=="row" else Vector3(.10,.05,n),Color("ffe49c")); node.mesh=b.finish()
			world.add_child(node); effect_nodes.append(node)
	for i in effects.size():
		var effect: Dictionary=effects[i]; var at: int=int(effect.at)
		var pos:=Vector3(at%n-(n-1)/2.0,.8,int(at/n)-(n-1)/2.0)
		if effect.power=="bee":
			var to: int=int(effect.target)
			pos=pos.lerp(Vector3(to%n-(n-1)/2.0,.8,int(to/n)-(n-1)/2.0),blend)+Vector3(0,sin(blend*PI),0)
		elif effect.power=="row": pos.x=0
		elif effect.power=="column": pos.z=0
		effect_nodes[i].position=pos
		effect_nodes[i].scale=Vector3.ONE*maxf(.01,sin(blend*PI))*(1+blend*2 if effect.power=="burst" else 1)
