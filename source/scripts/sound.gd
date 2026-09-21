extends Node
var music: AudioStreamPlayer
var effect: AudioStreamPlayer
var enabled := true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	music = AudioStreamPlayer.new()
	effect = AudioStreamPlayer.new()
	add_child(music)
	add_child(effect)
	music.stream = load("res://assets/ambience.wav")
	music.volume_db = -17
	music.finished.connect(func(): music.play())
	effect.stream = load("res://assets/chime.wav")
	effect.volume_db = -12

func configure(settings: Dictionary) -> void:
	enabled = settings.sound
	if settings.music:
		if not music.playing:
			music.play()
	else:
		music.stop()

func chime() -> void:
	if enabled:
		effect.play()

func _exit_tree() -> void:
	if music != null:
		music.stop()
		effect.stop()
		music.stream = null
		effect.stream = null

func _notification(what: int) -> void:
	if music == null:
		return
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		music.stream_paused = true
		effect.stream_paused = true
	elif what == NOTIFICATION_APPLICATION_RESUMED or what == NOTIFICATION_APPLICATION_FOCUS_IN:
		music.stream_paused = false
		effect.stream_paused = false
