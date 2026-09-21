extends SceneTree
const Rules=preload("res://scripts/match_rules.gd")
var failures:=0
var checks:=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1; printerr("FAIL: ",message)
func _initialize() -> void:
	var levels=JSON.parse_string(FileAccess.get_file_as_string("res://match_levels/levels.json"))
	var p=Rules.new(); p.setup(levels[0])
	for kind in 4:
		p.setup(levels[0]); var moves: int=p.moves
		check(p.use_tool(kind,14),"tool activates")
		check(p.moves==moves and p.tools_left[kind]==0,"tool is free but consumed")
		check(not p.use_tool(kind,14),"no duplicate tool")
		check(p.groups().is_empty(),"tool leaves stable field")
		var q=Rules.new(); q.setup(levels[0],JSON.parse_string(JSON.stringify(p.snapshot())))
		check(q.snapshot()==p.snapshot(),"tool state survives reload")
	p.setup(levels[0])
	check(p.start_booster("burst") and not p.start_booster("rainbow"),"single pre-level booster")
	var state=p.snapshot()
	var q=Rules.new(); q.setup(levels[0],JSON.parse_string(JSON.stringify(state)))
	check(q.starter_used and q.powers.count("burst")==1,"starter survives reload")
	p.setup(levels[0]); p.moves-=1
	check(not p.start_booster("row"),"starter unavailable after first move")
	# Isolate obstacle hits from cascade randomness.
	for kind in range(1,5):
		p.setup(levels[0]); p.obstacles[14]=kind; p.layers[14]=2
		check(not p.movable(14),"obstacle prevents swapping")
		p.cells[13]=p.cells[14]
		p.clear_group([13])
		check(p.layers[14]==(2 if kind==3 else 1),"adjacent matching obstacle damage")
		p.clear_group([14],{},-1,true)
		check(p.layers[14]==(1 if kind==3 else 0),"power hits obstacle")
	p.setup(levels[0]); p.obstacles[14]=4; p.layers[14]=1; p.cells[13]=(p.cells[14]+1)%p.colors
	p.clear_group([13]); check(p.layers[14]==1,"wrong colour cannot open pot")
	p.setup(levels[0]); p.layers[14]=1; p.obstacles[14]=3
	p.collected=[999,999,999,999,999,999]; p.dew.fill(0)
	check(not p.won(),"obstacles are required for victory")
	# Exact footprints distinguish combinations, independent of eventual cascades.
	p.setup(levels[249]); p.layers.fill(0)
	var hit=p.combine(23,24,"burst","burst")
	check(range(49).all(func(i):return i in hit),"double bomb four-tile radius")
	p.pending_effects.clear(); hit=p.combine(23,24,"bee","bee")
	check(p.pending_effects.size()==3,"double butterfly makes three flights")
	check(p.pending_effects[0].target!=p.pending_effects[1].target and p.pending_effects[1].target!=p.pending_effects[2].target,"distinct flight targets")
	p.pending_effects.clear(); hit=p.combine(23,24,"bee","row")
	check(p.pending_effects.size()==2 and p.pending_effects[1].power=="row","butterfly carries rocket")
	p.pending_effects.clear(); hit=p.combine(23,24,"row","column")
	var unique: Dictionary={}
	for i in hit: unique[i]=true
	check(unique.size()==13,"crossing row and column count centre once")
	# Previously saved games retain original goals, move budgets and rules.
	var legacy=JSON.parse_string(FileAccess.get_file_as_string("res://match_levels/legacy-levels.json"))
	for id in [1,26,126,250]:
		p.setup(legacy[id-1],{"rules_version":1})
		var old=p.snapshot(); old.erase("rules_version"); old.erase("tools_left"); old.erase("starter_used"); old.erase("layers")
		q.setup(levels[id-1],old)
		check(q.rules_version==1 and q.moves==int(legacy[id-1].moves),"legacy budget preserved")
		for step in legacy[id-1].witness: check(q.play(int(step[0]),int(step[1])),"legacy route step")
		check(q.won(),"legacy route still wins")
	print("Extended match checks: %d; failures: %d" %[checks,failures])
	quit(1 if failures else 0)
