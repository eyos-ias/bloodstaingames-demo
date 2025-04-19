extends Node2D

@onready var health_label: Label = $HealthLabel
var health: int = 5


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	health_label.text = str(health)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.is_in_group("bullet"):
		print("i got shot")
		health -= 1
		health_label.text = str(health)
		if health <= 0:
			queue_free()
