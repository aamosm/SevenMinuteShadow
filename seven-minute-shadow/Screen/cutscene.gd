extends Node

const INTRO_FONT = preload(
	"res://Fonts/Gloria_Hallelujah/GloriaHallelujah-Regular.ttf"
)


const INTRO_PAGES: Array[String] = [
	"""KIYOSHIMA — 17:53

Kiyoshima is still carrying on as if this were an ordinary evening. Shops are open. Postal routes are running. Most people have not been told to leave.

At 18:00, the island will be bombed.

The warning will come too late. The raid will not be called off. Nothing done in the next seven minutes can stop what is coming.""",

	"""ROUTE SIX

The postman on Route Six does not know this yet.

He has a ton of mail left in his bag, an evening round to finish, and a final collection scheduled for 18:00.

He can finish the deliveries.. He can fail halfway through... He can do his job perfectly..

whatever it may be.. Kiyoshima will still be bombed.
Nothing can be done in the next Seven Minutes. Let's hope the mails get delivered today, else they never will. ever."""
]

const ENTRY_REQUEST_META: StringName = (
	&"seven_minute_shadow_cutscene_entry"
)

const MAIL_CHECKPOINT_META: StringName = (
	&"seven_minute_shadow_mail_checkpoint"
)

const ENTRY_MAIL_CHECKPOINT := "mail_checkpoint"

static func request_mail_checkpoint() -> void:
	Global.set_meta(
		ENTRY_REQUEST_META,
		ENTRY_MAIL_CHECKPOINT
	)


static func request_fresh_start() -> void:
	if Global.has_meta(
		ENTRY_REQUEST_META
	):
		Global.remove_meta(
			ENTRY_REQUEST_META
		)

	if Global.has_meta(
		MAIL_CHECKPOINT_META
	):
		Global.remove_meta(
			MAIL_CHECKPOINT_META
		)

const RADIO_DIALOGUE = preload(
	"res://dialogue/radio.dialogue"
)

const RADIO_RENDER_SCALE: float = 0.5
const RADIO_MAX_FPS: int = 30

@onready var node_2d: Node2D = $Node2D
@onready var node_3d: Node3D = $Node3D

@onready var anim_player: AnimationPlayer = (
	$AnimationPlayer
)

@onready var anim_player_2d: AnimationPlayer = (
	$AnimationPlayer2
)

@onready var camera: Camera3D = (
	$Node3D/Camera3D
)

@onready var camera_2d: Camera2D = (
	$Node2D/Mailman/Camera2D
)

@onready var mailman = (
	$Node2D/Mailman/Mailman
)

@onready var envelope: Sprite2D = (
	$Node2D/Mailman/EnvelopeSealed
)

@onready var postbox: Sprite2D = (
	$Node2D/Mailman/Postoffice
)

@onready var instruction_label: Label = (
	$Node2D/Mailman/InstructionLabel
)

var envelope_origin := Vector2.ZERO

var envelope_float: bool = false
var float_time: float = 0.0


var original_fov: float
var original_rotation: Vector3


var _original_3d_scale: float = 1.0

var _original_3d_mode: int = (
	Viewport.SCALING_3D_MODE_BILINEAR
)

var _original_msaa_3d: int = (
	Viewport.MSAA_DISABLED
)

var _original_screen_space_aa: int = (
	Viewport.SCREEN_SPACE_AA_DISABLED
)

var _original_use_taa: bool = false
var _original_max_fps: int = 0

var _radio_render_settings_applied: bool = false


var _intro_layer: CanvasLayer

var _intro_background: ColorRect
var _intro_text: RichTextLabel
var _intro_continue: Label

var _intro_sound_player: AudioStreamPlayer


var _intro_active: bool = false
var _intro_typing: bool = false
var _intro_dismissing: bool = false

var _intro_page_index: int = 0
var _intro_type_token: int = 0


var _transition_layer: CanvasLayer
var _transition_cover: ColorRect

var _startup_layer: CanvasLayer
var _startup_cover: ColorRect

func _init() -> void:
	_startup_layer = CanvasLayer.new()
	_startup_layer.layer = 10000
	add_child(_startup_layer)

	_startup_cover = ColorRect.new()
	_startup_cover.position = Vector2(-4096.0, -4096.0)
	_startup_cover.size = Vector2(8192.0, 8192.0)
	_startup_cover.color = Color.BLACK
	_startup_cover.mouse_filter = Control.MOUSE_FILTER_STOP
	_startup_layer.add_child(_startup_cover)


