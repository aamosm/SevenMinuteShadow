extends Node2D


const HAND_FONT: FontFile = preload(
	"res://Fonts/Gloria_Hallelujah/GloriaHallelujah-Regular.ttf"
)


@export var required_deliveries: int = 12

@export var starting_time_limit: float = 2.4
@export var ending_time_limit: float = 0.80
@export var time_curve_power: float = 1.15

@export var shake_strength: float = 7.0
@export var shake_steps: int = 7

@export var fail_sound_volume_db: float = -3.0


@onready var background: TextureRect = $Background
@onready var envelope: TextureRect = $Envelope

@onready var lives_container: HBoxContainer = $Lives

@onready var icon: TextureRect = $Lives/Icon
@onready var icon_2: TextureRect = $Lives/Icon2
@onready var icon_3: TextureRect = $Lives/Icon3
@onready var icon_4: TextureRect = $Lives/Icon4

@onready var cross_icon: TextureRect = $CrossIcon


var address_pool: Array[String] = [
	"05-A",
	"05-B",
	"05-C",
	"05-D",
	"06-A",
	"06-B",
	"06-C",
	"06-D",
]


var choice_buttons: Array[Button] = []

var mail_count_label: Label
var address_title_label: Label
var address_label: Label
var timer_bar: ProgressBar

var current_address: String = ""

var deliveries: int = 0

var current_time_limit: float = 0.0
var time_remaining: float = 0.0

var active: bool = false

var envelope_start_position: Vector2

var fail_sound_player: AudioStreamPlayer


func _ready() -> void:
	Input.set_mouse_mode(
		Input.MOUSE_MODE_VISIBLE
	)

	MusicManager.start_gameplay(2)
	MusicManager.enter_minigame()

	background.self_modulate = Color(
		0.82,
		0.68,
		0.64,
		1.0
	)

	cross_icon.hide()

	_setup_existing_scene()
	_create_ui()
	_setup_fail_sound()

	_update_hearts()

	await get_tree().process_frame

	_start_round()


func _process(delta: float) -> void:
	_update_hearts()

	if not active:
		return

	time_remaining -= delta

	timer_bar.value = clampf(
		(time_remaining / current_time_limit) * 100.0,
		0.0,
		100.0
	)

	if time_remaining <= 0.0:
		_handle_timeout()


func _setup_existing_scene() -> void:
	var screen_size: Vector2 = get_viewport_rect().size

	envelope.position = Vector2(
		screen_size.x * 0.5 - envelope.size.x * 0.5,
		242.0
	)

	envelope_start_position = envelope.position

	lives_container.position = Vector2(
		screen_size.x * 0.5 - 82.0,
		40.0
	)

	lives_container.scale = Vector2.ONE
	lives_container.offset_transform_enabled = false

	for heart in [
		icon,
		icon_2,
		icon_3,
		icon_4
	]:
		heart.custom_minimum_size = Vector2(
			32.0,
			32.0
		)

		heart.expand_mode = (
			TextureRect.EXPAND_IGNORE_SIZE
		)

		heart.stretch_mode = (
			TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		)

	lives_container.add_theme_constant_override(
		"separation",
		7
	)

	cross_icon.position = Vector2(
		screen_size.x * 0.5 - cross_icon.size.x * 0.5,
		screen_size.y * 0.5 - cross_icon.size.y * 0.5
	)


