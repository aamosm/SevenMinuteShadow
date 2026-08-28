class_name DialogueManagerExampleBalloon extends CanvasLayer
## A basic dialogue balloon for use with Dialogue Manager.


## The dialogue resource
@export var dialogue_resource: DialogueResource

## Start from a given title when using balloon as a [Node] in a scene.
@export var start_from_title: String = ""

## If running as a [Node] in a scene then auto start the dialogue.
@export var auto_start: bool = false

## If all other input is blocked as long as dialogue is shown.
@export var will_block_other_input: bool = true

## The action to use for advancing the dialogue
@export var next_action: StringName = &"ui_accept"

## The action to use to skip typing the dialogue
@export var skip_action: StringName = &"ui_cancel"

@export var radio_blip_volume_db: float = -3.0
@export var radio_blip_every_n_characters: int = 2

## A sound player for voice lines (if they exist).
@onready var audio_stream_player: AudioStreamPlayer = %AudioStreamPlayer

## Temporary game states
var temporary_game_states: Array = []

## See if we are waiting for the player
var is_waiting_for_input: bool = false

## See if we are running a long mutation and should hide the balloon
var will_hide_balloon: bool = false

## A dictionary to store any ephemeral variables
var locals: Dictionary = {}

var _locale: String = TranslationServer.get_locale()

## The current line
var dialogue_line: DialogueLine:
	set(value):
		if value:
			dialogue_line = value
			apply_dialogue_line()
		else:
			# The dialogue has finished so close the balloon
			if owner == null:
				queue_free()
			else:
				hide()
	get:
		return dialogue_line

## A cooldown timer for delaying the balloon hide when encountering a mutation.
var mutation_cooldown: Timer = Timer.new()

## The base balloon anchor
@onready var balloon: Control = %Balloon

## The label showing the name of the currently speaking character
@onready var character_label: RichTextLabel = %CharacterLabel

## The label showing the currently spoken dialogue
@onready var dialogue_label: DialogueLabel = %DialogueLabel

## The menu of responses
@onready var responses_menu: DialogueResponsesMenu = %ResponsesMenu

## Indicator to show that player can progress dialogue.
@onready var progress: Polygon2D = %Progress


const RADIO_DIALOGUE_PATH: String = "res://dialogue/radio.dialogue"
const RADIO_BUS_NAME: String = "DialogueRadioBlips"

var _radio_blip_players: Array[AudioStreamPlayer] = []
var _radio_blips: Array[AudioStreamWAV] = []
var _radio_player_index: int = 0


func _ready() -> void:
	balloon.hide()

	progress.hide()
	progress.visible = false

	balloon.self_modulate.a = 0.82

	_setup_radio_blips()

	if not dialogue_label.spoke.is_connected(_on_dialogue_spoke):
		dialogue_label.spoke.connect(_on_dialogue_spoke)

	Engine.get_singleton("DialogueManager").mutated.connect(_on_mutated)

	# If the responses menu doesn't have a next action set, use this one
	if responses_menu.next_action.is_empty():
		responses_menu.next_action = next_action

	mutation_cooldown.timeout.connect(_on_mutation_cooldown_timeout)
	add_child(mutation_cooldown)

	if auto_start:
		if not is_instance_valid(dialogue_resource):
			assert(false, DMConstants.get_error_message(DMConstants.ERR_MISSING_RESOURCE_FOR_AUTOSTART))
		start()


func _is_radio_dialogue() -> bool:
	if not is_instance_valid(dialogue_resource):
		return false

	return dialogue_resource.resource_path == RADIO_DIALOGUE_PATH


