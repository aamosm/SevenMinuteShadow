extends Node2D


# =========================================================
# CAMERA / ROOM
# =========================================================

const ROOM_SIZE := Vector2(
	576.0,
	328.0
)

const CAMERA_CENTER := Vector2(
	288.0,
	164.0
)

const CAMERA_ZOOM: float = 2.0


const PLAYER_SPAWN := Vector2(
	288.0,
	250.0
)


# Interaction points are intentionally OUTSIDE the
# physical wall collisions.
const ARCHIVE_POINT := Vector2(
	288.0,
	136.0
)

const RETRY_POINT := Vector2(
	166.0,
	150.0
)

const LEAVE_POINT := Vector2(
	410.0,
	150.0
)


const INTERACTION_DISTANCE: float = 45.0


# -1 = actual Global.minigames_done
# 0-4 = force value while testing EndScene directly
@export_range(-1, 4, 1)
var test_recovered_items: int = -1


enum InteractionType {
	NONE,
	ARCHIVE,
	RETRY,
	LEAVE
}


enum ModalType {
	NONE,
	ARCHIVE,
	RETRY_CONFIRM,
	LEAVE_CONFIRM,
	ENDING
}


# =========================================================
# DOCUMENTS
# =========================================================

const DOCUMENTS: Array = [
	{
		"short_title": "LETTER I",
		"title": "PERSONAL LETTER",
		"archive":
			"ROUTE 6 / ITEM 01\n"
			+ "RECOVERED FROM A STREET POSTBOX",
		"body":
			"Emi,\n\n"
			+ "I found your blue ribbon.\n\n"
			+ "Before you start, it was under Father's chair, exactly "
			+ "where I said it would be. So I am not apologising for "
			+ "calling you careless.\n\n"
			+ "Mother says you should come on Sunday if the ferry is "
			+ "running. She bought enough fish for six people even though "
			+ "there are four of us, which means she has already decided "
			+ "you are coming.\n\n"
			+ "Bring my book back.\n\n"
			+ "And don't fold the corners this time.\n\n"
			+ "Aiko"
	},

	{
		"short_title": "LETTER II",
		"title": "PERSONAL LETTER",
		"archive":
			"ROUTE 6 / ITEM 02\n"
			+ "RECOVERED WITH WATER DAMAGE",
		"body":
			"Masao,\n\n"
			+ "I was still angry when you left, so I said not to come back.\n\n"
			+ "That was stupid.\n\n"
			+ "You may come back.\n\n"
			+ "I am writing it down because if I wait until you are standing "
			+ "in the doorway I will probably pretend I never said any of this.\n\n"
			+ "Your coat is still here. I washed it. The left pocket had three "
			+ "screws, a train ticket and half a sweet in it.\n\n"
			+ "I threw away the sweet.\n\n"
			+ "The screws are on the kitchen shelf.\n\n"
			+ "Noriko"
	},

	{
		"short_title": "LETTER III",
		"title": "PERSONAL LETTER",
		"archive":
			"ROUTE 6 / ITEM 03\n"
			+ "PARTIALLY SCORCHED",
		"body":
			"Hiro,\n\n"
			+ "Your examination results came.\n\n"
			+ "I did not open them.\n\n"
			+ "I wanted to.\n\n"
			+ "I held the envelope up to the window instead, but the paper "
			+ "is too thick, so your secrets remain safe.\n\n"
			+ "Your father says that if you passed mathematics he will stop "
			+ "calling your radio \"that ridiculous box\" for one whole week.\n\n"
			+ "I made him promise.\n\n"
			+ "Write when you get the result.\n\n"
			+ "Mother"
	},

	{
		"short_title": "TELEGRAM",
		"title": "HARBOUR TELEGRAM",
		"archive":
			"ROUTE 6 / ITEM 04\n"
			+ "RECOVERED FROM POSTBOX 08",
		"body":
			"TO: KATO LIGHTHOUSE\n"
			+ "FROM: KIYOSHIMA HARBOUR OFFICE\n\n"
			+ "KATO,\n\n"
			+ "I WENT OUT TO THE EAST BREAKWATER THIS MORNING.\n\n"
			+ "THE SHADOW OFF THE REEF WAS A WHALE.\n\n"
			+ "A LARGE WHALE, YES.\n\n"
			+ "NOT GOJIRA.\n\n"
			+ "PLEASE STOP TELLING THE SCHOOLCHILDREN THAT IT LOOKED AT YOU.\n\n"
			+ "MRS. MORI HAS ALREADY SENT TWO OF THEM HOME CRYING.\n\n"
			+ "IF YOU SEE IT AGAIN, WRITE DOWN THE TIME AND DIRECTION "
			+ "LIKE A NORMAL LIGHTHOUSE KEEPER.\n\n"
			+ "DO NOT NAME IT.\n\n"
			+ "COME BY THE OFFICE TOMORROW.\n\n"
			+ "I STILL OWE YOU TEA.\n\n"
			+ "MURAI\n"
			+ "KIYOSHIMA HARBOUR OFFICE"
	}
]


# =========================================================
# STATE
# =========================================================

var player: CharacterBody2D

var recovered_items: int = 0

var current_interaction: int = (
	InteractionType.NONE
)

var modal: int = (
	ModalType.NONE
)

var current_document: int = 0

var elapsed: float = 0.0


# =========================================================
# CRISP SCREEN-SPACE SIGNAGE
# =========================================================

