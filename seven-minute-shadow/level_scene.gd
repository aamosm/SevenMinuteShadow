extends Node2D

@export var fade_duration: float = 0.65
@export var screen_duration: float = 7

@onready var background: TextureRect = $TextureRect

@onready var lives_container: HBoxContainer = $Lives
@onready var icon: TextureRect = $Lives/Icon
@onready var icon_2: TextureRect = $Lives/Icon2
@onready var icon_3: TextureRect = $Lives/Icon3
@onready var icon_4: TextureRect = $Lives/Icon4

@onready var level_label: RichTextLabel = $Level
@onready var timer_label: RichTextLabel = $Timer
@onready var message_label: RichTextLabel = $Message

var route_label: RichTextLabel
var mail_label: RichTextLabel
var separator: ColorRect


const HOUSE_RANGES: Array[String] = [
	"HOUSES 01 - 02",
	"HOUSES 03 - 04",
	"HOUSES 05 - 06",
	"HOUSES 07 - 08",
	"HOUSES 09 - 10"
]


const MAIL_REMAINING: Array[int] = [
	20,
	16,
	12,
	8,
	4
]


const ROUTE_TIMES: Array[String] = [
	"17:53",
	"17:55",
	"17:56",
	"17:58",
	"17:59"
]


const RECORD_NAMES: Array[String] = [
	"KYOSHIMA CENTRAL POST",
	"MUNICIPAL EMERGENCY LOG",
	"CIVIL DEFENCE RECORD",
	"KYOSHIMA CENTRAL POST",
	"ROUTE SIX LEDGER"
]


const RECORD_TEXT: Array[String] = [
	"Route Six departed at 17:53.\nFinal collection scheduled: 18:00.",

	"17:55 - emergency frequency activated.\nTransmission ended after eleven seconds.",

	"17:56 - civil warning authenticated.\nEstimated window remaining: four minutes.",

	"17:58 - Route Six remained active.\nFinal collection unchanged: 18:00.",

	"17:59 - four items remained.\nNo later entries"
]


func _ready() -> void:
	if Global.lives <= 0:
		get_tree().change_scene_to_file(
			"res://Screen/game_over.tscn"
		)
		return

	if Global.minigames_done >= 5:
		get_tree().change_scene_to_file(
			"res://Screen/game_over.tscn"
		)
		return

	var stage: int = clampi(
		Global.minigames_done,
		0,
		4
	)

	_create_extra_ui()
	_setup_layout()
	_update_hearts()

	_apply_stage_text(stage)
	_apply_stage_visuals(stage)

	MusicManager.start_gameplay(stage)
	MusicManager.enter_interstitial()

	modulate.a = 0.0

	await _fade_to(1.0)

	await get_tree().create_timer(
		screen_duration
	).timeout

	await _fade_to(0.0)

	var minigame_number: int = stage + 1

	var minigame_path: String = (
		"res://Screen/minigame_"
		+ str(minigame_number)
		+ ".tscn"
	)

	get_tree().change_scene_to_file(
		minigame_path
	)


func _create_extra_ui() -> void:
	var normal_font: Font = message_label.get_theme_font(
		"normal_font"
	)


	route_label = RichTextLabel.new()

	route_label.name = "RouteLabel"
	route_label.bbcode_enabled = true
	route_label.scroll_active = false
	route_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	route_label.autowrap_mode = TextServer.AUTOWRAP_OFF

	route_label.add_theme_font_override(
		"normal_font",
		normal_font
	)

	add_child(route_label)


	mail_label = RichTextLabel.new()

	mail_label.name = "MailStatus"
	mail_label.bbcode_enabled = true
	mail_label.scroll_active = false
	mail_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mail_label.autowrap_mode = TextServer.AUTOWRAP_OFF

	mail_label.add_theme_font_override(
		"normal_font",
		normal_font
	)

	add_child(mail_label)


	separator = ColorRect.new()

	separator.name = "LoreSeparator"
	separator.mouse_filter = Control.MOUSE_FILTER_IGNORE

	add_child(separator)


