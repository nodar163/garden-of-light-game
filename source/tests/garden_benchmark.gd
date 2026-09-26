extends SceneTree
const Board = preload("res://scripts/garden_map.gd")
const Rules = preload("res://scripts/garden_rules.gd")
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	root.size=Vector2i(432,768)
	var board=Board.new()
	board.garden=Rules.defaults()
	for i in 30: board.garden.plots[str(i)]=i%14
	board.garden.repairs=[0,1,2,3,4]
	Rules.Farm.ensure(board.garden)
	board.garden.farm.shop_tier=3
	board.garden.farm.buildings=[0,1]
	board.size=Vector2(432,520)
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
