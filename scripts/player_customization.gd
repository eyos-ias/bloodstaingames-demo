extends Control
@onready var line_edit: LineEdit = $VBoxContainer/LineEdit
@onready var host: Button = $VBoxContainer/Host
@onready var join: Button = $VBoxContainer/Join
@onready var creating_lobby: Label = $CreatingLobby
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GDSync.lobby_created.connect(lobby_created)
	GDSync.lobby_joined.connect(lobby_joined)
	GDSync.lobby_join_failed.connect(lobby_join_failed)
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_host_pressed() -> void:
	GDSync.player_set_username(line_edit.text)
	creating_lobby.visible = true
	GDSync.lobby_create("test")


func _on_join_pressed() -> void:
	GDSync.player_set_username(line_edit.text)
	GDSync.lobby_join("test")


func lobby_created(lobby_id: String) -> void:
	print("Hosting lobby", " lobby id: ", lobby_id)
	GDSync.lobby_join(lobby_id)
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func lobby_joined(lobby_id: String) -> void:
	print("Lobby joined: ", lobby_id)
	get_tree().change_scene_to_file("res://scenes/game.tscn")
	# get_tree().change_scene_to_file("res://scenes/game.tscn")

func lobby_join_failed(error: int) -> void:
	print("Lobby join failed: ", error)
