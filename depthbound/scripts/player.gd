extends CharacterBody2D


const walkSPEED = 100.0
const runSPEED = 150.0



var is_mining: bool = false
var hitbox_offset: Vector2
var last_direction: Vector2 = Vector2.RIGHT
var detected_rocks: Array = []

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox
@onready var hitbox_collision_shape_2d: CollisionShape2D = $Hitbox/CollisionShape2D

func _ready() -> void:
	hitbox_offset = hitbox.position  # Initialise hitbox offset

func _physics_process(_delta: float) -> void:
	
	# Handle mining input
	if Input.is_action_just_pressed("use_pickaxe"):
		use_pickaxe()
		
	# Skip movement if mining
	if is_mining:
		velocity = Vector2.ZERO
		return
	
	process_movement()
	process_animation()
	move_and_slide()
	
#--------------------------------------------------------------------
# MOVEMENT AND ANIMATIONS
#--------------------------------------------------------------------

func process_movement() -> void:
		# Get the input direction and handle the movement/deceleration.
	var direction := Input.get_vector("left", "right", "up", "down")
	var speed = runSPEED if Input.is_action_pressed("sprint") else walkSPEED
	
	if direction != Vector2.ZERO:
		velocity = direction * speed
		last_direction = direction
		update_hitbox_position()
	else:
		velocity = Vector2.ZERO

		
func process_animation() -> void:
	# Disable hitbox until player swings pickaxe
	hitbox.monitoring = false
	
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
		
#--------------------------------------------------------------------
# HITBOX OFFSET
#--------------------------------------------------------------------

func update_hitbox_position() -> void:
	var x := hitbox_offset.x
	var y := hitbox_offset.y
	
	match last_direction:
		Vector2.LEFT:
			hitbox.position = Vector2(-x, y)
			hitbox_collision_shape_2d.rotation_degrees = 0
		Vector2.RIGHT:
			hitbox.position = Vector2(x, y)
			hitbox_collision_shape_2d.rotation_degrees = 0
		Vector2.UP:
			hitbox.position = Vector2(y, -x)
			hitbox_collision_shape_2d.rotation_degrees = 90
		Vector2.DOWN:
			hitbox.position = Vector2(y, x)
			hitbox_collision_shape_2d.rotation_degrees = 90


#--------------------------------------------------------------------
#             MINING
#--------------------------------------------------------------------

func use_pickaxe() -> void:
	detected_rocks.clear()
	is_mining = true
	hitbox.monitoring = true
	play_animation("swing_pickaxe", last_direction)


func _on_animated_sprite_2d_animation_finished() -> void:
	if is_mining:
		is_mining = false
		if detected_rocks.size() > 0:
			var rock_to_hit = get_most_overlapping_rock()
			print(rock_to_hit)


func _on_hitbox_body_entered(body: Node2D) -> void:
	if body is Rock:
		detected_rocks.append(body)
		
func get_most_overlapping_rock() -> Rock:
	var best_rock = detected_rocks[0]
	var best_dist = hitbox.global_position.distance_to(best_rock.global_position)
	
	for rock in detected_rocks:
		var dist = hitbox.global_position.distance_to(rock.global_position)
		if dist < best_dist:
			best_dist = dist
			best_rock = rock
			
	return best_rock
