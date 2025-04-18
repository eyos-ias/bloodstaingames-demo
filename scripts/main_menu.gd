extends Control

@onready var connect_button: Button = %Connet
@onready var connecting_label: Label = %ConnectingLabel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GDSync.connected.connect(connected)
	GDSync.connection_failed.connect(connection_failed)
	
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func connected() -> void:
	print("connected")
	get_tree().change_scene_to_file("res://scenes/player_customization.tscn")

func connection_failed(error: int) -> void:
	match (error):
		GDSync.ConnectionError.CONNECTION_ERROR_NONE:
			print("Connection failed: None")
		GDSync.ConnectionError.CONNECTION_ERROR_WRONG_VERSION:
			print("Connection failed: Wrong version")
		GDSync.ConnectionError.CONNECTION_ERROR_WRONG_HOST:
			print("Connection failed: Wrong host")

func _on_connet_pressed() -> void:
	connect_button.disabled = true
	connecting_label.visible = true
	GDSync.start_multiplayer()
