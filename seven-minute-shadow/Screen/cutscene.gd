extends Node

@onready var node_2d = $Node2D
@onready var node_3d = $Node3D
@onready var anim_player = $AnimationPlayer
@onready var anim_player_2d = $AnimationPlayer2
@onready var camera = $Node3D/Camera3D
@onready var mailman = $Node2D/Mailman/Mailman
const RADIO_DIALOGUE = preload("res://dialogue/radio.dialogue")

var original_fov: float
var original_rotation: Vector3

func _ready() -> void:
	# Store camera defaults
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


func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name != "Scene":
		return

	# Camera punch
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(camera, "fov", original_fov - 18.0, 0.18)
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
	await get_tree().create_timer(0.25).timeout
	
	mailman.walk("right")
	await get_tree().create_timer(4).timeout
	# Stop
	mailman.stop()