func _setup_layout() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size

	var column_x: float = viewport_size.x * 0.595

	var column_width: float = minf(
		viewport_size.x * 0.36,
		viewport_size.x - column_x - 34.0
	)


	route_label.position = Vector2(
		column_x,
		96.0
	)

	route_label.size = Vector2(
		column_width,
		32.0
	)


	level_label.position = Vector2(
		column_x,
		143.0
	)

	level_label.size = Vector2(
		column_width,
		64.0
	)


	timer_label.position = Vector2(
		column_x,
		209.0
	)

	timer_label.size = Vector2(
		column_width,
		62.0
	)


	mail_label.position = Vector2(
		column_x,
		291.0
	)

	mail_label.size = Vector2(
		column_width,
		76.0
	)


	separator.position = Vector2(
		column_x,
		381.0
	)

	separator.size = Vector2(
		column_width * 0.90,
		1.0
	)


	message_label.position = Vector2(
		column_x,
		403.0
	)

	message_label.size = Vector2(
		column_width,
		142.0
	)


	lives_container.position = Vector2(
		column_x,
		561.0
	)

	lives_container.size = Vector2(
		180.0,
		34.0
	)

	lives_container.scale = Vector2.ONE
	lives_container.pivot_offset = Vector2.ZERO

	lives_container.add_theme_constant_override(
		"separation",
		8
	)


	_setup_heart(icon)
	_setup_heart(icon_2)
	_setup_heart(icon_3)
	_setup_heart(icon_4)


	level_label.bbcode_enabled = true
	timer_label.bbcode_enabled = true
	message_label.bbcode_enabled = true

	level_label.scroll_active = false
	timer_label.scroll_active = false
	message_label.scroll_active = false

	level_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	timer_label.autowrap_mode = TextServer.AUTOWRAP_OFF

	message_label.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)


	route_label.add_theme_font_size_override(
		"normal_font_size",
		16
	)

	level_label.add_theme_font_size_override(
		"normal_font_size",
		35
	)

	timer_label.add_theme_font_size_override(
		"normal_font_size",
		35
	)

	mail_label.add_theme_font_size_override(
		"normal_font_size",
		24
	)

	message_label.add_theme_font_size_override(
		"normal_font_size",
		15
	)


func _setup_heart(heart: TextureRect) -> void:
	heart.custom_minimum_size = Vector2(
		32.0,
		32.0
	)

	heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE

	heart.stretch_mode = (
		TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	)


func _apply_stage_text(stage: int) -> void:
	route_label.text = "ROUTE SIX"

	level_label.text = HOUSE_RANGES[stage]

	timer_label.text = ROUTE_TIMES[stage]


	mail_label.text = (
		"[font_size=25]"
		+ str(MAIL_REMAINING[stage])
		+ " MAIL ITEMS"
		+ "[/font_size]\n"
		+ "[font_size=13]"
		+ "TO DELIVER"
		+ "[/font_size]"
	)


	message_label.text = (
		"[font_size=16]"
		+ RECORD_NAMES[stage]
		+ "[/font_size]\n"
		+ "[font_size=14]"
		+ RECORD_TEXT[stage]
		+ "[/font_size]"
	)


func _apply_stage_visuals(stage: int) -> void:
	var background_tint: Color
	var text_color: Color


	match stage:
		0:
			background_tint = Color(
				1.0,
				1.0,
				1.0,
				1.0
			)

			text_color = Color(
				0.44,
				0.0,
				0.0,
				1.0
			)


		1:
			background_tint = Color(
				0.95,
				0.87,
				0.78,
				1.0
			)

			text_color = Color(
				0.42,
				0.02,
				0.015,
				1.0
			)


		2:
			background_tint = Color(
				0.82,
				0.68,
				0.64,
				1.0
			)

			text_color = Color(
				0.34,
				0.025,
				0.025,
				1.0
			)


		3:
			background_tint = Color(
				0.65,
				0.50,
				0.56,
				1.0
			)

			text_color = Color(
				0.93,
				0.82,
				0.74,
				1.0
			)


		4:
			background_tint = Color(
				0.43,
				0.36,
				0.48,
				1.0
			)

			text_color = Color(
				0.96,
				0.88,
				0.80,
				1.0
			)


		_:
			background_tint = Color.WHITE
			text_color = Color.WHITE


	background.self_modulate = background_tint


	route_label.add_theme_color_override(
		"default_color",
		text_color
	)

	level_label.add_theme_color_override(
		"default_color",
		text_color
	)

	timer_label.add_theme_color_override(
		"default_color",
		text_color
	)

	mail_label.add_theme_color_override(
		"default_color",
		text_color
	)

	message_label.add_theme_color_override(
		"default_color",
		text_color
	)


	var separator_color: Color = text_color
	separator_color.a = 0.22

	separator.color = separator_color


func _update_hearts() -> void:
	icon.visible = Global.lives >= 1
	icon_2.visible = Global.lives >= 2
	icon_3.visible = Global.lives >= 3
	icon_4.visible = Global.lives >= 4

	lives_container.visible = Global.lives > 0


func _fade_to(target_alpha: float) -> void:
	var tween: Tween = create_tween()

	tween.set_trans(
		Tween.TRANS_SINE
	)

	tween.set_ease(
		Tween.EASE_IN_OUT
	)

	tween.tween_property(
		self,
		"modulate:a",
		target_alpha,
		fade_duration
	)

	await tween.finished
