extends CharacterBody2D

enum State { IDLE, WALK, RUN, JUMP, ATTACK }

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var state: State = State.IDLE

const WALK_SPEED := 80.0
const RUN_SPEED := 160.0
const ACCELERATION := 900.0
const FRICTION := 700.0
const AIR_ACCEL := 450.0
const AIR_FRICTION := 50.0
const JUMP_VEL := -300.0
const GRAVITY := 1200.0

func _ready() -> void:
	sprite.animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	handle_jump()
	handle_movement(delta)
	move_and_slide()
	update_state()

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

func handle_jump() -> void:
	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and state != State.ATTACK:
		velocity.y = JUMP_VEL

func handle_movement(delta: float) -> void:
	if state == State.ATTACK:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta * 0.5)
		return

	var dir := Input.get_axis("ui_left", "ui_right")
	var running := Input.is_action_pressed("ui_shift")
	var target := (RUN_SPEED if running else WALK_SPEED) * dir

	var accel := ACCELERATION if is_on_floor() else AIR_ACCEL
	var friction := FRICTION if is_on_floor() else AIR_FRICTION

	if dir != 0:
		velocity.x = move_toward(velocity.x, target, accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)

func update_state() -> void:
	if state == State.ATTACK:
		return

	if Input.is_action_just_pressed("ui_attack_1") and is_on_floor():
		state = State.ATTACK
		sprite.play("attack_1")
		return

	if not is_on_floor():
		state = State.JUMP
		sprite.play("jump")
		return

	var moving := absf(velocity.x) > 10.0
	if moving:
		sprite.flip_h = velocity.x < 0
		if Input.is_action_pressed("ui_shift"):
			state = State.RUN
			sprite.play("run")
		else:
			state = State.WALK
			sprite.play("walk")
	else:
		state = State.IDLE
		sprite.play("idle")

func _on_animation_finished() -> void:
	if state == State.ATTACK:
		state = State.IDLE
		sprite.play("idle")
