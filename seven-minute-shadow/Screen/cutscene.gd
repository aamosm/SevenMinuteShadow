extends Node

@onready var node_2d = $Node2D
@onready var node_3d = $Node3D
@onready var anim_player = $AnimationPlayer
@onready var anim_player_2d = $AnimationPlayer2
@onready var camera = $Node3D/Camera3D
@onready var mailman = $Node2D/Mailman/Mailman
@onready var envelope = $Node2D/Mailman/EnvelopeSealed
@onready var postbox = $Node2D/Mailman/Postoffice
@onready var instruction_label: Label = $Node2D/Mailman/InstructionLabel

var envelope_origin := Vector2.ZERO
var envelope_float := false
var float_time := 0.0
const RADIO_DIALOGUE = preload("res://dialogue/radio.dialogue")

var original_fov: float
var original_rotation: Vector3
func _process(delta):
	if envelope_float:
		float_time += delta
		envelope.position.y = envelope_origin.y + sin(float_time * 4.5) * 6.0

func _ready() -> void:
	# Store camera defaults
	envelope.visible = false
	envelope.modulate.a = 0.0
	envelope_origin = envelope.position
	original_fov = camera.fov
	original_rotation = camera.rotation_degrees


	# Start state
	node_2d.visible = false
	node_2d.process_mode = Node.PROCESS_MODE_DISABLED

	node_3d.visible = true
	node_3d.process_mode = Node.PROCESS_MODE_INHERIT

	anim_player.animation_finished.connect(_on_animation_finished)

	DialogueManager.show_dialogue_balloon(RADIO_DIALOGUE, "start")

	anim_player.speed_scale = 0.3
	anim_player.play("Scene")

func send_envelope():
	envelope.visible = true

	var tween = create_tween()
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

	# Camera punch
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)

	var target_fov = max(original_fov - 18.0, 1.0)
	tween.tween_property(camera, "fov", target_fov, 0.18)
	tween.tween_property(camera, "rotation_degrees", Vector3(
		original_rotation.x,
		original_rotation.y,
		original_rotation.z + 2.5
	), 0.18)

	await tween.finished

	# Switch to 2D
	node_3d.visible = false
	node_3d.process_mode = Node.PROCESS_MODE_DISABLED

	node_2d.visible = true
	node_2d.process_mode = Node.PROCESS_MODE_INHERIT

	# Reset camera
	camera.fov = original_fov
	camera.rotation_degrees = original_rotation
	
	anim_player_2d.animation_finished.connect(_on_2danimation_finished)
	anim_player_2d.play("2danimation_mailman")

func reveal_envelope():
	envelope.visible = true
	envelope.scale = Vector2(0.2, 0.2)
	envelope.modulate.a = 0.0

	var tween = create_tween()
	tween.set_parallel(true)

	tween.tween_property(envelope, "modulate:a", 1.0, 0.4)
	tween.tween_property(envelope, "scale", Vector2.ONE, 0.4)

	await tween.finished

	envelope_origin = envelope.position
	envelope_float = true

func _on_2danimation_finished(anim_name):
	if anim_name != "2danimation_mailman":
		return

	# Walk right
	mailman.walk("right")
	await get_tree().create_timer(1.8).timeout

	# Walk down
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
	# Stop
	mailman.stop()
	reveal_envelope()

	instruction_label.text = "Press space to float mail into the postbox"
	instruction_label.visible = true
	await wait_for_space()
	instruction_label.visible = false

	await send_envelope()
	get_tree().change_scene_to_file("res://Screen/level_scene.tscn")

func wait_for_space() -> void:
	while not Input.is_action_just_pressed("ui_accept"):
		await get_tree().process_frame
