extends Node2D


const HAND_FONT: FontFile = preload(
	"res://Fonts/Gloria_Hallelujah/GloriaHallelujah-Regular.ttf"
)


const ROUTE_07 = [
	{
		"address": "07-A",
		"name": "SATO",
		"place": "BAKERY"
	},
	{
		"address": "07-B",
		"name": "MORI",
		"place": "SCHOOL OFFICE"
	},
	{
		"address": "07-C",
		"name": "HAYASHI",
		"place": "CLINIC"
	},
	{
		"address": "07-D",
		"name": "ABE",
		"place": "FERRY WORKS"
	},
	{
		"address": "07-E",
		"name": "KONDO",
		"place": "TEA HOUSE"
	},
	{
		"address": "07-F",
		"name": "TANAKA",
		"place": "FISHMONGER"
	},
	{
		"address": "07-G",
		"name": "UEDA",
		"place": "CARPENTER"
	},
	{
		"address": "07-H",
		"name": "FUJII",
		"place": "BOOKSELLER"
	}
]


const ROUTE_08 = [
	{
		"address": "08-A",
		"name": "KATO",
		"place": "LIGHTHOUSE"
	},
	{
		"address": "08-B",
		"name": "ITO",
		"place": "ALTERATIONS"
	},
	{
		"address": "08-C",
		"name": "SUZUKI",
		"place": "RADIO & ELECTRIC"
	},
	{
		"address": "08-D",
		"name": "ONO",
		"place": "CIVIL DEFENCE"
	},
	{
		"address": "08-E",
		"name": "WATANABE",
		"place": "HOTEL"
	},
	{
		"address": "08-F",
		"name": "NAKAMURA",
		"place": "PRINT SHOP"
	},
	{
		"address": "08-G",
		"name": "ISHII",
		"place": "DOCK OFFICE"
	},
	{
		"address": "08-H",
		"name": "YAMADA",
		"place": "WATCHMAKER"
	}
]

const TELEGRAMS = [
	{
		"source": "CENTRAL FREIGHT DEPOT",
		"body":
			"FLOUR TRUCK MISSED THE FERRY.\n"
			+ "TWELVE SACKS ARRIVE TOMORROW.\n"
			+ "SAVE US A LOAF.",
		"answer": "07-A"
	},
	{
		"source": "DISTRICT EDUCATION BOARD",
		"body":
			"CLASSES END EARLY TOMORROW.\n"
			+ "PLEASE INFORM STAFF AND PARENTS.\n"
			+ "THE CHILDREN WILL NOT COMPLAIN.",
		"answer": "07-B"
	},
	{
		"source": "CENTRAL MEDICAL STORES",
		"body":
			"BANDAGES AND ANTISEPTIC SENT.\n"
			+ "MORE SUPPLIES ARRIVE MONDAY.\n"
			+ "MAKE THESE LAST.",
		"answer": "07-C"
	},
	{
		"source": "KIYOSHIMA HARBOUR AUTHORITY",
		"body":
			"FERRY THREE'S NEW PUMP IS HERE.\n"
			+ "DO NOT START HER YET.\n"
			+ "ABE KNOWS THE REST.",
		"answer": "07-D"
	},
	{
		"source": "NAVAL SUPPLY OFFICE",
		"body":
			"SIX COATS NEED NEW BUTTONS.\n"
			+ "TWO NEED SHORTER SLEEVES.\n"
			+ "SAME MEASUREMENTS AS BEFORE.",
		"answer": "08-B"
	},
	{
		"source": "DISTRICT COMMUNICATIONS",
		"body":
			"EMERGENCY SETS COME FIRST TONIGHT.\n"
			+ "CIVILIAN RADIOS CAN WAIT.\n"
			+ "SORRY, SUZUKI.",
		"answer": "08-C"
	},
	{
		"source": "KIYOSHIMA HARBOUR OFFICE",
		"body":
			"KATO,\n\n"
			+ "STOP TELLING THE CHILDREN\n"
			+ "THAT SHADOW WAS GOJIRA.\n"
			+ "IT WAS A WHALE.",
		"answer": "08-A"
	},
	{
		"source": "DISTRICT AIR DEFENCE COMMAND",
		"body":
			"AIR CONTACT RECLASSIFIED.\n"
			+ "MULTIPLE AIRCRAFT CONFIRMED EAST.\n"
			+ "THIS IS NOT A WEATHER FLIGHT.",
		"answer": "08-D"
	}
]

