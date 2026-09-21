extends RefCounted
## Deterministic match-3 model. Rendering consumes immutable animation frames.
var level: Dictionary
var n := 7
var colors := 5
var cells: Array = []
var powers: Array = []
var dew: Array = []
var collected: Array = [0,0,0,0,0,0]
var moves := 0
var rng_state := 1
var frames: Array = []
var record_frames := true
var rules_version := 2
var obstacles: Array = []
var layers: Array = []
var tools_left: Array = [1,1,1,1]
var starter_used := false
var pending_effects: Array = []

func target_cell(exclude: Array = []) -> int:
	var best := -1
	var result := 0
	for i in n*n:
		var score:=int(layers[i])*35+int(dew[i])*20+(5 if int(collected[int(cells[i])])<int(level.targets[int(cells[i])]) else 0)
		if i not in exclude and score>best: best=score; result=i
	return result

func combine(a: int,b: int,pa: String,pb: String) -> Array:
	var hit: Array=[a,b]
	powers[a]=""; powers[b]=""
	if pa=="rainbow" and pb=="rainbow":
		hit=range(n*n)
		pending_effects.append({"at":b,"power":"rainbow","target":b})
	elif pa=="rainbow" or pb=="rainbow":
		var other:=pb if pa=="rainbow" else pa
		var color:=0
		for c in colors:
			if cells.count(c)>cells.count(color): color=c
		for i in n*n:
			if int(cells[i])==color and not blocked(i): powers[i]=other; hit.append(i)
	elif pa=="bee" or pb=="bee":
		var other:=pb if pa=="bee" else pa
		for i in n*n:
			if adjacent(a,i) or adjacent(b,i): hit.append(i)
		var targets: Array=hit.duplicate()
		for k in (3 if other=="bee" else 1):
			var target:=target_cell(targets); targets.append(target)
			pending_effects.append({"at":b,"power":"bee","target":target})
			if other=="bee": hit.append(target)
			else:
				hit.append_array(footprint(target,other))
				pending_effects.append({"at":target,"power":other,"target":target})
	elif pa=="burst" and pb=="burst":
		for i in n*n:
			if absi(i%n-b%n)<=4 and absi(i/n-b/n)<=4: hit.append(i)
		pending_effects.append({"at":b,"power":"burst","target":b})
	elif pa=="burst" or pb=="burst":
		for i in n*n:
			if absi(i%n-b%n)<=1 or absi(i/n-b/n)<=1: hit.append(i)
		for d in [-1,0,1]:
			if b/n+d>=0 and b/n+d<n: pending_effects.append({"at":b+d*n,"power":"row","target":b})
			if b%n+d>=0 and b%n+d<n: pending_effects.append({"at":b+d,"power":"column","target":b})
	else:
		hit.append_array(footprint(b,"row")); hit.append_array(footprint(b,"column"))
		pending_effects.append({"at":b,"power":"row","target":b})
		pending_effects.append({"at":b,"power":"column","target":b})
	return hit

func use_tool(kind: int,index: int) -> bool:
	frames.clear()
	if won() or kind<0 or kind>3 or int(tools_left[kind])<=0 or index<0 or index>=n*n: return false
	tools_left[kind]=int(tools_left[kind])-1
	if kind==3:
		# Shuffle flowers while leaving obstacles and existing power-ups in place.
		fresh_board(); frame("shuffle")
	else:
		var hit: Array=[index] if kind==0 else footprint(index,"row" if kind==1 else "column")
		clear_group(hit,{},-1,true); fall(); resolve()
	if not won() and legal_actions().is_empty(): fresh_board(); frame("shuffle")
	frame("settled")
	return true

func start_booster(kind: String) -> bool:
	if starter_used or moves!=int(level.moves) or won() or kind not in ["row","burst","rainbow"]: return false
	for i in n*n:
		if movable(i) and powers[i]=="":
			powers[i]=kind; starter_used=true; return true
	return false

func blocked(i: int) -> bool:
	return not layers.is_empty() and int(layers[i])>0 and int(obstacles[i])>=2