func _enter_tree() -> void:
	var early_2d := get_node_or_null("Node2D")
	var early_3d := get_node_or_null("Node3D")

	if early_2d:
		early_2d.visible = false
		early_2d.process_mode = Node.PROCESS_MODE_DISABLED

	if early_3d:
		early_3d.visible = false
		early_3d.process_mode = Node.PROCESS_MODE_DISABLED


func _release_startup_cover() -> void:
	await RenderingServer.frame_post_draw

	if is_instance_valid(_startup_layer):
		_startup_layer.queue_free()

	_startup_layer = null
	_startup_cover = null


func _ready() -> void:
	Global.minigames_done = 0
	Global.lives = 4

	original_fov = camera.fov
	original_rotation = (
		camera.rotation_degrees
	)

	envelope_origin = envelope.position

	_reset_local_scene_state()

	var entry_request := (
		_consume_entry_request()
	)

	if (
		entry_request
		== ENTRY_MAIL_CHECKPOINT
		and _has_mail_checkpoint()
	):
		_create_transition_cover()
		_release_startup_cover()
		_enter_mail_checkpoint()
		return

	_clear_mail_checkpoint()
	_create_intro()

	await _prewarm_radio_scene()

	_play_intro()
	_release_startup_cover()

func _process(
	delta: float
) -> void:
	if not envelope_float:
		return


	float_time += delta


	envelope.position.y = (
		envelope_origin.y
		+ sin(
			float_time * 4.5
		) * 6.0
	)


func _reset_local_scene_state() -> void:
	_intro_active = false
	_intro_typing = false
	_intro_dismissing = false

	_intro_page_index = 0
	_intro_type_token = 0


	envelope_float = false
	float_time = 0.0


	instruction_label.visible = false


	envelope.visible = false
	envelope.modulate = Color.WHITE

	envelope.modulate.a = 0.0

	envelope.scale = Vector2.ONE


	anim_player.stop()

	anim_player_2d.stop()


	node_2d.visible = false

	node_2d.process_mode = (
		Node.PROCESS_MODE_DISABLED
	)


	node_3d.visible = false

	node_3d.process_mode = (
		Node.PROCESS_MODE_DISABLED
	)


	_restore_radio_render_settings()


func _consume_entry_request() -> String:
	var request := ""


	if Global.has_meta(
		ENTRY_REQUEST_META
	):
		request = str(
			Global.get_meta(
				ENTRY_REQUEST_META
			)
		)

		Global.remove_meta(
			ENTRY_REQUEST_META
		)


	return request

func _has_mail_checkpoint() -> bool:
	return Global.has_meta(
		MAIL_CHECKPOINT_META
	)


func _clear_mail_checkpoint() -> void:
	if Global.has_meta(
		MAIL_CHECKPOINT_META
	):
		Global.remove_meta(
			MAIL_CHECKPOINT_META
		)


func _save_mail_checkpoint() -> void:
	var snapshot: Dictionary = {
		"mailman_transform":
			mailman.transform,

		"camera_transform":
			camera_2d.transform,

		"camera_zoom":
			camera_2d.zoom,

		"envelope_origin":
			envelope_origin,

		"envelope_rotation":
			envelope.rotation,

		"envelope_scale":
			Vector2.ONE
	}


	Global.set_meta(
		MAIL_CHECKPOINT_META,
		snapshot
	)

