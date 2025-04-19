extends Node2D
var players_joined: bool = false

@onready var enemy_spawner = $EnemyInstantiator

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_timer_timeout() -> void:
	if !GDSync.is_gdsync_owner(self):
		return
	var player_count = 0
	for child in get_children():
		if child.is_in_group("player"):
			player_count += 1
	if players_joined:
		if player_count >= 2:
			var enemy = enemy_spawner.instantiate_node()
			# Random position within a reasonable range of the screen
			var random_x = randi_range(-500, 500)
			var random_y = randi_range(-500, 500)
			enemy.global_position = Vector2(random_x, random_y)
			print("spawning enemy at ", enemy.global_position)
