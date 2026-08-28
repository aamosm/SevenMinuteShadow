extends Control


const END_SCENE_PATH: String = "res://Screen/end_scene.tscn"

const GAMEPLAY_BUS: String = "GameplayMusicFX"

const GAMEPLAY_TRACK_NAME: String = (
	"hexxel-chill-hive-533766"
)

const HAND_FONT: FontFile = preload(
	"res://Fonts/Gloria_Hallelujah/GloriaHallelujah-Regular.ttf"
)


enum ScreenPhase {
	RECAP,
	NEWSPAPER_ONE,
	NEWSPAPER_TWO,
	LEAVING
}


var phase: ScreenPhase = ScreenPhase.RECAP

var recovered_letters: int = 0
var transitioning: bool = false


var serif_font: SystemFont


var recap_layer: Control
var recap_continue: Label


var newspaper: Panel

var page_one: Control
var page_two: Control

var page_one_hint: Label
var page_two_hint: Label


var fade_overlay: ColorRect


var page_turn_player: AudioStreamPlayer


var original_bus_effect_count: int = -1
var death_effects_added: bool = false


var glitch_enabled: bool = false

var glitch_active: bool = false

var glitch_wait: float = 0.35
var glitch_hold: float = 0.0

var glitch_saved_volume_db: float = 0.0


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

	_setup_page_turn_sound()

	_start_death_music()

	_build_scene()


func _process(delta: float) -> void:
	_process_music_glitch(
		delta
	)


func _create_font() -> void:
	serif_font = SystemFont.new()

	serif_font.font_names = PackedStringArray([
		"Georgia",
		"Times New Roman",
		"Noto Serif",
		"serif"
	])


# =========================================================
# MUSIC
# =========================================================

func _start_death_music() -> void:
	var bus_index: int = AudioServer.get_bus_index(
		GAMEPLAY_BUS
	)


	if bus_index >= 0:
		AudioServer.set_bus_mute(
			bus_index,
			false
		)


	if MusicManager.has_method(
		"start_gameplay"
	):
		MusicManager.call(
			"start_gameplay",
			4
		)


	if MusicManager.has_method(
		"enter_minigame"
	):
		MusicManager.call(
			"enter_minigame"
		)


	_add_death_distortion()


	glitch_enabled = true

	glitch_wait = randf_range(
		0.18,
		0.65
	)


func _add_death_distortion() -> void:
	var bus_index: int = AudioServer.get_bus_index(
		GAMEPLAY_BUS
	)


	if bus_index < 0:
		return


	original_bus_effect_count = (
		AudioServer.get_bus_effect_count(
			bus_index
		)
	)


	var distortion := AudioEffectDistortion.new()

	distortion.mode = (
		AudioEffectDistortion.MODE_LOFI
	)

	distortion.drive = 0.94

	distortion.pre_gain = 11.0

	distortion.post_gain = -8.5

	distortion.keep_hf_hz = 1700.0


	AudioServer.add_bus_effect(
		bus_index,
		distortion
	)


	var low_pass := AudioEffectLowPassFilter.new()

	low_pass.cutoff_hz = 2750.0


	AudioServer.add_bus_effect(
		bus_index,
		low_pass
	)


	death_effects_added = true


func _process_music_glitch(
	delta: float
) -> void:
	if not glitch_enabled:
		return


	var bus_index: int = AudioServer.get_bus_index(
		GAMEPLAY_BUS
	)


	if bus_index < 0:
		return


	if glitch_active:
		glitch_hold -= delta


		if glitch_hold <= 0.0:
			AudioServer.set_bus_volume_db(
				bus_index,
				glitch_saved_volume_db
			)

			glitch_active = false

			glitch_wait = randf_range(
				0.28,
				1.05
			)


		return


	glitch_wait -= delta


	if glitch_wait > 0.0:
		return


	glitch_saved_volume_db = (
		AudioServer.get_bus_volume_db(
			bus_index
		)
	)


	var drop_amount: float = randf_range(
		15.0,
		35.0
	)


	AudioServer.set_bus_volume_db(
		bus_index,
		glitch_saved_volume_db
		- drop_amount
	)


	glitch_active = true


	glitch_hold = randf_range(
		0.025,
		0.095
	)


