extends Node2D

@export var required_deliveries: int = 16

@export var initial_time_limit: float = 2.0
@export var final_time_limit: float = 0.38
@export var time_curve_power: float = 1.45

@export var postbox_move_time: float = 0.16
@export var screen_padding: float = 24.0

@export var min_cursor_distance: float = 350.0
@export var min_previous_distance: float = 220.0
@export var position_attempts: int = 24

@export var shake_strength: float = 7.0
@export var shake_steps: int = 7

@export var fail_sound_volume_db: float = -3.0


@onready var envelope: TextureRect = $Envelope
@onready var postbox: TextureRect = $Postbox

@onready var power_bar: ProgressBar = get_node_or_null(
	"PowerBar"
)

@onready var target_zone: ColorRect = get_node_or_null(
	"PowerBar/TargetZone"
)

@onready var lives_container: HBoxContainer = $Lives

@onready var icon: TextureRect = $Lives/Icon
@onready var icon_2: TextureRect = $Lives/Icon2
@onready var icon_3: TextureRect = $Lives/Icon3
@onready var icon_4: TextureRect = $Lives/Icon4

@onready var instruction_label: Label = get_node_or_null(
	"InstructionLabel"
)

@onready var shot_label: Label = get_node_or_null(
	"ShotLabel"
)

@onready var cross_icon: TextureRect = get_node_or_null(
	"CrossIcon"
)


var deliveries: int = 0

var current_time_limit: float
var time_remaining: float

var active: bool = false

var screen_size: Vector2

var previous_postbox_position: Vector2

var fail_sound_player: AudioStreamPlayer


func _ready() -> void:
	MusicManager.enter_minigame()

	Input.set_mouse_mode(
		Input.MOUSE_MODE_HIDDEN
	)

	screen_size = get_viewport_rect().size

	previous_postbox_position = postbox.position

	if cross_icon:
		cross_icon.hide()

	if target_zone:
		target_zone.hide()

	if power_bar:
		power_bar.show_percentage = false
		power_bar.min_value = 0.0
		power_bar.max_value = 100.0
		power_bar.value = 100.0

	_setup_fail_sound()

	_update_time_limit()
	_update_ui()
	_update_hearts()

	await _move_postbox()

	_start_round()


func _process(delta: float) -> void:
	envelope.global_position = (
		get_global_mouse_position()
		- envelope.size / 2.0
	)

	_update_hearts()

	if not active:
		return

	time_remaining -= delta

	if power_bar:
		power_bar.value = clampf(
			(time_remaining / current_time_limit) * 100.0,
			0.0,
			100.0
		)

	if time_remaining <= 0.0:
		_handle_timeout()


func _input(event: InputEvent) -> void:
	if not active:
		return

	if (
		event is InputEventMouseButton
		and event.pressed
		and event.button_index == MOUSE_BUTTON_LEFT
	):
		if _envelope_is_fully_inside_postbox():
			_handle_success()
		else:
			_handle_miss_click()


func _envelope_is_fully_inside_postbox() -> bool:
	var envelope_rect: Rect2 = envelope.get_global_rect()
	var postbox_rect: Rect2 = postbox.get_global_rect()

	return postbox_rect.encloses(
		envelope_rect
	)


func _start_round() -> void:
	time_remaining = current_time_limit

	if power_bar:
		power_bar.value = 100.0

	active = true


func _update_time_limit() -> void:
	var progress: float = 0.0

	if required_deliveries > 1:
		progress = float(deliveries) / float(
			required_deliveries - 1
		)

	progress = clampf(
		progress,
		0.0,
		1.0
	)

	var curved_progress: float = pow(
		progress,
		time_curve_power
	)

	current_time_limit = lerpf(
		initial_time_limit,
		final_time_limit,
		curved_progress
	)

	if progress > 0.72:
		var end_pressure: float = inverse_lerp(
			0.72,
			1.0,
			progress
		)

		current_time_limit -= lerpf(
			0.0,
			0.08,
			end_pressure
		)

	current_time_limit = maxf(
		current_time_limit,
		0.38
	)
func _move_postbox() -> void:
	active = false

	var old_position: Vector2 = postbox.position

	var next_position: Vector2 = _find_postbox_position()

	previous_postbox_position = old_position

	var tween: Tween = create_tween()

	tween.set_trans(
		Tween.TRANS_SINE
	)

	tween.set_ease(
		Tween.EASE_IN_OUT
	)

	tween.tween_property(
		postbox,
		"position",
		next_position,
		postbox_move_time
	)

	await tween.finished


