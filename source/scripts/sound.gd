extends Node
var music: AudioStreamPlayer
var effect: AudioStreamPlayer
var nature: AudioStreamPlayer
var home := false
var music_enabled := true
var match_streams: Dictionary = {}
var enabled := true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	music = AudioStreamPlayer.new()
	effect = AudioStreamPlayer.new()
	nature = AudioStreamPlayer.new()
	add_child(music)
	add_child(effect)
	add_child(nature)
	music.stream = load("res://assets/ambience.wav")
	music.volume_db = -17
	music.finished.connect(func(): music.play())
	effect.stream = load("res://assets/chime.wav")
	effect.volume_db = -12
	nature.stream = load("res://assets/nature.wav")
	nature.volume_db = -5
	nature.finished.connect(func():
		if home and music_enabled: nature.play())
	for key in ["swap","match","power","win"]:
		match_streams[key]=load("res://assets/"+("bloom" if key=="match" else key)+".wav")

func configure(settings: Dictionary) -> void:
	enabled = settings.sound
	music_enabled = settings.music
	if settings.music:
		if not music.playing:
			music.play()
	else:
		music.stop()
	set_home(home)

func set_home(value: bool) -> void:
	home=value
	if nature == null: return
	if home and music_enabled:
		if not nature.playing: nature.play()
	else: nature.stop()
	music.volume_db = -25 if home else -20

func play_match(kind: String) -> void:
	if enabled and match_streams.has(kind):
		effect.stream=match_streams[kind]
		effect.pitch_scale=1.0
		effect.play()

func chime() -> void:
	if enabled:
		effect.stream=load("res://assets/chime.wav")
		effect.play()

func _exit_tree() -> void:
	if music != null:
		music.stop()
		effect.stop()
		nature.stop()
		music.stream = null
		effect.stream = null
		nature.stream = null

func _notification(what: int) -> void:
	if music == null:
		return
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		music.stream_paused = true
		effect.stream_paused = true
		nature.stream_paused = true
	elif what == NOTIFICATION_APPLICATION_RESUMED or what == NOTIFICATION_APPLICATION_FOCUS_IN:
		music.stream_paused = false
		effect.stream_paused = false
		nature.stream_paused = false