var sign_layer: CanvasLayer

var archive_count_label: Label

var archive_marker: Label
var retry_marker: Label
var leave_marker: Label

var archive_prompt: Label
var retry_prompt: Label
var leave_prompt: Label


# =========================================================
# ARCHIVE UI
# =========================================================

var archive_layer: CanvasLayer

var archive_title: Label
var archive_record: Label
var archive_body: RichTextLabel

var no_items_label: Label

var document_buttons: Array[Button] = []


# =========================================================
# CONFIRMATION UI
# =========================================================

var confirm_layer: CanvasLayer

var confirm_title: Label
var confirm_body: Label
var confirm_controls: Label


# =========================================================
# FADE
# =========================================================

var fade_layer: CanvasLayer
var fade_rect: ColorRect


# =========================================================
# READY
# =========================================================

func _ready() -> void:
	Input.set_mouse_mode(
		Input.MOUSE_MODE_VISIBLE
	)


	if test_recovered_items >= 0:
		recovered_items = (
			test_recovered_items
		)

	else:
		recovered_items = clampi(
			Global.minigames_done,
			0,
			4
		)


	_build_room()

	_build_sign_layer()

	_setup_player()

	_build_archive_ui()

	_build_confirmation_ui()

	_build_fade_layer()

	_update_archive_board()


# =========================================================
# PROCESS
# =========================================================

func _process(
	delta: float
) -> void:
	elapsed += delta


	if player == null:
		return


	if modal != ModalType.NONE:
		return


	_update_current_interaction()

	_update_prompts()

	_update_marker_pulse()


# =========================================================
# INTERACTION DETECTION
# =========================================================

func _update_current_interaction() -> void:
	var position_now: Vector2 = (
		player.global_position
	)


	var archive_distance: float = (
		position_now.distance_to(
			ARCHIVE_POINT
		)
	)


	var retry_distance: float = (
		position_now.distance_to(
			RETRY_POINT
		)
	)


	var leave_distance: float = (
		position_now.distance_to(
			LEAVE_POINT
		)
	)


	var closest: float = INF


	current_interaction = (
		InteractionType.NONE
	)


	if (
		archive_distance
		<= INTERACTION_DISTANCE
	):
		closest = archive_distance

		current_interaction = (
			InteractionType.ARCHIVE
		)


	if (
		retry_distance
		<= INTERACTION_DISTANCE
		and retry_distance < closest
	):
		closest = retry_distance

		current_interaction = (
			InteractionType.RETRY
		)


	if (
		leave_distance
		<= INTERACTION_DISTANCE
		and leave_distance < closest
	):
		current_interaction = (
			InteractionType.LEAVE
		)


# =========================================================
# PROMPTS
# =========================================================

func _update_prompts() -> void:
	archive_prompt.visible = (
		current_interaction
		== InteractionType.ARCHIVE
	)


	retry_prompt.visible = (
		current_interaction
		== InteractionType.RETRY
	)


	leave_prompt.visible = (
		current_interaction
		== InteractionType.LEAVE
	)


func _update_marker_pulse() -> void:
	var pulse: float = (
		0.70
		+ sin(
			elapsed * 3.0
		) * 0.18
	)


	archive_marker.modulate.a = pulse
	retry_marker.modulate.a = pulse
	leave_marker.modulate.a = pulse


# =========================================================
# INPUT
# =========================================================

func _input(
	event: InputEvent
) -> void:
	if not (
		event is InputEventKey
	):
		return


	if not event.pressed:
		return


	if event.echo:
		return


	# =====================================================
	# ARCHIVE
	# =====================================================

	if modal == ModalType.ARCHIVE:
		if (
			event.keycode == KEY_SPACE
			or event.keycode == KEY_ESCAPE
		):
			get_viewport().set_input_as_handled()

			_close_archive()

			return


		if (
			event.keycode == KEY_RIGHT
			or event.keycode == KEY_D
		):
			get_viewport().set_input_as_handled()

			_next_document()

			return


		if (
			event.keycode == KEY_LEFT
			or event.keycode == KEY_A
		):
			get_viewport().set_input_as_handled()

			_previous_document()

			return


		return


	# =====================================================
	# TRY AGAIN CONFIRMATION
	# =====================================================

	if modal == ModalType.RETRY_CONFIRM:
		if event.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()

			_close_confirmation()

			return


		if (
			event.keycode == KEY_SPACE
			or event.keycode == KEY_ENTER
			or event.keycode == KEY_KP_ENTER
		):
			get_viewport().set_input_as_handled()

			_restart_game()

			return


		return


	# =====================================================
	# LEAVE CONFIRMATION
	# =====================================================

	if modal == ModalType.LEAVE_CONFIRM:
		if event.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()

			_close_confirmation()

			return


		if (
			event.keycode == KEY_SPACE
			or event.keycode == KEY_ENTER
			or event.keycode == KEY_KP_ENTER
		):
			get_viewport().set_input_as_handled()

			_end_game()

			return


		return


	if modal == ModalType.ENDING:
		return


	# =====================================================
	# WORLD
	# =====================================================

	if event.keycode != KEY_SPACE:
		return


	match current_interaction:
		InteractionType.ARCHIVE:
			get_viewport().set_input_as_handled()

			_open_archive()


		InteractionType.RETRY:
			get_viewport().set_input_as_handled()

			_open_retry_confirmation()


		InteractionType.LEAVE:
			get_viewport().set_input_as_handled()

			_open_leave_confirmation()