func movable(i: int) -> bool:
	return layers.is_empty() or int(layers[i])==0

func match_color(i: int) -> int:
	return -100-i if blocked(i) else int(cells[i])


func rand_int(limit: int) -> int:
	rng_state = (rng_state * 48271) % 2147483647
	return rng_state % limit

func setup(data: Dictionary, saved: Dictionary = {}) -> void:
	rules_version=int(saved.get("rules_version",2 if saved.is_empty() else 1))
	if rules_version==1:
		var legacy=JSON.parse_string(FileAccess.get_file_as_string("res://match_levels/legacy-levels.json"))
		data=legacy[int(data.id)-1]
	level = data.duplicate(true)
	n = int(data.size)
	colors = int(data.colors)
	moves = int(data.moves)
	rng_state = int(data.seed)
	collected = [0,0,0,0,0,0]
	cells.resize(n*n)
	powers.resize(n*n)
	powers.fill("")
	dew = data.dew.duplicate()
	for i in dew.size(): dew[i] = int(dew[i])
	obstacles=data.get("obstacles",[]).duplicate(); layers=data.get("layers",[]).duplicate()
	if obstacles.is_empty(): obstacles.resize(n*n); obstacles.fill(0); layers.resize(n*n); layers.fill(0)
	for i in n*n:
		obstacles[i]=int(obstacles[i]); layers[i]=int(layers[i])
	tools_left=[1,1,1,1]; starter_used=false
	fresh_board()
	if valid_save(saved):
		cells = saved.cells.duplicate()
		powers = saved.powers.duplicate()
		dew = saved.dew.duplicate()
		collected = saved.collected.duplicate()
		moves = int(saved.moves)
		rng_state = int(saved.rng)
		layers=saved.get("layers",layers).duplicate()
		tools_left=saved.get("tools_left",tools_left).duplicate()
		starter_used=saved.get("starter_used",false)
		for arr in [cells,dew,collected,layers,tools_left]:
			for i in arr.size(): arr[i] = int(arr[i])
	frames.clear()

func valid_save(saved: Dictionary) -> bool:
	for key in ["cells","powers","dew","collected"]:
		if not saved.get(key) is Array: return false
	if saved.cells.size() != n*n or saved.powers.size() != n*n or saved.dew.size() != n*n or saved.collected.size() != 6: return false
	if not saved.get("moves") is float and not saved.get("moves") is int: return false
	if int(saved.moves) < 0 or int(saved.moves) > int(level.moves): return false
	if not str(saved.get("rng", "")).is_valid_int() or int(saved.rng) <= 0 or int(saved.rng) >= 2147483647: return false
	for i in n*n:
		if not (typeof(saved.cells[i]) in [TYPE_INT,TYPE_FLOAT]) or float(saved.cells[i]) != int(saved.cells[i]) or int(saved.cells[i]) < 0 or int(saved.cells[i]) >= colors: return false
		if saved.powers[i] not in ["","row","column","burst","bee","rainbow"]: return false
		if not (typeof(saved.dew[i]) in [TYPE_INT,TYPE_FLOAT]) or float(saved.dew[i]) != int(saved.dew[i]) or int(saved.dew[i]) < 0 or int(saved.dew[i]) > int(level.dew[i]): return false
	for value in saved.collected:
		if not (typeof(value) in [TYPE_INT,TYPE_FLOAT]) or float(value) != int(value) or int(value) < 0: return false
	if saved.has("layers"):
		if not saved.layers is Array or saved.layers.size()!=n*n: return false
		for i in n*n:
			if not typeof(saved.layers[i]) in [TYPE_INT,TYPE_FLOAT] or float(saved.layers[i])!=int(saved.layers[i]) or int(saved.layers[i])<0 or int(saved.layers[i])>int(level.get("layers",layers)[i]): return false
	if saved.has("tools_left"):
		if not saved.tools_left is Array or saved.tools_left.size()!=4: return false
		for value in saved.tools_left:
			if not typeof(value) in [TYPE_INT,TYPE_FLOAT] or float(value)!=int(value) or int(value) not in [0,1]: return false
	if saved.has("starter_used") and not saved.starter_used is bool: return false
	return true

