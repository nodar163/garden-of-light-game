extends RefCounted
## Real shared meshes: each coloured model is a single draw call, never a sprite.
const FLOWERS=[Color("f75d98"),Color("ffc943"),Color("ae7cfa"),Color("44d4e7"),Color("ff9457"),Color("99d858")]
static var cache: Dictionary={}
static var material: StandardMaterial3D
var vertices:=PackedVector3Array()
var normals:=PackedVector3Array()
var colors:=PackedColorArray()
var indices:=PackedInt32Array()

func part(mesh: Mesh, at: Vector3, size_value: Vector3, color: Color, angles: Vector3=Vector3.ZERO) -> void:
	var arrays: Array=mesh.get_mesh_arrays() if mesh is PrimitiveMesh else mesh.surface_get_arrays(0)
	var points: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	var normal_values: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
	var triangles: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
	var basis_value:=Basis.from_euler(angles).scaled(size_value)
	var normal_basis:=basis_value.inverse().transposed()
	var offset: int=vertices.size()
	for i in points.size():
		vertices.append(at+basis_value*points[i])
		normals.append((normal_basis*normal_values[i]).normalized())
		colors.append(color*arrays[Mesh.ARRAY_COLOR][i] if arrays[Mesh.ARRAY_COLOR]!=null and arrays[Mesh.ARRAY_COLOR].size()>i else color)
	for i in triangles: indices.append(offset+i)

func ball(at: Vector3, size_value: Vector3, color: Color, angles: Vector3=Vector3.ZERO) -> void:
	var mesh:=SphereMesh.new(); mesh.radial_segments=20; mesh.rings=10
	part(mesh,at,size_value,color,angles)

func box(at: Vector3, size_value: Vector3, color: Color, angles: Vector3=Vector3.ZERO) -> void:
	# Rounded corners are actual geometry; shared models still have one draw call.
	var half:=size_value*.5
	var radius:=minf(.10,minf(half.x,minf(half.y,half.z))*.42)
	var rotation:=Basis.from_euler(angles)
	for axis in 3:
		var u: int=(axis+1)%3; var v: int=(axis+2)%3
		for side in [-1.0,1.0]:
			var offset:=vertices.size()
			for y in 4:
				for x in 4:
					var point:=Vector3.ZERO; point[axis]=half[axis]*side
					point[u]=[-half[u],-half[u]+radius,half[u]-radius,half[u]][x]
					point[v]=[-half[v],-half[v]+radius,half[v]-radius,half[v]][y]
					var core:=point.clamp(-half+Vector3.ONE*radius,half-Vector3.ONE*radius)
					var normal: Vector3=(point-core).normalized()
					point=core+normal*radius
					vertices.append(at+rotation*point); normals.append(rotation*normal)
					colors.append(color.darkened(.055*(1.0-normal.y)))
			for y in 3:
				for x in 3:
					var a:=offset+y*4+x; var b:=a+1; var c:=a+4; var d:=c+1
					if side>0: indices.append_array(PackedInt32Array([a,c,b,b,c,d]))
					else: indices.append_array(PackedInt32Array([a,b,c,b,d,c]))

func cylinder(at: Vector3, radius: float, height: float, color: Color, top: float=-1, angles: Vector3=Vector3.ZERO) -> void:
	var mesh:=CylinderMesh.new(); mesh.radial_segments=24
	mesh.top_radius=radius if top<0 else top; mesh.bottom_radius=radius; mesh.height=height
	part(mesh,at,Vector3.ONE,color,angles)

func finish() -> ArrayMesh:
	var arrays: Array=[]; arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices; arrays[Mesh.ARRAY_NORMAL]=normals; arrays[Mesh.ARRAY_COLOR]=colors; arrays[Mesh.ARRAY_INDEX]=indices
	var mesh:=ArrayMesh.new(); mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	if material==null:
		material=StandardMaterial3D.new(); material.vertex_color_use_as_albedo=true; material.vertex_color_is_srgb=true; material.roughness=.48
		material.albedo_color=Color(.88,.88,.88); material.metallic_specular=.32
	mesh.surface_set_material(0,material)
	return mesh

