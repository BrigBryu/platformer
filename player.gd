extends CharacterBody2D
@onready var animation_player_lower: AnimationPlayer = $AnimationPlayerLower
@onready var animation_player_upper: AnimationPlayer = $AnimationPlayerUpper
@onready var anchor: Node2D = $Anchor


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animation_player_lower.current_animation_changed.connect(func(animationName: String):
		if animation_player_upper.current_animation.substr(0,6) == "attack":
			return
		animation_player_upper.play(animationName)
		)
	animation_player_upper.animation_finished.connect(func(animationName: String):
		if animationName.substr(0,6) == "attack":
			#set uper to lower animation
			animation_player_upper.play(animation_player_lower.current_animation)
			#if lower was part way through set to same time
			animation_player_upper.seek(animation_player_lower.current_animation_position)
		)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	# Get horizontal input and update horizontal velocity
	var x_input: float = Input.get_axis("ui_left", "ui_right")
	velocity.x = x_input * 80

	# If not on the floor apply gravity and play the jump animation
	if not is_on_floor():
		velocity.y += 450 * delta
		animation_player_lower.play("jump")

	# Jump input
	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = -200
		
	# Attack input
	if Input.is_action_just_pressed("ui_accept"):
		animation_player_upper.play("attack")
		
	# Horizontal movement animations and flipping sprite
	if x_input == 0:
		animation_player_lower.play("stand")
	else:
		anchor.scale.x = sign(x_input)
		animation_player_lower.play("run")
# Move the player using the updated velocity
	move_and_slide()
