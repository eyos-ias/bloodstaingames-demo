extends Node2D

@export var player_scene: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GDSync.client_joined.connect(client_joined)
	GDSync.client_left.connect(client_left)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func client_joined(client_id: int) -> void:
	print("Player joined: ", client_id)
	var player: Player = player_scene.instantiate()
	player.position = position
	player.name = str(client_id)

	get_tree().current_scene.add_child(player)
	player.client_id = client_id
	GDSync.set_gdsync_owner(player, client_id)
	get_parent().players_joined = true


func client_left(client_id: int) -> void:
	print("Gonna handle player leaving here")
	# var player: Player = get_tree().current_scene.get_node(str(client_id))
	# if player:
	# 	player.queue_free()
