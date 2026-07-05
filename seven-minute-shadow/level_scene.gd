extends Node2D

@export var level_messages: Array[String] = [
	"Press the prompted key to shoot Mail into the Postbox",
	"level 2",
	"",
	"4",
	"",
	"level 6",
	"7"
]
@export var fade_duration: float = 0.5

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
	await fade_to(1.0)
	current_level = Global.minigames_done + 1
	level_label.text = "Level " + str(current_level)
	message_label.text = level_messages[clamp(current_level - 1, 0, level_messages.size() - 1)]
	await countdown(4.0)
	await fade_to(0.0)
	if Global.minigames_done < 3:
		Global.minigames_done += 1
		get_tree().change_scene_to_file("res://Screen/minigame_" + str(Global.minigames_done) + ".tscn")
	else:
		get_tree().change_scene_to_file("res://Screen/title_screen.tscn")

func _process(_delta: float) -> void:
	match Global.lives:
		4:
			icon.show()
			icon_2.show()
			icon_3.show()
			icon_4.show()
		3:
			icon.show()
			icon_2.show()
			icon_3.show()
			icon_4.hide()
		2:
			icon.show()
			icon_2.show()
			icon_3.hide()
			icon_4.hide()
		1:
			icon.show()
			icon_2.hide()
			icon_3.hide()
			icon_4.hide()
		0:
			lives_container.hide()
	timer_label.text = str(time_left)

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
