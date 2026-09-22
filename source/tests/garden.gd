extends SceneTree
const Rules=preload("res://scripts/garden_rules.gd")
const Saves=preload("res://scripts/save_store.gd")
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1; printerr("FAIL: ",message)
func _initialize() -> void:
	var data:=Saves.defaults()
	check(Rules.valid(data.garden),"valid fresh garden")
	check(data.garden.coins==50,"starter gift once")
	check(Rules.buy(data.garden,0,0) and data.garden.coins==0,"first planting affordable")
	check(not Rules.buy(data.garden,1,0),"insufficient balance rejected")
	check(not Rules.buy(data.garden,-1,0) and not Rules.buy(data.garden,30,0),"invalid plot rejected")
	check(not Rules.buy(data.garden,0,99),"invalid product rejected")
	check(Rules.remove(data.garden,0) and data.garden.coins==50,"full refund")
	check(not Rules.remove(data.garden,0) and data.garden.coins==50,"no duplicate refund")
	data.completed=[1,2,3]; data.match3.completed=[1,2]
	check(Rules.sync(data)==125 and data.garden.coins==175,"both modes rewarded separately")
	check(Rules.sync(data)==0 and data.garden.coins==175,"migration idempotent")
	var old=data.duplicate(true); old.erase("garden"); Rules.sync(old)
	check(old.garden.coins==175,"retroactive rewards preserve old progress")
	check(not Rules.buy(data.garden,0,5),"locked flower cannot be bought")
	Rules.buy(data.garden,0,0)
	var before: int=data.garden.coins
	check(Rules.buy(data.garden,0,1) and data.garden.coins==before-10,"replacement pays price difference")
	check(Rules.buy(data.garden,0,0) and data.garden.coins==before,"cheaper replacement refunds difference")
	data.completed=range(1,251); data.match3.completed=range(1,251); Rules.sync(data)
	check(data.garden.earned.size()==500,"500 unique rewards")
	for slot in Rules.PLOT_COUNT: check(Rules.buy(data.garden,slot,slot%Rules.ITEMS.size()) or slot==0,"place available item")
	check(not Rules.repair(data.garden,1),"restoration follows story order")
	for index in Rules.REPAIRS.size():
		check(Rules.repair(data.garden,index),"restoration affordable")
		var coins: int=data.garden.coins
		check(not Rules.repair(data.garden,index) and data.garden.coins==coins,"repair charged once")
	for order in 50: check(Rules.deliver(data.garden),"earned bouquet delivery")
	check(not Rules.deliver(data.garden),"orders cannot be farmed indefinitely")
	check(data.garden.coins>=0,"full garden fits campaign economy")
	check(Rules.valid(JSON.parse_string(JSON.stringify(data.garden))),"JSON garden valid")
	var save=Saves.new("user://garden-test.json"); save.data=data
	check(save.write(),"garden saved")
	var loaded=Saves.new(save.path); loaded.load_data()
	check(loaded.data.garden==data.garden,"all garden state restored")
	var malformed=data.garden.duplicate(true); malformed.coins=-1
	check(not Rules.valid(malformed),"negative balance rejected")
	malformed=data.garden.duplicate(true); malformed.earned.append("light:1")
	check(not Rules.valid(malformed),"duplicate reward ledger rejected")
	var broken=Saves.new("user://missing-garden-folder/save.json")
	broken.data=Saves.defaults(); before=broken.data.garden.coins
	check(not broken.garden_transaction(func(g):return Rules.buy(g,0,0)),"failed write reports failure")
	check(broken.data.garden.coins==before and broken.data.garden.plots.is_empty(),"failed purchase rolls back coins and item")
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(save.path+suffix): DirAccess.remove_absolute(save.path+suffix)
	print("Garden rules checks: %d; failures: %d" %[checks,failures])
	quit(1 if failures else 0)
