extends Button

var _hover_player: AudioStreamPlayer
var _click_player: AudioStreamPlayer

var _interaction_tween: Tween
var _locked := false


func _ready() -> void:
	_hover_player = AudioStreamPlayer.new()
	_hover_player.stream = _make_ui_sound(515.0, 0.040, 0.28, 0.08)
	_hover_player.volume_db = -3.0
	add_child(_hover_player)

	_click_player = AudioStreamPlayer.new()
	_click_player.stream = _make_ui_sound(235.0, 0.072, 0.43, 0.18)
	_click_player.volume_db = -2.0
	add_child(_click_player)

	pivot_offset = size / 2.0

	mouse_entered.connect(_on_hover)
	mouse_exited.connect(_on_unhover)
	focus_entered.connect(_on_hover)
	focus_exited.connect(_on_unhover)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)


func _make_ui_sound(
	frequency: float,
	duration: float,
	strength: float,
	noise_strength: float
) -> AudioStreamWAV:
	var sample_rate := 44100
	var frame_count := int(sample_rate * duration)
	var data := PackedByteArray()

	data.resize(frame_count * 2)

	for i in range(frame_count):
		var t := float(i) / float(sample_rate)
		var progress := t / duration
		var envelope := pow(1.0 - progress, 3.2)

		var fundamental := sin(TAU * frequency * t)
		var harmonic := sin(TAU * frequency * 2.08 * t) * 0.20
		var noise := randf_range(-1.0, 1.0) * noise_strength

		var sample := (fundamental + harmonic + noise) * envelope * strength
		sample = clamp(sample, -1.0, 1.0)

		var pcm := int(sample * 32767.0)

		if pcm < 0:
			pcm += 65536

		data[i * 2] = pcm & 0xFF
		data[i * 2 + 1] = (pcm >> 8) & 0xFF

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data

	return wav


func _play_hover_sound() -> void:
	_hover_player.pitch_scale = randf_range(0.98, 1.02)
	_hover_player.stop()
	_hover_player.play()


func _play_click_sound() -> void:
	_click_player.pitch_scale = randf_range(0.97, 1.01)
	_click_player.stop()
	_click_player.play()


func _on_hover() -> void:
	if _locked:
		return

	_play_hover_sound()
	_animate_scale(Vector2(1.018, 1.018), 0.07)


func _on_unhover() -> void:
	if _locked:
		return

	_animate_scale(Vector2.ONE, 0.09)


func _on_button_down() -> void:
	if _locked:
		return

	_animate_scale(Vector2(0.970, 0.970), 0.035)


func _on_button_up() -> void:
	if _locked:
		return

	_animate_scale(Vector2(1.018, 1.018), 0.055)


func _animate_scale(target: Vector2, duration: float) -> void:
	if _interaction_tween and _interaction_tween.is_valid():
		_interaction_tween.kill()

	_interaction_tween = create_tween()
	_interaction_tween.set_trans(Tween.TRANS_QUAD)
	_interaction_tween.set_ease(Tween.EASE_OUT)
	_interaction_tween.tween_property(self, "scale", target, duration)


func _on_pressed():
	if _locked:
		return

	_locked = true

	if _interaction_tween and _interaction_tween.is_valid():
		_interaction_tween.kill()

	_play_click_sound()

	var press := create_tween()
	press.set_trans(Tween.TRANS_QUAD)
	press.set_ease(Tween.EASE_OUT)
	press.tween_property(self, "scale", Vector2(0.945, 0.945), 0.045)

	await press.finished
	await get_tree().create_timer(0.08).timeout

	get_tree().quit()
