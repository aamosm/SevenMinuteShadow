extends AudioStreamPlayer

@export var resting_volume_db: float = -18.0
@export var fade_in_from_db: float = -45.0
@export var fade_in_duration: float = 3.0
@export var transition_duration: float = 1.15

var _transition_started := false
var _transition_bus_name := "TitleTransitionFX"
var _transition_distortion: AudioEffectDistortion
var _transition_filter: AudioEffectLowPassFilter
var _fade_in_tween: Tween


func _ready() -> void:
	_enable_loop()

	volume_db = fade_in_from_db

	if not playing:
		play()

	_fade_in_tween = create_tween()
	_fade_in_tween.set_trans(Tween.TRANS_SINE)
	_fade_in_tween.set_ease(Tween.EASE_OUT)
	_fade_in_tween.tween_property(
		self,
		"volume_db",
		resting_volume_db,
		fade_in_duration
	)


func _enable_loop() -> void:
	if stream == null:
		return

	for property in stream.get_property_list():
		var property_name: String = String(property.get("name", ""))

		if property_name == "loop":
			stream.set("loop", true)
			return

		if property_name == "loop_mode":
			if int(stream.get("loop_mode")) == 0:
				stream.set("loop_mode", 1)
			return


func _prepare_transition_bus() -> void:
	var bus_index: int = AudioServer.get_bus_index(_transition_bus_name)

	if bus_index == -1:
		AudioServer.add_bus()
		bus_index = AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus_index, _transition_bus_name)
		AudioServer.set_bus_send(bus_index, "Master")

	while AudioServer.get_bus_effect_count(bus_index) > 0:
		AudioServer.remove_bus_effect(bus_index, 0)

	_transition_distortion = AudioEffectDistortion.new()
	_transition_distortion.mode = AudioEffectDistortion.MODE_LOFI
	_transition_distortion.drive = 0.03
	_transition_distortion.pre_gain = 0.0
	_transition_distortion.post_gain = -2.0
	_transition_distortion.keep_hf_hz = 12000.0

	_transition_filter = AudioEffectLowPassFilter.new()
	_transition_filter.cutoff_hz = 12000.0
	_transition_filter.resonance = 0.18

	AudioServer.add_bus_effect(
		bus_index,
		_transition_distortion,
		0
	)

	AudioServer.add_bus_effect(
		bus_index,
		_transition_filter,
		1
	)


func distort_into_next_scene() -> void:
	if _transition_started:
		return

	if stream == null:
		return

	if not playing:
		return

	_transition_started = true

	if _fade_in_tween and _fade_in_tween.is_valid():
		_fade_in_tween.kill()

	_prepare_transition_bus()

	var playback_position: float = get_playback_position()

	var tail := AudioStreamPlayer.new()
	tail.stream = stream
	tail.volume_db = volume_db
	tail.pitch_scale = pitch_scale
	tail.bus = _transition_bus_name

	get_tree().root.add_child(tail)

	tail.play(playback_position)

	stop()

	var tween := get_tree().create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_EXPO)
	tween.set_ease(Tween.EASE_IN)

	tween.tween_property(
		_transition_distortion,
		"drive",
		0.82,
		transition_duration
	)

	tween.tween_property(
		_transition_distortion,
		"keep_hf_hz",
		850.0,
		transition_duration
	)

	tween.tween_property(
		_transition_distortion,
		"post_gain",
		-13.0,
		transition_duration
	)

	tween.tween_property(
		_transition_filter,
		"cutoff_hz",
		650.0,
		transition_duration
	)

	tween.tween_property(
		tail,
		"pitch_scale",
		0.46,
		transition_duration
	)

	tween.tween_property(
		tail,
		"volume_db",
		-60.0,
		transition_duration
	)

	tween.chain().tween_callback(tail.queue_free)
