extends Node

@onready var node_2d: Node2D = $Node2D
@onready var node_3d: Node3D = $Node3D
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var anim_player_2d: AnimationPlayer = $AnimationPlayer2
@onready var camera: Camera3D = $Node3D/Camera3D
@onready var mailman = $Node2D/Mailman/Mailman
@onready var envelope: Sprite2D = $Node2D/Mailman/EnvelopeSealed
@onready var postbox: Sprite2D = $Node2D/Mailman/Postoffice
@onready var instruction_label: Label = $Node2D/Mailman/InstructionLabel

var envelope_origin := Vector2.ZERO
var envelope_float := false
var float_time := 0.0

const RADIO_DIALOGUE = preload("res://dialogue/radio.dialogue")

const RADIO_RENDER_SCALE: float = 0.5
const RADIO_MAX_FPS: int = 30

var original_fov: float
var original_rotation: Vector3

var _original_3d_scale: float = 1.0
var _original_3d_mode: int = Viewport.SCALING_3D_MODE_BILINEAR
var _original_msaa_3d: int = Viewport.MSAA_DISABLED
var _original_screen_space_aa: int = Viewport.SCREEN_SPACE_AA_DISABLED
var _original_use_taa: bool = false
var _original_max_fps: int = 0

var _radio_render_settings_applied: bool = false


func _process(delta: float) -> void:
	if envelope_float:
		float_time += delta
		envelope.position.y = envelope_origin.y + sin(float_time * 4.5) * 6.0


func _ready() -> void:
	envelope.visible = false
	envelope.modulate.a = 0.0
	envelope_origin = envelope.position

	original_fov = camera.fov
	original_rotation = camera.rotation_degrees

	_apply_radio_render_settings()

	node_2d.visible = false
	node_2d.process_mode = Node.PROCESS_MODE_DISABLED

	node_3d.visible = true
	node_3d.process_mode = Node.PROCESS_MODE_INHERIT

	anim_player.animation_finished.connect(_on_animation_finished)

	DialogueManager.show_dialogue_balloon(RADIO_DIALOGUE, "start")

	anim_player.speed_scale = 0.3
	anim_player.play("Scene")


func _apply_radio_render_settings() -> void:
	if _radio_render_settings_applied:
		return

	var viewport: Viewport = get_viewport()

	_original_3d_scale = viewport.scaling_3d_scale
	_original_3d_mode = viewport.scaling_3d_mode
	_original_msaa_3d = viewport.msaa_3d
	_original_screen_space_aa = viewport.screen_space_aa
	_original_use_taa = viewport.use_taa
	_original_max_fps = Engine.max_fps

	viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_NEAREST
	viewport.scaling_3d_scale = RADIO_RENDER_SCALE
	viewport.msaa_3d = Viewport.MSAA_DISABLED
	viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	viewport.use_taa = false

	if _original_max_fps == 0:
		Engine.max_fps = RADIO_MAX_FPS
	else:
		Engine.max_fps = mini(_original_max_fps, RADIO_MAX_FPS)

	_radio_render_settings_applied = true


func _restore_radio_render_settings() -> void:
	if not _radio_render_settings_applied:
		return

	var viewport: Viewport = get_viewport()

	viewport.scaling_3d_scale = _original_3d_scale
	viewport.scaling_3d_mode = _original_3d_mode
	viewport.msaa_3d = _original_msaa_3d
	viewport.screen_space_aa = _original_screen_space_aa
	viewport.use_taa = _original_use_taa

	Engine.max_fps = _original_max_fps

	_radio_render_settings_applied = false


func _exit_tree() -> void:
	_restore_radio_render_settings()


func send_envelope() -> void:
	envelope.visible = true

	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(
		envelope,
		"global_position",
		postbox.global_position,
		0.8
	)

	await tween.finished

	envelope.visible = false


func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name != "Scene":
		return

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)

	var target_fov: float = maxf(original_fov - 18.0, 1.0)

	tween.tween_property(
		camera,
		"fov",
		target_fov,
		0.18
	)

	tween.tween_property(
		camera,
		"rotation_degrees",
		Vector3(
			original_rotation.x,
			original_rotation.y,
			original_rotation.z + 2.5
		),
		0.18
	)

	await tween.finished

	node_3d.visible = false
	node_3d.process_mode = Node.PROCESS_MODE_DISABLED

	_restore_radio_render_settings()

	node_2d.visible = true
	node_2d.process_mode = Node.PROCESS_MODE_INHERIT

	camera.fov = original_fov
	camera.rotation_degrees = original_rotation

	if not anim_player_2d.animation_finished.is_connected(_on_2danimation_finished):
		anim_player_2d.animation_finished.connect(_on_2danimation_finished)

	anim_player_2d.play("2danimation_mailman")


func reveal_envelope() -> void:
	envelope.visible = true
	envelope.scale = Vector2(0.2, 0.2)
	envelope.modulate.a = 0.0

	var tween: Tween = create_tween()
	tween.set_parallel(true)

	tween.tween_property(
		envelope,
		"modulate:a",
		1.0,
		0.4
	)

	tween.tween_property(
		envelope,
		"scale",
		Vector2.ONE,
		0.4
	)

	await tween.finished

	envelope_origin = envelope.position
	envelope_float = true


func _on_2danimation_finished(anim_name: StringName) -> void:
	if anim_name != "2danimation_mailman":
		return

	mailman.walk("right")
	await get_tree().create_timer(1.8).timeout

	mailman.walk("down")
	await get_tree().create_timer(0.65).timeout

	mailman.walk("right")
	await get_tree().create_timer(0.4).timeout

	mailman.walk("down")
	await get_tree().create_timer(0.45).timeout

	mailman.walk("right")
	await get_tree().create_timer(4.43).timeout

	mailman.walk("up")
	await get_tree().create_timer(0.2).timeout

	mailman.stop()

	await reveal_envelope()

	instruction_label.text = "Press space to float mail into the postbox"
	instruction_label.visible = true

	await wait_for_space()

	instruction_label.visible = false

	await send_envelope()

	get_tree().change_scene_to_file("res://Screen/level_scene.tscn")


func wait_for_space() -> void:
	while not Input.is_action_just_pressed("ui_accept"):
		await get_tree().process_frame
