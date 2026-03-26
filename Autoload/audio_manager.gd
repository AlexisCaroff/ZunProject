extends Node

const SAVE_PATH := "user://audio_settings.cfg"

var tracks: Array[AudioStream] = []
var track_names: Array[String] = []
var current_track_index: int = 0
var music_enabled: bool = false
var volume_linear: float = 0.8

@onready var _player: AudioStreamPlayer = AudioStreamPlayer.new()

func _ready() -> void:
	add_child(_player)
	_player.bus = "Music"  # crée un bus "Music" dans le Project > Audio ou remplace par "Master"
	_player.finished.connect(_on_track_finished)
	_load_settings()

# ---------- API publique ----------

func register_tracks(streams: Array[AudioStream], names: Array[String]) -> void:
	tracks = streams
	track_names = names

func play(index: int = current_track_index) -> void:
	if tracks.is_empty() or not music_enabled:
		return
	current_track_index = clampi(index, 0, tracks.size() - 1)
	_player.stream = tracks[current_track_index]
	_player.volume_db = linear_to_db(volume_linear)
	_player.play()

func stop() -> void:
	_player.stop()

func set_enabled(enabled: bool) -> void:
	music_enabled = enabled
	if music_enabled:
		play()
	else:
		stop()
	_save_settings()

func set_volume(linear: float) -> void:
	# linear : 0.0 à 1.0 depuis le slider
	volume_linear = clampf(linear, 0.0, 1.0)
	_player.volume_db = linear_to_db(volume_linear) 
	_save_settings()

func get_volume_linear() -> float:
	return volume_linear

func next_track() -> void:
	play((current_track_index + 1) % tracks.size())
	_save_settings()

func set_track(index: int) -> void:
	play(index)
	_save_settings()

# ---------- Persistance ----------

func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "enabled", music_enabled)
	cfg.set_value("audio", "volume_linear", volume_linear)
	cfg.set_value("audio", "track_index", current_track_index)
	cfg.save(SAVE_PATH)

func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	music_enabled = cfg.get_value("audio", "enabled", true)
	volume_linear = cfg.get_value("audio", "volume_linear", 0.8)
	current_track_index = cfg.get_value("audio", "track_index", 0)

func _on_track_finished() -> void:
	# Lecture en boucle de la même piste
	if music_enabled:
		_player.play()