# =========================================================
# PLAYER
# =========================================================

func _setup_player() -> void:
	player = get_node_or_null(
		"Player"
	) as CharacterBody2D


	if player == null:
		push_error(
			"EndScene could not find player.tscn."
		)

		return


	player.position = PLAYER_SPAWN


	# Keep the character above every room drawing.
	player.z_index = 20


	player.collision_layer = 1

	player.collision_mask |= 1


	var player_collision := (
		player.get_node_or_null(
			"CollisionShape2D"
		)
		as CollisionShape2D
	)


	if player_collision:
		# Full body collision for this room.
		#
		# The old tiny feet collision allowed the head and
		# torso to visually enter walls.
		var shape := RectangleShape2D.new()

		shape.size = Vector2(
			18.0,
			36.0
		)


		player_collision.shape = shape

		player_collision.position = Vector2(
			0.0,
			0.0
		)


	player.set(
		"cur_dir",
		"up"
	)


	if player.has_method(
		"play_anim"
	):
		player.call(
			"play_anim",
			0
		)


# =========================================================
# ROOM
# =========================================================

func _build_room() -> void:
	# Background outside room.
	_add_rect(
		Rect2(
			Vector2.ZERO,
			ROOM_SIZE
		),
		Color("#070809"),
		-20
	)


	# Outer shell.
	_add_rect(
		Rect2(
			Vector2(
				18,
				14
			),
			Vector2(
				540,
				301
			)
		),
		Color("#111214"),
		-12
	)


	# =====================================================
	# FLOOR
	# =====================================================

	_add_rect(
		Rect2(
			Vector2(
				38,
				106
			),
			Vector2(
				500,
				189
			)
		),
		Color("#302e2b"),
		-10
	)


	# Floor tile seams.
	for x in range(
		70,
		538,
		32
	):
		_add_line(
			Vector2(
				x,
				106
			),
			Vector2(
				x,
				295
			),
			Color(
				0.08,
				0.08,
				0.08,
				0.28
			),
			0.5,
			-9
		)


	for y in range(
		138,
		295,
		32
	):
		_add_line(
			Vector2(
				38,
				y
			),
			Vector2(
				538,
				y
			),
			Color(
				0.08,
				0.08,
				0.08,
				0.28
			),
			0.5,
			-9
		)


	# =====================================================
	# TOP SOLID WALL
	# =====================================================

	_add_rect(
		Rect2(
			Vector2(
				25,
				24
			),
			Vector2(
				526,
				82
			)
		),
		Color("#1d1d20"),
		-5
	)


	# Inner face.
	_add_rect(
		Rect2(
			Vector2(
				31,
				30
			),
			Vector2(
				514,
				64
			)
		),
		Color("#202022"),
		-4
	)


	# Lower wall edge.
	_add_rect(
		Rect2(
			Vector2(
				25,
				94
			),
			Vector2(
				526,
				12
			)
		),
		Color("#101012"),
		-3
	)


	# =====================================================
	# LEFT SOLID WALL BAY
	# =====================================================

	_add_rect(
		Rect2(
			Vector2(
				25,
				104
			),
			Vector2(
				120,
				88
			)
		),
		Color("#19191b"),
		-5
	)


	_add_rect(
		Rect2(
			Vector2(
				31,
				110
			),
			Vector2(
				108,
				72
			)
		),
		Color("#242222"),
		-4
	)


	# Inner edge / thickness.
	_add_rect(
		Rect2(
			Vector2(
				139,
				110
			),
			Vector2(
				6,
				72
			)
		),
		Color("#101012"),
		-3
	)


	# =====================================================
	# RIGHT SOLID WALL BAY
	# =====================================================

	_add_rect(
		Rect2(
			Vector2(
				431,
				104
			),
			Vector2(
				120,
				88
			)
		),
		Color("#19191b"),
		-5
	)


	_add_rect(
		Rect2(
			Vector2(
				437,
				110
			),
			Vector2(
				108,
				72
			)
		),
		Color("#242222"),
		-4
	)


	_add_rect(
		Rect2(
			Vector2(
				431,
				110
			),
			Vector2(
				6,
				72
			)
		),
		Color("#101012"),
		-3
	)


	# =====================================================
	# BOTTOM WALL
	# =====================================================

	_add_rect(
		Rect2(
			Vector2(
				25,
				295
			),
			Vector2(
				526,
				16
			)
		),
		Color("#18181a"),
		-4
	)


	# =====================================================
	# CENTRAL RUNNER
	# =====================================================

	_add_rect(
		Rect2(
			Vector2(
				224,
				150
			),
			Vector2(
				128,
				135
			)
		),
		Color("#382b29"),
		-8
	)


	_add_rect_border(
		Rect2(
			Vector2(
				224,
				150
			),
			Vector2(
				128,
				135
			)
		),
		Color(
			0.50,
			0.37,
			0.31,
			0.55
		),
		1.0,
		-7
	)


	# =====================================================
	# BENCHES
	# =====================================================

	_build_bench(
		Vector2(
			155,
			220
		)
	)


	_build_bench(
		Vector2(
			345,
			220
		)
	)


	# =====================================================
	# ARCHIVE BOARD
	# =====================================================

	_build_archive_board_visual()


	# =====================================================
	# SIDE WALL FRAMES
	# =====================================================

	_build_side_frame_visual(
		Rect2(
			Vector2(
				42,
				118
			),
			Vector2(
				86,
				56
			)
		)
	)


	_build_side_frame_visual(
		Rect2(
			Vector2(
				448,
				118
			),
			Vector2(
				86,
				56
			)
		)
	)


	# =====================================================
	# COLLISION
	#
	# These are deliberately a little larger than the
	# visible walls so the sprite itself cannot visually
	# enter them before physics stops the player.
	# =====================================================

	# Top wall.
	_make_static_rect(
		Rect2(
			Vector2(
				22,
				20
			),
			Vector2(
				532,
				96
			)
		)
	)


	# Left wall + retry bay.
	_make_static_rect(
		Rect2(
			Vector2(
				20,
				92
			),
			Vector2(
				138,
				112
			)
		)
	)


	# Right wall + leave bay.
	_make_static_rect(
		Rect2(
			Vector2(
				418,
				92
			),
			Vector2(
				138,
				112
			)
		)
	)


	# Bottom completely closed.
	_make_static_rect(
		Rect2(
			Vector2(
				20,
				286
			),
			Vector2(
				536,
				30
			)
		)
	)


	# Bench collisions.
	_make_static_rect(
		Rect2(
			Vector2(
				155,
				220
			),
			Vector2(
				76,
				24
			)
		)
	)


	_make_static_rect(
		Rect2(
			Vector2(
				345,
				220
			),
			Vector2(
				76,
				24
			)
		)
	)


