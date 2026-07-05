extends Node2D


@export var total_shots: int = 11
@export var target_width: float = 0.10        # how wide the green zone is — smaller = harder
@export var min_speed: float = 60.0
@export var max_speed: float = 160.0
@export var speed_change_interval_min: float = 1.0
@export var speed_change_interval_max: float = 2.0
@export var throw_time: float = 0.35
@export var shake_strength: float = 6.0

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
@onready var cross_icon: TextureRect = $CrossIcon   # add this node yourself, hidden by default

## The only keys that can ever be picked for a round. Edit this list freely.
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
var shots_remaining: int
var power_value: float = 0.0
var sweep_direction: int = 1
var current_speed: float
var target_center: float = 0.5
var current_key: Key
var current_key_label: String
var can_shoot: bool = true
var float_time: float = 0.0

func _ready() -> void:
	envelope_start_pos = envelope.position
	shots_remaining = total_shots
	cross_icon.visible = false
	_pick_new_speed()
	_start_speed_shift_loop()
	_pick_new_key()
	_randomize_target_zone()
	_update_shot_label()
	_update_hearts()

func _process(delta: float) -> void:
	float_time += delta
	envelope.position.y = envelope_start_pos.y + sin(float_time * 2.5) * 6.0

	_update_hearts()

	if not can_shoot:
		return

	# the bar sweeps up, then down, forever, until a valid key press resolves the shot
	power_value += sweep_direction * current_speed * delta
	if power_value >= 100.0:
		power_value = 100.0
		sweep_direction = -1
	elif power_value <= 0.0:
		power_value = 0.0
		sweep_direction = 1
	power_bar.value = power_value

func _unhandled_input(event: InputEvent) -> void:
	if not can_shoot:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == current_key:
			_resolve_shot()

func _pick_new_speed() -> void:
	current_speed = randf_range(min_speed, max_speed)

func _start_speed_shift_loop() -> void:
	while true:
		var wait_time := randf_range(speed_change_interval_min, speed_change_interval_max)
		await get_tree().create_timer(wait_time).timeout
		if not is_inside_tree():
			return
		_pick_new_speed()

func _pick_new_key() -> void:
	var choice = key_pool[randi() % key_pool.size()]
	current_key = choice["key"]
	current_key_label = choice["label"]
	instruction_label.text = "Press " + current_key_label + "!"

func _randomize_target_zone() -> void:
	var half_width: float = target_width / 2.0
	target_center = randf_range(half_width, 1.0 - half_width)
	_position_target_zone()

func _position_target_zone() -> void:
	var bar_width: float = power_bar.size.x
	var zone_px_width: float = bar_width * target_width
	var zone_center_px: float = bar_width * target_center
	target_zone.position.x = zone_center_px - (zone_px_width / 2.0)
	target_zone.size.x = zone_px_width
	target_zone.size.y = power_bar.size.y

func _resolve_shot() -> void:
	can_shoot = false
	var normalized_power: float = power_value / 100.0
	var distance_from_center: float = abs(normalized_power - target_center)
	var is_success: bool = distance_from_center <= (target_width / 2.0)

	if is_success:
		await _play_success()
	else:
		await _play_fail()

	_on_shot_finished()

func _play_success() -> void:
	instruction_label.text = "Nice!"
	var tween := create_tween()
	tween.tween_property(envelope, "position", postbox.position, throw_time)
	await tween.finished

func _play_fail() -> void:
	instruction_label.text = "Missed..."
	Global.lives -= 1
	_update_hearts()
	cross_icon.visible = true
	await _shake_screen()
	await get_tree().create_timer(0.3).timeout
	cross_icon.visible = false

func _shake_screen() -> void:
	var original_pos: Vector2 = position
	var shake_tween := create_tween()
	for i in range(6):
		var offset := Vector2(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength)
		)
		shake_tween.tween_property(self, "position", original_pos + offset, 0.03)
	shake_tween.tween_property(self, "position", original_pos, 0.03)
	await shake_tween.finished

func _on_shot_finished() -> void:
	shots_remaining -= 1
	_update_shot_label()

	if Global.lives <= 0:
		_end_minigame()
		return

	if shots_remaining <= 0:
		_end_minigame()
		return

	_reset_shot()

func _reset_shot() -> void:
	envelope.position = envelope_start_pos
	power_value = 0.0
	sweep_direction = 1
	power_bar.value = 0
	_pick_new_key()
	_randomize_target_zone()
	can_shoot = true

func _update_shot_label() -> void:
	if shots_remaining <= 0:
		shot_label.text = "Done!"
	else:
		var current_shot_number: int = total_shots - shots_remaining + 1
		shot_label.text = "Shot %d / %d" % [current_shot_number, total_shots]

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
		0:
			lives_container.hide()

func _end_minigame() -> void:
	get_tree().change_scene_to_file("res://Screen/level_scene.tscn")
