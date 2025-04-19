extends CharacterBody2D
class_name Player
const SPEED = 300.0
@onready var camera: Camera2D = $Camera2D
var client_id: int
@onready var animation_player = $SynchronizedAnimationPlayer
@onready var player_name: Label = $PlayerName
@onready var player_sprite: Sprite2D = $Sprite2D
@onready var bullet_instantiator = $BulletInstantiator

const max_speed: int = 600
const acceleration: int = 100
const friction: int = 20

func _ready() -> void:
	GDSync.connect_gdsync_owner_changed(self, owner_changed)
	GDSync.connection_failed.connect(connection_failed)
	print("player_name: ", GDSync.player_get_data(client_id, "Username", "Unkown"))
	player_name.text = GDSync.player_get_data(client_id, "Username", "Unkown")
	animation_player.play("run_horizontal")


func _physics_process(delta: float) -> void:
	# Get input direction for all four directions
	if !GDSync.is_gdsync_owner(self):
		return
	
	if Input.is_action_pressed("attack") and not animation_player.current_animation == "attack_horizontal":
		animation_player.play("attack_horizontal")
	
	if Input.is_action_just_released("attack"):
		var bullet = bullet_instantiator.instantiate_node()
		bullet.global_position = global_position
		bullet.direction = (get_global_mouse_position() - global_position).normalized()
		bullet.rotation = bullet.direction.angle()
		
	var direction = Vector2.ZERO
	# Flip sprite horizontally based on movement direction

	var input = Vector2(Input.get_axis("ui_left", "ui_right"), Input.get_axis("ui_up", "ui_down")).normalized()

	if input:
		if not animation_player.current_animation == "attack_horizontal":
			animation_player.play("run_horizontal")
		player_sprite.flip_h = input.x < 0
	else:
		if not animation_player.current_animation == "attack_horizontal":
			animation_player.play("idle_horizontal")
	
	var lerp_weight = delta * (acceleration if input else friction)

	velocity = lerp(velocity, input * max_speed, lerp_weight)


	move_and_slide()


func owner_changed(new_owner: int) -> void:
	var is_owner: bool = GDSync.is_gdsync_owner(self)
	camera.enabled = is_owner


func connection_failed(error: int):
	print("connection failed")
	match (error):
		ENUMS.CONNECTION_FAILED.TIMEOUT:
			print("Unable to connect, please check your internet connection.")

func _on_synchronized_animation_player_animation_finished(anim_name: StringName) -> void:
	if !GDSync.is_gdsync_owner(self):
		return