# =========================================================
# ARCHIVE VISUAL
# =========================================================

func _build_archive_board_visual() -> void:
	# Subtle backing / glow.
	_add_rect(
		Rect2(
			Vector2(
				180,
				34
			),
			Vector2(
				216,
				52
			)
		),
		Color(
			0.77,
			0.67,
			0.45,
			0.10
		),
		0
	)


	# Frame.
	_add_rect(
		Rect2(
			Vector2(
				185,
				38
			),
			Vector2(
				206,
				44
			)
		),
		Color("#09090a"),
		1
	)


	# Paper/display surface.
	_add_rect(
		Rect2(
			Vector2(
				191,
				43
			),
			Vector2(
				194,
				34
			)
		),
		Color("#cec3a6"),
		2
	)


	_add_rect_border(
		Rect2(
			Vector2(
				191,
				43
			),
			Vector2(
				194,
				34
			)
		),
		Color("#76664d"),
		1.0,
		3
	)


# =========================================================
# SIDE FRAME VISUAL
# =========================================================

func _build_side_frame_visual(
	rect: Rect2
) -> void:
	_add_rect(
		rect,
		Color("#0a0a0b"),
		1
	)


	_add_rect(
		Rect2(
			rect.position + Vector2(
				5,
				5
			),
			rect.size - Vector2(
				10,
				10
			)
		),
		Color("#2a2725"),
		2
	)


	_add_rect_border(
		Rect2(
			rect.position + Vector2(
				5,
				5
			),
			rect.size - Vector2(
				10,
				10
			)
		),
		Color("#6a5d49"),
		1.0,
		3
	)


# =========================================================
# BENCH
# =========================================================

func _build_bench(
	pos: Vector2
) -> void:
	# Shadow.
	_add_rect(
		Rect2(
			pos + Vector2(
				3,
				5
			),
			Vector2(
				76,
				22
			)
		),
		Color(
			0,
			0,
			0,
			0.28
		),
		0
	)


	# Seat.
	_add_rect(
		Rect2(
			pos,
			Vector2(
				76,
				16
			)
		),
		Color("#4c4137"),
		1
	)


	# Front lip.
	_add_rect(
		Rect2(
			pos + Vector2(
				0,
				13
			),
			Vector2(
				76,
				5
			)
		),
		Color("#332e29"),
		2
	)


	# Legs.
	_add_rect(
		Rect2(
			pos + Vector2(
				7,
				18
			),
			Vector2(
				5,
				6
			)
		),
		Color("#201e1c"),
		1
	)


	_add_rect(
		Rect2(
			pos + Vector2(
				64,
				18
			),
			Vector2(
				5,
				6
			)
		),
		Color("#201e1c"),
		1
	)


# =========================================================
# CRISP SIGNAGE LAYER
#
# IMPORTANT:
# These Labels are NOT children of the zoomed world.
# They are screen-space, so Godot no longer scales the
# text by 2x and makes it fuzzy.
# =========================================================

