extends Node

@onready var node_2d = $Node2D
@onready var node_3d = $Node3D
@onready var anim_player = $AnimationPlayer

func _ready():
	# Start state: 3D active, 2D off
	node_2d.visible = false
	node_2d.process_mode = Node.PROCESS_MODE_DISABLED
	
	node_3d.visible = true
	node_3d.process_mode = Node.PROCESS_MODE_INHERIT
	
	# Connect the signal so we know when the 3D animation finishes
	anim_player.animation_finished.connect(_on_animation_finished)
	
	anim_player.play("Scene")  # <-- put your 3D animation's name here

func _on_animation_finished(anim_name):
	if anim_name == "transition_anim":
		# Switch off 3D
		node_3d.visible = false
		node_3d.process_mode = Node.PROCESS_MODE_DISABLED
		
		# Switch on 2D
		node_2d.visible = true
		node_2d.process_mode = Node.PROCESS_MODE_INHERIT
