extends Button

var _hover_player: AudioStreamPlayer
var _click_player: AudioStreamPlayer

var _interaction_tween: Tween
var _distortion_material: ShaderMaterial
var _locked := false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_hover_player = AudioStreamPlayer.new()
	_hover_player.stream = _make_ui_sound(430.0, 0.045, 0.32, 0.10)
	_hover_player.volume_db = -3.0
	add_child(_hover_player)

	_click_player = AudioStreamPlayer.new()
	_click_player.stream = _make_ui_sound(175.0, 0.085, 0.48, 0.16)
	_click_player.volume_db = -2.0
	add_child(_click_player)

	pivot_offset = size / 2.0

	mouse_entered.connect(_on_hover)
	mouse_exited.connect(_on_unhover)
	focus_entered.connect(_on_hover)
	focus_exited.connect(_on_unhover)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)

	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


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


func _create_distortion() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	get_tree().current_scene.add_child(layer)

	var rect := ColorRect.new()
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.position = Vector2.ZERO
	rect.size = get_viewport_rect().size
	layer.add_child(rect)

	var shader := Shader.new()

	shader.code = """
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float amount = 0.0;
uniform float blackout = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void fragment() {
	vec2 uv = SCREEN_UV;

	float row = floor(uv.y * 85.0);
	float tick = floor(TIME * 30.0);
	float noise = hash(vec2(row, tick));

	float tear = (noise - 0.5) * 0.048 * amount;
	float wave = sin(uv.y * 95.0 + TIME * 38.0) * 0.0035 * amount;

	uv.x += tear + wave;

	float split = 0.009 * amount;

	float r = texture(screen_texture, uv + vec2(split, 0.0)).r;
	float g = texture(screen_texture, uv).g;
	float b = texture(screen_texture, uv - vec2(split, 0.0)).b;

	vec3 col = vec3(r, g, b);

	float scanline = step(0.52, fract(uv.y * 260.0));
	col *= 1.0 - scanline * 0.10 * amount;

	float grain = hash(uv + vec2(TIME * 0.31, TIME * 0.77)) - 0.5;
	col += grain * 0.11 * amount;

	float tear_band = step(
		0.975,
		hash(vec2(floor(uv.y * 150.0), tick))
	);

	col *= 1.0 - tear_band * 0.45 * amount;
	col = mix(col, vec3(0.0), blackout);

	COLOR = vec4(col, 1.0);
}
"""

	_distortion_material = ShaderMaterial.new()
	_distortion_material.shader = shader
	rect.material = _distortion_material


func _set_distortion(value: float) -> void:
	if _distortion_material:
		_distortion_material.set_shader_parameter("amount", value)


func _set_blackout(value: float) -> void:
	if _distortion_material:
		_distortion_material.set_shader_parameter("blackout", value)


func _on_pressed() -> void:
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

	var music := get_tree().current_scene.find_child("TitleMusic", true, false)

	if music and music.has_method("distort_into_next_scene"):
		music.call("distort_into_next_scene")
	elif music is AudioStreamPlayer:
		var music_fallback := create_tween()
		music_fallback.set_parallel(true)
		music_fallback.tween_property(music, "volume_db", -24.0, 0.20)
		music_fallback.tween_property(music, "pitch_scale", 0.72, 0.20)

	_create_distortion()

	var distortion := create_tween()
	distortion.set_parallel(true)
	distortion.set_trans(Tween.TRANS_QUAD)
	distortion.set_ease(Tween.EASE_IN)

	distortion.tween_method(_set_distortion, 0.0, 1.0, 0.19)
	distortion.tween_method(_set_blackout, 0.0, 0.72, 0.19)

	await distortion.finished

	Global.minigames_done = 0
	Global.lives = 4
	get_tree().change_scene_to_file("res://Screen/cutscene.tscn")