func _build_sign_layer() -> void:
	sign_layer = CanvasLayer.new()

	sign_layer.layer = 10

	add_child(
		sign_layer
	)


	# =====================================================
	# ARCHIVE
	# =====================================================

	var archive_title_label := _make_screen_label(
		"KIYOSHIMA POSTAL ARCHIVE",
		Rect2(
			Vector2(
				195,
				46
			),
			Vector2(
				186,
				13
			)
		),
		19,
		Color("#29241c")
	)


	archive_title_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)


	archive_title_label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)


	archive_count_label = _make_screen_label(
		"",
		Rect2(
			Vector2(
				198,
				61
			),
			Vector2(
				180,
				10
			)
		),
		10,
		Color("#625849")
	)


	archive_count_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)


	archive_count_label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)


	archive_marker = _make_screen_label(
		"(i)",
		Rect2(
			Vector2(
				274,
				111
			),
			Vector2(
				28,
				16
			)
		),
		18,
		Color("#e3cf92")
	)


	archive_marker.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)


	archive_prompt = _make_screen_label(
		"SPACE TO EXAMINE",
		Rect2(
			Vector2(
				236,
				128
			),
			Vector2(
				104,
				15
			)
		),
		12,
		Color("#eee1bb")
	)


	archive_prompt.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	archive_prompt.visible = false


	# =====================================================
	# TRY AGAIN
	# =====================================================

	var retry_title := _make_screen_label(
		"TRY AGAIN",
		Rect2(
			Vector2(
				48,
				126
			),
			Vector2(
				74,
				15
			)
		),
		20,
		Color("#ddd2bb")
	)


	retry_title.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)


	retry_title.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)


	var retry_subtitle := _make_screen_label(
		"RETURN TO 17:53",
		Rect2(
			Vector2(
				48,
				146
			),
			Vector2(
				74,
				11
			)
		),
		10,
		Color("#908571")
	)


	retry_subtitle.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)


	retry_marker = _make_screen_label(
		"(i)",
		Rect2(
			Vector2(
				68,
				160
			),
			Vector2(
				34,
				14
			)
		),
		17,
		Color("#d9c68d")
	)


	retry_marker.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)


	retry_prompt = _make_screen_label(
		"SPACE  TRY AGAIN",
		Rect2(
			Vector2(
				42,
				195
			),
			Vector2(
				100,
				14
			)
		),
		12,
		Color("#eee1bb")
	)


	retry_prompt.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	retry_prompt.visible = false


	# =====================================================
	# LEAVE
	# =====================================================

	var leave_title := _make_screen_label(
		"LEAVE",
		Rect2(
			Vector2(
				454,
				126
			),
			Vector2(
				74,
				15
			)
		),
		20,
		Color("#ddd2bb")
	)


	leave_title.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)


	leave_title.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)


	var leave_subtitle := _make_screen_label(
		"END GAME",
		Rect2(
			Vector2(
				454,
				146
			),
			Vector2(
				74,
				11
			)
		),
		10,
		Color("#908571")
	)


	leave_subtitle.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)


	leave_marker = _make_screen_label(
		"(i)",
		Rect2(
			Vector2(
				474,
				160
			),
			Vector2(
				34,
				14
			)
		),
		17,
		Color("#d9c68d")
	)


	leave_marker.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)


	leave_prompt = _make_screen_label(
		"SPACE  LEAVE",
		Rect2(
			Vector2(
				442,
				195
			),
			Vector2(
				92,
				14
			)
		),
		12,
		Color("#eee1bb")
	)


	leave_prompt.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	leave_prompt.visible = false


# =========================================================
# WORLD -> SCREEN
# =========================================================

func _world_to_screen(
	world_position: Vector2
) -> Vector2:
	var viewport_size: Vector2 = (
		get_viewport().get_visible_rect().size
	)


	var result: Vector2 = (
		(
			world_position
			- CAMERA_CENTER
		)
		* CAMERA_ZOOM
		+ viewport_size / 2.0
	)


	# Keep text on whole pixels.
	return Vector2(
		round(result.x),
		round(result.y)
	)


func _make_screen_label(
	text_value: String,
	world_rect: Rect2,
	font_size: int,
	color: Color
) -> Label:
	var label := Label.new()


	label.text = text_value


	label.position = _world_to_screen(
		world_rect.position
	)


	label.size = Vector2(
		round(
			world_rect.size.x
			* CAMERA_ZOOM
		),
		round(
			world_rect.size.y
			* CAMERA_ZOOM
		)
	)


	label.add_theme_font_size_override(
		"font_size",
		font_size
	)


	label.add_theme_color_override(
		"font_color",
		color
	)


	label.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)


	sign_layer.add_child(
		label
	)


	return label


# =========================================================
# ARCHIVE STATUS
# =========================================================

func _update_archive_board() -> void:
	match recovered_items:
		0:
			archive_count_label.text = (
				"NO RECOVERED MATERIAL"
			)

		1:
			archive_count_label.text = (
				"1 ITEM ON DISPLAY"
			)

		2:
			archive_count_label.text = (
				"2 ITEMS ON DISPLAY"
			)

		3:
			archive_count_label.text = (
				"3 ITEMS ON DISPLAY"
			)

		4:
			archive_count_label.text = (
				"3 LETTERS + 1 TELEGRAM"
			)


# =========================================================
# ARCHIVE UI
# =========================================================