func _find_postbox_position() -> Vector2:
	var postbox_size: Vector2 = postbox.size

	var minimum_x: float = screen_padding
	var minimum_y: float = screen_padding

	var maximum_x: float = (
		screen_size.x
		- postbox_size.x
		- screen_padding
	)

	var maximum_y: float = (
		screen_size.y
		- postbox_size.y
		- screen_padding
	)

	maximum_x = maxf(
		maximum_x,
		minimum_x
	)

	maximum_y = maxf(
		maximum_y,
		minimum_y
	)

	var cursor_position: Vector2 = (
		get_global_mouse_position()
	)

	var best_position: Vector2 = postbox.position

	var best_score: float = -INF


	for i in range(position_attempts):
		var candidate: Vector2 = Vector2(
			randf_range(
				minimum_x,
				maximum_x
			),
			randf_range(
				minimum_y,
				maximum_y
			)
		)

		var candidate_center: Vector2 = (
			candidate
			+ postbox_size / 2.0
		)

		var cursor_distance: float = (
			candidate_center.distance_to(
				cursor_position
			)
		)

		var previous_distance: float = (
			candidate.distance_to(
				postbox.position
			)
		)

		var cursor_score: float = cursor_distance

		var movement_score: float = (
			previous_distance * 0.7
		)

		var score: float = (
			cursor_score
			+ movement_score
		)

		if cursor_distance < min_cursor_distance:
			score -= (
				min_cursor_distance
				- cursor_distance
			) * 3.0

		if previous_distance < min_previous_distance:
			score -= (
				min_previous_distance
				- previous_distance
			) * 2.0

		if score > best_score:
			best_score = score
			best_position = candidate


	return best_position


func _handle_success() -> void:
	if not active:
		return

	active = false

	deliveries += 1

	_update_ui()

	if deliveries >= required_deliveries:
		await _end_game(true)
		return

	_update_time_limit()

	await _move_postbox()

	_start_round()


func _handle_timeout() -> void:
	if not active:
		return

	active = false

	Global.lives = maxi(
		Global.lives - 1,
		0
	)

	_update_hearts()

	await _play_failure_feedback()

	if Global.lives <= 0:
		await _end_game(false)
		return

	await _move_postbox()

	_start_round()


func _handle_miss_click() -> void:
	if not active:
		return

	active = false

	Global.lives = maxi(
		Global.lives - 1,
		0
	)

	_update_hearts()

	await _play_failure_feedback()

	if Global.lives <= 0:
		await _end_game(false)
		return

	await _move_postbox()

	_start_round()


func _play_failure_feedback() -> void:
	_play_fail_sound()

	if cross_icon:
		cross_icon.show()

	await _shake_screen()

	await get_tree().create_timer(
		0.12
	).timeout

	if cross_icon:
		cross_icon.hide()


func _shake_screen() -> void:
	var original_position: Vector2 = position

	var tween: Tween = create_tween()

	for i in range(shake_steps):
		var progress: float = (
			float(i)
			/ float(shake_steps)
		)

		var strength: float = (
			shake_strength
			* (1.0 - progress * 0.45)
		)

		var offset: Vector2 = Vector2(
			randf_range(
				-strength,
				strength
			),
			randf_range(
				-strength,
				strength
			)
		)

		tween.tween_property(
			self,
			"position",
			original_position + offset,
			0.025
		)

	tween.tween_property(
		self,
		"position",
		original_position,
		0.04
	)

	await tween.finished


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


func _update_ui() -> void:
	if instruction_label:
		instruction_label.text = (
			"Place the mail fully inside the box!"
		)

	if shot_label:
		shot_label.text = (
			str(deliveries)
			+ " / "
			+ str(required_deliveries)
		)


func _update_hearts() -> void:
	if icon:
		icon.visible = Global.lives >= 4

	if icon_2:
		icon_2.visible = Global.lives >= 3

	if icon_3:
		icon_3.visible = Global.lives >= 2

	if icon_4:
		icon_4.visible = Global.lives >= 1

	if lives_container:
		lives_container.visible = Global.lives > 0


func _end_game(won: bool) -> void:
	active = false

	Input.set_mouse_mode(
		Input.MOUSE_MODE_VISIBLE
	)

	if won:
		Global.minigames_done = 2

		if instruction_label:
			instruction_label.text = "All Delivered!"

		await get_tree().create_timer(
			0.75
		).timeout

		get_tree().change_scene_to_file(
			"res://Screen/level_scene.tscn"
		)

	else:
		if instruction_label:
			instruction_label.text = "Game Over!"

		if power_bar:
			power_bar.value = 0.0

		await get_tree().create_timer(
			0.65
		).timeout

		get_tree().change_scene_to_file(
			"res://Screen/game_over.tscn"
		)
