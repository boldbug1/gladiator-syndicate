extends CharacterBody2D

enum State { IDLE, MOVE, JUMP, ATTACK, DEFEND, HURT, DEATH }

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var state: State = State.IDLE
var facing_dir: float = 1.0 

# --- COMBO SYSTEM ---
var combo_step: int = 0
var combo_timer: float = 0.0
const COMBO_WINDOW: float = 1.5

# --- MOVEMENT ---
const SPEED := 280.0
const ACCEL := 1800.0
const FRICTION := 2200.0
const AIR_ACCEL := 1000.0
const AIR_FRICTION := 500.0

# --- JUMPING ---
const JUMP_VEL := -450.0
const GRAVITY := 900.0
const FALL_GRAVITY := 1400.0
const COYOTE_TIME := 0.08
var coyote_timer: float = 0.0

# --- ATTACK ---
const ATTACK_LUNGE := 200.0
const ATTACK_RANGE := 45.0
var attack_connected: bool = false

# --- DEFEND ---
var is_defending: bool = false

# --- HEALTH ---
var health: int = 100
var max_health: int = 100

# --- RESPAWN ---
var spawn_position: Vector2 = Vector2(267, 232)

func _ready() -> void:
	sprite.animation_finished.connect(_on_animation_finished)
	add_to_group("player")

func _physics_process(delta: float) -> void:
	if state == State.DEATH:
		return

	if combo_timer > 0:
		combo_timer -= delta

	apply_gravity(delta)
	handle_jump()
	handle_movement(delta)
	move_and_slide()
	update_state()

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		var current_gravity = FALL_GRAVITY if velocity.y > 0 else GRAVITY
		velocity.y += current_gravity * delta
	elif coyote_timer > 0:
		coyote_timer -= delta

func handle_jump() -> void:
	if state in [State.ATTACK, State.DEFEND, State.HURT]:
		return
		
	if is_on_floor():
		coyote_timer = COYOTE_TIME
	
	if Input.is_action_just_pressed("ui_accept") and coyote_timer > 0:
		velocity.y = JUMP_VEL
		coyote_timer = 0.0
		
	if Input.is_action_just_released("ui_accept") and velocity.y < 0:
		velocity.y *= 0.5 

func handle_movement(delta: float) -> void:
	if state in [State.ATTACK, State.HURT]:
		velocity.x = move_toward(velocity.x, 0, FRICTION * 0.3 * delta)
		return
	if state == State.DEFEND:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
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
	if state in [State.ATTACK, State.HURT]:
		return

	# Defend
	is_defending = Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	if is_defending and is_on_floor():
		if state != State.DEFEND:
			state = State.DEFEND
			sprite.play("defend")
		return

	# Attack input - combo
	if Input.is_action_just_pressed("ui_attack_1"):
		state = State.ATTACK
		attack_connected = false
		combo_timer = COMBO_WINDOW
		
		if not is_on_floor():
			sprite.play("attack_3")
			velocity.x = facing_dir * ATTACK_LUNGE * 1.2
			combo_step = 0
			hit_enemies()
			return
			
		velocity.x = facing_dir * ATTACK_LUNGE
		match combo_step:
			0:
				sprite.play("attack_1")
				combo_step = 1
			1:
				sprite.play("attack_2")
				combo_step = 2
			2:
				sprite.play("attack_3")
				velocity.x = facing_dir * (ATTACK_LUNGE * 1.5)
				combo_step = 0
		hit_enemies()
		return

	# Air state
	if not is_on_floor():
		state = State.JUMP
		sprite.play("jump")
		sprite.flip_h = facing_dir < 0
		return

	# Ground movement
	var moving := absf(velocity.x) > 10.0
	if moving:
		sprite.flip_h = facing_dir < 0
		state = State.MOVE
		sprite.play("run")
	else:
		state = State.IDLE
		sprite.play("idle")

func hit_enemies() -> void:
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy.has_method("take_damage"):
			var dist = global_position.distance_to(enemy.global_position)
			var in_front = (facing_dir > 0 and enemy.global_position.x > global_position.x) or (facing_dir < 0 and enemy.global_position.x < global_position.x)
			if dist < ATTACK_RANGE and in_front:
				var knockback_dir = Vector2(facing_dir, -0.5).normalized()
				enemy.take_damage(25, knockback_dir)
				print("[PLAYER] Hit enemy!")

func take_damage(dmg: int, knockback_dir: Vector2 = Vector2.ZERO) -> void:
	if state == State.DEATH:
		return

	if is_defending:
		state = State.HURT
		sprite.play("defend_hit")
		print("[PLAYER] Blocked! No damage taken")
		return

	health -= dmg
	print("[PLAYER] Hit! HP: %d/%d (damage: %d)" % [health, max_health, dmg])
	state = State.HURT
	sprite.play("hurt")
	velocity += knockback_dir * 200

	if health <= 0:
		die()

func die() -> void:
	state = State.DEATH
	velocity = Vector2.ZERO
	sprite.play("death")
	print("[PLAYER] Defeated! Respawning soon...")

func respawn() -> void:
	health = max_health
	state = State.IDLE
	global_position = spawn_position
	velocity = Vector2.ZERO
	sprite.play("idle")
	print("[PLAYER] Respawned at spawn point")

func _on_animation_finished() -> void:
	match state:
		State.ATTACK, State.HURT:
			state = State.IDLE
			sprite.play("idle")
		State.DEFEND:
			if not is_defending:
				state = State.IDLE
				sprite.play("idle")
		State.DEATH:
			respawn()
