extends Control


const END_SCENE_PATH: String = "res://Screen/end_scene.tscn"


var recovered_letters: int = 0
var transitioning: bool = false

var serif_font: SystemFont

var newspaper: Panel
var continue_label: Label
var fade_overlay: ColorRect


func _ready() -> void:
	recovered_letters = clampi(
		Global.minigames_done,
		0,
		4
	)

	set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	_create_font()
	_enter_death_music()
	_build_scene()

	modulate.a = 0.0

	var intro_tween: Tween = create_tween()

	intro_tween.set_trans(
		Tween.TRANS_SINE
	)

	intro_tween.set_ease(
		Tween.EASE_OUT
	)

	intro_tween.tween_property(
		self,
		"modulate:a",
		1.0,
		0.55
	)


func _create_font() -> void:
	serif_font = SystemFont.new()

	serif_font.font_names = PackedStringArray([
		"Georgia",
		"Times New Roman",
		"Noto Serif",
		"serif"
	])


func _enter_death_music() -> void:
	MusicManager.start_gameplay(4)
	MusicManager.enter_minigame()


	if MusicManager.distortion != null:
		MusicManager.distortion.drive = 0.90
		MusicManager.distortion.pre_gain = 11.0
		MusicManager.distortion.post_gain = -9.0

		MusicManager.distortion.keep_hf_hz = 2300.0


	if MusicManager.low_pass != null:
		MusicManager.low_pass.cutoff_hz = 3300.0


	MusicManager.base_pitch = 0.92

	MusicManager.wobble_amount = 0.020

	MusicManager.wobble_speed = 2.65


	if MusicManager.music_player != null:
		MusicManager.music_player.volume_db = -5.5


func _build_scene() -> void:
	var background := ColorRect.new()

	background.color = Color(
		0.025,
		0.022,
		0.020,
		1.0
	)

	background.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	background.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	add_child(
		background
	)


	var viewport_size: Vector2 = (
		get_viewport().get_visible_rect().size
	)


	var paper_size := Vector2(
		minf(
			1040.0,
			viewport_size.x - 90.0
		),
		minf(
			580.0,
			viewport_size.y - 55.0
		)
	)


	newspaper = Panel.new()

	newspaper.size = paper_size

	newspaper.position = (
		viewport_size / 2.0
		- paper_size / 2.0
	)

	newspaper.add_theme_stylebox_override(
		"panel",
		_create_newspaper_style()
	)

	add_child(
		newspaper
	)


	_create_masthead()
	_create_headline()
	_create_columns()
	_create_footer()


	fade_overlay = ColorRect.new()

	fade_overlay.color = Color(
		0.0,
		0.0,
		0.0,
		0.0
	)

	fade_overlay.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	fade_overlay.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	add_child(
		fade_overlay
	)


func _create_masthead() -> void:
	var masthead := Label.new()

	masthead.text = (
		"THE NATIONAL RECORD"
	)

	masthead.position = Vector2(
		35.0,
		13.0
	)

	masthead.size = Vector2(
		newspaper.size.x - 70.0,
		52.0
	)

	masthead.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	masthead.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	masthead.add_theme_font_override(
		"font",
		serif_font
	)

	masthead.add_theme_font_size_override(
		"font_size",
		34
	)

	masthead.add_theme_color_override(
		"font_color",
		Color(
			0.105,
			0.095,
			0.075,
			1.0
		)
	)

	newspaper.add_child(
		masthead
	)


	var top_rule := ColorRect.new()

	top_rule.position = Vector2(
		35.0,
		68.0
	)

	top_rule.size = Vector2(
		newspaper.size.x - 70.0,
		2.0
	)

	top_rule.color = Color(
		0.12,
		0.105,
		0.08,
		0.92
	)

	top_rule.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	newspaper.add_child(
		top_rule
	)


	var edition := Label.new()

	edition.text = (
		"ARCHIVE EDITION     •     SPECIAL REPORT"
	)

	edition.position = Vector2(
		35.0,
		72.0
	)

	edition.size = Vector2(
		newspaper.size.x - 70.0,
		25.0
	)

	edition.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	edition.add_theme_font_override(
		"font",
		serif_font
	)

	edition.add_theme_font_size_override(
		"font_size",
		12
	)

	edition.add_theme_color_override(
		"font_color",
		Color(
			0.27,
			0.245,
			0.20,
			1.0
		)
	)

	newspaper.add_child(
		edition
	)


