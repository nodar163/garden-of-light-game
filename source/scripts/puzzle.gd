extends RefCounted
## Pure rules. Directions: north, east, south, west. No rendering or file I/O.
const STEPS = [Vector2i(0,-1), Vector2i(1,0), Vector2i(0,1), Vector2i(-1,0)]
const BASE = {"empty":0, "source":1, "plant":1, "straight":5, "corner":3, "tee":11}
var level: Dictionary
var rotations: Array = []
var history: Array = []

func setup(data: Dictionary, saved: Array = []) -> void:
	level = data.duplicate(true)
	rotations = level.start.duplicate()
	for i in rotations.size():
		rotations[i] = int(rotations[i])
	if saved.size() == rotations.size():
		for i in saved.size():
			if movable(i) and (typeof(saved[i]) == TYPE_INT or typeof(saved[i]) == TYPE_FLOAT):
				rotations[i] = posmod(int(saved[i]), 4)
	history.clear()

func movable(index: int) -> bool:
	return level.cells[index] in ["straight", "corner", "tee"]

static func mask(kind: String, rotation: int) -> int:
	var value: int = BASE.get(kind, 0)
	for _i in posmod(rotation, 4):
		value = ((value << 1) & 15) | (value >> 3)
	return value

func lit() -> Array:
	var result: Array = []
	var n: int = int(level.size)
	var start: int = level.cells.find("source")
	if start < 0:
		return result
	result.append(start)
	var cursor := 0
	while cursor < result.size():
		var i: int = result[cursor]
		cursor += 1
		var ports := mask(level.cells[i], int(rotations[i]))
		for d in 4:
			if (ports & (1 << d)) == 0:
				continue
			var x: int = i % n + STEPS[d].x
			var y: int = i / n + STEPS[d].y
			if x < 0 or y < 0 or x >= n or y >= n:
				continue
			var j := y * n + x
			if j in result:
				continue
			if mask(level.cells[j], int(rotations[j])) & (1 << ((d + 2) % 4)):
				result.append(j)
	return result

func won() -> bool:
	var reached := lit()
	var plants := 0
	for i in level.cells.size():
		if level.cells[i] == "plant":
			plants += 1
			if i not in reached:
				return false
	return plants > 0

func turn(index: int) -> bool:
	if index < 0 or index >= rotations.size() or not movable(index) or won():
		return false
	history.append(rotations.duplicate())
	rotations[index] = (int(rotations[index]) + 1) % 4
	return true

func undo() -> bool:
	if history.is_empty():
		return false
	rotations = history.pop_back()
	return true

func restart() -> void:
	rotations = level.start.duplicate()
	for i in rotations.size():
		rotations[i] = int(rotations[i])
	history.clear()

func hint_index() -> int:
	if won():
		return -1
	for i in rotations.size():
		if movable(i) and mask(level.cells[i], int(rotations[i])) != mask(level.cells[i], int(level.solution[i])):
			return i
	return -1

func apply_hint(index: int) -> void:
	if index < 0 or index >= rotations.size() or not movable(index) or won():
		return
	history.append(rotations.duplicate())
	rotations[index] = int(level.solution[index])

static func validate(data: Dictionary) -> String:
	for key in ["id", "size", "cells", "start", "solution"]:
		if not data.has(key):
			return "Missing " + key
	var n := int(data.size)
	if n < 3 or n > 7 or int(data.id) < 1:
		return "Invalid size/id"
	for key in ["cells", "start", "solution"]:
		if not data[key] is Array or data[key].size() != n*n:
			return "Invalid array: " + key
	if data.cells.count("source") != 1 or data.cells.count("plant") < 1:
		return "One source and at least one plant required"
	for i in n*n:
		if not BASE.has(data.cells[i]):
			return "Unknown tile"
		for key in ["start", "solution"]:
			if not (typeof(data[key][i]) in [TYPE_INT, TYPE_FLOAT]) or float(data[key][i]) != int(data[key][i]) or int(data[key][i]) < 0 or int(data[key][i]) > 3:
				return "Invalid rotation"
		if data.cells[i] in ["source", "plant", "empty"] and data.start[i] != data.solution[i]:
			return "Fixed tile changes"
	return ""
