extends Node2D


@export var total_shots: int = 20

@export var starting_target_width: float = 0.22
@export var ending_target_width: float = 0.105

@export var starting_speed: float = 52.0
@export var ending_speed: float = 118.0
@export var speed_variation: float = 4.5

@export var difficulty_curve_power: float = 1.65

@export var throw_time: float = 0.35

@export var shake_strength: float = 7.0
@export var shake_steps: int = 7

@export var postbox_shift_count: int = 5
@export var postbox_shift_distance: float = 400.0
@export var postbox_shift_time: float = 0.2

@export var fail_sound_volume_db: float = -3.0


@onready var envelope: TextureRect = $Envelope
@onready var postbox: TextureRect = $Postbox

@onready var power_bar: ProgressBar = $PowerBar
@onready var target_zone: ColorRect = $PowerBar/TargetZone

@onready var shot_label: Label = $ShotLabel
@onready var instruction_label: Label = $InstructionLabel

@onready var lives_container: HBoxContainer = $Lives

@onready var icon: TextureRect = $Lives/Icon
@onready var icon_2: TextureRect = $Lives/Icon2
@onready var icon_3: TextureRect = $Lives/Icon3
@onready var icon_4: TextureRect = $Lives/Icon4

@onready var cross_icon: TextureRect = get_node_or_null(
	"CrossIcon"
)


var key_pool := [
	{"key": KEY_A, "label": "A"},
	{"key": KEY_S, "label": "S"},
	{"key": KEY_D, "label": "D"},
	{"key": KEY_W, "label": "W"},
	{"key": KEY_F, "label": "F"},
	{"key": KEY_G, "label": "G"},
	{"key": KEY_H, "label": "H"},
	{"key": KEY_J, "label": "J"},
	{"key": KEY_K, "label": "K"},
	{"key": KEY_L, "label": "L"},
	{"key": KEY_SPACE, "label": "SPACE"},
]


var envelope_start_pos: Vector2
var postbox_original_pos: Vector2

var postbox_shift_shots: Array[int] = []

var shots_remaining: int

var power_value: float = 0.0
var sweep_direction: int = 1
var reached_top: bool = false

var current_speed: float
var current_target_width: float

var target_center: float = 0.5

var current_key: Key
var current_key_label: String

var can_shoot: bool = true

var float_time: float = 0.0

var fail_sound_player: AudioStreamPlayer


func _ready() -> void:
	MusicManager.enter_minigame()

	envelope_start_pos = envelope.position
	postbox_original_pos = postbox.position

	shots_remaining = total_shots

	power_bar.show_percentage = false
	power_bar.min_value = 0.0
	power_bar.max_value = 100.0
	power_bar.value = 0.0

	target_zone.color = Color(
		0.15,
		0.82,
		0.30,
		0.92
	)

	if cross_icon:
		cross_icon.visible = false

	_setup_fail_sound()

	_pick_postbox_shift_shots()

	_apply_current_difficulty()

	_pick_new_key()
	_randomize_target_zone()

	_update_shot_label()
	_update_hearts()


func _process(delta: float) -> void:
	float_time += delta

	envelope.position.y = (
		envelope_start_pos.y
		+ sin(float_time * 2.5) * 6.0
	)

	_update_hearts()

	if not can_shoot:
		return

	power_value += (
		float(sweep_direction)
		* current_speed
		* delta
	)

	if sweep_direction == 1:
		if power_value >= 100.0:
			power_value = 100.0

			reached_top = true
			sweep_direction = -1

	else:
		if power_value <= 0.0:
			power_value = 0.0
			power_bar.value = power_value

			if reached_top:
				_attempt_shot(true)

			return

	power_bar.value = power_value


func _unhandled_input(event: InputEvent) -> void:
	if not can_shoot:
		return

	if (
		event is InputEventKey
		and event.pressed
		and not event.echo
	):
		if event.keycode == current_key:
			_attempt_shot(false)
		else:
			_attempt_shot(true)