static func mesh(kind: String, variant: int=0) -> ArrayMesh:
	var key:=kind+str(variant)
	if cache.has(key): return cache[key]
	var b:=new()
	match kind:
		"flower": b.flower(variant)
		"focus":
			var torus:=TorusMesh.new(); torus.inner_radius=.68; torus.outer_radius=.73; torus.rings=24; torus.ring_segments=6
			b.part(torus,Vector3.ZERO,Vector3.ONE,Color("ffda7b"))
		"sprout", "bud":
			b.cylinder(Vector3(0,.17,0),.035,.34,Color("588658"))
			for s in [-1,1]: b.ball(Vector3(s*.11,.17,0),Vector3(.3,.08,.15),Color("89ba71"),Vector3(0,s*.3,s*.4))
			if kind=="bud": b.ball(Vector3(0,.39,0),Vector3(.28,.35,.28),FLOWERS[variant%6])
			else: b.ball(Vector3(0,.29,0),Vector3(.13,.12,.13),Color("9ac177"))
		"tree": b.tree(variant)
		"shop", "house", "greenhouse": b.building(kind,variant)
		"person": b.person(variant)
		"bed": b.bed(variant)
		"seed": b.seed(variant)
		"watering": b.watering()
		"spade":
			b.cylinder(Vector3(0,.62,0),.05,1.1,Color("ad7951")); b.box(Vector3(0,.12,0),Vector3(.32,.27,.07),Color("98adb3")); b.box(Vector3(0,1.16,0),Vector3(.26,.08,.08),Color("b99361"))
		"hammer": b.cylinder(Vector3(0,.4,0),.065,.75,Color("bd9460")); b.box(Vector3(0,.85,0),Vector3(.6,.25,.29),Color("97b5b1"))
		"basket": b.basket()
		"counter": b.counter()
		"shelf": b.shelf()
		"cash": b.cash()
		"fountain": b.fountain()
		"bench": b.bench()
		"gate", "pergola":
			for x in [-1.0,1.0]:
				for z in [-.5,.5]: b.box(Vector3(x,.85,z),Vector3(.16,1.7,.16),Color("d9b78c"))
			for i in 7: b.box(Vector3(-1.2+i*.4,1.72,0),Vector3(.10,.10,1.5),Color("e9c99a"))
			if kind=="gate":
				for x in [-.5,.5]: b.box(Vector3(x,.60,0),Vector3(.9,.9,.07),Color("82ae8f"))
			else:
				for x in [-1.0,1.0]: b.ball(Vector3(x,1.8,0),Vector3(.6,.35,1.4),Color("84b36b"))
		"birdhouse", "hive":
			b.cylinder(Vector3(0,.45,0),.08,.9,Color("a28463"))
			b.box(Vector3(0,.95,0),Vector3(.65,.55,.52),Color("e1b979")); b.cylinder(Vector3(0,1.15,0),.52,.25,Color("84ae92"),0)
			b.ball(Vector3(0,.98,.275),Vector3(.18,.18,.04),Color("715442"))
		"rabbit":
			b.ball(Vector3(0,.3,0),Vector3(.6,.6,.55),Color("ece2cf")); b.ball(Vector3(0,.69,.08),Vector3(.4,.4,.4),Color("f5e9d7"))
			for s in [-1,1]: b.ball(Vector3(s*.12,1.02,.02),Vector3(.13,.49,.15),Color("e4d2bf"),Vector3(0,0,s*.13)); b.ball(Vector3(s*.1,.72,.265),Vector3(.035,.035,.035),Color("665851"))
		"sundial": b.cylinder(Vector3(0,.32,0),.25,.64,Color("beccba")); b.cylinder(Vector3(0,.69,0),.5,.12,Color("dfdcc0")); b.box(Vector3(0,.88,0),Vector3(.06,.32,.31),Color("b7a277"),Vector3(0,0,-.6))
		"urn", "cart":
			b.basket()
			for i in 3: b.part(mesh("flower",i),Vector3((i-1)*.3,.42,0),Vector3.ONE*.75,Color.WHITE)
			if kind=="cart":
				for s in [-1,1]: b.cylinder(Vector3(s*.55,.19,0),.24,.12,Color("86715b"),-1,Vector3(0,0,PI/2))
		"lamp":
			b.cylinder(Vector3(0,.5,0),.04,1,Color("396153")); b.box(Vector3(0,1.13,0),Vector3(.28,.32,.28),Color("ffe7a0")); b.cylinder(Vector3(0,1.37,0),.23,.18,Color("305e4f"),0)
		"burst":
			b.ball(Vector3(0,.35,0),Vector3(.75,.72,.75),Color("514678")); b.cylinder(Vector3(0,.79,0),.045,.28,Color("d2a463")); b.ball(Vector3(.05,.94,0),Vector3(.15,.15,.15),Color("ffd75b")); b.cylinder(Vector3(0,.68,0),.22,.07,Color("edd08a")); b.ball(Vector3(-.15,.48,.28),Vector3(.19,.13,.08),Color("9f8db5"))
		"bee":
			b.ball(Vector3(0,.25,0),Vector3(.14,.35,.45),Color("795467"))
			for s in [-1,1]:
				b.ball(Vector3(s*.24,.3,-.1),Vector3(.53,.12,.53),Color("ef9ab9"),Vector3(0,s*.5,s*.15)); b.ball(Vector3(s*.20,.28,.25),Vector3(.38,.1,.36),Color("ffd072"))
				b.ball(Vector3(s*.29,.37,-.13),Vector3(.20,.03,.23),Color("ba68de")); b.ball(Vector3(s*.29,.391,-.13),Vector3(.075,.024,.08),Color("fff2ba"))
		"row", "column":
			b.box(Vector3(0,.2,0),Vector3(.7,.32,.32),Color("64bdd6")); b.cylinder(Vector3(.35,.2,0),.23,.27,Color("f7dc7d"),0,Vector3(0,0,-PI/2)); b.box(Vector3(-.3,.2,0),Vector3(.1,.5,.5),Color("f0bc6a"))
		"rainbow":
			for i in 6: b.ball(Vector3(sin(i*TAU/6)*.22,.26,cos(i*TAU/6)*.22),Vector3(.33,.43,.33),FLOWERS[i])
			b.ball(Vector3(0,.42,0),Vector3(.26,.26,.26),Color("fff2cb"))
		"ice": b.box(Vector3(0,.22,0),Vector3(.8,.42,.8),Color("a2e5f4")); b.box(Vector3(0,.45,0),Vector3(.56,.06,.57),Color("e2faff"),Vector3(0,.4,0))
		"stone": b.ball(Vector3(0,.18,0),Vector3(.83,.52,.78),Color("84989a")); b.ball(Vector3(.2,.37,-.1),Vector3(.38,.26,.36),Color("bac8bc"))
		"vine":
			for i in 4: b.ball(Vector3(sin(i*2.4)*.3,.18,cos(i*2.4)*.3),Vector3(.24,.18,.65),Color("77a85e"),Vector3(0,i*2.4,0))
		"pot": b.cylinder(Vector3(0,.22,0),.32,.45,Color("dd9769"),.39); b.cylinder(Vector3(0,.48,0),.4,.1,Color("f1b789")); b.cylinder(Vector3(0,.54,0),.32,.03,Color("77523d"))
		_: b.box(Vector3.ZERO,Vector3.ONE,Color("83ac74"))
	cache[key]=b.finish()
	return cache[key]