func _restore_glitch_volume() -> void:
	if not glitch_active:
		return


	var bus_index: int = AudioServer.get_bus_index(
		GAMEPLAY_BUS
	)


	if bus_index >= 0:
		AudioServer.set_bus_volume_db(
			bus_index,
			glitch_saved_volume_db
		)


	glitch_active = false


func _remove_death_distortion() -> void:
	if not death_effects_added:
		return


	var bus_index: int = AudioServer.get_bus_index(
		GAMEPLAY_BUS
	)


	if bus_index < 0:
		death_effects_added = false
		return


	if original_bus_effect_count < 0:
		death_effects_added = false
		return


	while (
		AudioServer.get_bus_effect_count(
			bus_index
		)
		> original_bus_effect_count
	):
		var effect_index: int = (
			AudioServer.get_bus_effect_count(
				bus_index
			)
			- 1
		)


		AudioServer.remove_bus_effect(
			bus_index,
			effect_index
		)


	death_effects_added = false


func _stop_audio_under(
	node: Node
) -> void:
	if node is AudioStreamPlayer:
		var player := (
			node as AudioStreamPlayer
		)

		player.stop()


	elif node is AudioStreamPlayer2D:
		var player_2d := (
			node as AudioStreamPlayer2D
		)

		player_2d.stop()


	elif node is AudioStreamPlayer3D:
		var player_3d := (
			node as AudioStreamPlayer3D
		)

		player_3d.stop()


	for child in node.get_children():
		_stop_audio_under(
			child
		)


func _stop_gameplay_players_recursive(
	node: Node
) -> void:
	if node is AudioStreamPlayer:
		var player := (
			node as AudioStreamPlayer
		)


		if _is_gameplay_audio(
			player.bus,
			player.stream
		):
			player.stop()


	elif node is AudioStreamPlayer2D:
		var player_2d := (
			node as AudioStreamPlayer2D
		)


		if _is_gameplay_audio(
			player_2d.bus,
			player_2d.stream
		):
			player_2d.stop()


	elif node is AudioStreamPlayer3D:
		var player_3d := (
			node as AudioStreamPlayer3D
		)


		if _is_gameplay_audio(
			player_3d.bus,
			player_3d.stream
		):
			player_3d.stop()


	for child in node.get_children():
		_stop_gameplay_players_recursive(
			child
		)


func _is_gameplay_audio(
	bus_name: String,
	stream: AudioStream
) -> bool:
	if bus_name == GAMEPLAY_BUS:
		return true


	if stream == null:
		return false


	var stream_path: String = (
		stream.resource_path.to_lower()
	)


	return stream_path.contains(
		GAMEPLAY_TRACK_NAME.to_lower()
	)


func _force_stop_gameplay() -> void:
	if MusicManager.has_method(
		"stop_gameplay"
	):
		MusicManager.call(
			"stop_gameplay"
		)


	# MusicManager is an autoload, so stop every player
	# it owns directly as well.
	_stop_audio_under(
		MusicManager
	)


	# Catch any gameplay player that is not owned by
	# MusicManager for whatever reason.
	_stop_gameplay_players_recursive(
		get_tree().root
	)


func _hard_stop_gameplay_before_exit() -> void:
	glitch_enabled = false

	_restore_glitch_volume()

	_remove_death_distortion()


	var bus_index: int = AudioServer.get_bus_index(
		GAMEPLAY_BUS
	)


	# Mute first. Even if some persistent player tries to
	# produce another frame of audio, nothing can escape.
	if bus_index >= 0:
		AudioServer.set_bus_mute(
			bus_index,
			true
		)


	_force_stop_gameplay()


	await get_tree().process_frame
	await get_tree().process_frame


	# Do it again after pending tweens/callbacks have had
	# a chance to run.
	_force_stop_gameplay()


# =========================================================
# PAPER TURN SOUND
# =========================================================

func _setup_page_turn_sound() -> void:
	page_turn_player = AudioStreamPlayer.new()

	page_turn_player.bus = "Master"

	page_turn_player.stream = (
		_make_page_turn_sound()
	)

	page_turn_player.volume_db = -3.0

	add_child(
		page_turn_player
	)