func _build_archive_ui() -> void:
	var viewport_size: Vector2 = (
		get_viewport().get_visible_rect().size
	)


	archive_layer = CanvasLayer.new()

	archive_layer.layer = 50

	add_child(
		archive_layer
	)


	var dim := ColorRect.new()

	dim.position = Vector2.ZERO
	dim.size = viewport_size

	dim.color = Color(
		0,
		0,
		0,
		0.87
	)

	archive_layer.add_child(
		dim
	)


	var window := Panel.new()

	window.position = Vector2(
		126,
		55
	)

	window.size = Vector2(
		900,
		545
	)


	var window_style := StyleBoxFlat.new()

	window_style.bg_color = Color("#171719")

	window_style.border_color = Color("#665b49")

	window_style.border_width_left = 1
	window_style.border_width_top = 1
	window_style.border_width_right = 1
	window_style.border_width_bottom = 1


	window.add_theme_stylebox_override(
		"panel",
		window_style
	)


	archive_layer.add_child(
		window
	)


	var heading := Label.new()

	heading.text = (
		"KIYOSHIMA POSTAL COLLECTION"
	)

	heading.position = Vector2(
		28,
		19
	)

	heading.size = Vector2(
		844,
		34
	)

	heading.add_theme_font_size_override(
		"font_size",
		22
	)

	heading.add_theme_color_override(
		"font_color",
		Color("#d7cdb8")
	)

	window.add_child(
		heading
	)


	var heading_rule := ColorRect.new()

	heading_rule.position = Vector2(
		28,
		60
	)

	heading_rule.size = Vector2(
		844,
		1
	)

	heading_rule.color = Color(
		0.45,
		0.40,
		0.32,
		0.50
	)

	window.add_child(
		heading_rule
	)


	document_buttons.clear()


	var available: int = mini(
		recovered_items,
		DOCUMENTS.size()
	)


	for i in range(
		available
	):
		var document: Dictionary = (
			DOCUMENTS[i]
		)


		var button := Button.new()

		button.text = str(
			document["short_title"]
		)

		button.position = Vector2(
			28,
			92 + i * 60
		)

		button.size = Vector2(
			190,
			45
		)

		button.focus_mode = (
			Control.FOCUS_NONE
		)


		var normal := StyleBoxFlat.new()

		normal.bg_color = Color("#202022")

		normal.border_color = Color(
			0.42,
			0.37,
			0.30,
			0.55
		)

		normal.border_width_bottom = 1


		var hover := normal.duplicate()

		hover.bg_color = Color("#302c26")


		var pressed := normal.duplicate()

		pressed.bg_color = Color("#42392d")


		button.add_theme_stylebox_override(
			"normal",
			normal
		)

		button.add_theme_stylebox_override(
			"hover",
			hover
		)

		button.add_theme_stylebox_override(
			"pressed",
			pressed
		)


		button.add_theme_font_size_override(
			"font_size",
			14
		)

		button.add_theme_color_override(
			"font_color",
			Color("#c9bfaa")
		)


		button.pressed.connect(
			_on_document_button_pressed.bind(
				i
			)
		)


		window.add_child(
			button
		)

		document_buttons.append(
			button
		)


	var separator := ColorRect.new()

	separator.position = Vector2(
		245,
		82
	)

	separator.size = Vector2(
		1,
		395
	)

	separator.color = Color(
		0.40,
		0.36,
		0.29,
		0.50
	)

	window.add_child(
		separator
	)


	var paper := Panel.new()

	paper.position = Vector2(
		274,
		82
	)

	paper.size = Vector2(
		598,
		395
	)


	var paper_style := StyleBoxFlat.new()

	paper_style.bg_color = Color("#d8ceb5")

	paper_style.border_color = Color("#8a7c62")

	paper_style.border_width_left = 1
	paper_style.border_width_top = 1
	paper_style.border_width_right = 1
	paper_style.border_width_bottom = 1


	paper.add_theme_stylebox_override(
		"panel",
		paper_style
	)

	window.add_child(
		paper
	)


	archive_title = Label.new()

	archive_title.position = Vector2(
		25,
		17
	)

	archive_title.size = Vector2(
		548,
		31
	)

	archive_title.add_theme_font_size_override(
		"font_size",
		20
	)

	archive_title.add_theme_color_override(
		"font_color",
		Color("#28231d")
	)

	paper.add_child(
		archive_title
	)


	archive_record = Label.new()

	archive_record.position = Vector2(
		25,
		53
	)

	archive_record.size = Vector2(
		548,
		42
	)

	archive_record.add_theme_font_size_override(
		"font_size",
		10
	)

	archive_record.add_theme_color_override(
		"font_color",
		Color("#685e50")
	)

	paper.add_child(
		archive_record
	)


	var paper_rule := ColorRect.new()

	paper_rule.position = Vector2(
		25,
		101
	)

	paper_rule.size = Vector2(
		548,
		1
	)

	paper_rule.color = Color(
		0.30,
		0.26,
		0.20,
		0.44
	)

	paper.add_child(
		paper_rule
	)


	archive_body = RichTextLabel.new()

	archive_body.position = Vector2(
		25,
		117
	)

	archive_body.size = Vector2(
		548,
		252
	)

	archive_body.bbcode_enabled = false

	archive_body.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)

	archive_body.scroll_active = true

	archive_body.add_theme_font_size_override(
		"normal_font_size",
		15
	)

	archive_body.add_theme_color_override(
		"default_color",
		Color("#302a22")
	)

	archive_body.add_theme_constant_override(
		"line_separation",
		3
	)

	paper.add_child(
		archive_body
	)


	no_items_label = Label.new()

	no_items_label.text = (
		"NO CORRESPONDENCE FROM ROUTE 6'S\n"
		+ "FINAL ROUND WAS RECOVERED."
	)

	no_items_label.position = Vector2(
		274,
		220
	)

	no_items_label.size = Vector2(
		598,
		85
	)

	no_items_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	no_items_label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	no_items_label.add_theme_font_size_override(
		"font_size",
		17
	)

	no_items_label.add_theme_color_override(
		"font_color",
		Color("#9b9180")
	)

	window.add_child(
		no_items_label
	)


	var controls := Label.new()

	controls.text = (
		"A / D OR LEFT / RIGHT  SELECT        "
		+ "SPACE / ESC  CLOSE"
	)

	controls.position = Vector2(
		28,
		501
	)

	controls.size = Vector2(
		844,
		22
	)

	controls.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_RIGHT
	)

	controls.add_theme_font_size_override(
		"font_size",
		10
	)

	controls.add_theme_color_override(
		"font_color",
		Color("#766e63")
	)

	window.add_child(
		controls
	)


	archive_layer.visible = false