static func instance(kind: String, variant: int=0, position_value: Vector3=Vector3.ZERO, scale_value: float=1.0) -> MeshInstance3D:
	var node:=MeshInstance3D.new(); node.mesh=mesh(kind,variant); node.position=position_value; node.scale=Vector3.ONE*scale_value
	return node

func flower(id: int) -> void:
	var color: Color=FLOWERS[posmod(id,6)]
	cylinder(Vector3(0,.19,0),.036,.38,Color("22804e"),.025)
	for side in [-1,1]:
		ball(Vector3(side*.14,.16+side*.045,0),Vector3(.38,.075,.16),Color("53bb62"),Vector3(0,side*.45,side*.36))
		cylinder(Vector3(side*.12,.18+side*.045,.005),.007,.25,Color("ade87f"),.004,Vector3(0,0,side*-.9))
	var count: int=[6,10,7,5,8,10][posmod(id,6)]
	var layers: int=3 if id in [4,5] else 2 if id==2 else 1
	for layer in layers:
		var reach: float=.25-layer*.06
		for i in count:
			var a:=TAU*i/count+layer*.31
			var tone: Color=color.lightened(layer*.11)
			ball(Vector3(sin(a)*reach,.43+layer*.06,cos(a)*reach),Vector3((.17 if id==1 else .30 if id==3 else .25)-layer*.03,.14,(.51 if id==1 else .40 if id==3 else .46)-layer*.08),tone,Vector3(.22+layer*.15,a,0))
			ball(Vector3(sin(a)*(reach+.095),.475+layer*.06,cos(a)*(reach+.095)),Vector3(.13,.045,.19),tone.lightened(.13),Vector3(.22,a,0))
	ball(Vector3(0,.52+layers*.025,0),Vector3(.25,.15,.25),Color("ffa92e"))
	for i in 12:
		var a:=i*2.4; var r:=.028+float(i%3)*.027
		ball(Vector3(sin(a)*r,.60+layers*.025,cos(a)*r),Vector3(.035,.028,.035),Color("ffe977"))

