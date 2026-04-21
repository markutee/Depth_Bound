extends CharacterBody2D
class_name Player

const walkSPEED = 100.0
const runSPEED = 150.0

var is_mining: bool = false
var hitbox_offset: Vector2
var last_direction: Vector2 = Vector2.RIGHT
var detected_rocks: Array = []
var pickaxe_strength: int = 1
var can_move: bool = true

var inventory: Inventory

# Lamp upgrade
var lamp_level: int = 0
var lamp_energy_levels: Array[float] = [0.8, 1, 1.1, 1.2]
var lamp_scale_levels: Array[float] = [0.8, 1.15, 1.3, 1.45]

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox
@onready var hitbox_collision_shape_2d: CollisionShape2D = $Hitbox/CollisionShape2D
@onready var mining_timer: Timer = $MiningTimer
@onready var pickaxe_hit_sound: AudioStreamPlayer2D = $PickaxeHitSound
@onready var point_light_2d: PointLight2D = $PointLight2D

func _ready() -> void:
	hitbox_offset = hitbox.position # Initialise hitbox offset
	inventory = Inventory.new(4) # Create inventory with 4 slots
	update_lamp()

func reset(pos: Vector2) -> void:
	position = pos
	last_direction = Vector2.DOWN
	velocity = Vector2.ZERO
	process_animation()
	update_hitbox_position()

func _physics_process(_delta: float) -> void:
	if !can_move:
		return
	
	# Handle mining input
	if Input.is_action_pressed("use_pickaxe") and mining_timer.is_stopped():
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
	if dir.x != 0:
		animated_sprite_2d.flip_h = dir.x < 0
		animated_sprite_2d.play(prefix + "_right")
	elif dir.y < 0:
		animated_sprite_2d.play(prefix + "_up")
	elif dir.y > 0:
		animated_sprite_2d.play(prefix + "_down")

func die() -> bool:
	animated_sprite_2d.play("death")
	await animated_sprite_2d.animation_finished
	return true

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
# MINING
#--------------------------------------------------------------------

func use_pickaxe() -> void:
	detected_rocks.clear()
	is_mining = true
	hitbox.monitoring = true
	mining_timer.start() # start the cooldown timer
	play_animation("swing_pickaxe", last_direction)

func _on_animated_sprite_2d_animation_finished() -> void:
	if is_mining:
		is_mining = false
		if detected_rocks.size() > 0:
			var rock_to_hit = get_most_overlapping_rock()
			rock_to_hit.take_damage(pickaxe_strength)
			pickaxe_hit_sound.play()

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

func add_ore(data: OreData) -> bool:
	return inventory.add_item(data)

#--------------------------------------------------------------------
# LAMP UPGRADE
#--------------------------------------------------------------------

func upgrade_lamp() -> void:
	if lamp_level >= 3:
		return
	
	lamp_level += 1
	update_lamp()

func update_lamp() -> void:
	point_light_2d.energy = lamp_energy_levels[lamp_level]
	point_light_2d.texture_scale = lamp_scale_levels[lamp_level]
