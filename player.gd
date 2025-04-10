extends CharacterBody2D

@onready var animation_player_lower: AnimationPlayer = $AnimationPlayerLower
@onready var animation_player_upper: AnimationPlayer = $AnimationPlayerUpper
@onready var animation_player_sword: AnimationPlayer = $AnimationPlayerSword
@onready var anchor: Node2D = $Anchor

# should lock animation updates wait until done
var locked_states: Array = ["attack1", "attack2", "jump", "doubleJumpFlip"]

var current_action: String = "idle"

var facing_dir: int = 1

# Attack variables
var attacking: bool = false
var preAttack: bool = false
var currentAttack: int = 1
var maxAttackChain: int = 1  # increase TODO

# Jump
var flipMax: int = 1
var flipCur: int = 0

# speeds
var groundMoveSpeed: float = 80
var sprintPercentIncrease: float = 2
var airMoveSpeed: float = 50

func _ready() -> void:
	animation_player_upper.animation_finished.connect(func(animationName: String):
		if animationName.begins_with("attack"):
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
	)

func _physics_process(delta: float) -> void:
	var x_input: float = Input.get_axis("move_left", "move_right")
	if Input.is_action_just_released("sprint"): #or sprint duration ran out
		set_animation_speed_scale(1)
	# facing direction
	if abs(x_input) > 0.1:
		facing_dir = sign(x_input)
	anchor.scale.x = facing_dir
	
	# grounded state
	if is_on_floor():
		if x_input == 0:
			velocity = Vector2(0,0)
		flipCur = 0  # Reset the double jump
		
		# Change animation if not in a locked state
		if !(current_action in locked_states):
			if Input.is_action_just_pressed("jump"):
				# Immediately apply jump velocity TODO
				velocity.y = -150
				set_animations("jump")
			elif Input.is_action_just_pressed("attack"):
				attack(1)
			elif abs(x_input) > 0.1:
				if Input.is_action_pressed("sprint"):
					velocity.x = x_input * groundMoveSpeed * sprintPercentIncrease
					set_animation_speed_scale(sprintPercentIncrease)
				else:
					velocity.x = x_input * groundMoveSpeed
					set_animations("run")
			else:
				set_animations("idle")
	#not on ground
	else:
		velocity.x = x_input * airMoveSpeed
		if !(current_action in locked_states):
			set_animations("fall")
		
		# double jump flip
		if Input.is_action_just_pressed("jump") && flipCur < flipMax:
			flipCur += 1
			velocity.y = -200  # Upward impulse for double jump flip.
			set_animations("doubleJumpFlip")
		# Allow attack input in air if not already in an attack state.
		elif Input.is_action_just_pressed("attack") && (!current_action.begins_with("attack")):
			attack(1)
		else:
			velocity.y += 450 * delta  # Apply gravity
	
	if current_action.begins_with("attack"):
		if Input.is_action_just_pressed("attack"):
			preAttack = true
	
	move_and_slide()
	
	if current_action.begins_with("attack") && (!animation_player_upper.is_playing()):
		if is_on_floor():
			set_animations("idle")
		else:
			set_animations("fall")

func attack(currentAttack: int) -> void:
	attacking = true
	set_animations("attack" + str(currentAttack))
	# TODO hit detection

func set_animations(anim_name: String) -> void:
	# Only update if the requested animation is different and not already playing
	if current_action == anim_name && animation_player_lower.current_animation == anim_name && animation_player_lower.is_playing():
		return
	current_action = anim_name
	animation_player_lower.play(anim_name)
	animation_player_upper.play(anim_name)
	animation_player_sword.play(anim_name)

func set_animation_speed_scale(new_scale: float) -> void:
	animation_player_lower.speed_scale = new_scale
	animation_player_upper.speed_scale = new_scale
	animation_player_sword.speed_scale = new_scale