func snapshot() -> Dictionary:
	return {"rules_version":rules_version,"layers":layers.duplicate(),"tools_left":tools_left.duplicate(),"starter_used":starter_used,"cells":cells.duplicate(),"powers":powers.duplicate(),"dew":dew.duplicate(),"collected":collected.duplicate(),"moves":moves,"rng":str(rng_state)}

func frame(kind: String, extra: Dictionary = {}) -> void:
	if not record_frames: return
	var data := snapshot()
	data["kind"] = kind
	data.merge(extra)
	frames.append(data)

func fresh_board() -> void:
	for attempt in 200:
		for i in n*n:
			var candidates: Array = []
			for c in colors:
				if i%n >= 2 and cells[i-1] == c and cells[i-2] == c: continue
				if i >= n*2 and cells[i-n] == c and cells[i-n*2] == c: continue
				if i%n > 0 and i >= n and cells[i-1] == c and cells[i-n] == c and cells[i-n-1] == c: continue
				candidates.append(c)
			cells[i] = candidates[rand_int(candidates.size())]
		if not legal_actions().is_empty(): return
	assert(false, "Unable to construct playable board")

func adjacent(a: int, b: int) -> bool:
	return a >= 0 and b >= 0 and a < n*n and b < n*n and absi(a%n-b%n)+absi(a/n-b/n) == 1

func swap_cells(a: int, b: int) -> void:
	var c: Variant = cells[a]
	cells[a] = cells[b]
	cells[b] = c
	var p: Variant = powers[a]
	powers[a] = powers[b]
	powers[b] = p

func groups() -> Array:
	var parts: Array = []
	for axis in 2:
		for line in n:
			var run: Array = []
			for step in n+1:
				var i := line*n+step if axis == 0 else step*n+line
				if step == n or (not run.is_empty() and match_color(i) != match_color(run[0])):
					if run.size() >= 3: parts.append(run)
					run = []
				if step < n and int(cells[i]) >= 0 and not blocked(i): run.append(i)
	for y in n-1:
		for x in n-1:
			var i := y*n+x
			if not blocked(i) and int(cells[i]) >= 0 and match_color(i) == match_color(i+1) and match_color(i) == match_color(i+n) and match_color(i) == match_color(i+n+1):
				parts.append([i,i+1,i+n,i+n+1])
	var merged: Array = []
	for part in parts:
		var joint: Array = part.duplicate()
		var changed := true
		while changed:
			changed = false
			for j in range(merged.size()-1,-1,-1):
				var overlap := false
				for i in merged[j]:
					if i in joint: overlap = true; break
				if overlap:
					for i in merged[j]:
						if i not in joint: joint.append(i)
					merged.remove_at(j)
					changed = true
		merged.append(joint)
	return merged

func power_for(group: Array) -> String:
	var longest := 0
	var horizontal := true
	for i in group:
		for axis in 2:
			var length := 1
			var step := 1 if axis == 0 else n
			var j: int = i+step
			while j in group and (axis == 1 or j/n == i/n):
				length += 1
				j += step
			if length > longest: longest = length; horizontal = axis == 0
	if longest >= 5: return "rainbow"
	if group.size() >= 5: return "burst"
	if longest == 4: return "row" if horizontal else "column"
	if group.size() == 4: return "bee"
	return ""

func legal_actions() -> Array:
	var actions: Array = []
	for a in n*n:
		if powers[a] != "": actions.append([a,-1])
		for b in [a+1,a+n]:
			if not adjacent(a,b) or not movable(a) or not movable(b): continue
			if powers[a] != "" or powers[b] != "":
				actions.append([a,b]); continue
			swap_cells(a,b)
			var valid := has_match_at(a) or has_match_at(b)
			swap_cells(a,b)
			if valid: actions.append([a,b])
	return actions