# =========================================================
# OPEN ARCHIVE
# =========================================================

func _open_archive() -> void:
	modal = ModalType.ARCHIVE


	_set_player_locked(
		true
	)


	sign_layer.visible = false

	archive_layer.visible = true


	if recovered_items <= 0:
		archive_title.visible = false
		archive_record.visible = false
		archive_body.visible = false

		no_items_label.visible = true

	else:
		archive_title.visible = true
		archive_record.visible = true
		archive_body.visible = true

		no_items_label.visible = false


		current_document = clampi(
			current_document,
			0,
			recovered_items - 1
		)


		_show_document(
			current_document
		)


# =========================================================
# CLOSE ARCHIVE
# =========================================================

func _close_archive() -> void:
	archive_layer.visible = false

	sign_layer.visible = true


	modal = ModalType.NONE


	_set_player_locked(
		false
	)


# =========================================================
# DOCUMENT NAVIGATION
# =========================================================

func _show_document(
	index: int
) -> void:
	var available: int = mini(
		recovered_items,
		DOCUMENTS.size()
	)


	if available <= 0:
		return


	current_document = clampi(
		index,
		0,
		available - 1
	)


	var data: Dictionary = (
		DOCUMENTS[
			current_document
		]
	)


	archive_title.text = str(
		data["title"]
	)

	archive_record.text = str(
		data["archive"]
	)

	archive_body.text = str(
		data["body"]
	)


	archive_body.scroll_to_line(
		0
	)


	for i in range(
		document_buttons.size()
	):
		if i == current_document:
			document_buttons[i].modulate = Color(
				1.0,
				0.91,
				0.74,
				1.0
			)

		else:
			document_buttons[i].modulate = (
				Color.WHITE
			)


func _next_document() -> void:
	var amount: int = mini(
		recovered_items,
		DOCUMENTS.size()
	)


	if amount <= 0:
		return


	current_document += 1


	if current_document >= amount:
		current_document = 0


	_show_document(
		current_document
	)


func _previous_document() -> void:
	var amount: int = mini(
		recovered_items,
		DOCUMENTS.size()
	)


	if amount <= 0:
		return


	current_document -= 1


	if current_document < 0:
		current_document = amount - 1


	_show_document(
		current_document
	)


func _on_document_button_pressed(
	index: int
) -> void:
	_show_document(
		index
	)


# =========================================================
# CONFIRM UI
# =========================================================

func _build_confirmation_ui() -> void:
	var viewport_size: Vector2 = (
		get_viewport().get_visible_rect().size
	)


	confirm_layer = CanvasLayer.new()

	confirm_layer.layer = 60

	add_child(
		confirm_layer
	)


	var dim := ColorRect.new()

	dim.position = Vector2.ZERO
	dim.size = viewport_size

	dim.color = Color(
		0,
		0,
		0,
		0.90
	)

	confirm_layer.add_child(
		dim
	)


	var panel := Panel.new()

	panel.position = Vector2(
		316,
		205
	)

	panel.size = Vector2(
		520,
		245
	)


	var style := StyleBoxFlat.new()

	style.bg_color = Color("#171719")

	style.border_color = Color("#6b5e49")

	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1


	panel.add_theme_stylebox_override(
		"panel",
		style
	)


	confirm_layer.add_child(
		panel
	)


	confirm_title = Label.new()

	confirm_title.position = Vector2(
		28,
		30
	)

	confirm_title.size = Vector2(
		464,
		42
	)

	confirm_title.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	confirm_title.add_theme_font_size_override(
		"font_size",
		25
	)

	confirm_title.add_theme_color_override(
		"font_color",
		Color("#ded3bc")
	)

	panel.add_child(
		confirm_title
	)


	confirm_body = Label.new()

	confirm_body.position = Vector2(
		40,
		91
	)

	confirm_body.size = Vector2(
		440,
		62
	)

	confirm_body.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	confirm_body.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	confirm_body.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)

	confirm_body.add_theme_font_size_override(
		"font_size",
		15
	)

	confirm_body.add_theme_color_override(
		"font_color",
		Color("#aaa18f")
	)

	panel.add_child(
		confirm_body
	)


	confirm_controls = Label.new()

	confirm_controls.position = Vector2(
		30,
		184
	)

	confirm_controls.size = Vector2(
		460,
		28
	)

	confirm_controls.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	confirm_controls.add_theme_font_size_override(
		"font_size",
		11
	)

	confirm_controls.add_theme_color_override(
		"font_color",
		Color("#80776a")
	)

	panel.add_child(
		confirm_controls
	)


	confirm_layer.visible = false


# =========================================================
# TRY AGAIN CONFIRM
# =========================================================

func _open_retry_confirmation() -> void:
	modal = ModalType.RETRY_CONFIRM


	_set_player_locked(
		true
	)


	sign_layer.visible = false


	confirm_title.text = (
		"TRY AGAIN?"
	)


	confirm_body.text = (
		"Return to the beginning and run Route 6 again."
	)


	confirm_controls.text = (
		"SPACE / ENTER  BEGIN AGAIN        ESC  RETURN"
	)


	confirm_layer.visible = true


# =========================================================
# LEAVE CONFIRM
# =========================================================

