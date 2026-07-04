extends CharacterBody2D

const SPEED = 60
var cur_dir = "none"

var scripted = false

func _ready():
	$AnimatedSprite2D.play("side")

func _physics_process(delta):
	if !scripted:
		player_movement(delta)

	move_and_slide()

func player_movement(delta):
	if Input.is_action_pressed("ui_right") || Input.is_key_pressed(KEY_D):
		cur_dir = "right"
		play_anim(1)
		velocity.x = SPEED
		velocity.y = 0
	elif Input.is_action_pressed("ui_up") || Input.is_key_pressed(KEY_W):
		cur_dir = "up"
		play_anim(1)
		velocity.x = 0
		velocity.y = -SPEED
	elif Input.is_action_pressed("ui_down") || Input.is_key_pressed(KEY_S):
		cur_dir = "down"
		play_anim(1)
		velocity.x = 0
		velocity.y = SPEED
	else:
		velocity.x = 0
		velocity.y = 0
		play_anim(0)

func play_anim(movement):
	var dir = cur_dir
	var anim = $AnimatedSprite2D

	if dir == "right":
		anim.flip_h = false
		if movement == 1:
			anim.play("side")
	elif dir == "up":
		if movement == 1:
			anim.play("back")
		elif movement == 0:
			anim.play("idle")
	elif dir == "down":
		if movement == 1:
			anim.play("front")


func walk(direction: String):
	scripted = true

	match direction:
		"right":
			cur_dir = "right"
			velocity = Vector2.RIGHT * SPEED
		"left":
			cur_dir = "right"
			$AnimatedSprite2D.flip_h = true
			velocity = Vector2.LEFT * SPEED
		"up":
			cur_dir = "up"
			velocity = Vector2.UP * SPEED
		"down":
			cur_dir = "down"
			velocity = Vector2.DOWN * SPEED

	play_anim(1)

func stop():
	scripted = false
	velocity = Vector2.ZERO
	play_anim(0)