func tree(id: int) -> void:
	cylinder(Vector3(0,.7,0),.19,1.4,Color("a87443"),.13)
	for side in [-1,1]: cylinder(Vector3(side*.20,1.16,0),.075,.67,Color("b68145"),.045,Vector3(0,0,side*-.6))
	var green: Color=Color("53a94e") if id%3==0 else Color("79bd43") if id%3==1 else Color("3aab70")
	for i in 7:
		var a:=i*2.4
		ball(Vector3(sin(a)*.46,1.5+(i%3)*.30,cos(a)*.40),Vector3(1.13,1.13,1.09),green.lightened(.025*(i%3)))
	ball(Vector3(0,2.25,0),Vector3(1.12,1.0,1.16),green.lightened(.14))
	for i in 6:
		var a:=i*2.3
		ball(Vector3(sin(a)*.66,1.75+(i%2)*.35,cos(a)*.66),Vector3(.39,.24,.50),green.lightened(.13),Vector3(0,a,.2))
	if id%4==0:
		for i in 5: ball(Vector3(sin(i*2.4)*.68,1.6+(i%2)*.4,cos(i*2.4)*.68),Vector3(.16,.19,.16),Color("ff9767"))

func bed(id: int) -> void:
	box(Vector3(0,.09,0),Vector3(1.95,.18,1.12),Color("bfa67c"))
	box(Vector3(0,.19,0),Vector3(1.76,.12,.94),Color("785843") if id==0 else Color("90684b"))
	for i in 4: box(Vector3(-.65+i*.43,.27,0),Vector3(.07,.04,.80),Color("654b38"))
	for s in [-1,1]: box(Vector3(0,.23,s*.56),Vector3(2,.22,.09),Color("dfc397"))

func seed(id: int) -> void:
	box(Vector3(0,.35,0),Vector3(.5,.7,.11),Color("f4e4bc"))
	ball(Vector3(0,.4,.065),Vector3(.3,.3,.08),FLOWERS[id%6])
	box(Vector3(0,.12,.07),Vector3(.29,.035,.025),Color("6c9b6a"))

func watering() -> void:
	cylinder(Vector3(0,.3,0),.25,.46,Color("57acb1"),.23)
	cylinder(Vector3(.38,.4,0),.06,.58,Color("79c6c4"),.11,Vector3(0,0,-.95))
	box(Vector3(-.29,.43,0),Vector3(.09,.45,.08),Color("e0c988")); box(Vector3(-.13,.64,0),Vector3(.35,.07,.08),Color("e0c988"))

func basket() -> void:
	box(Vector3(0,.24,0),Vector3(.96,.48,.66),Color("cf9d65"))
	for i in 5: box(Vector3(0,.07+i*.09,.34),Vector3(1,.025,.02),Color("efd2a3"))
	for s in [-1,1]: cylinder(Vector3(s*.42,.67,0),.035,.45,Color("e7c38d"))
	box(Vector3(0,.90,0),Vector3(.88,.065,.065),Color("e7c38d"))

