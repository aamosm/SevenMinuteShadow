extends Control
class_name WinScreenDemo

var bg_rect: ColorRect
var particle_system: CPUParticles2D
var title_label: Label
var stats_label: Label
var lore_label: Label
var button_container: HBoxContainer

func _ready() -> void:
	self.set_anchors_preset(Control.PRESET_FULL_RECT)

	bg_rect = ColorRect.new()
	bg_rect.color = Color("#000000")
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg_rect)

	particle_system = CPUParticles2D.new()
	var vp_size = get_viewport_rect().size
	particle_system.position = Vector2(vp_size.x / 2, vp_size.y)
	particle_system.amount = 80
	particle_system.lifetime = 8.0
	particle_system.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particle_system.emission_rect_extents = Vector2(2000, 500)
	particle_system.direction = Vector2(1, -1)
	particle_system.spread = 20.0
	particle_system.gravity = Vector2(0, -5)
	particle_system.initial_velocity_min = 10.0
	particle_system.initial_velocity_max = 25.0
	particle_system.scale_amount_min = 2.0
	particle_system.scale_amount_max = 4.0

	var breeze_grad = Gradient.new()
	breeze_grad.offsets = [0.0, 0.2, 0.8, 1.0]
	breeze_grad.colors = [
		Color(1.0, 1.0, 1.0, 0.0),
		Color(0.8, 0.9, 1.0, 0.5),
		Color(0.6, 0.8, 1.0, 0.3),
		Color(1.0, 1.0, 1.0, 0.0)
	]
	particle_system.color_ramp = breeze_grad
	particle_system.emitting = false

	var particle_anchor = Control.new()
	particle_anchor.set_anchors_preset(Control.PRESET_CENTER)
	add_child(particle_anchor)
	particle_anchor.add_child(particle_system)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var main_vbox = VBoxContainer.new()
	main_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_theme_constant_override("separation", 25)
	center.add_child(main_vbox)

	title_label = Label.new()
	title_label.text = "ENDING 0/3\nTHE DEMO"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.modulate = Color.TRANSPARENT
	var title_settings = LabelSettings.new()
	title_settings.font_size = 56
	title_settings.font_color = Color("#f4d03f")
	title_settings.shadow_color = Color(0, 0, 0, 0.6)
	title_settings.shadow_size = 8
	title_label.label_settings = title_settings
	main_vbox.add_child(title_label)

	var global_node = get_node_or_null("/root/Global")
	var current_lives = 4
	if global_node and "lives" in global_node:
		current_lives = global_node.lives

	var max_lives = 4
	var hearts_text = ""
	for i in range(max_lives):
		if i < current_lives:
			hearts_text += "♥ "
		else:
			hearts_text += "♡ "

	stats_label = Label.new()
	stats_label.text = "Hearts Remaining: " + hearts_text.strip_edges()
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_label.modulate = Color.TRANSPARENT
	var stats_settings = LabelSettings.new()
	stats_settings.font_size = 28
	stats_settings.font_color = Color("#ff6b81")
	stats_settings.shadow_color = Color(0, 0, 0, 0.5)
	stats_settings.shadow_size = 4
	stats_label.label_settings = stats_settings
	main_vbox.add_child(stats_label)

	lore_label = Label.new()
	lore_label.text = "The plane still flies, and you will still be scortched.\nAt least the day went well...\n\nThank you for playing."
	lore_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lore_label.modulate = Color.TRANSPARENT
	var lore_settings = LabelSettings.new()
	lore_settings.font_size = 22
	lore_settings.font_color = Color("#dcdde1")
	lore_settings.line_spacing = 10
	lore_label.label_settings = lore_settings
	main_vbox.add_child(lore_label)

	button_container = HBoxContainer.new()
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	button_container.add_theme_constant_override("separation", 40)
	button_container.modulate = Color.TRANSPARENT
	main_vbox.add_child(button_container)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 40)
	main_vbox.add_child(spacer)
	main_vbox.move_child(spacer, 3)

	var btn_menu = _create_soft_button("Main Menu")
	btn_menu.pressed.connect(_on_menu_pressed)
	button_container.add_child(btn_menu)

	var btn_leave = _create_soft_button("Quit")
	btn_leave.pressed.connect(_on_leave_pressed)
	button_container.add_child(btn_leave)

	_play_cinematic_reveal()

func _play_cinematic_reveal() -> void:
	var timeline = create_tween()

	timeline.tween_callback(self._start_breeze)
	timeline.tween_property(bg_rect, "color", Color("#141f36"), 3.0)

	timeline.tween_property(title_label, "modulate:a", 1.0, 2.0).set_trans(Tween.TRANS_SINE)
	timeline.tween_interval(1.0)
	
	timeline.tween_property(stats_label, "modulate:a", 1.0, 1.5).set_trans(Tween.TRANS_SINE)
	timeline.tween_interval(1.0)
	
	timeline.tween_property(lore_label, "modulate:a", 1.0, 2.5).set_trans(Tween.TRANS_SINE)
	timeline.tween_interval(0.5)

	timeline.tween_property(button_container, "modulate:a", 1.0, 2.0).set_trans(Tween.TRANS_SINE)

func _start_breeze() -> void:
	particle_system.emitting = true

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://Screen/title_scene.tscn")

func _on_leave_pressed() -> void:
	get_tree().quit()

func _create_soft_button(btn_text: String) -> Button:
	var btn = Button.new()
	btn.text = btn_text
	btn.custom_minimum_size = Vector2(250, 50)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var normal_sb = StyleBoxFlat.new()
	normal_sb.bg_color = Color(0, 0, 0, 0.2)
	normal_sb.border_width_bottom = 1
	normal_sb.border_width_top = 1
	normal_sb.border_width_left = 1
	normal_sb.border_width_right = 1
	normal_sb.border_color = Color(0.6, 0.7, 0.9, 0.3)
	normal_sb.corner_radius_top_left = 6
	normal_sb.corner_radius_top_right = 6
	normal_sb.corner_radius_bottom_left = 6
	normal_sb.corner_radius_bottom_right = 6

	var hover_sb = normal_sb.duplicate()
	hover_sb.bg_color = Color(0.2, 0.3, 0.5, 0.6)
	hover_sb.border_color = Color("#f4d03f")
	hover_sb.shadow_color = Color(0.9, 0.8, 0.2, 0.2)
	hover_sb.shadow_size = 10

	btn.add_theme_stylebox_override("normal", normal_sb)
	btn.add_theme_stylebox_override("hover", hover_sb)
	btn.add_theme_stylebox_override("pressed", normal_sb)

	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", Color("#dcdde1"))
	btn.add_theme_color_override("font_hover_color", Color("#ffffff"))

	return btn