@export var correct_pause: float = 0.55
@export var route_complete_pause: float = 1.6

@export var first_question_time: float = 25.0
@export var final_question_time: float = 10.0

@export var shake_strength: float = 7.0
@export var shake_steps: int = 7

@export var fail_sound_volume_db: float = -3.0


@onready var background: TextureRect = $Background
@onready var envelope: TextureRect = $Envelope

@onready var lives_container: HBoxContainer = $Lives

@onready var icon: TextureRect = $Lives/Icon
@onready var icon_2: TextureRect = $Lives/Icon2
@onready var icon_3: TextureRect = $Lives/Icon3
@onready var icon_4: TextureRect = $Lives/Icon4

@onready var cross_icon: TextureRect = $CrossIcon


var title_label: Label
var remaining_label: Label

var timer_label: Label
var timer_bar: ProgressBar

var telegram_panel: ColorRect
var telegram_heading: Label
var telegram_source: Label
var telegram_body: RichTextLabel

var address_card: ColorRect
var address_caption: Label
var address_to_label: Label
var address_route_label: Label
var house_number_label: Label

var damage_mask: ColorRect
var damage_bar_1: ColorRect
var damage_bar_2: ColorRect
var damage_bar_3: ColorRect

var route_panel: ColorRect
var route_heading: Label
var route_book: RichTextLabel

var choice_panel: ColorRect
var choice_heading: Label
var instruction_label: Label
var status_label: Label

var address_buttons: Array[Button] = []

var fail_sound_player: AudioStreamPlayer

var question_order: Array[int] = []
var current_question_index: int = 0

var current_candidates: Array = []

var question_time_limit: float = 25.0
var question_time_remaining: float = 25.0
var timer_running: bool = false

var active: bool = false

var screen_size: Vector2


func _ready() -> void:
	randomize()

	Input.set_mouse_mode(
		Input.MOUSE_MODE_VISIBLE
	)

	MusicManager.start_gameplay(4)
	MusicManager.enter_minigame()

	screen_size = get_viewport_rect().size

	background.self_modulate = Color(
		0.44,
		0.36,
		0.46,
		1.0
	)

	if envelope:
		envelope.visible = false

	if cross_icon:
		cross_icon.hide()

		cross_icon.size = Vector2(
			92.0,
			92.0
		)

		cross_icon.position = (
			screen_size / 2.0
			- cross_icon.size / 2.0
		)

	_create_question_order()

	_setup_fail_sound()

	_create_ui()

	_update_hearts()

	_show_current_telegram()

	active = true


func _process(delta: float) -> void:
	if not active:
		return

	if not timer_running:
		return


	question_time_remaining -= delta

	question_time_remaining = maxf(
		question_time_remaining,
		0.0
	)

	_update_timer_ui()


	if question_time_remaining <= 0.0:
		timer_running = false

		_handle_timeout()


func _create_question_order() -> void:
	question_order.clear()

	for i in range(
		TELEGRAMS.size()
	):
		question_order.append(i)

	question_order.shuffle()


func _get_current_telegram() -> Dictionary:
	var telegram_index: int = (
		question_order[
			current_question_index
		]
	)

	return TELEGRAMS[
		telegram_index
	]


func _create_ui() -> void:
	_create_header()
	_create_timer_ui()
	_create_telegram_area()
	_create_damaged_address()
	_create_route_book()
	_create_choice_area()
	_create_address_buttons()


func _create_header() -> void:
	title_label = Label.new()

	title_label.text = "ROUTE 6"

	title_label.position = Vector2(
		38.0,
		24.0
	)

	title_label.size = Vector2(
		360.0,
		38.0
	)

	title_label.add_theme_font_override(
		"font",
		HAND_FONT
	)

	title_label.add_theme_font_size_override(
		"font_size",
		24
	)

	title_label.add_theme_color_override(
		"font_color",
		Color(
			0.96,
			0.89,
			0.82
		)
	)

	add_child(
		title_label
	)


	remaining_label = Label.new()

	remaining_label.position = Vector2(
		38.0,
		58.0
	)

	remaining_label.size = Vector2(
		350.0,
		28.0
	)

	remaining_label.add_theme_font_override(
		"font",
		HAND_FONT
	)

	remaining_label.add_theme_font_size_override(
		"font_size",
		14
	)

	remaining_label.add_theme_color_override(
		"font_color",
		Color(
			0.79,
			0.72,
			0.69
		)
	)

	add_child(
		remaining_label
	)


	lives_container.position = Vector2(
		screen_size.x - 315.0,
		25.0
	)

	lives_container.add_theme_constant_override(
		"separation",
		7
	)

