extends Node

const GAMEPLAY_MUSIC_SOURCE: AudioStreamMP3 = preload(
	"res://Assets/hexxel-chill-hive-533766.mp3"
)

const BUS_NAME: StringName = &"GameplayMusicFX"

const MINIGAME_VOLUME_DB: float = -5.0
const INTERSTITIAL_VOLUME_DB: float = -9.0

var gameplay_music: AudioStreamMP3
var player: AudioStreamPlayer

var distortion: AudioEffectDistortion
var low_pass: AudioEffectLowPassFilter

var current_stage: int = -1

var base_pitch: float = 1.0
var wobble_amount: float = 0.0
var wobble_speed: float = 0.10

var _stage_tween: Tween
var _volume_tween: Tween


func _ready() -> void:
	_setup_bus()

	gameplay_music = GAMEPLAY_MUSIC_SOURCE.duplicate() as AudioStreamMP3
	gameplay_music.loop = true

	player = AudioStreamPlayer.new()
	player.stream = gameplay_music
	player.bus = BUS_NAME
	player.volume_db = -24.0
	player.pitch_scale = 1.0

	add_child(player)


func _process(_delta: float) -> void:
	if not player.playing:
		return

	var seconds: float = float(Time.get_ticks_msec()) / 1000.0

	var slow_wobble: float = (
		sin(seconds * TAU * wobble_speed)
		* wobble_amount
	)

	var secondary_wobble: float = (
		sin(seconds * TAU * wobble_speed * 0.43 + 1.7)
		* wobble_amount
		* 0.35
	)

	player.pitch_scale = maxf(
		base_pitch + slow_wobble + secondary_wobble,
		0.01
	)


func _setup_bus() -> void:
	var bus_index: int = AudioServer.get_bus_index(BUS_NAME)

	if bus_index == -1:
		AudioServer.add_bus()

		bus_index = AudioServer.bus_count - 1

		AudioServer.set_bus_name(
			bus_index,
			BUS_NAME
		)

		AudioServer.set_bus_send(
			bus_index,
			&"Master"
		)

	while AudioServer.get_bus_effect_count(bus_index) > 0:
		AudioServer.remove_bus_effect(
			bus_index,
			0
		)

	distortion = AudioEffectDistortion.new()
	distortion.mode = AudioEffectDistortion.MODE_LOFI

	distortion.drive = 0.0
	distortion.pre_gain = 0.0
	distortion.post_gain = 0.0
	distortion.keep_hf_hz = 16000.0

	low_pass = AudioEffectLowPassFilter.new()

	low_pass.cutoff_hz = 18000.0
	low_pass.resonance = 0.10

	AudioServer.add_bus_effect(
		bus_index,
		distortion,
		0
	)

	AudioServer.add_bus_effect(
		bus_index,
		low_pass,
		1
	)


func start_gameplay(stage: int = 0) -> void:
	stage = clampi(stage, 0, 4)

	if not player.playing:
		player.volume_db = -24.0
		player.pitch_scale = 1.0
		player.play()

	set_stage(stage)


func enter_interstitial() -> void:
	if not player.playing:
		start_gameplay(
			clampi(Global.minigames_done, 0, 4)
		)

	_fade_volume(
		INTERSTITIAL_VOLUME_DB,
		0.8
	)


func enter_minigame() -> void:
	if not player.playing:
		start_gameplay(
			clampi(Global.minigames_done, 0, 4)
		)

	_fade_volume(
		_get_minigame_volume(),
		0.75
	)


func _get_minigame_volume() -> float:
	match current_stage:
		0:
			return MINIGAME_VOLUME_DB

		1:
			return MINIGAME_VOLUME_DB - 0.1

		2:
			return MINIGAME_VOLUME_DB - 0.2

		3:
			return MINIGAME_VOLUME_DB - 0.4

		4:
			return MINIGAME_VOLUME_DB - 0.6

	return MINIGAME_VOLUME_DB


