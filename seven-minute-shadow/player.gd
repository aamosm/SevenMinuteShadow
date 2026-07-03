extends CharacterBody2D


const SPEED = 100
var cur_dir = "none"
func _physics_process(delta):
	player_movement(delta)

func player_movement(delta):
	if Input.is_action_pressed("ui_right") || Input.is_key_pressed(KEY_D):
		cur_dir = "right"
		play_anim(1)
		velocity.x = SPEED
		velocity.y = 0
	elif Input.is_action_pressed("ui_left") || Input.is_key_pressed(KEY_A):
		cur_dir = "left"
		play_anim(1)
		velocity.x = -SPEED
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
	move_and_slide()

func play_anim(movement):
	var dir = cur_dir
	var anim = $AnimatedSprite2D
	if dir == "right":
		anim.flip_h = false
		if movement == 1:
			anim.play("side_walk")
		elif movement == 0:
			anim.play("side_idle")
	elif dir == "left":
		anim.flip_h = true
		if movement == 1:
			anim.play("side_walk")
		elif movement == 0:
			anim.play("side_idle")
	elif dir == "up":
		if movement == 1:
			anim.play("back_walk")
		elif movement == 0:
			anim.play("back_idle")
	elif dir == "down":
		if movement == 1:
			anim.play("front_walk")
		elif movement == 0:
			anim.play("front_idle")
