extends CharacterBody2D
class_name Player
const SPEED = 300.0

var client_id: int

func _physics_process(delta: float) -> void:
	# Get input direction for all four directions
	var direction = Vector2.ZERO
	direction.x = Input.get_axis("ui_left", "ui_right")
	direction.y = Input.get_axis("ui_up", "ui_down")
	
	# Normalize diagonal movement to maintain consistent speed
	if direction.length() > 0:
		direction = direction.normalized()
		velocity = direction * SPEED
	else:
		velocity = velocity.move_toward(Vector2.ZERO, SPEED)
	
	move_and_slide()
