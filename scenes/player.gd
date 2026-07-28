extends CharacterBody2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

const WALK_SPEED := 80.0
const RUN_SPEED := 160.0
const ACCELERATION := 900.0
const FRICTION := 700.0
const AIR_ACCEL := 450.0
const AIR_FRICTION := 50.0
const JUMP_VEL := -330.0
const GRAVITY := 1100.0

func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	handle_jump()
	handle_movement(delta)
	move_and_slide()
	update_animation()

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

func handle_jump() -> void:
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VEL

func handle_movement(delta: float) -> void:
	var dir := Input.get_axis("ui_left", "ui_right")
	var running := Input.is_action_pressed("ui_shift")
	var target := (RUN_SPEED if running else WALK_SPEED) * dir

	var accel := ACCELERATION if is_on_floor() else AIR_ACCEL
	var friction := FRICTION if is_on_floor() else AIR_FRICTION

	if dir != 0:
		velocity.x = move_toward(velocity.x, target, accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)

func update_animation() -> void:
	var moving := absf(velocity.x) > 10.0

	if moving and is_on_floor():
		sprite.flip_h = velocity.x < 0
		if Input.is_action_pressed("ui_shift"):
			sprite.play("run")
		else:
			sprite.play("walk")
	else:
		sprite.play("idle")