func _create_timer_ui() -> void:
	timer_label = Label.new()

	timer_label.position = Vector2(
		77.0,
		547.0
	)

	timer_label.size = Vector2(
		95.0,
		22.0
	)

	timer_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_LEFT
	)

	timer_label.add_theme_font_override(
		"font",
		HAND_FONT
	)

	timer_label.add_theme_font_size_override(
		"font_size",
		12
	)

	timer_label.add_theme_color_override(
		"font_color",
		Color(
			0.91,
			0.80,
			0.73
		)
	)

	add_child(
		timer_label
	)


	timer_bar = ProgressBar.new()

	timer_bar.position = Vector2(
		170.0,
		552.0
	)

	timer_bar.size = Vector2(
		240.0,
		9.0
	)

	timer_bar.min_value = 0.0
	timer_bar.max_value = 100.0
	timer_bar.value = 100.0

	timer_bar.show_percentage = false

	timer_bar.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)


	var timer_bg := StyleBoxFlat.new()

	timer_bg.bg_color = Color(
		0.12,
		0.07,
		0.09,
		0.82
	)

	timer_bg.corner_radius_top_left = 2
	timer_bg.corner_radius_top_right = 2
	timer_bg.corner_radius_bottom_left = 2
	timer_bg.corner_radius_bottom_right = 2


	var timer_fill := StyleBoxFlat.new()

	timer_fill.bg_color = Color(
		0.82,
		0.57,
		0.52,
		0.92
	)

	timer_fill.corner_radius_top_left = 2
	timer_fill.corner_radius_top_right = 2
	timer_fill.corner_radius_bottom_left = 2
	timer_fill.corner_radius_bottom_right = 2


	timer_bar.add_theme_stylebox_override(
		"background",
		timer_bg
	)

	timer_bar.add_theme_stylebox_override(
		"fill",
		timer_fill
	)

	add_child(
		timer_bar
	)
func _create_telegram_area() -> void:
	telegram_panel = ColorRect.new()

	telegram_panel.position = Vector2(
		38.0,
		86.0
	)

	telegram_panel.size = Vector2(
		655.0,
		408.0
	)

	telegram_panel.color = Color(
		0.09,
		0.06,
		0.08,
		0.66
	)

	telegram_panel.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	add_child(
		telegram_panel
	)


	telegram_heading = Label.new()

	telegram_heading.text = "TELEGRAM"

	telegram_heading.position = Vector2(
		62.0,
		128.0
	)

	telegram_heading.size = Vector2(
		280.0,
		36.0
	)

	telegram_heading.add_theme_font_override(
		"font",
		HAND_FONT
	)

	telegram_heading.add_theme_font_size_override(
		"font_size",
		23
	)

	telegram_heading.add_theme_color_override(
		"font_color",
		Color(
			0.96,
			0.89,
			0.82
		)
	)

	add_child(
		telegram_heading
	)


	telegram_source = Label.new()

	telegram_source.position = Vector2(
		62.0,
		176.0
	)

	telegram_source.size = Vector2(
		300.0,
		28.0
	)

	telegram_source.add_theme_font_override(
		"font",
		HAND_FONT
	)

	telegram_source.add_theme_font_size_override(
		"font_size",
		12
	)

	telegram_source.add_theme_color_override(
		"font_color",
		Color(
			0.76,
			0.70,
			0.68
		)
	)

	add_child(
		telegram_source
	)


	telegram_body = RichTextLabel.new()

	telegram_body.position = Vector2(
		62.0,
		235.0
	)

	telegram_body.size = Vector2(
		595.0,
		235.0
	)

	telegram_body.bbcode_enabled = false
	telegram_body.scroll_active = false

	telegram_body.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	telegram_body.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)

	telegram_body.add_theme_font_override(
		"normal_font",
		HAND_FONT
	)

	telegram_body.add_theme_font_size_override(
		"normal_font_size",
		19
	)

	telegram_body.add_theme_color_override(
		"default_color",
		Color(
			0.95,
			0.90,
			0.84
		)
	)

	telegram_body.add_theme_constant_override(
		"line_separation",
		6
	)

	add_child(
		telegram_body
	)


