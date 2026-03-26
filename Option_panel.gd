extends Control
class_name OptionsPanel

@onready var toggle_music: CheckButton = $VBoxContainer/ToggleMusic
@onready var slider_volume: HSlider = $VBoxContainer/SliderVolume
@onready var track_label: Label =$VBoxContainer/HBoxTracks/TrackLabel
@onready var btn_prev: Button = $VBoxContainer/HBoxTracks/BtnPrev
@onready var btn_next: Button = $VBoxContainer/HBoxTracks/BtnNext
@onready var btn_close: Button = $BtnClose

func _ready() -> void:
	# Initialise les contrôles depuis l'état actuel de l'AudioManager
	toggle_music.button_pressed = AudioManager.music_enabled
	slider_volume.value = AudioManager.get_volume_linear()
	

	toggle_music.toggled.connect(_on_toggle_music)
	slider_volume.value_changed.connect(_on_volume_changed)
	btn_prev.pressed.connect(_on_prev_track)
	btn_next.pressed.connect(_on_next_track)
	btn_close.pressed.connect(_on_close)

	# Grise les contrôles de piste si pas de pistes enregistrées
	var has_tracks := not AudioManager.tracks.is_empty()
	btn_prev.disabled = not has_tracks
	btn_next.disabled = not has_tracks

func refresh() -> void:
	toggle_music.button_pressed = AudioManager.music_enabled
	slider_volume.value = AudioManager.get_volume_linear()
	var has_tracks := not AudioManager.tracks.is_empty()
	btn_prev.disabled = not has_tracks
	btn_next.disabled = not has_tracks
	_update_track_label()
	

func _on_toggle_music(enabled: bool) -> void:
	AudioManager.set_enabled(enabled)

func _on_volume_changed(value: float) -> void:
	AudioManager.set_volume(value)

func _on_prev_track() -> void:
	var idx := (AudioManager.current_track_index - 1) % AudioManager.tracks.size()
	AudioManager.set_track(idx)
	_update_track_label()

func _on_next_track() -> void:
	AudioManager.next_track()
	_update_track_label()

func _update_track_label() -> void:
	if AudioManager.track_names.is_empty():
		track_label.text = "—"
		return
	track_label.text = AudioManager.track_names[AudioManager.current_track_index]

func _on_close() -> void:
	hide()