func has_match_at(i: int) -> bool:
	if blocked(i): return false
	var color: int = int(cells[i])
	for axis in 2:
		var count := 1
		for direction in [-1,1]:
			var j := i
			for distance in 2:
				var next: int = j + direction*(1 if axis == 0 else n)
				if next < 0 or next >= n*n or (axis == 0 and next/n != i/n) or match_color(next) != color: break
				count += 1; j = next
		if count >= 3: return true
	for dx in [-1,0]:
		for dy in [-1,0]:
			var x: int = i%n+dx
			var y: int = i/n+dy
			if x < 0 or y < 0 or x >= n-1 or y >= n-1: continue
			var p := y*n+x
			if match_color(p) == color and match_color(p+1) == color and match_color(p+n) == color and match_color(p+n+1) == color: return true
	return false

func won() -> bool:
	for hp in layers:
		if int(hp)>0: return false
	for c in 6:
		if int(collected[c]) < int(level.targets[c]): return false
	for d in dew:
		if int(d) > 0: return false
	return true

func footprint(index: int, kind: String, color: int = -1) -> Array:
	var hit: Array = [index]
	if kind == "rainbow":
		if color < 0: color = best_color()
		for i in n*n:
			if int(cells[i]) == color: hit.append(i)
	elif kind == "bee":
		for i in n*n:
			if adjacent(index,i): hit.append(i)
		var target := 0
		var best := -1
		for i in n*n:
			var score := int(layers[i])*35 + int(dew[i])*20 + (5 if int(collected[int(cells[i])]) < int(level.targets[int(cells[i])]) else 0)
			if score > best and i not in hit: best = score; target = i
		hit.append(target)
	else:
		for i in n*n:
			if (kind == "row" and i/n == index/n) or (kind == "column" and i%n == index%n) or (kind == "burst" and absi(i%n-index%n) <= 2 and absi(i/n-index/n) <= 2): hit.append(i)
	return hit

func best_color() -> int:
	var best := -1
	var choice := 0
	for c in colors:
		var score := cells.count(c) + maxi(0,int(level.targets[c])-int(collected[c]))
		if score > best: best = score; choice = c
	return choice

func clear_group(initial: Array, creates: Dictionary = {}, rainbow_color: int = -1, forced_power: bool = false) -> void:
	var hit: Array = []
	for i in initial:
		if i not in hit: hit.append(i)
	var cursor := 0
	var activated: Array = []
	var effects: Array = pending_effects.duplicate(true)
	pending_effects.clear()
	while cursor < hit.size():
		var i: int = hit[cursor]
		cursor += 1
		if powers[i] != "" and not creates.has(i):
			activated.append(i)
			var area := footprint(i,powers[i],rainbow_color)
			effects.append({"at":i,"power":powers[i],"target":area.back()})
			for j in area:
				if j not in hit: hit.append(j)
	var flower_hits: Array=[]
	var damage: Array=[]
	for i in hit:
		if not blocked(i): flower_hits.append(i)
	for i in n*n:
		if int(layers[i])<=0: continue
		var powered:=forced_power and i in hit
		for j in activated:
			if i in footprint(j,powers[j],rainbow_color): powered=true
		var touches:=false
		for j in flower_hits:
			if adjacent(i,j) and (int(obstacles[i])!=4 or cells[j]==cells[i]): touches=true
		var direct: bool=i in flower_hits
		if powered or (int(obstacles[i])!=3 and (touches or direct)):
			damage.append(i)
	frame("clear", {"hit":flower_hits.duplicate(),"activated":activated,"effects":effects,"damage":damage})
	for i in damage: layers[i]=maxi(0,int(layers[i])-1)
	for i in flower_hits:
		collected[int(cells[i])] += 1
		dew[i] = maxi(0,int(dew[i])-1)
		cells[i] = -1
		powers[i] = ""
	for i in creates:
		cells[i] = creates[i].color
		powers[i] = creates[i].power

