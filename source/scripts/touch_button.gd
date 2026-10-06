extends Button
## At 320 px wide, a 100-unit target on the 720-unit canvas is about 44 px.
func _ready() -> void: call_deferred("ensure_touch_size")
func ensure_touch_size() -> void:
	custom_minimum_size=custom_minimum_size.max(Vector2(100,100))