func _fade_volume(
	target_db: float,
	duration: float
) -> void:
	if _volume_tween and _volume_tween.is_valid():
		_volume_tween.kill()

	_volume_tween = create_tween()

	_volume_tween.set_trans(
		Tween.TRANS_SINE
	)

	_volume_tween.set_ease(
		Tween.EASE_IN_OUT
	)

	_volume_tween.tween_property(
		player,
		"volume_db",
		target_db,
		duration
	)


func set_stage(stage: int) -> void:
	stage = clampi(stage, 0, 4)

	if stage == current_stage:
		return

	current_stage = stage

	var target_drive: float = 0.0
	var target_keep_hf: float = 16000.0
	var target_cutoff: float = 18000.0
	var target_pitch: float = 1.0
	var target_wobble: float = 0.0
	var target_wobble_speed: float = 0.10


	match stage:
		0:
			target_drive = 0.0
			target_keep_hf = 16000.0
			target_cutoff = 18000.0

			target_pitch = 1.0

			target_wobble = 0.0
			target_wobble_speed = 0.10


		1:
			target_drive = 0.012
			target_keep_hf = 15200.0
			target_cutoff = 17000.0

			target_pitch = 0.9997

			target_wobble = 0.00035
			target_wobble_speed = 0.105


		2:
			target_drive = 0.032
			target_keep_hf = 13500.0
			target_cutoff = 15300.0

			target_pitch = 0.9985

			target_wobble = 0.0009
			target_wobble_speed = 0.115


		3:
			target_drive = 0.065
			target_keep_hf = 10800.0
			target_cutoff = 12900.0

			target_pitch = 0.9960

			target_wobble = 0.0018
			target_wobble_speed = 0.125


		4:
			target_drive = 0.115
			target_keep_hf = 7500.0
			target_cutoff = 10000.0

			target_pitch = 0.9925

			target_wobble = 0.0034
			target_wobble_speed = 0.14


	if _stage_tween and _stage_tween.is_valid():
		_stage_tween.kill()

	_stage_tween = create_tween()

	_stage_tween.set_parallel(true)

	_stage_tween.set_trans(
		Tween.TRANS_SINE
	)

	_stage_tween.set_ease(
		Tween.EASE_IN_OUT
	)

	_stage_tween.tween_property(
		distortion,
		"drive",
		target_drive,
		5.0
	)

	_stage_tween.tween_property(
		distortion,
		"keep_hf_hz",
		target_keep_hf,
		5.0
	)

	_stage_tween.tween_property(
		low_pass,
		"cutoff_hz",
		target_cutoff,
		5.0
	)

	_stage_tween.tween_property(
		self,
		"base_pitch",
		target_pitch,
		5.0
	)

	_stage_tween.tween_property(
		self,
		"wobble_amount",
		target_wobble,
		5.0
	)

	_stage_tween.tween_property(
		self,
		"wobble_speed",
		target_wobble_speed,
		5.0
	)


func fade_out(duration: float = 2.0) -> void:
	if not player.playing:
		return

	if _volume_tween and _volume_tween.is_valid():
		_volume_tween.kill()

	_volume_tween = create_tween()

	_volume_tween.set_trans(
		Tween.TRANS_SINE
	)

	_volume_tween.set_ease(
		Tween.EASE_IN
	)

	_volume_tween.tween_property(
		player,
		"volume_db",
		-60.0,
		duration
	)

	await _volume_tween.finished

	player.stop()


func stop_immediately() -> void:
	if _volume_tween and _volume_tween.is_valid():
		_volume_tween.kill()

	if _stage_tween and _stage_tween.is_valid():
		_stage_tween.kill()

	player.stop()

	player.volume_db = -60.0
	player.pitch_scale = 1.0

	current_stage = -1

	base_pitch = 1.0
	wobble_amount = 0.0
	wobble_speed = 0.10

	distortion.drive = 0.0
	distortion.keep_hf_hz = 16000.0

	low_pass.cutoff_hz = 18000.0