func _make_page_turn_sound() -> AudioStreamWAV:
	var sample_rate: int = 44100

	var duration: float = 0.58


	var frame_count: int = int(
		float(sample_rate)
		* duration
	)


	var data := PackedByteArray()

	data.resize(
		frame_count * 2
	)


	var smooth_noise: float = 0.0
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


		smooth_noise = lerpf(
			smooth_noise,
			raw_noise,
			0.14
		)


		var scratch: float = (
			raw_noise
			- previous_noise
		)


		previous_noise = raw_noise


		var lift: float = exp(
			-pow(
				(progress - 0.14) / 0.11,
				2.0
			)
		)


		var sweep: float = exp(
			-pow(
				(progress - 0.49) / 0.23,
				2.0
			)
		)


		var fall: float = exp(
			-pow(
				(progress - 0.82) / 0.09,
				2.0
			)
		)


		var paper_scratch: float = (
			scratch
			* lift
			* 0.17
		)


		paper_scratch += (
			raw_noise
			* sweep
			* 0.16
		)


		var paper_body: float = (
			smooth_noise
			* (
				lift
				+ sweep
			)
			* 0.23
		)


		var soft_flap: float = (
			sin(
				TAU
				* 68.0
				* t
			)
			* fall
			* 0.14
		)


		var sample: float = (
			paper_scratch
			+ paper_body
			+ soft_flap
		)


		var fade_in: float = clampf(
			progress / 0.025,
			0.0,
			1.0
		)


		var fade_out: float = clampf(
			(1.0 - progress) / 0.07,
			0.0,
			1.0
		)


		sample *= fade_in
		sample *= fade_out

		sample *= 0.95


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


func _play_page_turn_sound() -> void:
	if page_turn_player == null:
		return


	page_turn_player.pitch_scale = randf_range(
		0.97,
		1.03
	)


	page_turn_player.stop()

	page_turn_player.play()


# =========================================================
# BUILD SCENE
# =========================================================

func _build_scene() -> void:
	var background := ColorRect.new()

	background.color = Color.BLACK

	background.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	background.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	add_child(
		background
	)


	_build_newspaper()

	_build_recap_screen()


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


# =========================================================
# BLACK GAME-END REPORT
# =========================================================

func _build_recap_screen() -> void:
	recap_layer = Control.new()

	recap_layer.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	add_child(
		recap_layer
	)


	var black := ColorRect.new()

	black.color = Color.BLACK

	black.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	black.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	recap_layer.add_child(
		black
	)


	var viewport_size: Vector2 = (
		get_viewport().get_visible_rect().size
	)


	var x: float = (
		viewport_size.x * 0.105
	)


	var width: float = (
		viewport_size.x
		- x * 2.0
	)


	var title := Label.new()

	title.text = "ROUTE 6"

	title.position = Vector2(
		x,
		55.0
	)

	title.size = Vector2(
		width,
		45.0
	)

	title.add_theme_font_override(
		"font",
		HAND_FONT
	)

	title.add_theme_font_size_override(
		"font_size",
		25
	)

	title.add_theme_color_override(
		"font_color",
		Color(
			0.93,
			0.91,
			0.86,
			1.0
		)
	)

	recap_layer.add_child(
		title
	)


	var subtitle := Label.new()

	subtitle.text = (
		"FINAL DELIVERY RECORD"
	)

	subtitle.position = Vector2(
		x,
		97.0
	)

	subtitle.size = Vector2(
		width,
		28.0
	)

	subtitle.add_theme_font_override(
		"font",
		HAND_FONT
	)

	subtitle.add_theme_font_size_override(
		"font_size",
		12
	)

	subtitle.add_theme_color_override(
		"font_color",
		Color(
			0.54,
			0.52,
			0.49,
			1.0
		)
	)

	recap_layer.add_child(
		subtitle
	)


	var stats := Label.new()

	stats.text = _get_recap_stats()

	stats.position = Vector2(
		x,
		158.0
	)

	stats.size = Vector2(
		width,
		112.0
	)

	stats.add_theme_font_override(
		"font",
		HAND_FONT
	)

	stats.add_theme_font_size_override(
		"font_size",
		15
	)

	stats.add_theme_color_override(
		"font_color",
		Color(
			0.78,
			0.76,
			0.71,
			1.0
		)
	)

	stats.add_theme_constant_override(
		"line_spacing",
		5
	)

	recap_layer.add_child(
		stats
	)


	var rule := ColorRect.new()

	rule.position = Vector2(
		x,
		290.0
	)

	rule.size = Vector2(
		width * 0.72,
		1.0
	)

	rule.color = Color(
		0.35,
		0.34,
		0.32,
		0.50
	)

	rule.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	recap_layer.add_child(
		rule
	)


	var report := RichTextLabel.new()

	report.text = (
		_get_recap_report()
	)

	report.position = Vector2(
		x,
		320.0
	)

	report.size = Vector2(
		width * 0.82,
		205.0
	)

	report.bbcode_enabled = false

	report.scroll_active = false

	report.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)

	report.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	report.add_theme_font_override(
		"normal_font",
		HAND_FONT
	)

	report.add_theme_font_size_override(
		"normal_font_size",
		17
	)

	report.add_theme_color_override(
		"default_color",
		Color(
			0.91,
			0.89,
			0.84,
			1.0
		)
	)

	report.add_theme_constant_override(
		"line_separation",
		6
	)

	recap_layer.add_child(
		report
	)


	recap_continue = Label.new()

	recap_continue.text = (
		"SPACE / ENTER / CLICK TO CONTINUE"
	)

	recap_continue.position = Vector2(
		x,
		viewport_size.y - 69.0
	)

	recap_continue.size = Vector2(
		width,
		28.0
	)

	recap_continue.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_RIGHT
	)

	recap_continue.add_theme_font_override(
		"font",
		HAND_FONT
	)

	recap_continue.add_theme_font_size_override(
		"font_size",
		11
	)

	recap_continue.add_theme_color_override(
		"font_color",
		Color(
			0.48,
			0.47,
			0.44,
			1.0
		)
	)

	recap_layer.add_child(
		recap_continue
	)


	_add_hint_pulse(
		recap_continue
	)


	recap_layer.modulate.a = 0.0


	var intro := create_tween()

	intro.set_trans(
		Tween.TRANS_SINE
	)

	intro.set_ease(
		Tween.EASE_OUT
	)

	intro.tween_property(
		recap_layer,
		"modulate:a",
		1.0,
		0.55
	)


