extends Node2D

@export var speed: float = 1000.0
@export var lifetime: float = 2.0

var direction: Vector2
var time_alive: float = 0.0

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	# Move bullet in its direction
	# position += direction * speed * delta
	position += direction * speed * delta
	
	# Track lifetime and destroy when expired
	time_alive += delta
	if time_alive >= lifetime:
		queue_free()
