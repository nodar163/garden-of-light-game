extends SceneTree
const Saves=preload("res://scripts/save_store.gd")
const Estate=preload("res://scripts/estate_rules.gd")
const Farm=preload("res://scripts/garden_farm.gd")
const Requests=preload("res://scripts/garden_requests.gd")
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1; printerr("FAIL: ",label)
func _initialize() -> void:
	var save:=Saves.defaults(); var g: Dictionary=save.garden; Farm.ensure(g); g.repairs=[0,1,2,3,4]; g.coins=100000
	check(Saves.valid(save),"legacy save")
	g.farm.orders_done=500; g.farm.harvested=1000
	check(Estate.progress(g)==2000,"farm route can unlock all ordinary repairs")
	for stage in 3:
		for home in [false,true]:
			for id in 24: check(Estate.upgrade(g,home,id),"farm unlocks stage")
	check(not Estate.complete(g),"final honour still requires both modes")
	for room in 6: check(Estate.room_rank(g,room)==3,"room benefit reaches rank 3")
	var before: int=g.coins
	check(Estate.choose(g,true,0,2) and g.coins==before,"free permanent style")
	check(not Estate.choose(g,true,0,3),"unknown style rejected")
	check(Saves.valid(save),"new styles persist")
	var bad:=save.duplicate(true); bad.garden.estate_styles["house:0"]=0.5
	check(not Saves.valid(bad),"fractional style rejected")
	g.farm=Farm.defaults(); Farm.ensure(g)
	check(Farm.plant(g,0,0),"plant after repair")
	before=g.coins; check(Farm.cultivate(g,0) and g.coins==before-2,"kitchen reduces compost cost")
	for i in 3: Farm.grow(g)
	before=g.coins; check(Farm.harvest(g,0)==6 and g.coins==before+6,"conservatory and bedroom benefits")
	check(not Requests.claim(g),"cannot claim before fulfilling")
	for id in Requests.REQUESTS.size():
		var req: Array=Requests.REQUESTS[id]
		var picked: Array=[0,0,0,0,0,0]; picked[int(req[2])]=req[3]
		check(Requests.sold(g,picked),"request fulfilled")
		check(not Requests.sold(g,picked),"letter waits for reading")
		before=g.coins
		check(Requests.claim(g) and g.coins==before+60,"one story gift")
		check(not Requests.claim(g),"no duplicate gift")
	check(Saves.valid(save),"completed story persists")
	bad=save.duplicate(true); bad.garden.requests={"next":8,"ready":true}
	check(not Saves.valid(bad),"invalid completed story rejected")
	g.erase("requests"); g.farm=Farm.defaults(); Farm.ensure(g); g.farm.stock[0]=3
	Farm.arrange(g,0); Farm.arrange(g,0); Farm.wrap_bouquet(g,0)
	check(Farm.serve(g) and Requests.state(g).ready,"real shop sale fulfils story")
	check(Saves.valid(JSON.parse_string(JSON.stringify(save))),"new state survives JSON round trip")
	print("Living garden checks=",checks," failures=",failures); quit(1 if failures else 0)