func _get_recap_stats() -> String:
	var sections: String = (
		"SECTIONS COMPLETED    "
		+ str(recovered_letters)
		+ " / 4"
	)


	var houses: String = (
		"HOUSES REACHED        "
		+ _get_houses_reached()
	)


	var time_line: String = (
		"LAST ROUTE ENTRY      "
		+ _get_last_route_time()
	)


	var status: String = (
		"ROUTE STATUS          "
		+ (
			"COMPLETE"
			if recovered_letters >= 4
			else "INCOMPLETE"
		)
	)


	return (
		sections
		+ "\n"
		+ houses
		+ "\n"
		+ time_line
		+ "\n"
		+ status
	)


func _get_houses_reached() -> String:
	match recovered_letters:
		0:
			return "NONE"

		1:
			return "01 - 02"

		2:
			return "01 - 04"

		3:
			return "01 - 06"

		4:
			return "01 - 08"

		_:
			return "UNKNOWN"


func _get_last_route_time() -> String:
	match recovered_letters:
		0:
			return "17:53"

		1:
			return "17:55"

		2:
			return "17:56"

		3:
			return "17:58"

		4:
			return "18:00"

		_:
			return "--:--"


func _get_recap_report() -> String:
	match recovered_letters:
		0:
			return (
				"The postman did not finish the first section of Route 6. "
				+ "The rest of the bag never reached a postbox.\n\n"
				+ "Mail already inside a street box had some protection from the fire. "
				+ "Anything still being carried had almost none."
			)

		1:
			return (
				"The postman completed Houses 01-02. "
				+ "He failed to finish the next section, and the rest of the bag "
				+ "never reached a postbox.\n\n"
				+ "The mail already delivered had a better chance of surviving. "
				+ "Whether any of it did would not be known until much later."
			)

		2:
			return (
				"The postman completed Houses 01-04. "
				+ "He failed during the next section. "
				+ "The remaining mail stayed with him.\n\n"
				+ "Letters already dropped into postboxes were partly shielded "
				+ "from the fires. Some of those boxes would remain standing."
			)

		3:
			return (
				"The postman completed Houses 01-06. "
				+ "He failed on the final section of the route. "
				+ "The last part of the bag was never delivered.\n\n"
				+ "What had already been placed inside postboxes stood a better chance. "
				+ "Some boxes survived even where the paper around them did not."
			)

		4:
			return (
				"The postman completed Route 6. "
				+ "Every section of the evening round was delivered.\n\n"
				+ "The postboxes offered the letters some protection from the fires. "
				+ "What survived inside them would be found much later."
			)

		_:
			return ""