func _open_leave_confirmation() -> void:
	modal = ModalType.LEAVE_CONFIRM


	_set_player_locked(
		true
	)


	sign_layer.visible = false


	confirm_title.text = (
		"LEAVE?"
	)


	confirm_body.text = (
		"Leave the archive and end the game."
	)


	confirm_controls.text = (
		"SPACE / ENTER  LEAVE        ESC  RETURN"
	)


	confirm_layer.visible = true


func _close_confirmation() -> void:
	confirm_layer.visible = false

	sign_layer.visible = true


	modal = ModalType.NONE


	_set_player_locked(
		false
	)


# =========================================================
# RESTART GAME
# =========================================================

func _restart_game() -> void:
	modal = ModalType.ENDING


	confirm_layer.visible = false


	Global.minigames_done = 0
	Global.lives = 4


	if MusicManager.has_method(
		"stop_gameplay"
	):
		MusicManager.call(
			"stop_gameplay"
		)


	await _fade_to_black(
		0.55
	)


	var main_scene_path: String = str(
		ProjectSettings.get_setting(
			"application/run/main_scene",
			""
		)
	)


	if main_scene_path.is_empty():
		push_error(
			"No project Main Scene is configured."
		)

		fade_rect.color.a = 0.0

		sign_layer.visible = true

		modal = ModalType.NONE


		_set_player_locked(
			false
		)

		return


	get_tree().change_scene_to_file(
		main_scene_path
	)


# =========================================================
# END GAME
# =========================================================

func _end_game() -> void:
	modal = ModalType.ENDING


	confirm_layer.visible = false


	_set_player_locked(
		true
	)


	if MusicManager.has_method(
		"stop_gameplay"
	):
		MusicManager.call(
			"stop_gameplay"
		)


	await _fade_to_black(
		1.0
	)


	await get_tree().create_timer(
		0.35
	).timeout


	get_tree().quit()


# =========================================================
# PLAYER LOCK
# =========================================================

func _set_player_locked(
	locked: bool
) -> void:
	if player == null:
		return


	if locked:
		player.velocity = Vector2.ZERO

		player.set_physics_process(
			false
		)

	else:
		player.set_physics_process(
			true
		)


# =========================================================
# FADE
# =========================================================

func _build_fade_layer() -> void:
	var viewport_size: Vector2 = (
		get_viewport().get_visible_rect().size
	)


	fade_layer = CanvasLayer.new()

	fade_layer.layer = 100

	add_child(
		fade_layer
	)


	fade_rect = ColorRect.new()

	fade_rect.position = Vector2.ZERO
	fade_rect.size = viewport_size

	fade_rect.color = Color(
		0,
		0,
		0,
		0
	)

	fade_rect.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)


	fade_layer.add_child(
		fade_rect
	)


func _fade_to_black(
	duration: float
) -> void:
	var tween := create_tween()


	tween.set_trans(
		Tween.TRANS_SINE
	)

	tween.set_ease(
		Tween.EASE_IN_OUT
	)


	tween.tween_property(
		fade_rect,
		"color:a",
		1.0,
		duration
	)


	await tween.finished


# =========================================================
# STATIC COLLISION
# =========================================================

func _make_static_rect(
	rect: Rect2
) -> void:
	var body := StaticBody2D.new()


	body.position = (
		rect.position
		+ rect.size / 2.0
	)


	body.collision_layer = 1
	body.collision_mask = 0


	var collision := CollisionShape2D.new()


	var shape := RectangleShape2D.new()

	shape.size = rect.size


	collision.shape = shape


	body.add_child(
		collision
	)


	add_child(
		body
	)


# =========================================================
# DRAW RECT
# =========================================================

func _add_rect(
	rect: Rect2,
	color: Color,
	z: int
) -> Polygon2D:
	var polygon := Polygon2D.new()


	polygon.polygon = PackedVector2Array([
		rect.position,

		rect.position + Vector2(
			rect.size.x,
			0
		),

		rect.position + rect.size,

		rect.position + Vector2(
			0,
			rect.size.y
		)
	])


	polygon.color = color

	polygon.z_index = z


	add_child(
		polygon
	)


	return polygon


# =========================================================
# DRAW BORDER
# =========================================================

func _add_rect_border(
	rect: Rect2,
	color: Color,
	width: float,
	z: int
) -> void:
	_add_rect(
		Rect2(
			rect.position,
			Vector2(
				rect.size.x,
				width
			)
		),
		color,
		z
	)


	_add_rect(
		Rect2(
			Vector2(
				rect.position.x,
				rect.position.y
				+ rect.size.y
				- width
			),
			Vector2(
				rect.size.x,
				width
			)
		),
		color,
		z
	)


	_add_rect(
		Rect2(
			rect.position,
			Vector2(
				width,
				rect.size.y
			)
		),
		color,
		z
	)


	_add_rect(
		Rect2(
			Vector2(
				rect.position.x
				+ rect.size.x
				- width,
				rect.position.y
			),
			Vector2(
				width,
				rect.size.y
			)
		),
		color,
		z
	)


# =========================================================
# DRAW LINE
# =========================================================

func _add_line(
	from: Vector2,
	to: Vector2,
	color: Color,
	width: float,
	z: int
) -> void:
	var line := Line2D.new()


	line.points = PackedVector2Array([
		from,
		to
	])


	line.width = width

	line.default_color = color

	line.z_index = z


	add_child(
		line
	)
