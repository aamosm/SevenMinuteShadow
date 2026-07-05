extends Node2D


@export_multiline var level_message: String = "Make the day perfect and grant a second chance to the people who need it."
@export var fade_duration: float = 0.5   # seconds for fade in / fade out


@onready var lives_container: HBoxContainer = $Lives
@onready var icon: TextureRect = $Lives/Icon
@onready var icon_2: TextureRect = $Lives/Icon2
@onready var icon_3: TextureRect = $Lives/Icon3
@onready var icon_4: TextureRect = $Lives/Icon4
@onready var level_label: RichTextLabel = $Level
@onready var timer_label: RichTextLabel = $Timer
@onready var message_label: RichTextLabel = $Message

var time_left: float
var current_level: int  

func _ready() -> void:
	modulate.a = 0.0
	await fade_to(1.0)   # fade IN

	current_level = Global.minigames_done + 1
	level_label.text = "Level " + str(current_level)
	message_label.text = level_message

	await countdown(5.0)

	await fade_to(0.0)   # fade OUT before switching scenes

	if Global.minigames_done < 3:
		Global.minigames_done += 1
		get_tree().change_scene_to_file("res://Screen/minigame_" + str(Global.minigames_done) + ".tscn")
	else:
		get_tree().change_scene_to_file("res://Screen/title_screen.tscn")

func _process(_delta: float) -> void:
	match Global.lives:
		4:
			icon.hide()
		3:
			icon.hide()
			icon_2.hide()
		2:
			icon.hide()
			icon_2.hide()
			icon_3.hide()
		1:
			icon.hide()
			icon_2.hide()
			icon_3.hide()
			icon_4.hide()
		0:
			lives_container.hide()

	timer_label.text = str(time_left)
	# level_label is intentionally NOT updated here. it's set once in


func countdown(start_time: float) -> void:
	time_left = start_time
	while time_left > 0.0:
		await get_tree().create_timer(0.1).timeout
		time_left = max(time_left - 0.1, 0.0)   
	time_left = 0.0   

func fade_to(target_alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", target_alpha, fade_duration)
	await tween.finished
