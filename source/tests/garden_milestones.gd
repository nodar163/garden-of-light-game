extends SceneTree
const Rules=preload("res://scripts/garden_rules.gd")
const Story=preload("res://scripts/garden_story.gd")
const Saves=preload("res://scripts/save_store.gd")
const Main=preload("res://scripts/main.gd")
var checks:=0
var failures:=0
func check(ok: bool,title: String) -> void:
	checks+=1
	if not ok: failures+=1; printerr("FAIL: ",title)
func _initialize() -> void: call_deferred("run")
func capture(name: String) -> void:
	await process_frame; await process_frame; await RenderingServer.frame_post_draw
	if DisplayServer.get_name()!="headless": root.get_texture().get_image().save_png("res://artifacts/milestone-"+name+".png")
func run() -> void:
	var data: Dictionary=Saves.defaults(); Rules.sync(data)
	var garden: Dictionary=data.garden
	garden.story.erase("milestones")
	check(Rules.valid(garden),"legacy story is valid")
	Story.ensure(garden)
	check(garden.story.milestones.is_empty(),"legacy save migrates")
	check(not Story.milestone_claim(garden,0),"early milestone cannot be claimed")
	var money: int=garden.coins
	for id in 8:
		var target: int=int(Story.MILESTONES[id][0])
		for i in range(garden.earned.size()+1,target+1):
			if i<=250: data.completed.append(i)
			else: data.match3.completed.append(i-250)
		Rules.sync(data)
		check(Story.milestone_ready(garden,id),"milestone ready %d" % id)
		check(Story.milestone_claim(garden,id),"claim %d" % id)
		check(not Story.milestone_claim(garden,id),"no duplicate %d" % id)
		check(garden.coins==money+target*Rules.REWARD,"no cost or duplicate coins %d" % id)
	check(garden.story.milestones.size()==8 and garden.earned.size()==500,"all campaign landmarks")
	check(Saves.valid(data),"landmarks serialize")
	var bad: Dictionary=data.duplicate(true); bad.garden.story.milestones.append(7)
	check(not Saves.valid(bad),"duplicate claim rejected")
	root.size=Vector2i(390,700)
	var game=Main.new(); game.store=Saves.new("user://milestones-"+str(OS.get_process_id())+".json"); game.store.data=data
	game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); root.add_child(game); await process_frame
	game.store.data=data
	game.garden_ui.journey(); await capture("journey-ru")
	game.garden_ui.open_garden(); await capture("garden-ru")
	game.store.data.settings.language="en"; game.garden_ui.journey(); await capture("journey-en")
	game.queue_free(); await process_frame; await create_timer(.2).timeout
	for suffix in ["",".tmp",".bak"]:
		var path: String="user://milestones-"+str(OS.get_process_id())+".json"+suffix
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	print("Milestones checks=",checks," failures=",failures); quit(1 if failures else 0)