func _enter_mail_checkpoint() -> void:
	var snapshot: Dictionary = (
		Global.get_meta(
			MAIL_CHECKPOINT_META,
			{}
		)
	)


	if snapshot.is_empty():
		_clear_mail_checkpoint()

		if is_instance_valid(
			_transition_layer
		):
			_transition_layer.queue_free()

		_create_intro()
		_play_intro()

		return

	_restore_radio_render_settings()


	node_3d.visible = false

	node_3d.process_mode = (
		Node.PROCESS_MODE_DISABLED
	)


	node_2d.visible = true

	node_2d.process_mode = (
		Node.PROCESS_MODE_INHERIT
	)


	anim_player.stop()
	anim_player_2d.stop()

	if snapshot.has(
		"camera_transform"
	):
		camera_2d.transform = (
			snapshot["camera_transform"]
		)


	if snapshot.has(
		"camera_zoom"
	):
		camera_2d.zoom = (
			snapshot["camera_zoom"]
		)


	if mailman.has_method(
		"walk"
	):
		mailman.call(
			"walk",
			"up"
		)


	if mailman.has_method(
		"stop"
	):
		mailman.call(
			"stop"
		)


	if snapshot.has(
		"mailman_transform"
	):
		mailman.transform = (
			snapshot["mailman_transform"]
		)

	if snapshot.has(
		"envelope_origin"
	):
		envelope_origin = (
			snapshot["envelope_origin"]
		)


	envelope.position = envelope_origin


	if snapshot.has(
		"envelope_rotation"
	):
		envelope.rotation = (
			snapshot["envelope_rotation"]
		)


	envelope.scale = Vector2.ONE

	envelope.modulate = Color.WHITE

	envelope.visible = true


	float_time = 0.0

	envelope_float = true


	instruction_label.text = (
		"Press space to float mail into the postbox"
	)

	instruction_label.visible = true
	await get_tree().process_frame
	await get_tree().process_frame


	await _remove_transition_cover()


	await _wait_for_mail_space()


	instruction_label.visible = false

	envelope_float = false


	await send_envelope()


	_start_gameplay_audio()


	get_tree().change_scene_to_file(
		"res://Screen/level_scene.tscn"
	)



func _input(
	event: InputEvent
) -> void:
	if not _intro_active:
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
		and event.button_index
		== MOUSE_BUTTON_LEFT
	):
		pressed = true


	if not pressed:
		return


	get_viewport().set_input_as_handled()


	if _intro_typing:
		_finish_current_intro_page()
		return


	if (
		_intro_page_index
		< INTRO_PAGES.size() - 1
	):
		_intro_page_index += 1

		_show_intro_page()

		return


	if not _intro_dismissing:
		_dismiss_intro()


func _create_intro() -> void:
	var viewport_size: Vector2 = (
		get_viewport().get_visible_rect().size
	)


	var side_margin: float = (
		viewport_size.x * 0.105
	)


	var top_margin: float = (
		viewport_size.y * 0.085
	)


	var prompt_y: float = (
		viewport_size.y - 64.0
	)


	_intro_layer = CanvasLayer.new()

	_intro_layer.layer = 100

	add_child(
		_intro_layer
	)


	_intro_background = ColorRect.new()

	_intro_background.color = Color.BLACK

	_intro_background.position = Vector2.ZERO

	_intro_background.size = viewport_size

	_intro_background.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)


	_intro_layer.add_child(
		_intro_background
	)


	_intro_text = RichTextLabel.new()

	_intro_text.bbcode_enabled = false

	_intro_text.scroll_active = false

	_intro_text.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	_intro_text.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)


	_intro_text.position = Vector2(
		side_margin,
		top_margin
	)


	_intro_text.size = Vector2(
		viewport_size.x
		- side_margin * 2.0,

		prompt_y
		- top_margin
		- 28.0
	)


	_intro_text.add_theme_font_override(
		"normal_font",
		INTRO_FONT
	)


	_intro_text.add_theme_font_size_override(
		"normal_font_size",
		19
	)


	_intro_text.add_theme_color_override(
		"default_color",
		Color(
			0.91,
			0.90,
			0.86,
			1.0
		)
	)


	_intro_text.add_theme_constant_override(
		"line_separation",
		4
	)


	_intro_layer.add_child(
		_intro_text
	)



	_intro_continue = Label.new()


	_intro_continue.position = Vector2(
		side_margin,
		prompt_y
	)


	_intro_continue.size = Vector2(
		viewport_size.x
		- side_margin * 2.0,
		28.0
	)


	_intro_continue.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_RIGHT
	)


	_intro_continue.add_theme_font_override(
		"font",
		INTRO_FONT
	)


	_intro_continue.add_theme_font_size_override(
		"font_size",
		12
	)


	_intro_continue.add_theme_color_override(
		"font_color",
		Color(
			0.60,
			0.59,
			0.56,
			1.0
		)
	)


	_intro_continue.visible = false


	_intro_layer.add_child(
		_intro_continue
	)


	_intro_sound_player = (
		AudioStreamPlayer.new()
	)


	_intro_sound_player.stream = (
		_make_intro_paper_sound()
	)


	_intro_sound_player.volume_db = -9.0


	_intro_layer.add_child(
		_intro_sound_player
	)


func _play_intro() -> void:
	_intro_active = true

	_intro_typing = false

	_intro_dismissing = false

	_intro_page_index = 0

	_show_intro_page()