func _create_headline() -> void:
	var headline := Label.new()

	headline.text = (
		"WHAT REMAINED OF KIYOSHIMA"
	)

	headline.position = Vector2(
		43.0,
		99.0
	)

	headline.size = Vector2(
		newspaper.size.x - 86.0,
		55.0
	)

	headline.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	headline.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	headline.add_theme_font_override(
		"font",
		serif_font
	)

	headline.add_theme_font_size_override(
		"font_size",
		31
	)

	headline.add_theme_color_override(
		"font_color",
		Color(
			0.10,
			0.09,
			0.07,
			1.0
		)
	)

	newspaper.add_child(
		headline
	)


	var deck := Label.new()

	deck.text = (
		"Long after the bombing, fragments of ordinary mail "
		+ "became part of the surviving record of the island's final evening."
	)

	deck.position = Vector2(
		120.0,
		153.0
	)

	deck.size = Vector2(
		newspaper.size.x - 240.0,
		48.0
	)

	deck.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	deck.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	deck.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)

	deck.add_theme_font_override(
		"font",
		serif_font
	)

	deck.add_theme_font_size_override(
		"font_size",
		16
	)

	deck.add_theme_color_override(
		"font_color",
		Color(
			0.25,
			0.225,
			0.18,
			1.0
		)
	)

	newspaper.add_child(
		deck
	)


	var headline_rule := ColorRect.new()

	headline_rule.position = Vector2(
		43.0,
		207.0
	)

	headline_rule.size = Vector2(
		newspaper.size.x - 86.0,
		1.0
	)

	headline_rule.color = Color(
		0.20,
		0.18,
		0.14,
		0.75
	)

	headline_rule.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	newspaper.add_child(
		headline_rule
	)


