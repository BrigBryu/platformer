extends CharacterBody2D

@onready var animation_player_lower: AnimationPlayer = $AnimationPlayerLower
@onready var animation_player_upper: AnimationPlayer = $AnimationPlayerUpper
@onready var animation_player_sword: AnimationPlayer = $AnimationPlayerSword
@onready var anchor: Node2D = $Anchor
@onready var area_attack_1: Area2D = $Anchor/AreaAttack1
@onready var area_attack_2: Area2D = $Anchor/AreaAttack2
@onready var player_collision_shape_2d: CollisionShape2D = $CollisionShape2D

# should lock animation updates wait until done
var locked_states: Array[bool] = [false, false, false]  # [attack1, attack2, doubleJumpFlip]
var locked_states_index_attack1: int = 0
var locked_states_index_attack2: int = 1
var locked_states_index_doubleJumpFlip: int = 2

var current_action: String = "idle"
var facing_dir: int = 1

# Attack variables
var attacking: bool = false
var preAttack: bool = false
var currentAttack: int = 1
var maxAttackChain: int = 2  # increase TODO
var attack_area_on: Array[bool] = [false, false]

# Jump
var flipMax: int = 1
var flipCur: int = 0

# speeds
var groundMoveSpeed: float = 80
var sprintPercentIncrease: float = 2
var airMoveSpeed: float = 50

# sprint
var sprint_max_time: float = 1.0
var sprint_reload_time: float = 0.2
var sprint_timer: float = 0.0

func _ready() -> void:
	animation_player_upper.animation_finished.connect(upper_animation_finished)
	area_attack_1.body_entered.connect(attack_hit)
	area_attack_2.body_entered.connect(attack_hit)

func _physics_process(delta: float) -> void:
	var x_input: float = Input.get_axis("move_left", "move_right")
	
	# Store previous facing direction before updating.
	var prev_facing_dir: int = facing_dir
	# Only update facing direction if not attacking, or if we're about to chain an attack
	if abs(x_input) > 0.1 and (!current_action.begins_with("attack") or preAttack):
		facing_dir = sign(x_input)
	anchor.scale.x = facing_dir
	
	# Handle attack input at any time
	if Input.is_action_just_pressed("attack"):
		if current_action.begins_with("attack"):
			preAttack = true
		else:
			attack(1)
	
	# Handle attack state - no gravity or movement during attacks
	if current_action.begins_with("attack"):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Grounded state: sprint is available only when on the floor.
	if is_on_floor():
		if x_input == 0:
			velocity = Vector2.ZERO
		flipCur = 0  # Reset the double jump
		
		if !is_state_locked():
			if Input.is_action_just_pressed("jump"):
				# Apply jump velocity.
				velocity.y = -150
				set_animations("jump")
			elif abs(x_input) > 0.1:
				# Sprint
				if Input.is_action_pressed("sprint"):
					sprint_timer += delta
					if sprint_timer <= sprint_max_time:
						print("sprint_timer: ", sprint_timer)
						velocity.x = x_input * groundMoveSpeed * sprintPercentIncrease
						set_animation_speed_scale(sprintPercentIncrease)
						set_animations("run")
					else:
						velocity.x = x_input * groundMoveSpeed
						set_animation_speed_scale(1)
						set_animations("run")
				else:
					if sprint_timer - sprint_reload_time > 0:
						sprint_timer -= sprint_reload_time
						print("sprint_timer: ", sprint_timer)
					else:
						sprint_timer = 0
					velocity.x = x_input * groundMoveSpeed
					set_animation_speed_scale(1)
					set_animations("run")
			else:
				set_animations("idle")
	# In-air state: ignore sprint and reset speed scale.
	else:
		set_animation_speed_scale(1)
		velocity.x = x_input * airMoveSpeed
		velocity.y += 450 * delta  # Apply gravity.
		
		# Double jump flip.
		if Input.is_action_just_pressed("jump") and flipCur < flipMax:
			flipCur += 1
			velocity.y = -200  # Upward impulse for double jump flip.
			set_animations("doubleJumpFlip")
		elif current_action != "doubleJumpFlip":
			set_animations("fall")
	
	move_and_slide()
	
	if current_action.begins_with("attack") and (!animation_player_upper.is_playing()):
		if is_on_floor():
			set_animations("idle")
		else:
			set_animations("fall")

func attack(currentAttack: int) -> void:
	attacking = true
	attack_area_on[currentAttack - 1] = true

	set_animations("attack" + str(currentAttack))

func attack_hit(body: Node2D) -> void:
	if body == self:
		return
	if attack_area_on[0] && body.has_method("take_damage"):
		print("attack 1 hit")
	elif attack_area_on[1] && body.has_method("take_damage"):
		print("attack 2 hit")

func upper_animation_finished(animationName: String) -> void:
	if animationName.begins_with("attack"):
		for i in range(attack_area_on.size()):
			attack_area_on[i] = false
		if preAttack:
			currentAttack += 1
			if currentAttack > maxAttackChain:
				currentAttack = 1
			preAttack = false
			attack(currentAttack)
		else:
			currentAttack = 1
			attacking = false
			if is_on_floor():
				set_animations("idle")
			else:
				set_animations("fall")
	elif animationName == "jump":
		if is_on_floor():
			set_animations("idle")
		else:
			set_animations("fall")
	elif animationName == "doubleJumpFlip":
		if is_on_floor():
			set_animations("idle")
		else:
			set_animations("fall")

func set_animations(anim_name: String) -> void:
	# Update animations only if the requested animation differs from the current one.
	if current_action == anim_name and animation_player_lower.current_animation == anim_name and animation_player_lower.is_playing():
		return
	current_action = anim_name
	animation_player_lower.play(anim_name)
	animation_player_upper.play(anim_name)
	animation_player_sword.play(anim_name)

func set_animation_speed_scale(new_scale: float) -> void:
	animation_player_lower.speed_scale = new_scale
	animation_player_upper.speed_scale = new_scale
	animation_player_sword.speed_scale = new_scale

func lock_state(state: String) -> void:
	match state:
		"attack1":
			locked_states[locked_states_index_attack1] = true
		"attack2":
			locked_states[locked_states_index_attack2] = true
		"doubleJumpFlip":
			locked_states[locked_states_index_doubleJumpFlip] = true

func unlock_state(state: String) -> void:
	match state:
		"attack1":
			locked_states[locked_states_index_attack1] = false
		"attack2":
			locked_states[locked_states_index_attack2] = false
		"doubleJumpFlip":
			locked_states[locked_states_index_doubleJumpFlip] = false

func is_state_locked() -> bool:
	for state in locked_states:
		if state:
			return true
	return false
