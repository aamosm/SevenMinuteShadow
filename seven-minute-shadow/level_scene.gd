extends Node2D

@export var fade_duration: float = 0.65
@export var screen_duration: float = 8

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
var instruction_label: RichTextLabel
var countdown_label: RichTextLabel
var separator: ColorRect

var screen_time_left: float = 0.0
var countdown_running: bool = false


const HOUSE_RANGES: Array[String] = [
	"HOUSES 01 - 02",
	"HOUSES 03 - 04",
	"HOUSES 05 - 06",
	"HOUSES 07 - 08"
]


const MAIL_REMAINING: Array[int] = [
	20,
	16,
	12,
	8
]


const ROUTE_TIMES: Array[String] = [
	"17:53",
	"17:55",
	"17:56",
	"17:58"
]


const RECORD_NAMES: Array[String] = [
	"KYOSHIMA CENTRAL POST",
	"KIYOSHIMA CIVIL DEFENCE",
	"KIYOSHIMA CIVIL DEFENCE",
	"EMERGENCY SERVICE BULLETIN"
]


const RECORD_TEXT: Array[String] = [
	"Kiyoshima's evening postal round began as usual.\nCivil Defence reports no active alert.\nFinal collection remains scheduled for 18:00.",

	"At 17:54, Civil Defence received an unverified air-raid warning for Kiyoshima.\nThe warning is still being checked.\nUntil confirmation, public services have been ordered to continue.",

	"At 17:56, the warning is confirmed.\nA bombing raid is expected before 18:00.\nSirens have begun in the central wards. Route Six is still outside.",

	"17:58. Communications are failing and evacuation has begun too late in several outer wards.\nImpact is expected before 18:00.\nRoute Six still has eight pieces of mail."
]


const INSTRUCTIONS: Array[String] = [
	"KEYBOARD - Press the shown key while the bar is inside green.",
	"MOUSE - Move the envelope fully onto the postbox, then click.",
	"MOUSE - Click the address that matches the envelope.",
	"MOUSE - Inspect, then drag the requested envelope into the slot."
]


func _ready() -> void:
	if Global.lives <= 0:
		get_tree().change_scene_to_file(
			"res://Screen/game_over.tscn"
		)
		return

	if Global.minigames_done >= 4:
		get_tree().change_scene_to_file(
			"res://Screen/win_scene.tscn"
		)
		return

	var stage: int = clampi(
		Global.minigames_done,
		0,
		3
	)

	_create_extra_ui()
	_setup_layout()

	_update_hearts()
	_apply_stage_text(stage)
	_apply_stage_visuals(stage)

	var music_stage: int = stage

	if stage == 3:
		music_stage = 4

	MusicManager.start_gameplay(
		music_stage
	)

	MusicManager.enter_interstitial()

	modulate.a = 0.0

	await _fade_to(1.0)

	screen_time_left = screen_duration
	countdown_running = true
	_update_countdown_text()

	await get_tree().create_timer(
		screen_duration
	).timeout

	countdown_running = false
	screen_time_left = 0.0
	_update_countdown_text()

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


func _process(delta: float) -> void:
	if not countdown_running:
		return

	screen_time_left = maxf(
		screen_time_left - delta,
		0.0
	)

	_update_countdown_text()


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


	instruction_label = RichTextLabel.new()

	instruction_label.name = "Instruction"
	instruction_label.bbcode_enabled = true
	instruction_label.scroll_active = false
	instruction_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	instruction_label.autowrap_mode = TextServer.AUTOWRAP_OFF

	instruction_label.add_theme_font_override(
		"normal_font",
		normal_font
	)

	add_child(instruction_label)


	countdown_label = RichTextLabel.new()

	countdown_label.name = "Countdown"
	countdown_label.bbcode_enabled = true
	countdown_label.scroll_active = false
	countdown_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	countdown_label.autowrap_mode = TextServer.AUTOWRAP_OFF

	countdown_label.add_theme_font_override(
		"normal_font",
		normal_font
	)

	add_child(countdown_label)


	separator = ColorRect.new()

	separator.name = "LoreSeparator"
	separator.mouse_filter = Control.MOUSE_FILTER_IGNORE

	add_child(separator)