func _create_damaged_address() -> void:
	address_card = ColorRect.new()

	address_card.position = Vector2(
		381.0,
		102.0
	)

	address_card.size = Vector2(
		286.0,
		120.0
	)

	address_card.color = Color(
		0.12,
		0.07,
		0.09,
		0.58
	)

	address_card.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	add_child(
		address_card
	)


	address_caption = Label.new()

	address_caption.text = "DELIVERY LABEL"

	address_caption.position = Vector2(
		395.0,
		112.0
	)

	address_caption.size = Vector2(
		245.0,
		18.0
	)

	address_caption.add_theme_font_override(
		"font",
		HAND_FONT
	)

	address_caption.add_theme_font_size_override(
		"font_size",
		9
	)

	address_caption.add_theme_color_override(
		"font_color",
		Color(
			0.69,
			0.58,
			0.58
		)
	)

	add_child(
		address_caption
	)


	address_to_label = Label.new()

	address_to_label.text = "TO: KIYOSHIMA"

	address_to_label.position = Vector2(
		395.0,
		139.0
	)

	address_to_label.size = Vector2(
		250.0,
		22.0
	)

	address_to_label.add_theme_font_override(
		"font",
		HAND_FONT
	)

	address_to_label.add_theme_font_size_override(
		"font_size",
		13
	)

	address_to_label.add_theme_color_override(
		"font_color",
		Color(
			0.78,
			0.53,
			0.53,
			0.90
		)
	)

	add_child(
		address_to_label
	)


	address_route_label = Label.new()

	address_route_label.text = "ROUTE 6"

	address_route_label.position = Vector2(
		395.0,
		166.0
	)

	address_route_label.size = Vector2(
		250.0,
		22.0
	)

	address_route_label.add_theme_font_override(
		"font",
		HAND_FONT
	)

	address_route_label.add_theme_font_size_override(
		"font_size",
		13
	)

	address_route_label.add_theme_color_override(
		"font_color",
		Color(
			0.78,
			0.53,
			0.53,
			0.90
		)
	)

	add_child(
		address_route_label
	)


	house_number_label = Label.new()

	house_number_label.position = Vector2(
		395.0,
		193.0
	)

	house_number_label.size = Vector2(
		250.0,
		24.0
	)

	house_number_label.add_theme_font_override(
		"font",
		HAND_FONT
	)

	house_number_label.add_theme_font_size_override(
		"font_size",
		13
	)

	house_number_label.add_theme_color_override(
		"font_color",
		Color(
			0.78,
			0.53,
			0.53,
			0.90
		)
	)

	add_child(
		house_number_label
	)


	damage_mask = ColorRect.new()

	damage_mask.position = Vector2(
		507.0,
		198.0
	)

	damage_mask.size = Vector2(
		54.0,
		18.0
	)

	damage_mask.color = Color(
		0.12,
		0.07,
		0.09,
		0.98
	)

	damage_mask.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	add_child(
		damage_mask
	)


	damage_bar_1 = ColorRect.new()

	damage_bar_1.position = Vector2(
		506.0,
		202.0
	)

	damage_bar_1.size = Vector2(
		55.0,
		3.0
	)

	damage_bar_1.rotation = deg_to_rad(
		-4.0
	)

	damage_bar_1.color = Color(
		0.56,
		0.31,
		0.34,
		0.95
	)

	damage_bar_1.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	add_child(
		damage_bar_1
	)


	damage_bar_2 = ColorRect.new()

	damage_bar_2.position = Vector2(
		510.0,
		207.0
	)

	damage_bar_2.size = Vector2(
		49.0,
		3.0
	)

	damage_bar_2.rotation = deg_to_rad(
		3.5
	)

	damage_bar_2.color = Color(
		0.42,
		0.22,
		0.26,
		0.96
	)

	damage_bar_2.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	add_child(
		damage_bar_2
	)


	damage_bar_3 = ColorRect.new()

	damage_bar_3.position = Vector2(
		514.0,
		211.0
	)

	damage_bar_3.size = Vector2(
		42.0,
		2.0
	)

	damage_bar_3.rotation = deg_to_rad(
		-1.5
	)

	damage_bar_3.color = Color(
		0.68,
		0.39,
		0.40,
		0.75
	)

	damage_bar_3.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	add_child(
		damage_bar_3
	)