func _show_intro_page() -> void:
	_intro_type_token += 1


	var token: int = (
		_intro_type_token
	)


	_intro_typing = true

	_intro_continue.visible = false


	_intro_text.text = (
		INTRO_PAGES[
			_intro_page_index
		]
	)


	_intro_text.visible_characters = 0


	_type_intro_page(
		token
	)


func _type_intro_page(
	token: int
) -> void:
	var page_text: String = (
		INTRO_PAGES[
			_intro_page_index
		]
	)


	var total_characters: int = (
		page_text.length()
	)


	var character_index: int = 0


	while character_index < total_characters:
		if not _intro_active:
			return


		if token != _intro_type_token:
			return


		if not _intro_typing:
			return


		character_index += 1


		_intro_text.visible_characters = (
			character_index
		)


		var character: String = (
			page_text.substr(
				character_index - 1,
				1
			)
		)


		if (
			character.strip_edges() != ""
			and character_index % 5 == 0
		):
			_play_intro_paper_sound()


		var delay: float = 0.020


		if character == ".":
			delay = 0.095

		elif character == ",":
			delay = 0.050

		elif character == "\n":
			delay = 0.070


		await get_tree().create_timer(
			delay
		).timeout


	if token != _intro_type_token:
		return


	if not _intro_active:
		return


	_intro_typing = false

	_intro_text.visible_characters = -1

	_update_intro_continue_text()


func _finish_current_intro_page() -> void:
	_intro_type_token += 1

	_intro_typing = false

	_intro_text.visible_characters = -1


	if _intro_sound_player:
		_intro_sound_player.stop()


	_update_intro_continue_text()


func _update_intro_continue_text() -> void:
	if (
		_intro_page_index
		< INTRO_PAGES.size() - 1
	):
		_intro_continue.text = (
			"SPACE / ENTER / CLICK — NEXT"
		)

	else:
		_intro_continue.text = (
			"SPACE / ENTER / CLICK — CONTINUE"
		)


	_intro_continue.visible = true


func _dismiss_intro() -> void:
	if _intro_dismissing:
		return

	_intro_dismissing = true
	_intro_active = false
	_intro_typing = false
	_intro_type_token += 1

	if _intro_sound_player:
		_intro_sound_player.stop()

	_intro_continue.visible = false

	var text_tween: Tween = create_tween()

	text_tween.set_trans(
		Tween.TRANS_SINE
	)

	text_tween.set_ease(
		Tween.EASE_IN_OUT
	)

	text_tween.tween_property(
		_intro_text,
		"modulate:a",
		0.0,
		0.30
	)

	await text_tween.finished

	_start_radio_playback()

	await RenderingServer.frame_post_draw

	var reveal: Tween = create_tween()

	reveal.set_trans(
		Tween.TRANS_SINE
	)

	reveal.set_ease(
		Tween.EASE_IN_OUT
	)

	reveal.tween_property(
		_intro_background,
		"modulate:a",
		0.0,
		0.18
	)

	await reveal.finished

	if is_instance_valid(
		_intro_layer
	):
		_intro_layer.queue_free()

	_intro_layer = null
	_intro_background = null
	_intro_text = null
	_intro_continue = null
	_intro_sound_player = null

func _prewarm_radio_scene() -> void:
	_apply_radio_render_settings()

	node_2d.visible = false
	node_2d.process_mode = (
		Node.PROCESS_MODE_DISABLED
	)

	node_3d.visible = true
	node_3d.process_mode = (
		Node.PROCESS_MODE_INHERIT
	)

	if not anim_player.animation_finished.is_connected(
		_on_animation_finished
	):
		anim_player.animation_finished.connect(
			_on_animation_finished
		)

	anim_player.stop()

	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw

	node_3d.visible = false
	node_3d.process_mode = (
		Node.PROCESS_MODE_DISABLED
	)

func _start_radio_playback() -> void:
	node_2d.visible = false
	node_2d.process_mode = (
		Node.PROCESS_MODE_DISABLED
	)

	node_3d.visible = true
	node_3d.process_mode = (
		Node.PROCESS_MODE_INHERIT
	)

	if not OS.has_feature(
		"web"
	):
		if _original_max_fps == 0:
			Engine.max_fps = (
				RADIO_MAX_FPS
			)

		else:
			Engine.max_fps = mini(
				_original_max_fps,
				RADIO_MAX_FPS
			)

	DialogueManager.show_dialogue_balloon(
		RADIO_DIALOGUE,
		"start"
	)

	anim_player.speed_scale = 0.3

	anim_player.play(
		"Scene"
	)