func _apply_current_difficulty() -> void:
	var completed: int = (
		total_shots
		- shots_remaining
	)

	var progress: float = 0.0

	if total_shots > 1:
		progress = float(completed) / float(
			total_shots - 1
		)

	var curved_progress: float = pow(
		progress,
		difficulty_curve_power
	)

	current_target_width = lerpf(
		starting_target_width,
		ending_target_width,
		curved_progress
	)

	var base_speed: float = lerpf(
		starting_speed,
		ending_speed,
		curved_progress
	)

	var variation_multiplier: float = lerpf(
		0.65,
		1.0,
		curved_progress
	)

	current_speed = base_speed + randf_range(
		-speed_variation * variation_multiplier,
		speed_variation * variation_multiplier
	)

	current_speed = maxf(
		current_speed,
		1.0
	)


func _pick_new_key() -> void:
	var choice: Dictionary = key_pool[
		randi() % key_pool.size()
	]

	current_key = choice["key"]
	current_key_label = choice["label"]

	instruction_label.text = (
		"Press "
		+ current_key_label
		+ "!"
	)


func _randomize_target_zone() -> void:
	var half_width: float = (
		current_target_width / 2.0
	)

	var edge_margin: float = 0.05

	var minimum_center: float = (
		half_width
		+ edge_margin
	)

	var maximum_center: float = (
		1.0
		- half_width
		- edge_margin
	)

	target_center = randf_range(
		minimum_center,
		maximum_center
	)

	_position_target_zone()


func _position_target_zone() -> void:
	var bar_width: float = power_bar.size.x

	var zone_px_width: float = (
		bar_width
		* current_target_width
	)

	var zone_center_px: float = (
		bar_width
		* target_center
	)

	target_zone.position.x = (
		zone_center_px
		- zone_px_width / 2.0
	)

	target_zone.position.y = 0.0

	target_zone.size.x = zone_px_width
	target_zone.size.y = power_bar.size.y


func _is_in_zone() -> bool:
	var normalized_power: float = (
		power_value / 100.0
	)

	return abs(
		normalized_power
		- target_center
	) <= (
		current_target_width / 2.0
	)


func _pick_postbox_shift_shots() -> void:
	var pool: Array[int] = []

	for i in range(
		1,
		total_shots + 1
	):
		pool.append(i)

	pool.shuffle()

	postbox_shift_shots.clear()

	var amount: int = mini(
		postbox_shift_count,
		pool.size()
	)

	for i in range(amount):
		postbox_shift_shots.append(
			pool[i]
		)


func _attempt_shot(force_fail: bool) -> void:
	if not can_shoot:
		return

	can_shoot = false

	var success: bool = (
		not force_fail
		and _is_in_zone()
	)

	if success:
		await _play_success()
	else:
		await _play_fail()

	await _on_shot_finished()


func _play_success() -> void:
	instruction_label.text = "Nice!"

	var tween: Tween = create_tween()

	tween.set_trans(
		Tween.TRANS_QUAD
	)

	tween.set_ease(
		Tween.EASE_IN
	)

	tween.tween_property(
		envelope,
		"position",
		postbox.position,
		throw_time
	)

	await tween.finished


func _play_fail() -> void:
	instruction_label.text = "Missed..."

	Global.lives = maxi(
		Global.lives - 1,
		0
	)

	_update_hearts()

	_play_fail_sound()

	if cross_icon:
		cross_icon.visible = true

	await _shake_screen()

	await get_tree().create_timer(
		0.18
	).timeout

	if cross_icon:
		cross_icon.visible = false


func _setup_fail_sound() -> void:
	fail_sound_player = AudioStreamPlayer.new()

	fail_sound_player.stream = _make_fail_sound()
	fail_sound_player.volume_db = fail_sound_volume_db

	add_child(
		fail_sound_player
	)


