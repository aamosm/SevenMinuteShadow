extends Control
class_name GameOverBook


var died_in_level: String = "level_1"


var level_lore: Dictionary = {
	"level_1": "Kiyoshima was bombed on XX.XX.XXX.\nThe deliveries that weren't made are forever left so.",
	"level_2": "The library consumed your fading essence.\nTime is a luxury you no longer possess.",
	"level_3": "The grandfather clock strikes your final second.\nThe shadow reigns absolute.",
	"boss": "The master of shadows claimed your time.\nSeven minutes was not enough.",
	"default": "Your time has expired.\nThe shadow claims another wandering soul."
}


var hinge: Control
var flipping_page: Panel
var lore_label: Label
var click_to_turn: Label
var interaction_btn: Button
var is_flipping: bool = false

func _ready() -> void:

	self.set_anchors_preset(Control.PRESET_FULL_RECT)
	

	var bg = ColorRect.new()
	bg.color = Color("#050508") # Deep shadow black
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	

	var book_root = Control.new()
	book_root.custom_minimum_size = Vector2(800, 500)
	center.add_child(book_root)
	

	var left_page = Panel.new()
	left_page.add_theme_stylebox_override("panel", _create_page_style(true, Color("#151518")))
	left_page.position = Vector2(0, 0)
	left_page.size = Vector2(400, 500)
	book_root.add_child(left_page)
	

	var right_page = Panel.new()
	right_page.add_theme_stylebox_override("panel", _create_page_style(false, Color("#151518")))
	right_page.position = Vector2(400, 0)
	right_page.size = Vector2(400, 500)
	book_root.add_child(right_page)
	
	# Game Over Container
	var game_over_vbox = VBoxContainer.new()
	game_over_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	game_over_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	game_over_vbox.add_theme_constant_override("separation", 30)
	right_page.add_child(game_over_vbox)
	
	# Game Over Text
	var go_label = Label.new()
	go_label.text = "GAME OVER"
	go_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var go_settings = LabelSettings.new()
	go_settings.font_size = 48
	go_settings.font_color = Color("#8a1111") # Dried blood red
	go_settings.shadow_color = Color(0, 0, 0, 0.8)
	go_settings.shadow_size = 6
	go_label.label_settings = go_settings
	game_over_vbox.add_child(go_label)
	
	# Try Again Button
	var btn_try_again = _create_button("Try Again")
	btn_try_again.pressed.connect(_on_try_again_pressed)
	game_over_vbox.add_child(btn_try_again)
	
	# Leave Button
	var btn_leave = _create_button("Leave")
	btn_leave.pressed.connect(_on_leave_pressed)
	game_over_vbox.add_child(btn_leave)


	hinge = Control.new()
	hinge.position = Vector2(400, 0) # Center spine
	book_root.add_child(hinge)
	
	flipping_page = Panel.new()

	flipping_page.add_theme_stylebox_override("panel", _create_page_style(false, Color("#1c1c22")))
	flipping_page.position = Vector2(0, 0)
	flipping_page.size = Vector2(400, 500)
	hinge.add_child(flipping_page)
	

	var margin_cont = MarginContainer.new()
	margin_cont.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin_cont.add_theme_constant_override("margin_left", 40)
	margin_cont.add_theme_constant_override("margin_right", 40)
	flipping_page.add_child(margin_cont)
	

	lore_label = Label.new()
	if level_lore.has(died_in_level):
		lore_label.text = level_lore[died_in_level]
	else:
		lore_label.text = level_lore["default"]
		
	lore_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lore_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lore_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var lore_settings = LabelSettings.new()
	lore_settings.font_size = 22
	lore_settings.font_color = Color("#c7bba1") # Aged parchment bone
	lore_settings.line_spacing = 8
	lore_label.label_settings = lore_settings
	margin_cont.add_child(lore_label)
	
	# Click to turn hint
	click_to_turn = Label.new()
	click_to_turn.text = "Click to open >"
	click_to_turn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	click_to_turn.position = Vector2(-30, -40)
	click_to_turn.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	click_to_turn.grow_vertical = Control.GROW_DIRECTION_BEGIN
	
	var hint_settings = LabelSettings.new()
	hint_settings.font_size = 16
	hint_settings.font_color = Color("#888888")
	click_to_turn.label_settings = hint_settings
	flipping_page.add_child(click_to_turn)
	
	# Pulsing animation for the hint
	var alpha_tween = create_tween().set_loops()
	alpha_tween.tween_property(click_to_turn, "modulate:a", 0.3, 1.2).set_trans(Tween.TRANS_SINE)
	alpha_tween.tween_property(click_to_turn, "modulate:a", 1.0, 1.2).set_trans(Tween.TRANS_SINE)

	# Interaction Button (Invisible button covering screen to trigger flip)
	interaction_btn = Button.new()
	interaction_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	interaction_btn.modulate = Color.TRANSPARENT # Fully invisible
	interaction_btn.pressed.connect(_on_interaction_pressed)
	add_child(interaction_btn)


