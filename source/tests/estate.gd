extends SceneTree
const Rules=preload("res://scripts/estate_rules.gd")
const Saves=preload("res://scripts/save_store.gd")
const Farm=preload("res://scripts/garden_farm.gd")
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1; printerr("FAIL: ",label)
func _initialize() -> void:
	var save:=Saves.defaults(); var g: Dictionary=save.garden
	check(Saves.valid(save),"legacy save accepted without extension")
	g.repairs=[0,1,2,3,4]; g.coins=100000
	check(not Rules.upgrade(g,true,0),"coins alone cannot unlock house")
	for id in range(1,1001): save.completed.append(id); save.match3.completed.append(id)
	Saves.Garden.sync(save)
	check(g.earned.size()==2000,"1000 first wins in both modes")
	var before: int=g.coins
	check(Saves.Garden.sync(save)==0 and int(g.coins)==before,"no duplicate rewards")
	g.earned.pop_back()
	check(not Rules.complete(g),"1999 wins cannot finish")
	g.estate={"land:23":2}
	check(not Rules.upgrade(g,false,23),"last upgrade locked before 2000")
	g.earned.append("match:1000"); g.estate={}
	var cost:=0
	for stage in range(1,4):
		for inside in [false,true]:
			for id in 24:
				check(Rules.upgrade(g,inside,id),"all 144 stages reachable")
				cost+=Rules.price(stage)
	check(cost==25920,"renovation budget below 50000 level income")
	check(Rules.complete(g),"fully restored at 2000 wins")
	check(Saves.valid(save),"extended save valid")
	check(not Rules.upgrade(g,true,0),"completed repairs cannot charge twice")
	var invalid:=save.duplicate(true); invalid.garden.estate["house:24"]=1
	check(not Saves.valid(invalid),"invalid repair IDs rejected")
	invalid=save.duplicate(true); invalid.garden.estate["house:0"]=1.5
	check(not Saves.valid(invalid),"fractional tiers rejected")
	g.estate={}; g.farm=Farm.defaults(); Farm.ensure(g)
	check(Farm.plant(g,0,0) and Farm.plant(g,1,1),"paired varieties planted")
	check(Farm.companion_bonus(g,0)==1,"complementary planting bonus")
	check(Farm.cultivate(g,0) and not Farm.cultivate(g,0),"compost once per crop")
	for _step in 3: Farm.grow(g)
	check(Farm.harvest(g,0)==4,"care and companion add two flowers")
	check(not g.farm.beds["0"].cultivated,"care resets after harvest")
	check(Farm.arrange(g,0),"arrange harvest")
	var base: int=Farm.bouquet(g,Farm.draft_counts(g)).coins
	check(Farm.finish_bouquet(g,"trim") and not Farm.finish_bouquet(g,"trim"),"trim once")
	check(not Farm.finish_bouquet(g,"ribbon"),"wrap before ribbon")
	check(Farm.wrap_bouquet(g,0) and Farm.finish_bouquet(g,"ribbon"),"wrap and tie")
	check(int(Farm.bouquet(g,Farm.draft_counts(g)).coins)==base+22,"craft and requested paper bonuses")
	check(Farm.serve(g) and not Farm.serve(g),"sale cannot be duplicated")
	check(Saves.valid(save),"new farm actions remain serializable")
	print("Estate checks=",checks," failures=",failures); quit(1 if failures else 0)
