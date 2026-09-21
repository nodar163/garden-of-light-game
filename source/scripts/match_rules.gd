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

func rand_int(limit: int) -> int:
	rng_state = (rng_state * 48271) % 2147483647
	return rng_state % limit

func setup(data: Dictionary, saved: Dictionary = {}) -> void:
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
	fresh_board()
	if valid_save(saved):
		cells = saved.cells.duplicate()
		powers = saved.powers.duplicate()
		dew = saved.dew.duplicate()
		collected = saved.collected.duplicate()
		moves = int(saved.moves)
		rng_state = int(saved.rng)
		for arr in [cells,dew,collected]:
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
	return true

func snapshot() -> Dictionary:
	return {"cells":cells.duplicate(),"powers":powers.duplicate(),"dew":dew.duplicate(),"collected":collected.duplicate(),"moves":moves,"rng":str(rng_state)}

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
				if step == n or (not run.is_empty() and cells[i] != cells[run[0]]):
					if run.size() >= 3: parts.append(run)
					run = []
				if step < n and int(cells[i]) >= 0: run.append(i)
	for y in n-1:
		for x in n-1:
			var i := y*n+x
			if int(cells[i]) >= 0 and cells[i] == cells[i+1] and cells[i] == cells[i+n] and cells[i] == cells[i+n+1]:
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
			if not adjacent(a,b): continue
			if powers[a] != "" or powers[b] != "":
				actions.append([a,b]); continue
			swap_cells(a,b)
			var valid := has_match_at(a) or has_match_at(b)
			swap_cells(a,b)
			if valid: actions.append([a,b])
	return actions

func has_match_at(i: int) -> bool:
	var color: int = int(cells[i])
	for axis in 2:
		var count := 1
		for direction in [-1,1]:
			var j := i
			for distance in 2:
				var next: int = j + direction*(1 if axis == 0 else n)
				if next < 0 or next >= n*n or (axis == 0 and next/n != i/n) or cells[next] != color: break
				count += 1; j = next
		if count >= 3: return true
	for dx in [-1,0]:
		for dy in [-1,0]:
			var x: int = i%n+dx
			var y: int = i/n+dy
			if x < 0 or y < 0 or x >= n-1 or y >= n-1: continue
			var p := y*n+x
			if cells[p] == color and cells[p+1] == color and cells[p+n] == color and cells[p+n+1] == color: return true
	return false

func won() -> bool:
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
			var score := int(dew[i])*20 + (5 if int(collected[int(cells[i])]) < int(level.targets[int(cells[i])]) else 0)
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

func clear_group(initial: Array, creates: Dictionary = {}, rainbow_color: int = -1) -> void:
	var hit: Array = []
	for i in initial:
		if i not in hit: hit.append(i)
	var cursor := 0
	var activated: Array = []
	var effects: Array = []
	while cursor < hit.size():
		var i: int = hit[cursor]
		cursor += 1
		if powers[i] != "" and not creates.has(i):
			activated.append(i)
			var area := footprint(i,powers[i],rainbow_color)
			effects.append({"at":i,"power":powers[i],"target":area.back()})
			for j in area:
				if j not in hit: hit.append(j)
	frame("clear", {"hit":hit.duplicate(),"activated":activated,"effects":effects})
	for i in hit:
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
		if not adjacent(a,b): return false
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
			if pa != "" and pb != "":
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
			clear_group(hit,{},color); fall(); resolve()
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
			score += 1 + int(dew[i])*7
			if int(collected[int(cells[i])]) < int(level.targets[int(cells[i])]): score += 4
		if b >= 0: swap_cells(a,b)
		if score > best: best = score; choice = action
	return choice
