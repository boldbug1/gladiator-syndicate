extends CharacterBody2D

enum State { IDLE, MOVE, JUMP, ATTACK }

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var state: State = State.IDLE
var facing_dir: float = 1.0 

# --- COMBO SYSTEM ---
var combo_step: int = 0
var combo_timer: float = 0.0
const COMBO_WINDOW: float = 2

# --- MOVEMENT (Smooth & Flowing) ---
const SPEED := 240.0
const ACCEL := 1200.0 # Halved for smoother startup
const FRICTION := 1400.0 # Halved for a natural slide to a stop
const AIR_ACCEL := 800.0
const AIR_FRICTION := 400.0

# --- JUMPING (Natural Arcs) ---
const JUMP_VEL := -420.0
const GRAVITY := 980.0 # Standard, smoother gravity
const FALL_GRAVITY := 1300.0 # Less extreme downward pull

# --- ATTACK FEEL ---
const ATTACK_LUNGE := 150.0 

func _ready() -> void:
	sprite.animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
	if combo_timer > 0:
		combo_timer -= delta
		if combo_timer <= 0:
			combo_step = 0

	apply_gravity(delta)
	handle_jump()
	handle_movement(delta)
	move_and_slide()
	update_state()

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		var current_gravity = FALL_GRAVITY if velocity.y > 0 else GRAVITY
		velocity.y += current_gravity * delta

func handle_jump() -> void:
	if state == State.ATTACK:
		return
		
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VEL
		
	if Input.is_action_just_released("ui_accept") and velocity.y < 0:
		velocity.y *= 0.5 

func handle_movement(delta: float) -> void:
	if state == State.ATTACK:
		# Reduced friction here allows the character to "glide" smoothly during a lunge
		velocity.x = move_toward(velocity.x, 0, FRICTION * 0.4 * delta)
		return

	var dir := Input.get_axis("ui_left", "ui_right")
	
	if dir != 0:
		facing_dir = sign(dir)

	var accel := ACCEL if is_on_floor() else AIR_ACCEL
	var friction := FRICTION if is_on_floor() else AIR_FRICTION

	if dir != 0:
		velocity.x = move_toward(velocity.x, dir * SPEED, accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)

func update_state() -> void:
	if state == State.ATTACK:
		return

	if Input.is_action_just_pressed("ui_attack_1"):
		state = State.ATTACK
		
		if not is_on_floor():
			sprite.play("attack_3")
			combo_step = 0
			return
			
		combo_timer = COMBO_WINDOW
		
		# Smooth forward momentum applied on attack
		velocity.x = facing_dir * ATTACK_LUNGE
		
		if combo_step == 0:
			sprite.play("attack_1")
			combo_step = 1
		elif combo_step == 1:
			sprite.play("attack_2")
			combo_step = 2
		else: 
			sprite.play("attack_3")
			# 3rd hit glides a bit further
			velocity.x = facing_dir * (ATTACK_LUNGE * 1.4) 
			combo_step = 0 
			
		return

	if not is_on_floor():
		state = State.JUMP
		sprite.play("jump")
		if Input.get_axis("ui_left", "ui_right") != 0:
			sprite.flip_h = facing_dir < 0
		return

	var moving := absf(velocity.x) > 10.0
	if moving:
		sprite.flip_h = facing_dir < 0
		state = State.MOVE
		sprite.play("run")
	else:
		state = State.IDLE
		sprite.play("idle")

func _on_animation_finished() -> void:
	if state == State.ATTACK:
		state = State.IDLE
		sprite.play("idle")