func _create_columns() -> void:
	var column_gap: float = 50.0

	var column_width: float = (
		(
			newspaper.size.x
			- 86.0
			- column_gap
		)
		/ 2.0
	)


	var left_x: float = 43.0

	var right_x: float = (
		left_x
		+ column_width
		+ column_gap
	)


	var left_heading := Label.new()

	left_heading.text = (
		"A CITY STILL IN MOTION"
	)

	left_heading.position = Vector2(
		left_x,
		224.0
	)

	left_heading.size = Vector2(
		column_width,
		27.0
	)

	left_heading.add_theme_font_override(
		"font",
		serif_font
	)

	left_heading.add_theme_font_size_override(
		"font_size",
		15
	)

	left_heading.add_theme_color_override(
		"font_color",
		Color(
			0.13,
			0.115,
			0.09,
			1.0
		)
	)

	newspaper.add_child(
		left_heading
	)


	var left_body := RichTextLabel.new()

	left_body.text = (
		"Nothing in the surviving records suggests Kiyoshima "
		+ "understood how little time remained. Shops were closing, "
		+ "ferries were running, and postal routes were still being "
		+ "completed when the bombing began.\n\n"
		+ "Much of the island's paper record disappeared in the destruction. "
		+ "Names survived without homes, addresses without streets, "
		+ "and messages without recipients.\n\n"
		+ "What remained was scattered, incomplete, and often found years later."
	)

	left_body.position = Vector2(
		left_x,
		257.0
	)

	left_body.size = Vector2(
		column_width,
		248.0
	)

	left_body.bbcode_enabled = false
	left_body.scroll_active = false

	left_body.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	left_body.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)

	left_body.add_theme_font_override(
		"normal_font",
		serif_font
	)

	left_body.add_theme_font_size_override(
		"normal_font_size",
		16
	)

	left_body.add_theme_color_override(
		"default_color",
		Color(
			0.17,
			0.15,
			0.115,
			1.0
		)
	)

	left_body.add_theme_constant_override(
		"line_separation",
		4
	)

	newspaper.add_child(
		left_body
	)


	var column_rule := ColorRect.new()

	column_rule.position = Vector2(
		newspaper.size.x / 2.0,
		224.0
	)

	column_rule.size = Vector2(
		1.0,
		283.0
	)

	column_rule.color = Color(
		0.25,
		0.22,
		0.17,
		0.42
	)

	column_rule.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	newspaper.add_child(
		column_rule
	)


	var right_heading := Label.new()

	right_heading.text = (
		"RECOVERED FROM THE RUINS"
	)

	right_heading.position = Vector2(
		right_x,
		224.0
	)

	right_heading.size = Vector2(
		column_width,
		27.0
	)

	right_heading.add_theme_font_override(
		"font",
		serif_font
	)

	right_heading.add_theme_font_size_override(
		"font_size",
		15
	)

	right_heading.add_theme_color_override(
		"font_color",
		Color(
			0.13,
			0.115,
			0.09,
			1.0
		)
	)

	newspaper.add_child(
		right_heading
	)


	var recovered_big := Label.new()

	recovered_big.text = (
		_get_recovered_headline()
	)

	recovered_big.position = Vector2(
		right_x,
		257.0
	)

	recovered_big.size = Vector2(
		column_width,
		48.0
	)

	recovered_big.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	recovered_big.add_theme_font_override(
		"font",
		serif_font
	)

	recovered_big.add_theme_font_size_override(
		"font_size",
		25
	)

	recovered_big.add_theme_color_override(
		"font_color",
		Color(
			0.33,
			0.115,
			0.09,
			1.0
		)
	)

	newspaper.add_child(
		recovered_big
	)


	var right_body := RichTextLabel.new()

	right_body.text = (
		"Search teams and archivists later catalogued fragments "
		+ "from the ruins: receipts, photographs, notices, "
		+ "and pieces of undelivered mail.\n\n"
		+ "One postal route appeared repeatedly in surviving sorting records: Route 6.\n\n"
		+ _get_recovery_sentence()
		+ "\n\n"
		+ "The recovered letters were preserved with the rest "
		+ "of the Kiyoshima collection."
	)

	right_body.position = Vector2(
		right_x,
		311.0
	)

	right_body.size = Vector2(
		column_width,
		194.0
	)

	right_body.bbcode_enabled = false
	right_body.scroll_active = false

	right_body.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	right_body.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)

	right_body.add_theme_font_override(
		"normal_font",
		serif_font
	)

	right_body.add_theme_font_size_override(
		"normal_font_size",
		15
	)

	right_body.add_theme_color_override(
		"default_color",
		Color(
			0.17,
			0.15,
			0.115,
			1.0
		)
	)

	right_body.add_theme_constant_override(
		"line_separation",
		4
	)

	newspaper.add_child(
		right_body
	)


