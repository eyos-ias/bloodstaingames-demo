extends Node

signal is_not_active

func _ready():
	GDSync.connection_failed.connect(connection_failed)


var check_timer: float = 0.0

func _process(delta: float) -> void:
	check_timer += delta
	if check_timer >= 5.0:
		check_timer = 0.0
		if GDSync.is_active():
			print("is active")
		else:
			print("is not active")
			is_not_active.emit()
func connection_failed(error: int):
	match (error):
		ENUMS.CONNECTION_FAILED.INVALID_PUBLIC_KEY:
			push_error("The public or private key you entered were invalid.")
		ENUMS.CONNECTION_FAILED.TIMEOUT:
			push_error("Unable to connect, please check your internet connection.")
