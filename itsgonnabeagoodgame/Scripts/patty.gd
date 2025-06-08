extends RigidBody2D

signal patty_landed

var has_landed = false
var landing_check_timer = 0.0
var velocity_threshold = 10.0
var landing_check_duration = 0.1

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 10

	collision_layer = 1
	collision_mask = 1
	
	print("Patty sprite node exists: ", sprite != null)
	if sprite:
		print("Current sprite texture: ", sprite.texture)


func _physics_process(delta: float):
	if not has_landed:
		var current_velocity = linear_velocity.length()

		if current_velocity < velocity_threshold:
			landing_check_timer += delta
			if landing_check_timer >= landing_check_duration:
				_land()
		else:
			landing_check_timer = 0.0

func _land():
	if not has_landed:
		has_landed = true

		freeze = true
		freeze_mode = RigidBody2D.FREEZE_MODE_STATIC

		patty_landed.emit()
		print("PATTY HAS LANDED")

		modulate = Color(0.9, 0.9, 0.9, 1.0)

func set_patty_sprite(texture: Texture2D):
	if texture and sprite:
		sprite.texture = texture
	else:
		print("FAILED TO SET PATTY TEXTURE")