# =========================================================
# NEWSPAPER
# =========================================================

func _build_newspaper() -> void:
	var viewport_size: Vector2 = (
		get_viewport().get_visible_rect().size
	)


	var paper_size := Vector2(
		minf(
			1040.0,
			viewport_size.x - 90.0
		),
		minf(
			570.0,
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


	page_one = Control.new()

	page_one.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	page_one.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	newspaper.add_child(
		page_one
	)


	page_two = Control.new()

	page_two.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	page_two.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	newspaper.add_child(
		page_two
	)


	page_two.hide()


	_build_page_one()

	_build_page_two()


	newspaper.hide()


func _build_page_one() -> void:
	_add_masthead(
		page_one,
		"FROM THE ARCHIVE"
	)


	var headline := _make_label(
		"KIYOSHIMA RECORDS STILL INCOMPLETE YEARS AFTER RAID",
		27,
		Color(
			0.09,
			0.08,
			0.06,
			1.0
		)
	)

	headline.position = Vector2(
		44.0,
		99.0
	)

	headline.size = Vector2(
		newspaper.size.x - 88.0,
		50.0
	)

	headline.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	headline.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	page_one.add_child(
		headline
	)


	var deck := _make_label(
		"Archive work continues as fragments from the eastern wards are identified.",
		14,
		Color(
			0.25,
			0.225,
			0.18,
			1.0
		)
	)

	deck.position = Vector2(
		120.0,
		151.0
	)

	deck.size = Vector2(
		newspaper.size.x - 240.0,
		35.0
	)

	deck.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	deck.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	page_one.add_child(
		deck
	)


	_add_rule(
		page_one,
		199.0
	)


	var column_gap: float = 50.0


	var column_width: float = (
		(
			newspaper.size.x
			- 90.0
			- column_gap
		)
		/ 2.0
	)


	var left_x: float = 45.0


	var right_x: float = (
		left_x
		+ column_width
		+ column_gap
	)


	var left_heading := _make_label(
		"MOST PAPER RECORDS DESTROYED",
		14,
		Color(
			0.12,
			0.105,
			0.08,
			1.0
		)
	)

	left_heading.position = Vector2(
		left_x,
		216.0
	)

	left_heading.size = Vector2(
		column_width,
		25.0
	)

	page_one.add_child(
		left_heading
	)


	var left_body := _make_body(
		"Most of Kiyoshima's eastern wards burned. "
		+ "The district post office and municipal offices were among "
		+ "the buildings lost. Delivery books, household registers "
		+ "and shop ledgers disappeared with them.\n\n"
		+ "When survey teams returned, street signs were missing and "
		+ "whole rows of houses were gone. Parts of the district could "
		+ "only be traced from older maps and surviving records."
	)

	left_body.position = Vector2(
		left_x,
		250.0
	)

	left_body.size = Vector2(
		column_width,
		205.0
	)

	page_one.add_child(
		left_body
	)


	var divider := ColorRect.new()

	divider.position = Vector2(
		newspaper.size.x / 2.0,
		216.0
	)

	divider.size = Vector2(
		1.0,
		245.0
	)

	divider.color = Color(
		0.23,
		0.20,
		0.15,
		0.44
	)

	divider.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	page_one.add_child(
		divider
	)


	var right_heading := _make_label(
		"FINAL POSTAL ROUND TRACED",
		14,
		Color(
			0.12,
			0.105,
			0.08,
			1.0
		)
	)

	right_heading.position = Vector2(
		right_x,
		216.0
	)

	right_heading.size = Vector2(
		column_width,
		25.0
	)

	page_one.add_child(
		right_heading
	)


	var right_body := _make_body(
		"Route 6 appears in one surviving postal ledger. "
		+ "It records an evening round leaving with the final bag of mail. "
		+ "There is no later entry for the carrier.\n\n"
		+ "Fragments of the route were identified much later from damaged "
		+ "postal records and mail recovered in the eastern wards."
	)

	right_body.position = Vector2(
		right_x,
		250.0
	)

	right_body.size = Vector2(
		column_width,
		205.0
	)

	page_one.add_child(
		right_body
	)


	page_one_hint = _make_label(
		"SPACE / ENTER / CLICK TO TURN PAGE",
		11,
		Color(
			0.31,
			0.28,
			0.22,
			1.0
		)
	)

	page_one_hint.position = Vector2(
		newspaper.size.x - 385.0,
		newspaper.size.y - 38.0
	)

	page_one_hint.size = Vector2(
		340.0,
		24.0
	)

	page_one_hint.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_RIGHT
	)

	page_one.add_child(
		page_one_hint
	)


	_add_hint_pulse(
		page_one_hint
	)


func _build_page_two() -> void:
	_add_masthead(
		page_two,
		"RECOVERY REPORT"
	)


	if recovered_letters <= 0:
		_build_no_recovery_page()

	else:
		_build_letter_recovery_page()


	page_two_hint = _make_label(
		"SPACE / ENTER / CLICK TO CONTINUE",
		11,
		Color(
			0.31,
			0.28,
			0.22,
			1.0
		)
	)

	page_two_hint.position = Vector2(
		newspaper.size.x - 365.0,
		newspaper.size.y - 38.0
	)

	page_two_hint.size = Vector2(
		320.0,
		24.0
	)

	page_two_hint.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_RIGHT
	)

	page_two.add_child(
		page_two_hint
	)


	_add_hint_pulse(
		page_two_hint
	)


