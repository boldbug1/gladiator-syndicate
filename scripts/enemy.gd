extends CharacterBody2D

enum State { IDLE, FOLLOW, ATTACK, HURT }

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var player: CharacterBody2D = null

var state: State = State.IDLE
var prev_state: State = State.IDLE
var health: int = 50
var max_health: int = 50
var attack_cooldown: float = 0.0
var attack_index: int = 0

const FOLLOW_RADIUS: float = 300.0
const ATTACK_RADIUS: float = 35.0
const SPEED: float = 130.0
const ACCEL: float = 800.0
const FRICTION: float = 1000.0
const JUMP_VEL: float = -380.0
const GRAVITY: float = 1200.0
const ATTACK_RATE: float = 1.2
const DAMAGE: int = 10

func _ready() -> void:
	sprite.animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
	if not player:
		player = get_tree().get_first_node_in_group("player")
		if not player:
			return

	if attack_cooldown > 0:
		attack_cooldown -= delta

	if not is_on_floor():
		velocity.y += GRAVITY * delta

	match state:
		State.IDLE:
			handle_idle(delta)
		State.FOLLOW:
			handle_follow(delta)
		State.ATTACK:
			handle_attack(delta)
		State.HURT:
			handle_hurt(delta)

	move_and_slide()

	if state != prev_state:
		var names = ["IDLE", "FOLLOW", "ATTACK", "HURT"]
		print("[ENEMY] %s → %s | HP: %d/%d" % [names[prev_state], names[state], health, max_health])
		prev_state = state

func handle_idle(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
	sprite.play("idle")

	var dist = global_position.distance_to(player.global_position)
	if dist < FOLLOW_RADIUS:
		state = State.FOLLOW

func handle_follow(delta: float) -> void:
	var dir = sign(player.global_position.x - global_position.x)
	velocity.x = move_toward(velocity.x, dir * SPEED, ACCEL * delta)
	sprite.flip_h = dir < 0
	sprite.play("run")

	if is_on_floor() and player.global_position.y < global_position.y - 32:
		velocity.y = JUMP_VEL

	var dist = global_position.distance_to(player.global_position)
	if dist < ATTACK_RADIUS and attack_cooldown <= 0:
		state = State.ATTACK
		velocity.x = 0
		enter_attack()
	elif dist > FOLLOW_RADIUS * 1.5:
		state = State.IDLE

func enter_attack() -> void:
	if attack_index == 0:
		sprite.play("attack")
		attack_index = 1
	else:
		sprite.play("attack_2")
		attack_index = 0
	attack_cooldown = ATTACK_RATE

	# Apply damage to player if not defending
	if player.has_method("take_damage"):
		player.take_damage(DAMAGE, global_position.direction_to(player.global_position))
		print("[ENEMY] Dealt %d damage to player" % DAMAGE)

func handle_attack(_delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0, FRICTION * _delta)
	# Wait for animation_finished to change state

func handle_hurt(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0, FRICTION * delta)

func take_damage(dmg: int) -> void:
	health -= dmg

	if health <= 0:
		print("[ENEMY] Defeated! (HP: 0/%d)" % max_health)
		queue_free()
		return

	state = State.HURT
	sprite.play("hurt")

func _on_animation_finished() -> void:
	match state:
		State.ATTACK:
			if player and global_position.distance_to(player.global_position) < ATTACK_RADIUS and attack_cooldown <= 0:
				enter_attack()
			elif player and global_position.distance_to(player.global_position) < FOLLOW_RADIUS:
				state = State.FOLLOW
			else:
				state = State.IDLE
		State.HURT:
			if player and global_position.distance_to(player.global_position) < FOLLOW_RADIUS:
				state = State.FOLLOW
			else:
				state = State.IDLE
