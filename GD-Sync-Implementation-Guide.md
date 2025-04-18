# GD-Sync Implementation Guide

This document provides a detailed overview of how GD-Sync is implemented in this demo project and how you can implement it in your own Godot projects.

## How GD-Sync is Used in This Project

### 1. Connection Management

In `main_menu.gd`, the initial connection to GD-Sync servers is established:

```gdscript
# Connect signals for server connection
GDSync.connected.connect(connected)
GDSync.connection_failed.connect(connection_failed)

func _on_connect_pressed():
    # Initiate connection to GD-Sync servers
    GDSync.start_multiplayer()
```

### 2. Player Customization

The `player_customization_menu.gd` handles player data:

```gdscript
# Set the player's username and data
GDSync.player_set_username(%Username.text)
GDSync.player_set_data("Color", %Color.color)
```

### 3. Lobby System

#### Creating Lobbies
In `lobby_creator.gd`:

```gdscript
# Create a new lobby with custom options
GDSync.lobby_create(
    %LobbyName.text,
    %Password.text,
    %Visible.button_pressed,
    %PlayerLimit.value,
    {
        "Gamemode" : "Co-op"
    }
)
```

#### Joining Lobbies
In `lobby_joiner.gd`:

```gdscript
# Join an existing lobby
GDSync.lobby_join(%JoinName.text, %JoinPassword.text)
```

#### Lobby Management
In `lobby.gd`:

```gdscript
# Show players in the lobby
for clientID in GDSync.lobby_get_all_clients():
    client_joined(clientID)

# Start the game (host only)
func _on_start_pressed():
    GDSync.lobby_close()
    GDSync.change_scene("res://Main.tscn")
```

### 4. In-Game Player Management

In `Main.gd`, players are instantiated and managed:

```gdscript
func _enter_tree():
    # Connect signals
    GDSync.client_joined.connect(client_joined)
    GDSync.client_left.connect(client_left)
    GDSync.disconnected.connect(disconnected)
    
    # Add existing players
    for id in GDSync.lobby_get_all_clients():
        client_joined(id)

func client_joined(client_id : int):
    # Create player instance
    var player = PLAYER_SCENE.instantiate()
    player.name = str(client_id)
    player.position = $StartLocation.position
    add_child(player)
    
    # Set ownership
    GDSync.set_gdsync_owner(player, client_id)
```

### 5. Synchronizing Player Data

In `Player.tscn`, several GD-Sync components are used:

```gdscript
# Property synchronizer for position/rotation
[node name="PropertySynchronizer" type="Node" parent="."]
script = ExtResource("2_gal3n")
broadcast = 2
process = 1
refresh_rate = 20
node_path = NodePath("..")
properties = PackedStringArray("position", "basis")
interpolated = true
interpolation_speed = 15.0

# Node instantiator for bullets
[node name="BulletInstantiator" type="Node" parent="."]
script = ExtResource("3_evbh7")
target_location = NodePath("")
scene = ExtResource("4_v05f3")
replicate_on_join = true
sync_starting_changes = true
```

In `Player.gd`, player-specific functions are exposed and GD-Sync is used to determine ownership:

```gdscript
func _ready():
    # Expose functions for remote calls
    GDSync.expose_func(attack)
    GDSync.expose_func(apply_damage)
    GDSync.expose_func(damage)
    
    # Player model customization based on GD-Sync data
    var client_id = name.to_int()
    _character_skin.set_color(GDSync.player_get_data(client_id, "Color", Color.WHITE))
    _username.text = GDSync.player_get_data(client_id, "Username", "Unkown")
    _username.visible = !GDSync.is_gdsync_owner(self)

func _physics_process(delta):
    # Only process inputs for the local player
    if !GDSync.is_gdsync_owner(self): return
    
    # Movement logic...
```

## Implementing GD-Sync in Your Own Project

### 1. Installation and Setup

