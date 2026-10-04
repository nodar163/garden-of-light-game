extends "res://scripts/scene_3d.gd"
var kind:="flower"
var variant:=0
var flowers: Array=[]
var wrap_id:=0

func _ready() -> void:
	super._ready()
	viewport.transparent_bg=true; sun.shadow_enabled=false
	if kind=="bouquet":
		var b:=Models.new(); b.cylinder(Vector3(0,.15,0),.14,.7,[Color("edbb97"),Color("b7d5bb"),Color("d7c0dc")][clampi(wrap_id,0,2)],.5)
		for i in flowers.size(): b.part(Models.mesh("flower",int(flowers[i])),Vector3((i-1)*.32,.4,0),Vector3.ONE*.9,Color.WHITE)
		var model:=MeshInstance3D.new(); model.mesh=b.finish(); world.add_child(model)
	else: add(kind,Vector3.ZERO,1.0,variant)
	var extent: float=1.1 if kind=="flower" else 2.1 if kind=="person" else 1.6 if kind=="bouquet" else 1.5 if kind in ["hammer","spade","watering","row","column","rainbow","ice","stone"] else 4.7
	var target_y: float=.35 if kind=="flower" else .75 if kind=="person" else .4 if extent<2 else .8
	pose(Vector3(0,target_y,0),extent)
	# Thumbnails are actual 3D models rendered once, with no permanent frame cost.
	viewport.render_target_update_mode=SubViewport.UPDATE_ONCE

func fit() -> void:
	super.fit()
	if viewport!=null: viewport.render_target_update_mode=SubViewport.UPDATE_ONCE