func _setup_layout() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size

	var column_x: float = viewport_size.x * 0.595

	var column_width: float = minf(
		viewport_size.x * 0.36,
		viewport_size.x - column_x - 32.0
	)


	route_label.position = Vector2(
		column_x,
		58.0
	)

	route_label.size = Vector2(
		column_width,
		28.0
	)


	level_label.position = Vector2(
		column_x,
		91.0
	)

	level_label.size = Vector2(
		column_width,
		58.0
	)


	timer_label.position = Vector2(
		column_x,
		151.0
	)

	timer_label.size = Vector2(
		column_width,
		51.0
	)


	mail_label.position = Vector2(
		column_x,
		217.0
	)

	mail_label.size = Vector2(
		column_width,
		67.0
	)


	separator.position = Vector2(
		column_x,
		301.0
	)

	separator.size = Vector2(
		column_width * 0.92,
		1.0
	)


	message_label.position = Vector2(
		column_x,
		319.0
	)

	message_label.size = Vector2(
		column_width,
		160.0
	)


	instruction_label.position = Vector2(
		column_x,
		493.0
	)

	instruction_label.size = Vector2(
		column_width,
		34.0
	)


	countdown_label.position = Vector2(
		column_x,
		535.0
	)

	countdown_label.size = Vector2(
		column_width,
		27.0
	)


	lives_container.position = Vector2(
		column_x,
		579.0
	)

	lives_container.size = Vector2(
		180.0,
		32.0
	)

	lives_container.scale = Vector2.ONE
	lives_container.pivot_offset = Vector2.ZERO

	lives_container.offset_transform_enabled = false
	lives_container.offset_transform_scale = Vector2.ONE

	lives_container.add_theme_constant_override(
		"separation",
		7
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
		15
	)

	level_label.add_theme_font_size_override(
		"normal_font_size",
		33
	)

	timer_label.add_theme_font_size_override(
		"normal_font_size",
		33
	)

	mail_label.add_theme_font_size_override(
		"normal_font_size",
		22
	)

	message_label.add_theme_font_size_override(
		"normal_font_size",
		14
	)

	instruction_label.add_theme_font_size_override(
		"normal_font_size",
		12
	)

	countdown_label.add_theme_font_size_override(
		"normal_font_size",
		12
	)


func _setup_heart(
	heart: TextureRect
) -> void:
	heart.custom_minimum_size = Vector2(
		31.0,
		31.0
	)

	heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE

	heart.stretch_mode = (
		TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	)


func _apply_stage_text(
	stage: int
) -> void:
	route_label.text = "ROUTE SIX"

	level_label.text = (
		HOUSE_RANGES[stage]
	)

	timer_label.text = (
		ROUTE_TIMES[stage]
	)


	mail_label.text = (
		"[font_size=24]"
		+ str(MAIL_REMAINING[stage])
		+ " MAIL ITEMS"
		+ "[/font_size]\n"
		+ "[font_size=12]"
		+ "TO DELIVER"
		+ "[/font_size]"
	)


	message_label.text = (
		"[font_size=15]"
		+ RECORD_NAMES[stage]
		+ "[/font_size]\n"
		+ "[font_size=13]"
		+ RECORD_TEXT[stage]
		+ "[/font_size]"
	)


	instruction_label.text = (
		"[font_size=12]"
		+ INSTRUCTIONS[stage]
		+ "[/font_size]"
	)


func _update_countdown_text() -> void:
	if countdown_label == null:
		return

	countdown_label.text = (
		"NEXT IN "
		+ String.num(
			screen_time_left,
			1
		)
	)


func _apply_stage_visuals(
	stage: int
) -> void:
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
				0.91,
				0.80,
				0.73,
				1.0
			)

			text_color = Color(
				0.40,
				0.018,
				0.015,
				1.0
			)


		2:
			background_tint = Color(
				0.72,
				0.58,
				0.60,
				1.0
			)

			text_color = Color(
				0.30,
				0.02,
				0.025,
				1.0
			)


		3:
			background_tint = Color(
				0.43,
				0.35,
				0.47,
				1.0
			)

			text_color = Color(
				0.96,
				0.86,
				0.78,
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

	instruction_label.add_theme_color_override(
		"default_color",
		text_color
	)

	var countdown_color: Color = text_color
	countdown_color.a = 0.65

	countdown_label.add_theme_color_override(
		"default_color",
		countdown_color
	)


	var separator_color: Color = text_color
	separator_color.a = 0.20

	separator.color = separator_color


func _update_hearts() -> void:
	icon.visible = Global.lives >= 1
	icon_2.visible = Global.lives >= 2
	icon_3.visible = Global.lives >= 3
	icon_4.visible = Global.lives >= 4

	lives_container.visible = (
		Global.lives > 0
	)


func _fade_to(
	target_alpha: float
) -> void:
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