func building(kind: String, tier: int) -> void:
	var wall:=Color("fff0bd") if kind!="greenhouse" else Color("91dfcf")
	box(Vector3(0,.85,0),Vector3(2.8,1.7,2.0),wall)
	for s in [-1,1]: box(Vector3(s*.77,1.15,1.015),Vector3(.66,.64,.05),Color("65b8c0")); box(Vector3(s*.77,1.15,1.06),Vector3(.04,.65,.07),Color("fff6d7"))
	box(Vector3(0,.58,1.025),Vector3(.55,1.16,.06),Color("458573"))
	ball(Vector3(.16,.57,1.08),Vector3(.075,.075,.075),Color("f0cd78"))
	for s in [-1,1]: box(Vector3(s*.73,2.01,0),Vector3(1.8,.13,2.6),Color("3fbeb0") if kind=="greenhouse" else Color("df645d"),Vector3(0,0,s*-.35))
	box(Vector3(0,2.29,0),Vector3(.16,.11,2.67),Color("ffb164"))
	box(Vector3(0,.045,1.16),Vector3(3.1,.09,1.05),Color("e4cfab"))
	for x in [-1.36,1.36]: box(Vector3(x,.87,1.04),Vector3(.11,1.75,.12),Color("e7cda6"))
	for s in [-1,1]:
		box(Vector3(s*.77,.73,1.09),Vector3(.85,.15,.22),Color("b38967"))
		for i in 2: part(mesh("flower",i),Vector3(s*.77+(i-.5)*.25,.8,1.1),Vector3.ONE*.33,Color.WHITE)
		box(Vector3(s*.77,1.15,1.08),Vector3(.66,.035,.04),Color("fff6dc"))
	for side in [-1,1]:
		for row in 4:
			for tile in 7:
				box(Vector3(side*(.20+row*.35),2.25-row*.12,-1.12+tile*.37),Vector3(.42,.075,.34),Color("f17c66") if kind!="greenhouse" else Color("68d6ca"),Vector3(0,0,side*-.35))
	box(Vector3(0,.065,1.9),Vector3(1.25,.13,.48),Color("ffd7a0"))
	for side in [-1,1]:
		part(mesh("pot"),Vector3(side*1.2,.09,1.5),Vector3.ONE*.7,Color.WHITE)
		part(mesh("flower",2 if side<0 else 0),Vector3(side*1.2,.45,1.5),Vector3.ONE*.75,Color.WHITE)
	if kind=="shop":
		box(Vector3(0,1.21,1.55),Vector3(3.15,.12,1.1),Color("fff6d7"),Vector3(.18,0,0))
		for i in 7: box(Vector3(-1.32+i*.44,1.24,1.56),Vector3(.21,.13,1.12),Color("5b9b86"),Vector3(.18,0,0))
		for s in [-1,1]: cylinder(Vector3(s*1.5,.6,2),.04,1.2,Color("946f4c"))
		box(Vector3(0,1.65,1.04),Vector3(1.45,.28,.10),Color("436e55"))
		if tier>=3: ball(Vector3(0,1.68,1.13),Vector3(.17,.17,.1),Color("ffd976"))
	if kind=="greenhouse":
		for i in range(-2,3): box(Vector3(i*.55,1.0,1.06),Vector3(.05,1.7,.06),Color("fff5da"))