func _create_route_book() -> void:
	route_panel = ColorRect.new()

	route_panel.position = Vector2(
		729.0,
		86.0
	)

	route_panel.size = Vector2(
		361.0,
		213.0
	)

	route_panel.color = Color(
		0.10,
		0.06,
		0.08,
		0.59
	)

	route_panel.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	add_child(
		route_panel
	)


	route_heading = Label.new()

	route_heading.position = Vector2(
		747.0,
		108.0
	)

	route_heading.size = Vector2(
		325.0,
		30.0
	)

	route_heading.add_theme_font_override(
		"font",
		HAND_FONT
	)

	route_heading.add_theme_font_size_override(
		"font_size",
		16
	)

	route_heading.add_theme_color_override(
		"font_color",
		Color(
			0.96,
			0.89,
			0.82
		)
	)

	add_child(
		route_heading
	)


	route_book = RichTextLabel.new()

	route_book.position = Vector2(
		748.0,
		148.0
	)

	route_book.size = Vector2(
		320.0,
		132.0
	)

	route_book.bbcode_enabled = false
	route_book.scroll_active = false

	route_book.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	route_book.autowrap_mode = (
		TextServer.AUTOWRAP_OFF
	)

	route_book.add_theme_font_override(
		"normal_font",
		HAND_FONT
	)

	route_book.add_theme_font_size_override(
		"normal_font_size",
		13
	)

	route_book.add_theme_color_override(
		"default_color",
		Color(
			0.88,
			0.83,
			0.78
		)
	)

	route_book.add_theme_constant_override(
		"line_separation",
		5
	)

	add_child(
		route_book
	)


func _create_choice_area() -> void:
	choice_panel = ColorRect.new()

	choice_panel.position = Vector2(
		729.0,
		305.0
	)

	choice_panel.size = Vector2(
		361.0,
		232.0
	)

	choice_panel.color = Color(
		0.10,
		0.06,
		0.08,
		0.52
	)

	choice_panel.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	add_child(
		choice_panel
	)


	choice_heading = Label.new()

	choice_heading.text = (
		"FIND THE CORRECT ADDRESS"
	)

	choice_heading.position = Vector2(
		744.0,
		328.0
	)

	choice_heading.size = Vector2(
		332.0,
		28.0
	)

	choice_heading.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	choice_heading.add_theme_font_override(
		"font",
		HAND_FONT
	)

	choice_heading.add_theme_font_size_override(
		"font_size",
		14
	)

	choice_heading.add_theme_color_override(
		"font_color",
		Color(
			0.95,
			0.89,
			0.83
		)
	)

	add_child(
		choice_heading
	)


	instruction_label = Label.new()

	instruction_label.text = (
		"Read the telegram and use the four entries above.\n"
		+ "The final part of the house number is damaged."
	)

	instruction_label.position = Vector2(
		746.0,
		360.0
	)

	instruction_label.size = Vector2(
		328.0,
		47.0
	)

	instruction_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	instruction_label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	instruction_label.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)

	instruction_label.add_theme_font_override(
		"font",
		HAND_FONT
	)

	instruction_label.add_theme_font_size_override(
		"font_size",
		9
	)

	instruction_label.add_theme_color_override(
		"font_color",
		Color(
			0.75,
			0.69,
			0.67
		)
	)

	add_child(
		instruction_label
	)


	status_label = Label.new()

	status_label.position = Vector2(
		743.0,
		505.0
	)

	status_label.size = Vector2(
		333.0,
		20.0
	)

	status_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	status_label.add_theme_font_override(
		"font",
		HAND_FONT
	)

	status_label.add_theme_font_size_override(
		"font_size",
		10
	)

	status_label.add_theme_color_override(
		"font_color",
		Color(
			0.92,
			0.78,
			0.71
		)
	)

	add_child(
		status_label
	)


func _create_address_buttons() -> void:
	var button_positions: Array[Vector2] = [
		Vector2(736.0, 412.0),
		Vector2(918.0, 412.0),
		Vector2(736.0, 461.0),
		Vector2(918.0, 461.0)
	]


	for i in range(4):
		var button := Button.new()

		button.position = button_positions[i]

		button.size = Vector2(
			170.0,
			42.0
		)

		button.focus_mode = (
			Control.FOCUS_NONE
		)

		button.mouse_default_cursor_shape = (
			Control.CURSOR_POINTING_HAND
		)

		button.add_theme_font_override(
			"font",
			HAND_FONT
		)

		button.add_theme_font_size_override(
			"font_size",
			17
		)

		button.add_theme_color_override(
			"font_color",
			Color(
				0.95,
				0.90,
				0.84
			)
		)

		button.add_theme_color_override(
			"font_hover_color",
			Color.WHITE
		)

		button.add_theme_stylebox_override(
			"normal",
			_make_button_style(
				Color(
					0.13,
					0.08,
					0.11,
					0.92
				),
				Color(
					0.50,
					0.40,
					0.44,
					0.75
				)
			)
		)

		button.add_theme_stylebox_override(
			"hover",
			_make_button_style(
				Color(
					0.21,
					0.12,
					0.16,
					0.96
				),
				Color(
					0.84,
					0.69,
					0.66,
					0.96
				)
			)
		)

		button.add_theme_stylebox_override(
			"pressed",
			_make_button_style(
				Color(
					0.28,
					0.16,
					0.19,
					1.0
				),
				Color(
					0.92,
					0.77,
					0.70,
					1.0
				)
			)
		)

		button.pressed.connect(
			_on_address_button_pressed.bind(
				button
			)
		)

		add_child(
			button
		)

		address_buttons.append(
			button
		)