func _build_no_recovery_page() -> void:
	var headline := _make_label(
		"NOTHING WAS RECOVERED FROM THE SITE",
		29,
		Color(
			0.09,
			0.08,
			0.06,
			1.0
		)
	)

	headline.position = Vector2(
		45.0,
		104.0
	)

	headline.size = Vector2(
		newspaper.size.x - 90.0,
		50.0
	)

	headline.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	headline.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	page_two.add_child(
		headline
	)


	var deck := _make_label(
		"No mail from Route 6's final round could be identified among the ruins.",
		14,
		Color(
			0.25,
			0.225,
			0.18,
			1.0
		)
	)

	deck.position = Vector2(
		140.0,
		158.0
	)

	deck.size = Vector2(
		newspaper.size.x - 280.0,
		42.0
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

	page_two.add_child(
		deck
	)


	_add_rule(
		page_two,
		213.0
	)


	var heading := _make_label(
		"ARCHIVE NOTE",
		14,
		Color(
			0.12,
			0.105,
			0.08,
			1.0
		)
	)

	heading.position = Vector2(
		80.0,
		238.0
	)

	heading.size = Vector2(
		newspaper.size.x - 160.0,
		25.0
	)

	page_two.add_child(
		heading
	)


	var body := _make_body(
		"Search teams found burned paper throughout the district, "
		+ "but nothing that could be tied to Route 6's final round.\n\n"
		+ "The sorting records were gone, and none of the mail recovered "
		+ "from surviving boxes could be matched to the route.\n\n"
		+ "The final round remains listed as unrecovered."
	)

	body.position = Vector2(
		80.0,
		278.0
	)

	body.size = Vector2(
		newspaper.size.x - 160.0,
		145.0
	)

	body.add_theme_font_size_override(
		"normal_font_size",
		17
	)

	page_two.add_child(
		body
	)


func _build_letter_recovery_page() -> void:
	var headline := _make_label(
		"WET LETTERS FOUND IN SURVIVING POSTBOXES",
		28,
		Color(
			0.09,
			0.08,
			0.06,
			1.0
		)
	)

	headline.position = Vector2(
		45.0,
		103.0
	)

	headline.size = Vector2(
		newspaper.size.x - 90.0,
		50.0
	)

	headline.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	headline.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	page_two.add_child(
		headline
	)


	var deck := _make_label(
		"Most paper at the site was scorched. "
		+ "A few envelopes survived inside boxes that remained standing.",
		14,
		Color(
			0.25,
			0.225,
			0.18,
			1.0
		)
	)

	deck.position = Vector2(
		125.0,
		157.0
	)

	deck.size = Vector2(
		newspaper.size.x - 250.0,
		42.0
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

	page_two.add_child(
		deck
	)


	_add_rule(
		page_two,
		213.0
	)


	var left_width: float = 620.0


	var left_heading := _make_label(
		"MAIL SURVIVED FIRE AND WATER",
		14,
		Color(
			0.12,
			0.105,
			0.08,
			1.0
		)
	)

	left_heading.position = Vector2(
		50.0,
		232.0
	)

	left_heading.size = Vector2(
		left_width,
		25.0
	)

	page_two.add_child(
		left_heading
	)


	var left_body := _make_body(
		"Almost every loose sheet recovered from the eastern wards "
		+ "was scorched or pulped by water. Several street postboxes, "
		+ "however, were still standing.\n\n"
		+ "Inside them were wet bundles of mail. Water used against "
		+ "the fires, followed by rain, had soaked through the boxes. "
		+ "The envelopes were stuck together and blackened at the edges, "
		+ "but some names and route marks were still readable."
	)

	left_body.position = Vector2(
		50.0,
		267.0
	)

	left_body.size = Vector2(
		left_width,
		190.0
	)

	page_two.add_child(
		left_body
	)


	var divider := ColorRect.new()

	divider.position = Vector2(
		705.0,
		232.0
	)

	divider.size = Vector2(
		1.0,
		225.0
	)

	divider.color = Color(
		0.23,
		0.20,
		0.15,
		0.44
	)

	divider.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	page_two.add_child(
		divider
	)


	var right_heading := _make_label(
		"ROUTE 6",
		14,
		Color(
			0.12,
			0.105,
			0.08,
			1.0
		)
	)

	right_heading.position = Vector2(
		738.0,
		232.0
	)

	right_heading.size = Vector2(
		250.0,
		25.0
	)

	page_two.add_child(
		right_heading
	)


	var count := _make_label(
		_get_recovered_count_text(),
		24,
		Color(
			0.39,
			0.12,
			0.09,
			1.0
		)
	)

	count.position = Vector2(
		738.0,
		274.0
	)

	count.size = Vector2(
		250.0,
		68.0
	)

	count.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)

	page_two.add_child(
		count
	)


	var note := _make_body(
		_get_recovery_archive_note()
	)

	note.position = Vector2(
		738.0,
		358.0
	)

	note.size = Vector2(
		250.0,
		100.0
	)

	note.add_theme_font_size_override(
		"normal_font_size",
		13
	)

	page_two.add_child(
		note
	)


func _get_recovered_count_text() -> String:
	if recovered_letters == 1:
		return (
			"1 LETTER\nIDENTIFIED"
		)


	return (
		str(recovered_letters)
		+ " LETTERS\nIDENTIFIED"
	)


func _get_recovery_archive_note() -> String:
	if recovered_letters == 1:
		return (
			"One envelope was matched "
			+ "to Route 6's final round.\n\n"
			+ "It is held in the Kiyoshima archive."
		)


	return (
		str(recovered_letters)
		+ " envelopes were matched "
		+ "to Route 6's final round.\n\n"
		+ "They are held in the Kiyoshima archive."
	)


# =========================================================
# INPUT / TRANSITIONS
# =========================================================

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


	match phase:
		ScreenPhase.RECAP:
			_open_newspaper()

		ScreenPhase.NEWSPAPER_ONE:
			_turn_newspaper_page()

		ScreenPhase.NEWSPAPER_TWO:
			_go_to_end_scene()

		_:
			pass


func _open_newspaper() -> void:
	if transitioning:
		return


	transitioning = true


	recap_continue.hide()


	var fade_out := create_tween()

	fade_out.set_trans(
		Tween.TRANS_SINE
	)

	fade_out.set_ease(
		Tween.EASE_IN_OUT
	)

	fade_out.tween_property(
		recap_layer,
		"modulate:a",
		0.0,
		0.42
	)


	await fade_out.finished


	recap_layer.hide()


	newspaper.show()

	newspaper.modulate.a = 0.0


	var fade_in := create_tween()

	fade_in.set_trans(
		Tween.TRANS_SINE
	)

	fade_in.set_ease(
		Tween.EASE_OUT
	)

	fade_in.tween_property(
		newspaper,
		"modulate:a",
		1.0,
		0.50
	)


	await fade_in.finished


	phase = ScreenPhase.NEWSPAPER_ONE

	transitioning = false


func _turn_newspaper_page() -> void:
	if transitioning:
		return


	transitioning = true


	page_one_hint.hide()


	_play_page_turn_sound()


	newspaper.pivot_offset = Vector2(
		0.0,
		newspaper.size.y / 2.0
	)


	var close_tween := create_tween()

	close_tween.set_trans(
		Tween.TRANS_SINE
	)

	close_tween.set_ease(
		Tween.EASE_IN
	)

	close_tween.tween_property(
		newspaper,
		"scale:x",
		0.025,
		0.38
	)


	await close_tween.finished


	page_one.hide()

	page_two.show()


	var open_tween := create_tween()

	open_tween.set_trans(
		Tween.TRANS_SINE
	)

	open_tween.set_ease(
		Tween.EASE_OUT
	)

	open_tween.tween_property(
		newspaper,
		"scale:x",
		1.0,
		0.42
	)


	await open_tween.finished


	phase = ScreenPhase.NEWSPAPER_TWO

	transitioning = false


func _go_to_end_scene() -> void:
	if transitioning:
		return


	transitioning = true

	phase = ScreenPhase.LEAVING


	page_two_hint.hide()


	var fade := create_tween()

	fade.set_trans(
		Tween.TRANS_SINE
	)

	fade.set_ease(
		Tween.EASE_IN_OUT
	)

	fade.tween_property(
		fade_overlay,
		"color:a",
		1.0,
		0.72
	)


	await fade.finished


	await _hard_stop_gameplay_before_exit()


	get_tree().change_scene_to_file(
		END_SCENE_PATH
	)


func _exit_tree() -> void:
	glitch_enabled = false

	_restore_glitch_volume()

	_remove_death_distortion()

	_force_stop_gameplay()


# =========================================================
# COMMON NEWSPAPER UI
# =========================================================

func _add_masthead(
	parent: Control,
	subtitle_text: String
) -> void:
	var masthead := _make_label(
		"THE KIYOSHIMA CHRONICLE",
		32,
		Color(
			0.09,
			0.08,
			0.06,
			1.0
		)
	)

	masthead.position = Vector2(
		40.0,
		12.0
	)

	masthead.size = Vector2(
		newspaper.size.x - 80.0,
		46.0
	)

	masthead.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	masthead.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	parent.add_child(
		masthead
	)


	var top_rule := ColorRect.new()

	top_rule.position = Vector2(
		40.0,
		62.0
	)

	top_rule.size = Vector2(
		newspaper.size.x - 80.0,
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

	parent.add_child(
		top_rule
	)


	var subtitle := _make_label(
		subtitle_text,
		10,
		Color(
			0.31,
			0.28,
			0.22,
			1.0
		)
	)

	subtitle.position = Vector2(
		40.0,
		68.0
	)

	subtitle.size = Vector2(
		newspaper.size.x - 80.0,
		22.0
	)

	subtitle.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	parent.add_child(
		subtitle
	)


func _add_rule(
	parent: Control,
	y: float
) -> void:
	var rule := ColorRect.new()

	rule.position = Vector2(
		45.0,
		y
	)

	rule.size = Vector2(
		newspaper.size.x - 90.0,
		1.0
	)

	rule.color = Color(
		0.21,
		0.19,
		0.145,
		0.70
	)

	rule.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	parent.add_child(
		rule
	)


func _make_label(
	text_value: String,
	font_size: int,
	font_color: Color
) -> Label:
	var label := Label.new()

	label.text = text_value

	label.add_theme_font_override(
		"font",
		serif_font
	)

	label.add_theme_font_size_override(
		"font_size",
		font_size
	)

	label.add_theme_color_override(
		"font_color",
		font_color
	)

	label.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	return label


func _make_body(
	text_value: String
) -> RichTextLabel:
	var body := RichTextLabel.new()

	body.text = text_value

	body.bbcode_enabled = false

	body.scroll_active = false

	body.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	body.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)

	body.add_theme_font_override(
		"normal_font",
		serif_font
	)

	body.add_theme_font_size_override(
		"normal_font_size",
		14
	)

	body.add_theme_color_override(
		"default_color",
		Color(
			0.16,
			0.145,
			0.11,
			1.0
		)
	)

	body.add_theme_constant_override(
		"line_separation",
		3
	)

	return body


func _add_hint_pulse(
	label: Label
) -> void:
	var tween := create_tween()

	tween.set_loops()


	tween.tween_property(
		label,
		"modulate:a",
		0.40,
		1.0
	).set_trans(
		Tween.TRANS_SINE
	)


	tween.tween_property(
		label,
		"modulate:a",
		1.0,
		1.0
	).set_trans(
		Tween.TRANS_SINE
	)


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
