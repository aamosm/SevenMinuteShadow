extends Button


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_pressed() -> void:
	Global.minigames_done = 0
	Global.lives = 4
	get_tree().change_scene_to_file("res://Screen/cutscene.tscn")