func fall() -> void:
	var from: Array = []
	from.resize(n*n)
	for x in n:
		var dest := n-1
		for y in range(n-1,-1,-1):
			var i := y*n+x
			if blocked(i):
				for row in range(dest,y,-1):
					var empty:=row*n+x
					cells[empty]=rand_int(colors); powers[empty]=""; from[empty]=(y-1)*n+x
				from[i]=i; dest=y-1
				continue
			if int(cells[i]) >= 0:
				var j := dest*n+x
				cells[j] = cells[i]; powers[j] = powers[i]; from[j] = i
				dest -= 1
		for y in range(dest,-1,-1):
			var i := y*n+x
			cells[i] = rand_int(colors); powers[i] = ""; from[i] = (y-dest-1)*n+x
	frame("fall", {"from":from})

func resolve(preferred: Array = []) -> void:
	for wave in 100:
		var matches := groups()
		if matches.is_empty(): return
		var hit: Array = []
		var creates: Dictionary = {}
		for group in matches:
			hit.append_array(group)
			var power := power_for(group)
			if power != "":
				var at: int = group[group.size()/2]
				for i in preferred:
					if i in group: at = i; break
				if powers[at] == "": creates[at] = {"color":cells[at],"power":power}
		clear_group(hit, creates)
		fall()
		preferred = []
	# Extremely long cascades are safely stopped with a playable fresh board.
	powers.fill("")
	fresh_board()
	frame("shuffle")

func play(a: int, b: int = -1) -> bool:
	frames.clear()
	if won() or moves <= 0 or a < 0 or a >= n*n: return false
	if b == -1:
		if powers[a] == "": return false
		moves -= 1
		clear_group([a]); fall(); resolve()
	else:
		if not adjacent(a,b) or not movable(a) or not movable(b): return false
		swap_cells(a,b)
		frame("swap", {"a":a,"b":b})
		var pa: String = powers[a]
		var pb: String = powers[b]
		if pa == "" and pb == "" and groups().is_empty():
			swap_cells(a,b)
			frame("swap", {"a":a,"b":b})
			return false
		moves -= 1
		if pa != "" or pb != "":
			var hit: Array = [a,b]
			var color := int(cells[b]) if pa == "rainbow" else int(cells[a]) if pb == "rainbow" else -1
			if pa != "" and pb != "" and rules_version>=2:
				hit=combine(a,b,pa,pb)
				color=-1
			elif pa != "" and pb != "":
				if pa == "rainbow" and pb == "rainbow": hit = range(n*n)
				elif pa == "rainbow" or pb == "rainbow":
					var other := pb if pa == "rainbow" else pa
					for i in n*n:
						if int(cells[i]) == color and i != a and i != b: powers[i] = other; hit.append(i)
				elif pa in ["row","column"] and pb in ["row","column"]:
					hit.append_array(footprint(b,"row")); hit.append_array(footprint(b,"column"))
				elif pa == "burst" or pb == "burst":
					for i in n*n:
						if absi(i%n-b%n) <= 1 or absi(i/n-b/n) <= 1: hit.append(i)
				else:
					hit.append_array(footprint(a,"burst")); hit.append_array(footprint(b,"burst"))
			clear_group(hit,{},color,true); fall(); resolve()
		else: resolve([b,a])
	if not won() and moves > 0 and legal_actions().is_empty():
		fresh_board()
		frame("shuffle")
	frame("settled")
	return true

func suggest() -> Array:
	var best := -1.0
	var choice: Array = []
	for action in legal_actions():
		var a: int = action[0]
		var b: int = action[1]
		var hit: Array = []
		var score := 0.0
		if b >= 0: swap_cells(a,b)
		if powers[a] != "": hit.append_array(footprint(a,powers[a])); score += 2
		if b >= 0 and powers[b] != "": hit.append_array(footprint(b,powers[b])); score += 2
		for group in groups():
			hit.append_array(group)
			if group.size() > 3: score += group.size()*2
		var unique: Dictionary = {}
		for i in hit: unique[i] = true
		for i in unique:
			score += 1 + int(dew[i])*7 + int(layers[i])*25
			for neighbour in [i-1,i+1,i-n,i+n]:
				if adjacent(i,neighbour): score+=int(layers[neighbour])*9
			if int(collected[int(cells[i])]) < int(level.targets[int(cells[i])]): score += 4
		if b >= 0: swap_cells(a,b)
		if score > best: best = score; choice = action
	return choice
