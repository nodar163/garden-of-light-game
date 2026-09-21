extends SceneTree
const Board = preload("res://scripts/match_board.gd")
const Rules = preload("res://scripts/match_rules.gd")
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	root.size=Vector2i(432,768)
	var model=Rules.new()
	var levels=JSON.parse_string(FileAccess.get_file_as_string("res://match_levels/levels.json"))
	model.setup(levels[249])
	var board=Board.new()
	board.model=model; board.size=Vector2(432,520)
	root.add_child(board)
	await process_frame
	var times: Array=[]
	for i in 90:
		var start=Time.get_ticks_usec()
		board.queue_redraw()
		await RenderingServer.frame_post_draw
		if i>9: times.append(Time.get_ticks_usec()-start)
	times.sort()
	print("RENDER BENCH median_us=",times[times.size()/2]," p95_us=",times[int(times.size()*.95)]," objects=",Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)," primitives=",Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)," draw_calls=",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	board.queue_free()
	await process_frame
	quit()
