extends SceneTree
const Rules = preload("res://scripts/match_rules.gd")
const Saves = preload("res://scripts/save_store.gd")
var checks := 0
var failures := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures += 1; printerr("FAIL: ",message)

func _initialize() -> void:
	var levels: Array = JSON.parse_string(FileAccess.get_file_as_string("res://match_levels/levels.json"))
	check(levels.size()==250,"exactly 250 match levels")
	var seen := {}
	for data in levels:
		var p=Rules.new()
		p.record_frames=false
		p.setup(data)
		check(p.groups().is_empty(),"stable starting board %d" % data.id)
		check(not p.legal_actions().is_empty(),"legal first move %d" % data.id)
		var fingerprint:=JSON.stringify(p.cells)
		check(not seen.has(fingerprint),"unique starting layout")
		seen[fingerprint]=true
		var original:=p.snapshot()
		var invalid_found:=false
		for a in p.n*p.n:
			if invalid_found: break
			for b in [a+1,a+p.n]:
				if not p.adjacent(a,b): continue
				if not p.play(a,b):
					check(p.snapshot()==original,"invalid swap preserves board moves and RNG")
					invalid_found=true; break
				p.setup(data)
		for step in data.witness.size():
			var action: Array=data.witness[step]
			check(p.play(int(action[0]),int(action[1])),"winning route step %d/%d" % [data.id,step])
			if step==data.witness.size()/2:
				var restored=Rules.new()
				restored.record_frames=false
				var saved: Dictionary=JSON.parse_string(JSON.stringify(p.snapshot()))
				restored.setup(data,saved)
				check(restored.snapshot()==p.snapshot(),"JSON save restores complete mid-level state")
				p=restored
		check(p.won() and p.moves>=0,"winning route within budget %d" % data.id)
		check(not p.play(0,1),"won board is locked")
	# Test formation rules directly, independent of any authored solution.
	var p=Rules.new()
	p.setup(levels[0])
	check(p.power_for([0,1,2,3])=="row","four horizontal creates beam")
	check(p.power_for([0,6,12,18])=="column","four vertical creates beam")
	check(p.power_for([0,1,6,7])=="bee","square creates butterfly")
	check(p.power_for([0,1,2,8,14])=="burst","L shape creates burst")
	check(p.power_for([0,1,2,3,4])=="rainbow","five creates rainbow")
	for power in ["row","column","bee","burst","rainbow"]:
		p.setup(levels[0]); p.powers[14]=power; p.dew[14]=2
		var before: int=p.moves
		check(p.play(14,-1),"tap activates "+power)
		check(p.moves==before-1,"activation spends one move")
		check(int(p.dew[14])<2,"power clears dew layer")
		check(not p.frames.is_empty() and p.groups().is_empty(),"animation frames end on stable board")
	for a in ["row","column","bee","burst","rainbow"]:
		for b in ["row","column","bee","burst","rainbow"]:
			p.setup(levels[0]); p.powers[14]=a; p.powers[15]=b
			check(p.play(14,15) and p.groups().is_empty(),"power combination "+a+" + "+b)
	p.setup(levels[0]); p.moves=0
	check(not p.play(0,1),"exhausted moves lock input")
	var old_save:=Saves.defaults()
	old_save.erase("match3")
	old_save.completed=[1,2,3]
	check(Saves.valid(old_save),"previous save format remains valid")
	var migration=Saves.new("user://match-migration-test.json")
	var migration_file:=FileAccess.open(migration.path,FileAccess.WRITE)
	migration_file.store_string(JSON.stringify(old_save)); migration_file.close()
	migration.load_data()
	check(migration.data.completed==[1,2,3] and migration.data.match3.current==1,"loading old save preserves progress and initializes new mode")
	DirAccess.remove_absolute(migration.path)
	p.setup(levels[0]); var corrupt:=p.snapshot(); corrupt.cells[0]=99
	check(not p.valid_save(corrupt),"corrupt colour rejected")
	corrupt=p.snapshot(); corrupt.rng="broken"
	check(not p.valid_save(corrupt),"corrupt RNG rejected")
	print("Match checks: %d; failures: %d" % [checks,failures])
	quit(1 if failures else 0)
