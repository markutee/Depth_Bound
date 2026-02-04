extends CharacterBody2D


const walkSPEED = 100.0
const runSPEED = 150.0

var last_direction: Vector2 = Vector2.RIGHT

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D



func _physics_process(_delta: float) -> void:
	process_movement()
	process_animation()
	move_and_slide()
	
func process_movement() -> void:
		# Get the input direction and handle the movement/deceleration.
	var direction := Input.get_vector("left", "right", "up", "down")
	var speed = runSPEED if Input.is_action_pressed("sprint") else walkSPEED
	
	if direction != Vector2.ZERO:
		velocity = direction * speed
		last_direction = direction
	else:
		velocity = Vector2.ZERO

		
func process_animation() -> void:
	if velocity != Vector2.ZERO:
		play_animation("run", last_direction)
	else:
		play_animation("idle", last_direction)

func play_animation(prefix: String, dir: Vector2) -> void:
	if dir.x !=0:
		animated_sprite_2d.flip_h = dir.x < 0
		animated_sprite_2d.play(prefix + "_right")
	elif dir.y  < 0:
		animated_sprite_2d.play(prefix + "_up")
	elif dir.y  > 0:
		animated_sprite_2d.play(prefix + "_down")
		
		
		
	