func _setup_radio_blips() -> void:
	var bus_index: int = AudioServer.get_bus_index(RADIO_BUS_NAME)

	if bus_index == -1:
		AudioServer.add_bus()

		bus_index = AudioServer.bus_count - 1

		AudioServer.set_bus_name(
			bus_index,
			RADIO_BUS_NAME
		)

		AudioServer.set_bus_send(
			bus_index,
			"Master"
		)

	while AudioServer.get_bus_effect_count(bus_index) > 0:
		AudioServer.remove_bus_effect(
			bus_index,
			0
		)

	var high_pass := AudioEffectHighPassFilter.new()
	high_pass.cutoff_hz = 520.0
	high_pass.resonance = 0.25

	var low_pass := AudioEffectLowPassFilter.new()
	low_pass.cutoff_hz = 3000.0
	low_pass.resonance = 0.30

	var distortion := AudioEffectDistortion.new()
	distortion.mode = AudioEffectDistortion.MODE_LOFI
	distortion.drive = 0.25
	distortion.pre_gain = 1.5
	distortion.post_gain = -2.0
	distortion.keep_hf_hz = 2600.0

	AudioServer.add_bus_effect(
		bus_index,
		high_pass,
		0
	)

	AudioServer.add_bus_effect(
		bus_index,
		low_pass,
		1
	)

	AudioServer.add_bus_effect(
		bus_index,
		distortion,
		2
	)

	for i in range(4):
		var player := AudioStreamPlayer.new()

		player.bus = RADIO_BUS_NAME
		player.volume_db = radio_blip_volume_db

		add_child(player)

		_radio_blip_players.append(player)

	_radio_blips.append(
		_make_radio_blip(
			410.0,
			0.042,
			0.40,
			0.34
		)
	)

	_radio_blips.append(
		_make_radio_blip(
			455.0,
			0.037,
			0.38,
			0.39
		)
	)

	_radio_blips.append(
		_make_radio_blip(
			495.0,
			0.034,
			0.36,
			0.43
		)
	)

	_radio_blips.append(
		_make_radio_blip(
			440.0,
			0.039,
			0.39,
			0.37
		)
	)

	_radio_blips.append(
		_make_radio_blip(
			530.0,
			0.032,
			0.34,
			0.45
		)
	)

	_radio_blips.append(
		_make_radio_blip(
			385.0,
			0.043,
			0.41,
			0.32
		)
	)


func _make_radio_blip(
	frequency: float,
	duration: float,
	strength: float,
	noise_strength: float
) -> AudioStreamWAV:
	var sample_rate: int = 44100
	var frame_count: int = int(
		float(sample_rate) * duration
	)

	var data := PackedByteArray()

	data.resize(frame_count * 2)

	for i in range(frame_count):
		var t: float = float(i) / float(sample_rate)
		var progress: float = t / duration

		var attack: float = minf(
			progress / 0.06,
			1.0
		)

		var decay: float = pow(
			1.0 - progress,
			3.4
		)

		var envelope: float = attack * decay

		var fundamental: float = sin(
			TAU * frequency * t
		)

		var harmonic: float = sin(
			TAU * frequency * 1.93 * t
		) * 0.24

		var rough_harmonic: float = sin(
			TAU * frequency * 3.16 * t
		) * 0.09

		var static_noise: float = randf_range(
			-1.0,
			1.0
		) * noise_strength

		var sample: float = (
			fundamental
			+ harmonic
			+ rough_harmonic
			+ static_noise
		)

		sample *= envelope
		sample *= strength

		sample = clampf(
			sample * 1.35,
			-1.0,
			1.0
		)

		var pcm: int = int(
			sample * 32767.0
		)

		if pcm < 0:
			pcm += 65536

		data[i * 2] = pcm & 0xFF
		data[i * 2 + 1] = (pcm >> 8) & 0xFF

	var wav := AudioStreamWAV.new()

	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data

	return wav


func _on_dialogue_spoke(
	letter: String,
	letter_index: int,
	_speed: float
) -> void:
	if not _is_radio_dialogue():
		return

	if letter.is_empty():
		return

	if letter.strip_edges().is_empty():
		return

	if (
		letter == "."
		or letter == ","
		or letter == "!"
		or letter == "?"
		or letter == ":"
		or letter == ";"
		or letter == "-"
		or letter == "—"
	):
		return

	var character_step: int = maxi(
		radio_blip_every_n_characters,
		1
	)

	if letter_index % character_step != 0:
		return

	_play_radio_blip(
		letter,
		letter_index
	)


func _play_radio_blip(
	letter: String,
	letter_index: int
) -> void:
	if _radio_blips.is_empty():
		return

	if _radio_blip_players.is_empty():
		return

	var player := _radio_blip_players[
		_radio_player_index
	]

	_radio_player_index += 1

	if _radio_player_index >= _radio_blip_players.size():
		_radio_player_index = 0

	var character_code: int = letter.unicode_at(0)

	var sound_index: int = (
		character_code
		+ letter_index
	) % _radio_blips.size()

	player.stream = _radio_blips[sound_index]

	var pitch_offset: float = float(
		(character_code + letter_index) % 9 - 4
	) * 0.013

	player.pitch_scale = 1.0 + pitch_offset

	player.volume_db = radio_blip_volume_db + randf_range(
		-1.5,
		0.5
	)

	player.play()