1. Install the GD-Sync addon:
   - Through the Godot Asset Library
   - Or download from the [GD-Sync website](https://www.gd-sync.com/)

2. Enable the addon:
   - Project → Project Settings → Plugins → Enable GD-Sync

3. Configure API keys:
   - Project → Tools → GD-Sync
   - Enter your Public and Private API keys

### 2. Connection Management

Create a main menu scene that handles connection to GD-Sync servers:

```gdscript
extends Control

func _ready():
    # Connect signals
    GDSync.connected.connect(on_connected)
    GDSync.connection_failed.connect(on_connection_failed)

func _on_connect_button_pressed():
    # Start connection
    GDSync.start_multiplayer()
    $StatusLabel.text = "Connecting..."

func on_connected():
    # Successfully connected
    $StatusLabel.text = "Connected!"
    # Navigate to lobby or player customization

func on_connection_failed(error):
    # Connection failed
    $StatusLabel.text = "Connection failed: " + str(error)
```

### 3. Player Customization and Data

Create a player customization system:

```gdscript
extends Control

func _on_continue_pressed():
    # Save player data
    GDSync.player_set_username($UsernameInput.text)
    GDSync.player_set_data("CharacterType", $CharacterSelect.selected)
    
    # Additional player data
    var player_data = {
        "Color": $ColorPicker.color,
        "Weapon": $WeaponSelect.selected
    }
    
    # Set all data at once
    for key in player_data:
        GDSync.player_set_data(key, player_data[key])
    
    # Continue to lobby system
    get_tree().change_scene_to_file("res://scenes/lobby_browser.tscn")
```

### 4. Lobby System

#### Creating a Lobby Browser

```gdscript
extends Control

func _ready():
    # Connect signals
    GDSync.lobbies_received.connect(on_lobbies_received)
    
    # Request lobby list
    refresh_lobbies()

func refresh_lobbies():
    $LobbyList.clear()
    GDSync.get_public_lobbies()

func on_lobbies_received(lobbies):
    $LobbyList.clear()
    
    for lobby in lobbies:
        var text = lobby.name + " (" + str(lobby.player_count) + "/" + str(lobby.max_players) + ")"
        var item = $LobbyList.add_item(text)
        $LobbyList.set_item_metadata(item, lobby.name)
```

#### Creating a Lobby

```gdscript
extends Control

func _ready():
    GDSync.lobby_created.connect(on_lobby_created)
    GDSync.lobby_creation_failed.connect(on_lobby_creation_failed)

func _on_create_button_pressed():
    var lobby_name = $NameInput.text
    var password = $PasswordInput.text
    var is_public = $PublicCheckbox.pressed
    var player_limit = $PlayerLimitSpinner.value
    
    # Create the lobby
    GDSync.lobby_create(lobby_name, password, is_public, player_limit)

func on_lobby_created(lobby_name):
    get_tree().change_scene_to_file("res://scenes/lobby.tscn")

func on_lobby_creation_failed(lobby_name, error):
    $StatusLabel.text = "Failed to create lobby: " + str(error)
```

#### Joining a Lobby

```gdscript
func _on_join_button_pressed():
    var selected = $LobbyList.get_selected_items()
    if selected.size() == 0: return
    
    var lobby_name = $LobbyList.get_item_metadata(selected[0])
    var password = $PasswordInput.text
    
    # Join the lobby
    GDSync.lobby_join(lobby_name, password)
```

### 5. Player Synchronization

#### Basic Character Scene Setup

1. Create a character scene with these components:
   - Main node (e.g., CharacterBody2D)
   - PropertySynchronizer node for position/rotation
   - NodeInstantiator for projectiles/items (if needed)
   - Visual representation (sprite, animation)

```gdscript
# Character scene structure
- Player (CharacterBody2D)
  |- PropertySynchronizer (Node)
  |- Sprite
  |- CollisionShape
  |- AnimationPlayer
  |- ProjectileSpawner (NodeInstantiator)
```

2. Configure the PropertySynchronizer:
   - Add it as a child node of your character
   - Set the node_path to point to the parent node
   - Select properties to synchronize (position, rotation, etc.)
   - Configure sync mode (broadcast to all vs. authoritative)
   - Enable interpolation for smooth movement

3. Character Movement Script:

```gdscript
extends CharacterBody2D

func _ready():
    # Only process input for the local player
    set_process_input(GDSync.is_gdsync_owner(self))
    set_physics_process(GDSync.is_gdsync_owner(self))
    
    # Set player appearance based on player data
    var client_id = name.to_int()
    $Sprite.modulate = GDSync.player_get_data(client_id, "Color", Color.WHITE)
    $NameLabel.text = GDSync.player_get_data(client_id, "Username", "Player")

func _physics_process(delta):
    # Only the owning client processes movement
    if !GDSync.is_gdsync_owner(self): return
    
    # Movement code...
    var input_vector = Vector2(
        Input.get_axis("ui_left", "ui_right"),
        Input.get_axis("ui_up", "ui_down")
    )
    
    velocity = input_vector.normalized() * speed
    move_and_slide()
```

### 6. Game Manager

Create a main game scene that manages players:

```gdscript
extends Node2D

var player_scene = preload("res://scenes/player.tscn")

func _ready():
    # Connect signals
    GDSync.client_joined.connect(on_client_joined)
    GDSync.client_left.connect(on_client_left)
    GDSync.disconnected.connect(on_disconnected)
    
    # Spawn existing players
    for client_id in GDSync.lobby_get_all_clients():
        spawn_player(client_id)

func on_client_joined(client_id):
    spawn_player(client_id)

func on_client_left(client_id):
    if has_node(str(client_id)):
        get_node(str(client_id)).queue_free()

func on_disconnected():
    get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func spawn_player(client_id):
    var player = player_scene.instantiate()
    player.name = str(client_id)
    player.position = $SpawnPoint.position
    add_child(player)
    
    # Set ownership
    GDSync.set_gdsync_owner(player, client_id)
```

### 7. Remote Function Calls

For actions that need to be synchronized:

```gdscript
func _ready():
    # Expose functions for remote calls
    GDSync.expose_func(fire_weapon)
    GDSync.expose_func(take_damage)

func _on_fire_button_pressed():
    # Call locally
    fire_weapon()
    
    # Call on all clients
    GDSync.call_func_on_all(fire_weapon)
    
    # Or call on a specific client
    GDSync.call_func_on(other_client_id, take_damage, [damage_amount])

func fire_weapon():
    # Weapon firing logic
    var bullet = $ProjectileSpawner.instantiate_node()
    bullet.global_position = $FirePoint.global_position
    bullet.direction = $FirePoint.global_transform.x

func take_damage(amount):
    health -= amount
    if health <= 0:
        die()
```

### 8. Synced Objects with NodeInstantiator

For projectiles, pickups, or other synced objects:

```gdscript
# Scene structure
- Bullet (Area2D)
  |- PropertySynchronizer
  |- Sprite
  |- CollisionShape

# Bullet script
extends Area2D

var speed = 500
var direction = Vector2.RIGHT
var shooter_id = -1

func _ready():
    # Expose functions
    GDSync.expose_func(hit_target)

func _physics_process(delta):
    position += direction * speed * delta

func hit_target(target_id):
    # Handle hit logic
    queue_free()

func _on_body_entered(body):
    if body.has_method("take_damage") and GDSync.is_gdsync_owner(self):
        var target_id = body.name.to_int()
        
        # Call remotely
        GDSync.call_func_on_all(hit_target, [target_id])
        
        # Apply damage to the target
        body.take_damage(10)
```

## Advanced Features

### Game State Synchronization

Use lobby data to synchronize game state:

```gdscript
# Set game state
GDSync.lobby_set_data("game_state", "in_progress")
GDSync.lobby_set_data("score", current_score)

# Listen for changes
func _ready():
    GDSync.lobby_data_changed.connect(on_lobby_data_changed)

func on_lobby_data_changed(key, value):
    if key == "game_state":
        handle_game_state_change(value)
    elif key == "score":
        update_score_display(value)
```

### Host Authority

Implement host-based authority:

```gdscript
func _ready():
    # Listen for host changes
    GDSync.host_changed.connect(on_host_changed)

func on_host_changed(is_host, host_id):
    # Update UI or game logic based on host status
    $HostControls.visible = is_host
    
    if is_host:
        # Take control of game timing or AI
        start_game_loop()

# Functions that only the host should execute
func spawn_enemy():
    if !GDSync.is_host(): return
    
    var enemy = $EnemySpawner.instantiate_node()
    # Configure enemy...
```

### Synchronized Scene Changes

Change scenes for all players simultaneously:

```gdscript
func start_game():
    if !GDSync.is_host(): return
    
    # Close lobby to prevent new joins
    GDSync.lobby_close()
    
    # Change scene for all players
    GDSync.change_scene("res://scenes/game.tscn")
```

## Common Challenges and Solutions

### Network Latency

- Use interpolation in PropertySynchronizer for smooth movement
- Implement prediction for player movement
- Adjust "interpolation_speed" based on your game's needs

### Authority Management

- For competitive games, make the host authoritative
- For cooperative games, let each player control their character
- Use PropertySynchronizer's "broadcast" setting to determine authority

### Optimizing Network Usage

- Only synchronize essential properties
- Use appropriate refresh rates (lower for less important objects)
- Configure "Delta Threshold" in PropertySynchronizer to reduce updates for minor changes

## Debugging Tips

- Use `GDSync.debug_print_clients()` to view connected clients
- Test locally by running multiple instances of your game
- Implement debug visualization for network state
- Check the Godot console for GD-Sync error messages 