func person(id: int) -> void:
	var shirt: Color=[Color("e8969f"),Color("74b4c9"),Color("bc9fdc"),Color("ecbd69")][id%4]
	if id==4: shirt=Color("79a575")
	if id==5: shirt=Color("b091c9")
	for s in [-1,1]:
		cylinder(Vector3(s*.12,.18,0),.075,.36,Color("566573")); ball(Vector3(s*.12,.025,.055),Vector3(.17,.12,.26),Color("5d5247"))
	ball(Vector3(0,.63,0),Vector3(.55,.75,.33),shirt)
	for s in [-1,1]: ball(Vector3(s*.29,.57,0),Vector3(.15,.53,.18),shirt,Vector3(0,0,s*.14))
	ball(Vector3(0,1.15,0),Vector3(.48,.52,.45),Color("f1c5a0"))
	ball(Vector3(0,1.1,.23),Vector3(.075,.09,.11),Color("e6b28e"))
	for s in [-1,1]: ball(Vector3(s*.235,1.13,0),Vector3(.08,.14,.1),Color("ecc09a"))
	ball(Vector3(0,1.35,-.03),Vector3(.52,.27,.48),Color("765341") if id%2==0 else Color("a8734d"))
	if id==4:
		ball(Vector3(0,1.46,0),Vector3(.58,.21,.55),Color("c7b17c")); box(Vector3(0,1.42,.20),Vector3(.68,.045,.42),Color("e1c994"))
		ball(Vector3(0,.58,.14),Vector3(.4,.58,.12),Color("6a9ead"))
		for s in [-1,1]: box(Vector3(s*.12,.84,.13),Vector3(.065,.30,.025),Color("87b5c1"),Vector3(0,0,s*-.14)); ball(Vector3(s*.12,.71,.20),Vector3(.04,.04,.025),Color("e7c886"))
		ball(Vector3(0,.98,.13),Vector3(.3,.12,.23),Color("a98160"))
	if id==5:
		ball(Vector3(0,1.15,-.15),Vector3(.56,.64,.35),Color("614938"))
		cylinder(Vector3(0,.50,0),.35,.4,shirt,.22)
	for s in [-1,1]: ball(Vector3(s*.09,1.16,.21),Vector3(.037,.049,.024),Color("4b4846"))
	for side in [-1,1]:
		ball(Vector3(side*.092,1.17,.219),Vector3(.078,.09,.038),Color("fff8e9"))
		ball(Vector3(side*.090,1.169,.24),Vector3(.040,.058,.025),Color("39474c"))
		ball(Vector3(side*.083,1.185,.256),Vector3(.014,.019,.010),Color.WHITE)
		ball(Vector3(side*.095,1.239,.205),Vector3(.092,.027,.039),Color("76523e"),Vector3(0,0,side*-.12))
		ball(Vector3(side*.16,1.095,.18),Vector3(.065,.046,.019),Color("eea186"))
		ball(Vector3(side*.32,.32,.018),Vector3(.13,.16,.15),Color("f1c5a0"))
	ball(Vector3(0,1.042,.224),Vector3(.12,.049,.031),Color("a75854"))
	ball(Vector3(0,1.054,.244),Vector3(.081,.019,.012),Color("fff6e3"))

func counter() -> void:
	box(Vector3(0,.48,0),Vector3(2.9,.96,1.1),Color("38b9a0"))
	box(Vector3(0,1,0),Vector3(3.15,.15,1.25),Color("ffe2b3"))
	for i in 6: box(Vector3(-1.2+i*.48,.47,.56),Vector3(.018,.77,.02),Color("679581"))

	for x in [-.95,0,.95]:
		box(Vector3(x,.48,.56),Vector3(.72,.62,.04),Color("1c968b"))
		box(Vector3(x,.48,.588),Vector3(.60,.48,.025),Color("5ed3bb"))
		ball(Vector3(x,.65,.617),Vector3(.065,.065,.035),Color("ffe17c"))

func shelf() -> void:
	for s in [-1,1]: box(Vector3(s*.69,.53,0),Vector3(.09,1.06,.55),Color("947457"))
	for i in 3: box(Vector3(0,.15+i*.38,0),Vector3(1.5,.09,.64),Color("ffe1a7"))
	box(Vector3(0,.48,-.25),Vector3(1.42,.91,.06),Color("65cdb0"))
	for x in [-.5,0,.5]: cylinder(Vector3(x,.93,0),.17,.27,Color("f4c990"),.22)


func cash() -> void:
	box(Vector3(0,.12,0),Vector3(.58,.24,.47),Color("688f83")); box(Vector3(0,.36,-.10),Vector3(.5,.31,.12),Color("46685d"),Vector3(-.2,0,0)); box(Vector3(0,.38,-.02),Vector3(.36,.13,.03),Color("e6f3d6"))
	for i in 6: box(Vector3(-.15+(i%3)*.15,.25,.05+(i/3)*.10),Vector3(.07,.025,.06),Color("eddfbd"))

func fountain() -> void:
	cylinder(Vector3(0,.12,0),.9,.24,Color("d5c7a1")); cylinder(Vector3(0,.26,0),.76,.08,Color("69c4d1")); cylinder(Vector3(0,.55,0),.15,.6,Color("e1d3b6")); cylinder(Vector3(0,.9,0),.4,.12,Color("d5c7a1")); ball(Vector3(0,1.1,0),Vector3(.18,.34,.18),Color("a9e5e9"))

func bench() -> void:
	for s in [-1,1]: box(Vector3(s*.65,.24,0),Vector3(.1,.48,.52),Color("597b68"))
	for i in 3: box(Vector3(0,.48,-.2+i*.2),Vector3(1.7,.08,.16),Color("d1ad7a"))
	for i in 3: box(Vector3(0,.7+i*.15,-.3),Vector3(1.7,.09,.08),Color("d1ad7a"))
