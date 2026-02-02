extends CharacterBody2D


const SPEED = 100.0



func _physics_process(delta: float) -> void:
	process_movement()
	move_and_slide()
	
func process_movement() -> void:
		# Get the input direction and handle the movement/deceleration.
	var direction := Input.get_vector("left", "right", "up", "down")
	if direction != Vector2.ZERO:
		velocity = direction * SPEED
	else:
		velocity = Vector2.ZERO