func _make_fail_sound() -> AudioStreamWAV:
	var sample_rate: int = 44100
	var duration: float = 0.14

	var frame_count: int = int(
		float(sample_rate)
		* duration
	)

	var data: PackedByteArray = PackedByteArray()

	data.resize(
		frame_count * 2
	)

	for i in range(frame_count):
		var t: float = (
			float(i)
			/ float(sample_rate)
		)

		var progress: float = (
			t / duration
		)

		var envelope_value: float = pow(
			1.0 - progress,
			2.7
		)

		var low_hit: float = sin(
			TAU
			* 92.0
			* t
		)

		var broken_tone: float = sin(
			TAU
			* 173.0
			* t
		) * 0.35

		var rough_tone: float = sin(
			TAU
			* 347.0
			* t
		) * 0.16

		var static_noise: float = randf_range(
			-1.0,
			1.0
		) * 0.55

		var sample: float = (
			low_hit * 0.62
			+ broken_tone
			+ rough_tone
			+ static_noise
		)

		sample *= envelope_value
		sample *= 0.72

		sample = clampf(
			sample,
			-1.0,
			1.0
		)

		var pcm: int = int(
			sample * 32767.0
		)

		if pcm < 0:
			pcm += 65536

		data[i * 2] = pcm & 0xFF

		data[i * 2 + 1] = (
			pcm >> 8
		) & 0xFF

	var wav: AudioStreamWAV = AudioStreamWAV.new()

	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data

	return wav


func _play_fail_sound() -> void:
	if fail_sound_player == null:
		return

	fail_sound_player.pitch_scale = randf_range(
		0.94,
		1.03
	)

	fail_sound_player.stop()
	fail_sound_player.play()


func _shake_screen() -> void:
	var original_pos: Vector2 = position

	var shake_tween: Tween = create_tween()

	for i in range(shake_steps):
		var strength_multiplier: float = (
			1.0
			- float(i)
			/ float(shake_steps)
			* 0.45
		)

		var offset: Vector2 = Vector2(
			randf_range(
				-shake_strength,
				shake_strength
			),
			randf_range(
				-shake_strength,
				shake_strength
			)
		) * strength_multiplier

		shake_tween.tween_property(
			self,
			"position",
			original_pos + offset,
			0.025
		)

	shake_tween.tween_property(
		self,
		"position",
		original_pos,
		0.04
	)

	await shake_tween.finished


func _shift_postbox() -> void:
	var tween_out: Tween = create_tween()

	tween_out.set_trans(
		Tween.TRANS_QUAD
	)

	tween_out.set_ease(
		Tween.EASE_IN
	)

	tween_out.tween_property(
		postbox,
		"position:x",
		postbox_original_pos.x
		- postbox_shift_distance,
		postbox_shift_time
	)

	await tween_out.finished

	postbox.position.x = (
		postbox_original_pos.x
		+ postbox_shift_distance
	)

	var tween_in: Tween = create_tween()

	tween_in.set_trans(
		Tween.TRANS_QUAD
	)

	tween_in.set_ease(
		Tween.EASE_OUT
	)

	tween_in.tween_property(
		postbox,
		"position:x",
		postbox_original_pos.x,
		postbox_shift_time
	)

	await tween_in.finished


func _on_shot_finished() -> void:
	shots_remaining -= 1

	var completed_shot_number: int = (
		total_shots
		- shots_remaining
	)

	_update_shot_label()

	if Global.lives <= 0:
		get_tree().change_scene_to_file(
			"res://Screen/game_over.tscn"
		)
		return

	if shots_remaining <= 0:
		_end_minigame()
		return

	if completed_shot_number in postbox_shift_shots:
		await _shift_postbox()

	_reset_shot()


func _reset_shot() -> void:
	envelope.position = envelope_start_pos

	power_value = 0.0
	sweep_direction = 1
	reached_top = false

	power_bar.value = 0.0

	_apply_current_difficulty()

	_pick_new_key()
	_randomize_target_zone()

	can_shoot = true


func _update_shot_label() -> void:
	if shots_remaining <= 0:
		shot_label.text = "Route complete"
		return

	var current_shot_number: int = (
		total_shots
		- shots_remaining
		+ 1
	)

	shot_label.text = (
		"Mail %d / %d"
		% [
			current_shot_number,
			total_shots
		]
	)


func _update_hearts() -> void:
	match Global.lives:
		4:
			icon.show()
			icon_2.show()
			icon_3.show()
			icon_4.show()

		3:
			icon.hide()
			icon_2.show()
			icon_3.show()
			icon_4.show()

		2:
			icon.hide()
			icon_2.hide()
			icon_3.show()
			icon_4.show()

		1:
			icon.hide()
			icon_2.hide()
			icon_3.hide()
			icon_4.show()

		_:
			lives_container.hide()


func _end_minigame() -> void:
	Global.minigames_done = 1

	get_tree().change_scene_to_file(
		"res://Screen/level_scene.tscn"
	)