func _make_button_style(
	background_color: Color,
	border_color: Color
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()

	style.bg_color = background_color
	style.border_color = border_color

	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1

	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3

	return style


func _show_current_telegram() -> void:
	if (
		current_question_index
		>= question_order.size()
	):
		return


	var telegram: Dictionary = (
		_get_current_telegram()
	)


	var remaining: int = (
		question_order.size()
		- current_question_index
	)


	remaining_label.text = (
		str(remaining)
		+ " MAIL ITEMS REMAIN"
	)


	telegram_source.text = (
		"FROM: "
		+ str(
			telegram["source"]
		)
	)


	telegram_body.text = str(
		telegram["body"]
	)


	_update_damaged_address(
		str(
			telegram["answer"]
		)
	)


	_build_current_candidates()


	_update_route_book()
	_update_address_buttons()


	status_label.text = ""


	_start_question_timer()


func _get_route_entries_for_answer(
	answer: String
) -> Array:
	if answer.begins_with(
		"07-"
	):
		return ROUTE_07

	return ROUTE_08


func _build_current_candidates() -> void:
	current_candidates.clear()


	var telegram: Dictionary = (
		_get_current_telegram()
	)


	var correct_address: String = str(
		telegram["answer"]
	)


	var route_entries: Array = (
		_get_route_entries_for_answer(
			correct_address
		)
	)


	var correct_entry: Dictionary = {}

	var wrong_entries: Array = []


	for entry in route_entries:
		var candidate_address: String = str(
			entry["address"]
		)


		if candidate_address == correct_address:
			correct_entry = entry

		else:
			wrong_entries.append(
				entry
			)


	wrong_entries.shuffle()


	current_candidates.append(
		correct_entry
	)


	for i in range(3):
		current_candidates.append(
			wrong_entries[i]
		)


	current_candidates.shuffle()


func _update_damaged_address(
	answer: String
) -> void:
	var prefix: String = (
		answer.substr(
			0,
			2
		)
	)


	house_number_label.text = (
		"HOUSE NO. "
		+ prefix
		+ "-"
	)


func _update_route_book() -> void:
	var telegram: Dictionary = (
		_get_current_telegram()
	)


	var answer: String = str(
		telegram["answer"]
	)


	var prefix: String = (
		answer.substr(
			0,
			2
		)
	)


	route_heading.text = (
		"ROUTE BOOK  HOUSES "
		+ prefix
	)


	var entries_for_book: Array = (
		current_candidates.duplicate()
	)


	entries_for_book.sort_custom(
		func(a, b):
			return str(
				a["address"]
			) < str(
				b["address"]
			)
	)


	var route_text: String = ""


	for entry in entries_for_book:
		route_text += (
			str(
				entry["address"]
			)
			+ "   "
			+ str(
				entry["name"]
			)
			+ "   "
			+ str(
				entry["place"]
			)
			+ "\n"
		)


	route_book.text = route_text


func _update_address_buttons() -> void:
	var button_choices: Array = (
		current_candidates.duplicate()
	)


	button_choices.shuffle()


	for i in range(
		address_buttons.size()
	):
		var button: Button = (
			address_buttons[i]
		)

		var entry: Dictionary = (
			button_choices[i]
		)

		var address: String = str(
			entry["address"]
		)


		button.text = address

		button.disabled = false

		button.set_meta(
			"address",
			address
		)

		button.show()


func _get_question_time_limit() -> float:
	var progress: float = 0.0


	if question_order.size() > 1:
		progress = (
			float(
				current_question_index
			)
			/ float(
				question_order.size() - 1
			)
		)


	progress = clampf(
		progress,
		0.0,
		1.0
	)


	return lerpf(
		first_question_time,
		final_question_time,
		progress
	)


func _start_question_timer() -> void:
	question_time_limit = (
		_get_question_time_limit()
	)

	question_time_remaining = (
		question_time_limit
	)

	timer_running = true

	_update_timer_ui()


func _update_timer_ui() -> void:
	if timer_label:
		timer_label.text = (
			"TIME  "
			+ String.num(
				question_time_remaining,
				1
			)
		)


	if timer_bar:
		var percentage: float = 0.0


		if question_time_limit > 0.0:
			percentage = (
				question_time_remaining
				/ question_time_limit
			) * 100.0


		timer_bar.value = clampf(
			percentage,
			0.0,
			100.0
		)


	if timer_label:
		var ratio: float = 1.0


		if question_time_limit > 0.0:
			ratio = (
				question_time_remaining
				/ question_time_limit
			)


		if ratio <= 0.25:
			timer_label.add_theme_color_override(
				"font_color",
				Color(
					1.0,
					0.48,
					0.42
				)
			)

		else:
			timer_label.add_theme_color_override(
				"font_color",
				Color(
					0.91,
					0.80,
					0.73
				)
			)


func _on_address_button_pressed(
	button: Button
) -> void:
	if not active:
		return


	var chosen_address: String = str(
		button.get_meta(
			"address",
			""
		)
	)


	var telegram: Dictionary = (
		_get_current_telegram()
	)


	var correct_address: String = str(
		telegram["answer"]
	)


	if chosen_address == correct_address:
		await _handle_correct(
			chosen_address
		)

	else:
		await _handle_wrong()


func _handle_correct(
	address: String
) -> void:
	if not active:
		return


	active = false
	timer_running = false


	_set_buttons_disabled(
		true
	)


	status_label.add_theme_color_override(
		"font_color",
		Color(
			0.72,
			0.88,
			0.70
		)
	)


	status_label.text = (
		"CORRECT  "
		+ address
	)


	await get_tree().create_timer(
		correct_pause
	).timeout


	current_question_index += 1


	if (
		current_question_index
		>= question_order.size()
	):
		await _finish_game()
		return


	_show_current_telegram()

	active = true


func _handle_wrong() -> void:
	if not active:
		return


	active = false
	timer_running = false


	_set_buttons_disabled(
		true
	)


	Global.lives = maxi(
		Global.lives - 1,
		0
	)


	_update_hearts()


	status_label.add_theme_color_override(
		"font_color",
		Color(
			0.92,
			0.55,
			0.52
		)
	)


	status_label.text = (
		"WRONG ADDRESS"
	)


	await _play_failure_feedback()


	if Global.lives <= 0:
		await _game_over()
		return


	status_label.text = (
		"CHECK THE ROUTE BOOK"
	)


	_set_buttons_disabled(
		false
	)


	active = true

	_start_question_timer()


func _handle_timeout() -> void:
	if not active:
		return


	active = false
	timer_running = false


	_set_buttons_disabled(
		true
	)


	Global.lives = maxi(
		Global.lives - 1,
		0
	)


	_update_hearts()


	status_label.add_theme_color_override(
		"font_color",
		Color(
			0.92,
			0.55,
			0.52
		)
	)


	status_label.text = (
		"TOO SLOW"
	)


	await _play_failure_feedback()


	if Global.lives <= 0:
		await _game_over()
		return


	status_label.text = (
		"TRY AGAIN"
	)


	_set_buttons_disabled(
		false
	)


	active = true

	_start_question_timer()


func _set_buttons_disabled(
	disabled: bool
) -> void:
	for button in address_buttons:
		button.disabled = disabled


func _finish_game() -> void:
	active = false
	timer_running = false


	_set_buttons_disabled(
		true
	)


	for button in address_buttons:
		button.hide()


	route_panel.hide()
	route_heading.hide()
	route_book.hide()

	choice_panel.hide()
	choice_heading.hide()
	instruction_label.hide()
	status_label.hide()

	address_card.hide()
	address_caption.hide()
	address_to_label.hide()
	address_route_label.hide()
	house_number_label.hide()

	damage_mask.hide()
	damage_bar_1.hide()
	damage_bar_2.hide()
	damage_bar_3.hide()

	telegram_source.hide()

	timer_label.hide()
	timer_bar.hide()


	remaining_label.text = (
		"0 MAIL ITEMS REMAIN"
	)


	telegram_heading.text = (
		"ROUTE 6"
	)


	telegram_body.text = (
		"\n\nROUTE COMPLETE"
	)


	telegram_body.add_theme_font_size_override(
		"normal_font_size",
		30
	)


	telegram_body.add_theme_color_override(
		"default_color",
		Color(
			0.96,
			0.89,
			0.82
		)
	)


	Global.minigames_done = 4


	await get_tree().create_timer(
		route_complete_pause
	).timeout


	get_tree().change_scene_to_file(
		"res://Screen/uwintemp.tscn"
	)


func _game_over() -> void:
	active = false
	timer_running = false


	_set_buttons_disabled(
		true
	)


	status_label.text = (
		"ROUTE FAILED"
	)


	await get_tree().create_timer(
		0.65
	).timeout


	get_tree().change_scene_to_file(
		"res://Screen/game_over.tscn"
	)


func _update_hearts() -> void:
	if icon:
		icon.visible = (
			Global.lives >= 4
		)

	if icon_2:
		icon_2.visible = (
			Global.lives >= 3
		)

	if icon_3:
		icon_3.visible = (
			Global.lives >= 2
		)

	if icon_4:
		icon_4.visible = (
			Global.lives >= 1
		)

	if lives_container:
		lives_container.visible = (
			Global.lives > 0
		)


func _play_failure_feedback() -> void:
	_play_fail_sound()


	if cross_icon:
		cross_icon.show()


	await _shake_screen()


	await get_tree().create_timer(
		0.12
	).timeout


	if cross_icon:
		cross_icon.hide()


func _shake_screen() -> void:
	var original_position: Vector2 = (
		position
	)


	var tween: Tween = (
		create_tween()
	)


	for i in range(
		shake_steps
	):
		var progress: float = (
			float(i)
			/ float(shake_steps)
		)


		var strength: float = (
			shake_strength
			* (
				1.0
				- progress * 0.45
			)
		)


		var offset: Vector2 = Vector2(
			randf_range(
				-strength,
				strength
			),
			randf_range(
				-strength,
				strength
			)
		)


		tween.tween_property(
			self,
			"position",
			original_position + offset,
			0.025
		)


	tween.tween_property(
		self,
		"position",
		original_position,
		0.04
	)


	await tween.finished


func _setup_fail_sound() -> void:
	fail_sound_player = (
		AudioStreamPlayer.new()
	)


	fail_sound_player.stream = (
		_make_fail_sound()
	)


	fail_sound_player.volume_db = (
		fail_sound_volume_db
	)


	add_child(
		fail_sound_player
	)


func _make_fail_sound() -> AudioStreamWAV:
	var sample_rate: int = 44100
	var duration: float = 0.14


	var frame_count: int = int(
		float(sample_rate)
		* duration
	)


	var data := PackedByteArray()

	data.resize(
		frame_count * 2
	)


	for i in range(
		frame_count
	):
		var t: float = (
			float(i)
			/ float(sample_rate)
		)


		var progress: float = (
			t / duration
		)


		var envelope_value: float = pow(
			1.0 - progress,
			2.7
		)


		var low_hit: float = sin(
			TAU
			* 92.0
			* t
		)


		var broken_tone: float = (
			sin(
				TAU
				* 173.0
				* t
			)
			* 0.35
		)


		var rough_tone: float = (
			sin(
				TAU
				* 347.0
				* t
			)
			* 0.16
		)


		var static_noise: float = (
			randf_range(
				-1.0,
				1.0
			)
			* 0.55
		)


		var sample: float = (
			low_hit * 0.62
			+ broken_tone
			+ rough_tone
			+ static_noise
		)


		sample *= envelope_value
		sample *= 0.72


		sample = clampf(
			sample,
			-1.0,
			1.0
		)


		var pcm: int = int(
			sample * 32767.0
		)


		if pcm < 0:
			pcm += 65536


		data[i * 2] = (
			pcm & 0xFF
		)


		data[i * 2 + 1] = (
			(pcm >> 8)
			& 0xFF
		)


	var wav := AudioStreamWAV.new()

	wav.format = (
		AudioStreamWAV.FORMAT_16_BITS
	)

	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data

	return wav


func _play_fail_sound() -> void:
	if fail_sound_player == null:
		return


	fail_sound_player.pitch_scale = (
		randf_range(
			0.94,
			1.03
		)
	)


	fail_sound_player.stop()

	fail_sound_player.play()
