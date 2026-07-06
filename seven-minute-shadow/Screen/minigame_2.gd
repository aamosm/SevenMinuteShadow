extends Node2D

@export var required_deliveries: int = 10
@export var initial_time_limit: float = 2.0
@export var time_decrease_per_success: float = 0.15
@export var min_time_limit: float = 0.6

@onready var envelope: TextureRect = $Envelope
@onready var postbox: TextureRect = $Postbox
@onready var power_bar: ProgressBar = get_node_or_null("PowerBar")
@onready var target_zone: ColorRect = get_node_or_null("PowerBar/TargetZone")
@onready var lives_container: HBoxContainer = $Lives
@onready var icon: TextureRect = $Lives/Icon
@onready var icon_2: TextureRect = $Lives/Icon2
@onready var icon_3: TextureRect = $Lives/Icon3
@onready var icon_4: TextureRect = $Lives/Icon4

@onready var instruction_label: Label = get_node_or_null("InstructionLabel")
@onready var shot_label: Label = get_node_or_null("ShotLabel")
@onready var cross_icon: TextureRect = get_node_or_null("CrossIcon")

var deliveries: int = 0
var current_time_limit: float
var time_remaining: float
var active: bool = false
var screen_size: Vector2

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	screen_size = get_viewport_rect().size
	
	if cross_icon:
		cross_icon.hide()
	if target_zone:
		target_zone.hide() # Hide the green zone, we only need the bar for time
		
	current_time_limit = initial_time_limit
	time_remaining = current_time_limit
	
	_update_ui()
	_update_hearts()
	active = true
	_move_postbox()

func _process(delta: float) -> void:
	if not active:
		return
		
	# Envelope follows cursor
	envelope.global_position = get_global_mouse_position() - (envelope.size / 2.0)
	
	# Countdown timer logic
	time_remaining -= delta
	if power_bar:
		power_bar.value = (time_remaining / current_time_limit) * 100.0
		
	if time_remaining <= 0:
		_handle_timeout()

func _input(event: InputEvent) -> void:
	if not active:
		return
		
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if postbox.get_global_rect().has_point(get_global_mouse_position()):
			_handle_success()
		else:
			_handle_miss_click()

func _move_postbox() -> void:
	var max_x = screen_size.x - postbox.size.x
	var max_y = screen_size.y - postbox.size.y
	# Keep it slightly away from edges
	var padding = 20.0
	var next_pos = Vector2(
		randf_range(padding, max_x - padding), 
		randf_range(padding, max_y - padding)
	)
	
	var tween = create_tween()
	tween.tween_property(postbox, "position", next_pos, 0.15).set_trans(Tween.TRANS_SINE)

func _handle_success() -> void:
	deliveries += 1
	# Speed up the game for the next delivery
	current_time_limit = max(min_time_limit, current_time_limit - time_decrease_per_success)
	time_remaining = current_time_limit
	
	_update_ui()
	_move_postbox()
	
	if deliveries >= required_deliveries:
		_end_game(true)

func _handle_timeout() -> void:
	# Failed to click before the timer ran out
	Global.lives -= 1
	_update_hearts()
	_flash_cross()
	
	if Global.lives <= 0:
		get_tree().change_scene_to_file("res://Screen/game_over.tscn")
	else:
		# Reset timer and move the box to give them another chance
		time_remaining = current_time_limit
		_move_postbox()

func _handle_miss_click() -> void:
	# Clicked the screen but missed the postbox
	Global.lives -= 1
	_update_hearts()
	_flash_cross()
	
	if Global.lives <= 0:
		_end_game(false)
	# Note: We intentionally don't reset the timer here, forcing them to quickly correct their aim

func _flash_cross() -> void:
	if cross_icon:
		cross_icon.show()
		await get_tree().create_timer(0.15).timeout
		cross_icon.hide()

func _update_ui() -> void:
	if instruction_label:
		instruction_label.text = "Click the box before time runs out!"
	if shot_label:
		shot_label.text = str(deliveries) + " / " + str(required_deliveries)

func _update_hearts() -> void:
	if icon: icon.visible = Global.lives >= 4
	if icon_2: icon_2.visible = Global.lives >= 3
	if icon_3: icon_3.visible = Global.lives >= 2
	if icon_4: icon_4.visible = Global.lives >= 1
	if Global.lives <= 0 and lives_container:
		lives_container.hide()

func _end_game(won: bool) -> void:
	active = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if won:
		if instruction_label:
			instruction_label.text = "All Delivered!"
			await get_tree().create_timer(1.5).timeout
			get_tree().change_scene_to_file("res://Screen/uwintemp.tscn")
	else:
		if instruction_label:
			instruction_label.text = "Game Over!"
			if power_bar:
				power_bar.value = 0
		await get_tree().create_timer(1.5).timeout
		get_tree().change_scene_to_file("res://Screen/game_over.tscn")