func _create_ui() -> void:
	var screen_size: Vector2 = get_viewport_rect().size


	mail_count_label = Label.new()

	mail_count_label.position = Vector2(
		0.0,
		95.0
	)

	mail_count_label.size = Vector2(
		screen_size.x,
		35.0
	)

	mail_count_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	mail_count_label.add_theme_font_override(
		"font",
		HAND_FONT
	)

	mail_count_label.add_theme_font_size_override(
		"font_size",
		19
	)

	mail_count_label.add_theme_color_override(
		"font_color",
		Color(
			0.38,
			0.035,
			0.025,
			1.0
		)
	)

	add_child(mail_count_label)


	address_title_label = Label.new()

	address_title_label.text = "DELIVER TO"

	address_title_label.position = Vector2(
		0.0,
		150.0
	)

	address_title_label.size = Vector2(
		screen_size.x,
		30.0
	)

	address_title_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	address_title_label.add_theme_font_override(
		"font",
		HAND_FONT
	)

	address_title_label.add_theme_font_size_override(
		"font_size",
		15
	)

	address_title_label.add_theme_color_override(
		"font_color",
		Color(
			0.38,
			0.035,
			0.025,
			0.80
		)
	)

	add_child(address_title_label)


	address_label = Label.new()

	address_label.position = Vector2(
		0.0,
		178.0
	)

	address_label.size = Vector2(
		screen_size.x,
		58.0
	)

	address_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	address_label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	address_label.add_theme_font_override(
		"font",
		HAND_FONT
	)

	address_label.add_theme_font_size_override(
		"font_size",
		42
	)

	address_label.add_theme_color_override(
		"font_color",
		Color(
			0.38,
			0.035,
			0.025,
			1.0
		)
	)

	add_child(address_label)


	var button_width: float = 175.0
	var button_height: float = 64.0

	var gap_x: float = 46.0
	var gap_y: float = 25.0

	var group_width: float = (
		button_width * 2.0
		+ gap_x
	)

	var start_x: float = (
		screen_size.x * 0.5
		- group_width * 0.5
	)

	var start_y: float = 365.0


	for i in range(4):
		var button: Button = Button.new()

		button.size = Vector2(
			button_width,
			button_height
		)

		var column: int = i % 2
		var row: int = i / 2

		button.position = Vector2(
			start_x
			+ float(column)
			* (button_width + gap_x),

			start_y
			+ float(row)
			* (button_height + gap_y)
		)

		button.add_theme_font_override(
			"font",
			HAND_FONT
		)

		button.add_theme_font_size_override(
			"font_size",
			27
		)

		button.add_theme_color_override(
			"font_color",
			Color(
				0.37,
				0.035,
				0.025,
				1.0
			)
		)

		button.add_theme_color_override(
			"font_hover_color",
			Color(
				0.25,
				0.015,
				0.01,
				1.0
			)
		)

		button.add_theme_stylebox_override(
			"normal",
			_make_button_style(
				Color(
					1.0,
					0.94,
					0.84,
					0.82
				),
				2
			)
		)

		button.add_theme_stylebox_override(
			"hover",
			_make_button_style(
				Color(
					1.0,
					0.97,
					0.90,
					0.96
				),
				3
			)
		)

		button.add_theme_stylebox_override(
			"pressed",
			_make_button_style(
				Color(
					0.91,
					0.81,
					0.70,
					1.0
				),
				3
			)
		)

		button.pressed.connect(
			_on_choice_pressed.bind(i)
		)

		add_child(button)

		choice_buttons.append(button)


	timer_bar = ProgressBar.new()

	timer_bar.position = Vector2(
		screen_size.x * 0.5 - 205.0,
		575.0
	)

	timer_bar.size = Vector2(
		410.0,
		18.0
	)

	timer_bar.min_value = 0.0
	timer_bar.max_value = 100.0
	timer_bar.value = 100.0

	timer_bar.show_percentage = false

	var timer_background := StyleBoxFlat.new()

	timer_background.bg_color = Color(
		0.12,
		0.04,
		0.035,
		0.35
	)

	timer_background.corner_radius_top_left = 6
	timer_background.corner_radius_top_right = 6
	timer_background.corner_radius_bottom_left = 6
	timer_background.corner_radius_bottom_right = 6

	timer_bar.add_theme_stylebox_override(
		"background",
		timer_background
	)


	var timer_fill := StyleBoxFlat.new()

	timer_fill.bg_color = Color(
		0.42,
		0.06,
		0.04,
		0.92
	)

	timer_fill.corner_radius_top_left = 6
	timer_fill.corner_radius_top_right = 6
	timer_fill.corner_radius_bottom_left = 6
	timer_fill.corner_radius_bottom_right = 6

	timer_bar.add_theme_stylebox_override(
		"fill",
		timer_fill
	)

	add_child(timer_bar)