func _unhandled_input(_event: InputEvent) -> void:
	# Only the balloon is allowed to handle input while it's showing
	if will_block_other_input:
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	## Detect a change of locale and update the current dialogue line to show the new language
	if (
		what == NOTIFICATION_TRANSLATION_CHANGED
		and _locale != TranslationServer.get_locale()
		and is_instance_valid(dialogue_label)
	):
		_locale = TranslationServer.get_locale()

		var visible_ratio: float = dialogue_label.visible_ratio

		dialogue_line = await dialogue_resource.get_next_dialogue_line(
			dialogue_line.id
		)

		if visible_ratio < 1:
			dialogue_label.skip_typing()


## Start some dialogue
func start(
	with_dialogue_resource: DialogueResource = null,
	title: String = "",
	extra_game_states: Array = []
) -> void:
	temporary_game_states = [self] + extra_game_states
	is_waiting_for_input = false

	if is_instance_valid(with_dialogue_resource):
		dialogue_resource = with_dialogue_resource

	if not title.is_empty():
		start_from_title = title

	dialogue_line = await dialogue_resource.get_next_dialogue_line(
		start_from_title,
		temporary_game_states
	)

	show()


## Apply any changes to the balloon given a new [DialogueLine].
func apply_dialogue_line() -> void:
	mutation_cooldown.stop()

	progress.hide()
	progress.visible = false

	is_waiting_for_input = false

	balloon.focus_mode = Control.FOCUS_ALL
	balloon.grab_focus()

	character_label.visible = not dialogue_line.character.is_empty()

	character_label.text = tr(
		dialogue_line.character,
		"dialogue"
	)

	dialogue_label.hide()
	dialogue_label.dialogue_line = dialogue_line

	responses_menu.hide()
	responses_menu.responses = dialogue_line.responses

	# Show our balloon
	balloon.show()

	will_hide_balloon = false

	dialogue_label.show()

	if not dialogue_line.text.is_empty():
		dialogue_label.type_out()

		await dialogue_label.finished_typing

	progress.hide()
	progress.visible = false

	# Wait for next line
	if dialogue_line.has_tag("voice"):
		audio_stream_player.stream = load(
			dialogue_line.get_tag_value("voice")
		)

		audio_stream_player.play()

		await audio_stream_player.finished

		next(
			dialogue_line.next_id
		)

	elif dialogue_line.responses.size() > 0:
		balloon.focus_mode = Control.FOCUS_NONE

		responses_menu.show()

	elif dialogue_line.time != "":
		var time: float = (
			dialogue_line.text.length() * 0.02
			if dialogue_line.time == "auto"
			else dialogue_line.time.to_float()
		)

		await get_tree().create_timer(
			time
		).timeout

		next(
			dialogue_line.next_id
		)

	else:
		is_waiting_for_input = true

		balloon.focus_mode = Control.FOCUS_ALL
		balloon.grab_focus()


## Go to the next line
func next(next_id: String) -> void:
	is_waiting_for_input = false

	progress.hide()
	progress.visible = false

	dialogue_line = await dialogue_resource.get_next_dialogue_line(
		next_id,
		temporary_game_states
	)


#region Signals


func _on_mutation_cooldown_timeout() -> void:
	if will_hide_balloon:
		will_hide_balloon = false
		balloon.hide()


func _on_mutated(mutation: Dictionary) -> void:
	if not mutation.is_inline:
		is_waiting_for_input = false
		will_hide_balloon = true
		mutation_cooldown.start(0.1)


func _on_balloon_gui_input(event: InputEvent) -> void:
	if dialogue_label.is_typing:
		var mouse_was_clicked: bool = (
			event is InputEventMouseButton
			and event.button_index == MOUSE_BUTTON_LEFT
			and event.is_pressed()
		)

		var skip_button_was_pressed: bool = event.is_action_pressed(
			skip_action
		)

		if mouse_was_clicked or skip_button_was_pressed:
			get_viewport().set_input_as_handled()
			dialogue_label.skip_typing()

		return

	if not is_waiting_for_input:
		return

	if dialogue_line.responses.size() > 0:
		return

	if (
		event.is_action_pressed(next_action)
		and get_viewport().gui_get_focus_owner() == balloon
	):
		get_viewport().set_input_as_handled()

		next(
			dialogue_line.next_id
		)


func _on_responses_menu_response_selected(
	response: DialogueResponse
) -> void:
	next(
		response.next_id
	)


#endregion