func _play_intro_paper_sound() -> void:
	if _intro_sound_player == null:
		return


	_intro_sound_player.pitch_scale = (
		randf_range(
			0.90,
			1.08
		)
	)


	_intro_sound_player.volume_db = (
		randf_range(
			-11.0,
			-8.0
		)
	)


	_intro_sound_player.stop()

	_intro_sound_player.play()


func _make_intro_paper_sound() -> AudioStreamWAV:
	var sample_rate: int = 44100

	var duration: float = 0.055


	var frame_count: int = int(
		float(sample_rate)
		* duration
	)


	var data := PackedByteArray()


	data.resize(
		frame_count * 2
	)


	var previous_noise: float = 0.0


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


		var raw_noise: float = randf_range(
			-1.0,
			1.0
		)


		var scratch_noise: float = (
			raw_noise
			- previous_noise * 0.55
		)


		previous_noise = raw_noise


		var initial_click_envelope: float = (
			exp(
				-t * 180.0
			)
		)


		var paper_envelope: float = (
			(
				1.0
				- exp(
					-t * 130.0
				)
			)
			* exp(
				-t * 48.0
			)
		)


		var low_mechanical_tap: float = (
			sin(
				TAU
				* 105.0
				* t
			)
			* initial_click_envelope
			* 0.30
		)


		var dry_click: float = (
			scratch_noise
			* initial_click_envelope
			* 0.38
		)


		var paper_scrape: float = (
			raw_noise
			* paper_envelope
			* 0.34
		)


		var sample: float = (
			low_mechanical_tap
			+ dry_click
			+ paper_scrape
		)


		var final_fade: float = (
			pow(
				1.0 - progress,
				1.8
			)
		)


		sample *= final_fade

		sample *= 0.82


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


		data[
			i * 2 + 1
		] = (
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


func _apply_radio_render_settings() -> void:
	if _radio_render_settings_applied:
		return


	var viewport: Viewport = (
		get_viewport()
	)


	_original_3d_scale = (
		viewport.scaling_3d_scale
	)


	_original_3d_mode = (
		viewport.scaling_3d_mode
	)


	_original_msaa_3d = (
		viewport.msaa_3d
	)


	_original_screen_space_aa = (
		viewport.screen_space_aa
	)


	_original_use_taa = (
		viewport.use_taa
	)


	_original_max_fps = (
		Engine.max_fps
	)


	viewport.scaling_3d_mode = (
		Viewport.SCALING_3D_MODE_NEAREST
	)


	viewport.scaling_3d_scale = (
		RADIO_RENDER_SCALE
	)


	viewport.msaa_3d = (
		Viewport.MSAA_DISABLED
	)


	viewport.screen_space_aa = (
		Viewport.SCREEN_SPACE_AA_DISABLED
	)


	viewport.use_taa = false


	_radio_render_settings_applied = true


func _restore_radio_render_settings() -> void:
	if not _radio_render_settings_applied:
		return


	var viewport: Viewport = (
		get_viewport()
	)


	viewport.scaling_3d_scale = (
		_original_3d_scale
	)


	viewport.scaling_3d_mode = (
		_original_3d_mode
	)


	viewport.msaa_3d = (
		_original_msaa_3d
	)


	viewport.screen_space_aa = (
		_original_screen_space_aa
	)


	viewport.use_taa = (
		_original_use_taa
	)


	Engine.max_fps = (
		_original_max_fps
	)


	_radio_render_settings_applied = false


func _exit_tree() -> void:
	_restore_radio_render_settings()

func _on_animation_finished(
	anim_name: StringName
) -> void:
	if anim_name != "Scene":
		return


	var tween: Tween = create_tween()


	tween.set_parallel(
		true
	)


	tween.set_trans(
		Tween.TRANS_CUBIC
	)


	tween.set_ease(
		Tween.EASE_OUT
	)


	var target_fov: float = maxf(
		original_fov - 18.0,
		1.0
	)


	tween.tween_property(
		camera,
		"fov",
		target_fov,
		0.18
	)


	tween.tween_property(
		camera,
		"rotation_degrees",
		Vector3(
			original_rotation.x,
			original_rotation.y,
			original_rotation.z + 2.5
		),
		0.18
	)


	await tween.finished


	node_3d.visible = false


	node_3d.process_mode = (
		Node.PROCESS_MODE_DISABLED
	)


	_restore_radio_render_settings()


	node_2d.visible = true


	node_2d.process_mode = (
		Node.PROCESS_MODE_INHERIT
	)


	camera.fov = original_fov


	camera.rotation_degrees = (
		original_rotation
	)


	if not anim_player_2d.animation_finished.is_connected(
		_on_2danimation_finished
	):
		anim_player_2d.animation_finished.connect(
			_on_2danimation_finished
		)


	anim_player_2d.play(
		"2danimation_mailman"
	)

func _on_2danimation_finished(
	anim_name: StringName
) -> void:
	if anim_name != "2danimation_mailman":
		return


	mailman.walk(
		"right"
	)


	await get_tree().create_timer(
		1.8
	).timeout


	mailman.walk(
		"down"
	)


	await get_tree().create_timer(
		0.65
	).timeout


	mailman.walk(
		"right"
	)


	await get_tree().create_timer(
		0.4
	).timeout


	mailman.walk(
		"down"
	)


	await get_tree().create_timer(
		0.45
	).timeout


	mailman.walk(
		"right"
	)


	await get_tree().create_timer(
		4.43
	).timeout


	mailman.walk(
		"up"
	)


	await get_tree().create_timer(
		0.2
	).timeout


	mailman.stop()



	await reveal_envelope()

	_save_mail_checkpoint()


	instruction_label.text = (
		"Press space to float mail into the postbox"
	)


	instruction_label.visible = true


	await _wait_for_mail_space()


	instruction_label.visible = false

	envelope_float = false


	await send_envelope()


	get_tree().change_scene_to_file(
		"res://Screen/level_scene.tscn"
	)

func reveal_envelope() -> void:
	envelope.visible = true


	envelope.scale = Vector2(
		0.2,
		0.2
	)


	envelope.modulate = Color.WHITE

	envelope.modulate.a = 0.0


	var tween: Tween = create_tween()


	tween.set_parallel(
		true
	)


	tween.tween_property(
		envelope,
		"modulate:a",
		1.0,
		0.4
	)


	tween.tween_property(
		envelope,
		"scale",
		Vector2.ONE,
		0.4
	)


	await tween.finished


	envelope_origin = envelope.position

	float_time = 0.0

	envelope_float = true


func send_envelope() -> void:
	envelope.visible = true


	var tween: Tween = create_tween()


	tween.set_trans(
		Tween.TRANS_SINE
	)


	tween.set_ease(
		Tween.EASE_IN_OUT
	)


	tween.tween_property(
		envelope,
		"global_position",
		postbox.global_position,
		0.8
	)


	await tween.finished


	envelope.visible = false

func _wait_for_mail_space() -> void:

	await get_tree().process_frame


	while not Input.is_action_just_pressed(
		"ui_accept"
	):
		await get_tree().process_frame


func _start_gameplay_audio() -> void:
	var gameplay_bus := AudioServer.get_bus_index(
		"GameplayMusicFX"
	)

	if gameplay_bus >= 0:
		AudioServer.set_bus_mute(
			gameplay_bus,
			false
		)

	if MusicManager.has_method(
		"start_gameplay"
	):
		MusicManager.call(
			"start_gameplay",
			0
		)

	if MusicManager.has_method(
		"enter_interstitial"
	):
		MusicManager.call(
			"enter_interstitial"
		)


func _create_transition_cover() -> void:
	var viewport_size := (
		get_viewport().get_visible_rect().size
	)


	_transition_layer = CanvasLayer.new()

	_transition_layer.layer = 1000


	add_child(
		_transition_layer
	)


	_transition_cover = ColorRect.new()

	_transition_cover.position = Vector2.ZERO

	_transition_cover.size = viewport_size

	_transition_cover.color = Color.BLACK

	_transition_cover.mouse_filter = (
		Control.MOUSE_FILTER_STOP
	)


	_transition_layer.add_child(
		_transition_cover
	)


func _remove_transition_cover() -> void:
	if not is_instance_valid(
		_transition_cover
	):
		return


	var tween: Tween = create_tween()


	tween.set_trans(
		Tween.TRANS_SINE
	)


	tween.set_ease(
		Tween.EASE_IN_OUT
	)


	tween.tween_property(
		_transition_cover,
		"color:a",
		0.0,
		0.16
	)


	await tween.finished


	if is_instance_valid(
		_transition_layer
	):
		_transition_layer.queue_free()


	_transition_layer = null
	_transition_cover = null