func _make_button_style(
	background_color: Color,
	border_width: int
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()

	style.bg_color = background_color

	style.border_color = Color(
		0.40,
		0.05,
		0.035,
		0.70
	)

	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width

	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5

	return style


func _start_round() -> void:
	if deliveries >= required_deliveries:
		_finish_minigame()
		return

	_update_time_limit()

	current_address = address_pool[
		randi() % address_pool.size()
	]

	address_label.text = current_address

	mail_count_label.text = (
		"MAIL "
		+ str(deliveries + 1)
		+ " / "
		+ str(required_deliveries)
	)

	var choices: Array[String] = (
		_generate_choices(
			current_address
		)
	)

	choices.shuffle()

	for i in range(4):
		choice_buttons[i].text = choices[i]
		choice_buttons[i].disabled = false
		choice_buttons[i].modulate = Color.WHITE

	envelope.position = envelope_start_position
	envelope.modulate = Color.WHITE

	time_remaining = current_time_limit

	timer_bar.value = 100.0

	active = true


func _update_time_limit() -> void:
	var progress: float = 0.0

	if required_deliveries > 1:
		progress = (
			float(deliveries)
			/ float(required_deliveries - 1)
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
		starting_time_limit,
		ending_time_limit,
		curved_progress
	)


func _generate_choices(
	correct: String
) -> Array[String]:
	var choices: Array[String] = [
		correct
	]

	var progress: float = 0.0

	if required_deliveries > 1:
		progress = (
			float(deliveries)
			/ float(required_deliveries - 1)
		)


	if progress < 0.40:
		var random_pool: Array[String] = (
			address_pool.duplicate()
		)

		random_pool.erase(correct)

		random_pool.shuffle()

		while choices.size() < 4:
			choices.append(
				random_pool.pop_back()
			)


	elif progress < 0.75:
		var correct_house: String = (
			correct.substr(0, 2)
		)

		var correct_letter: String = (
			correct.substr(3, 1)
		)

		var same_house: Array[String] = []
		var same_letter: Array[String] = []
		var others: Array[String] = []


		for address in address_pool:
			if address == correct:
				continue

			if address.substr(0, 2) == correct_house:
				same_house.append(address)

			elif address.substr(3, 1) == correct_letter:
				same_letter.append(address)

			else:
				others.append(address)


		same_house.shuffle()
		same_letter.shuffle()
		others.shuffle()


		if not same_house.is_empty():
			_add_unique_choice(
				choices,
				same_house[0]
			)

		if not same_letter.is_empty():
			_add_unique_choice(
				choices,
				same_letter[0]
			)

		while choices.size() < 4:
			var candidate: String = (
				others[
					randi()
					% others.size()
				]
			)

			_add_unique_choice(
				choices,
				candidate
			)


	else:
		var correct_house: String = (
			correct.substr(0, 2)
		)

		var correct_letter: String = (
			correct.substr(3, 1)
		)

		var same_house: Array[String] = []
		var same_letter: Array[String] = []


		for address in address_pool:
			if address == correct:
				continue

			if address.substr(0, 2) == correct_house:
				same_house.append(address)

			if address.substr(3, 1) == correct_letter:
				same_letter.append(address)


		same_house.shuffle()
		same_letter.shuffle()


		for address in same_house:
			if choices.size() >= 3:
				break

			_add_unique_choice(
				choices,
				address
			)


		for address in same_letter:
			if choices.size() >= 4:
				break

			_add_unique_choice(
				choices,
				address
			)


		var fallback: Array[String] = (
			address_pool.duplicate()
		)

		fallback.erase(correct)
		fallback.shuffle()

		for address in fallback:
			if choices.size() >= 4:
				break

			_add_unique_choice(
				choices,
				address
			)


	return choices


func _add_unique_choice(
	choices: Array[String],
	value: String
) -> void:
	if value in choices:
		return

	choices.append(value)


func _on_choice_pressed(
	index: int
) -> void:
	if not active:
		return

	active = false

	_disable_buttons()

	var selected_button: Button = (
		choice_buttons[index]
	)

	var selected_address: String = (
		selected_button.text
	)

	if selected_address == current_address:
		await _handle_success(
			selected_button
		)

	else:
		await _handle_wrong_choice(
			selected_button
		)


func _handle_success(
	button: Button
) -> void:
	button.modulate = Color(
		0.70,
		1.0,
		0.70,
		1.0
	)

	var target_position: Vector2 = (
		button.global_position
		+ button.size * 0.5
		- envelope.size * 0.5
	)

	var tween: Tween = create_tween()

	tween.set_parallel(true)

	tween.set_trans(
		Tween.TRANS_QUAD
	)

	tween.set_ease(
		Tween.EASE_IN
	)

	tween.tween_property(
		envelope,
		"global_position",
		target_position,
		0.20
	)

	tween.tween_property(
		envelope,
		"modulate:a",
		0.0,
		0.20
	)

	await tween.finished

	deliveries += 1

	if deliveries >= required_deliveries:
		await _finish_minigame()
		return

	await get_tree().create_timer(
		0.10
	).timeout

	_start_round()


func _handle_wrong_choice(
	button: Button
) -> void:
	button.modulate = Color(
		1.0,
		0.45,
		0.40,
		1.0
	)

	Global.lives = maxi(
		Global.lives - 1,
		0
	)

	_update_hearts()

	await _failure_feedback()

	if Global.lives <= 0:
		get_tree().change_scene_to_file(
			"res://Screen/game_over.tscn"
		)
		return

	await get_tree().create_timer(
		0.12
	).timeout

	_start_round()


func _handle_timeout() -> void:
	if not active:
		return

	active = false

	_disable_buttons()

	Global.lives = maxi(
		Global.lives - 1,
		0
	)

	_update_hearts()

	await _failure_feedback()

	if Global.lives <= 0:
		get_tree().change_scene_to_file(
			"res://Screen/game_over.tscn"
		)
		return

	await get_tree().create_timer(
		0.12
	).timeout

	_start_round()


func _disable_buttons() -> void:
	for button in choice_buttons:
		button.disabled = true


func _failure_feedback() -> void:
	_play_fail_sound()

	cross_icon.show()

	await _shake_screen()

	await get_tree().create_timer(
		0.12
	).timeout

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

	fail_sound_player.stream = (
		_make_fail_sound()
	)

	fail_sound_player.volume_db = (
		fail_sound_volume_db
	)

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

	var data := PackedByteArray()

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
			TAU * 92.0 * t
		)

		var broken_tone: float = (
			sin(
				TAU * 173.0 * t
			)
			* 0.35
		)

		var rough_tone: float = (
			sin(
				TAU * 347.0 * t
			)
			* 0.16
		)

		var static_noise: float = (
			randf_range(
				-1.0,
				1.0
			)
			* 0.55
		)

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

		data[i * 2] = (
			pcm & 0xFF
		)

		data[i * 2 + 1] = (
			(pcm >> 8)
			& 0xFF
		)


	var wav := AudioStreamWAV.new()

	wav.format = (
		AudioStreamWAV.FORMAT_16_BITS
	)

	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data

	return wav


func _play_fail_sound() -> void:
	fail_sound_player.pitch_scale = (
		randf_range(
			0.94,
			1.03
		)
	)

	fail_sound_player.stop()
	fail_sound_player.play()


func _update_hearts() -> void:
	icon.visible = Global.lives >= 4
	icon_2.visible = Global.lives >= 3
	icon_3.visible = Global.lives >= 2
	icon_4.visible = Global.lives >= 1

	lives_container.visible = (
		Global.lives > 0
	)


func _finish_minigame() -> void:
	active = false

	_disable_buttons()

	mail_count_label.text = (
		"ALL 12 SORTED"
	)

	address_title_label.text = ""
	address_label.text = "DONE"

	timer_bar.value = 0.0

	Global.minigames_done = 3

	await get_tree().create_timer(
		0.75
	).timeout

	get_tree().change_scene_to_file(
		"res://Screen/level_scene.tscn"
	)