func _create_footer() -> void:
	var footer_rule := ColorRect.new()

	footer_rule.position = Vector2(
		43.0,
		newspaper.size.y - 51.0
	)

	footer_rule.size = Vector2(
		newspaper.size.x - 86.0,
		1.0
	)

	footer_rule.color = Color(
		0.20,
		0.18,
		0.14,
		0.72
	)

	footer_rule.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	newspaper.add_child(
		footer_rule
	)


	var archive_note := Label.new()

	archive_note.text = (
		"KIYOSHIMA ARCHIVE COLLECTION"
	)

	archive_note.position = Vector2(
		43.0,
		newspaper.size.y - 41.0
	)

	archive_note.size = Vector2(
		350.0,
		25.0
	)

	archive_note.add_theme_font_override(
		"font",
		serif_font
	)

	archive_note.add_theme_font_size_override(
		"font_size",
		10
	)

	archive_note.add_theme_color_override(
		"font_color",
		Color(
			0.36,
			0.325,
			0.26,
			1.0
		)
	)

	newspaper.add_child(
		archive_note
	)


	continue_label = Label.new()

	continue_label.text = (
		"SPACE / ENTER / CLICK TO CONTINUE"
	)

	continue_label.position = Vector2(
		newspaper.size.x - 390.0,
		newspaper.size.y - 43.0
	)

	continue_label.size = Vector2(
		347.0,
		28.0
	)

	continue_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_RIGHT
	)

	continue_label.add_theme_font_override(
		"font",
		serif_font
	)

	continue_label.add_theme_font_size_override(
		"font_size",
		11
	)

	continue_label.add_theme_color_override(
		"font_color",
		Color(
			0.30,
			0.27,
			0.22,
			1.0
		)
	)

	newspaper.add_child(
		continue_label
	)


	var pulse := create_tween()

	pulse.set_loops()

	pulse.tween_property(
		continue_label,
		"modulate:a",
		0.42,
		1.0
	).set_trans(
		Tween.TRANS_SINE
	)

	pulse.tween_property(
		continue_label,
		"modulate:a",
		1.0,
		1.0
	).set_trans(
		Tween.TRANS_SINE
	)


func _get_recovered_headline() -> String:
	if recovered_letters == 1:
		return "1 LETTER RECOVERED"

	return (
		str(recovered_letters)
		+ " LETTERS RECOVERED"
	)


func _get_recovery_sentence() -> String:
	match recovered_letters:
		0:
			return (
				"No letters from its final bag "
				+ "have ever been recovered."
			)

		1:
			return (
				"One letter from its final bag "
				+ "was recovered."
			)

		2:
			return (
				"Two letters from its final bag "
				+ "were recovered."
			)

		3:
			return (
				"Three letters from its final bag "
				+ "were recovered."
			)

		4:
			return (
				"Four letters from its final bag "
				+ "were recovered."
			)

		_:
			return (
				str(recovered_letters)
				+ " letters from its final bag were recovered."
			)


func _input(
	event: InputEvent
) -> void:
	if transitioning:
		return


	var pressed: bool = false


	if (
		event is InputEventKey
		and event.pressed
		and not event.echo
	):
		if (
			event.keycode == KEY_SPACE
			or event.keycode == KEY_ENTER
			or event.keycode == KEY_KP_ENTER
		):
			pressed = true


	if (
		event is InputEventMouseButton
		and event.pressed
		and event.button_index == MOUSE_BUTTON_LEFT
	):
		pressed = true


	if not pressed:
		return


	get_viewport().set_input_as_handled()

	_go_to_end_scene()


func _go_to_end_scene() -> void:
	if transitioning:
		return


	transitioning = true

	continue_label.hide()


	var tween: Tween = create_tween()

	tween.set_trans(
		Tween.TRANS_SINE
	)

	tween.set_ease(
		Tween.EASE_IN_OUT
	)


	tween.tween_property(
		fade_overlay,
		"color:a",
		1.0,
		0.7
	)


	await tween.finished


	MusicManager.stop_gameplay()


	get_tree().change_scene_to_file(
		END_SCENE_PATH
	)


func _exit_tree() -> void:
	MusicManager.stop_gameplay()


func _create_newspaper_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()

	style.bg_color = Color(
		0.84,
		0.80,
		0.69,
		1.0
	)

	style.border_color = Color(
		0.30,
		0.27,
		0.21,
		0.80
	)

	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1

	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2

	style.shadow_color = Color(
		0.0,
		0.0,
		0.0,
		0.72
	)

	style.shadow_size = 18

	return style