func _on_interaction_pressed() -> void:
	if is_flipping: return
	is_flipping = true
	interaction_btn.hide() # Disable so we can click the buttons underneath
	
	# 3D Page flip effect using 2D scale on the X axis
	var tween = create_tween()
	# Page stands up (Scale X to 0)
	tween.tween_property(hinge, "scale:x", 0.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(self._on_half_flip)
	# Page falls to the left (Scale X to -1)
	tween.tween_property(hinge, "scale:x", -1.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _on_half_flip() -> void:
	# Hide front text so it doesn't render backwards
	lore_label.hide()
	click_to_turn.hide()
	
	# Change page back color (darker, acting as the back of the page)
	# Because we scale to -1, the local Right Page layout visually perfectly mirrors to look like a Left Page!
	flipping_page.add_theme_stylebox_override("panel", _create_page_style(false, Color("#121215")))


func _on_try_again_pressed() -> void:
	get_tree().change_scene_to_file("res://Screen/title_scene.tscn")

func _on_leave_pressed() -> void:
	get_tree().quit()


func _create_page_style(is_left: bool, bg_col: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = bg_col
	
	# Shadow and Spine setup
	if is_left:
		style.corner_radius_top_left = 16
		style.corner_radius_bottom_left = 16
		style.border_width_right = 6 # Spine
		style.border_color = Color("#08080a")
	else:
		style.corner_radius_top_right = 16
		style.corner_radius_bottom_right = 16
		style.border_width_left = 6 # Spine
		style.border_color = Color("#08080a")
		
	style.shadow_color = Color(0, 0, 0, 0.7)
	style.shadow_size = 12
	return style

func _create_button(btn_text: String) -> Button:
	var btn = Button.new()
	btn.text = btn_text
	btn.custom_minimum_size = Vector2(220, 50)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	var normal_sb = StyleBoxFlat.new()
	normal_sb.bg_color = Color(0, 0, 0, 0.4)
	normal_sb.border_width_bottom = 2
	normal_sb.border_color = Color("#8a1111")
	normal_sb.corner_radius_top_left = 6
	normal_sb.corner_radius_top_right = 6
	normal_sb.corner_radius_bottom_left = 6
	normal_sb.corner_radius_bottom_right = 6
	
	var hover_sb = normal_sb.duplicate()
	hover_sb.bg_color = Color("#330a0a") # Blood tint on hover
	
	btn.add_theme_stylebox_override("normal", normal_sb)
	btn.add_theme_stylebox_override("hover", hover_sb)
	btn.add_theme_stylebox_override("pressed", normal_sb)
	btn.add_theme_font_size_override("font_size", 24)
	btn.add_theme_color_override("font_color", Color("#c7bba1"))
	btn.add_theme_color_override("font_hover_color", Color("#ffffff"))
	
	return btn
