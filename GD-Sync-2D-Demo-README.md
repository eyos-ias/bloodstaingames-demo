# Building a 2D Multiplayer Game with GD-Sync

This README provides a comprehensive guide to creating a medium-sized 2D multiplayer game using the GD-Sync addon for Godot.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Step 1: Project Setup](#step-1-project-setup)
- [Step 2: GD-Sync Configuration](#step-2-gd-sync-configuration)
- [Step 3: Project Structure](#step-3-project-structure)
- [Step 4: Creating Core Game Elements](#step-4-creating-core-game-elements)
- [Step 5: Implementing Multiplayer](#step-5-implementing-multiplayer)
- [Step 6: Synchronizing Game State](#step-6-synchronizing-game-state)
- [Step 7: Lobby System](#step-7-lobby-system)
- [Step 8: Testing and Deployment](#step-8-testing-and-deployment)
- [Common Issues and Solutions](#common-issues-and-solutions)

## Prerequisites

- Godot Engine 4.x
- Basic understanding of GDScript
- GD-Sync addon (from Godot Asset Library or [GD-Sync website](https://www.gd-sync.com/))
- GD-Sync API keys (register at [GD-Sync website](https://www.gd-sync.com/))

## Step 1: Project Setup

1. Create a new Godot project:
   - Open Godot and click "New Project"
   - Name it "GD-Sync-2D-Demo" (or your preferred name)
   - Choose a location to save the project
   - Select "2D" as the renderer
   - Click "Create & Edit"

2. Install the GD-Sync addon:
   - In Godot, go to AssetLib tab
   - Search for "GD-Sync"
   - Download and install the addon
   - Alternatively, you can download it from the [GD-Sync website](https://www.gd-sync.com/) and extract it into your project's `addons` folder

3. Enable the addon:
   - Go to Project → Project Settings → Plugins
   - Find GD-Sync and check the "Enable" checkbox

## Step 2: GD-Sync Configuration

1. Configure your API keys:
   - Go to Project → Tools → GD-Sync
   - Enter your Public and Private API keys from the GD-Sync website
   - Optional: Enable Protected Mode for additional security

2. Create a basic folder structure:
   ```
   res://
   ├── addons/         # Contains GD-Sync
   ├── assets/         # Sprites, sounds, etc.
   ├── scenes/         # Game scenes
   │   ├── main/       # Main game scene
   │   ├── ui/         # UI elements
   │   └── players/    # Player-related scenes
   └── scripts/        # Game scripts
   ```

## Step 3: Project Structure

1. Create the following scenes:
   - `scenes/ui/main_menu.tscn` - The main menu
   - `scenes/ui/lobby_browser.tscn` - For finding and joining games
   - `scenes/players/player.tscn` - The player character
   - `scenes/main/game_world.tscn` - The main game world

2. Set up the project autoloads:
   - Go to Project → Project Settings → Autoload
   - Add a new script called `global.gd` if you need global variables
   - Note: GD-Sync already adds its own autoload called "GDSync"

## Step 4: Creating Core Game Elements

1. Create the player character:
   - Create a new scene `player.tscn` with a CharacterBody2D as the root
   - Add a Sprite2D node for the player's appearance
   - Add a CollisionShape2D node for collision detection
   - Add a Camera2D node (we'll enable it only for the local player later)
   - Attach a script to handle movement and actions

2. Basic player script (`player.gd`):
   ```gdscript
   extends CharacterBody2D

   const SPEED = 300.0
   const JUMP_VELOCITY = -400.0

   # Get the gravity from the project settings
   var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

   func _ready():
       # We'll use this to determine if this is the local player
       var is_local_player = int(name) == GDSync.get_client_id()
       
       # Only enable camera and input processing for the local player
       $Camera2D.enabled = is_local_player
       set_process_input(is_local_player)
       set_physics_process(is_local_player)

   func _physics_process(delta):
       # Add gravity
       if not is_on_floor():
           velocity.y += gravity * delta

       # Handle Jump
       if Input.is_action_just_pressed("ui_accept") and is_on_floor():
           velocity.y = JUMP_VELOCITY

       # Get input direction
       var direction = Input.get_axis("ui_left", "ui_right")
       
       # Handle movement
       if direction:
           velocity.x = direction * SPEED
       else:
           velocity.x = move_toward(velocity.x, 0, SPEED)

       move_and_slide()
   ```

3. Create a simple game world:
   - Create a new scene `game_world.tscn` with Node2D as the root
   - Add a TileMap for the level design
   - Add platforms, obstacles, and collectibles
   - Create a spawn point for players (a Position2D or Marker2D node)

## Step 5: Implementing Multiplayer

1. Create the main menu UI (`main_menu.tscn`):
   - Add buttons for "Create Game", "Join Game", "Settings", and "Quit"
   - Attach a script to handle button clicks and multiplayer setup

2. Main menu script (`main_menu.gd`):
   ```gdscript
   extends Control

   func _ready():
       # Connect GD-Sync signals
       GDSync.connected.connect(on_connected)
       GDSync.connection_failed.connect(on_connection_failed)
       
       # Configure UI
       Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

   func _on_create_game_pressed():
       # Start multiplayer connection
       GDSync.start_multiplayer()
       $Buttons.hide()
       $StatusLabel.text = "Connecting to GD-Sync servers..."

   func _on_join_game_pressed():
       # Start multiplayer connection and show lobby browser
       GDSync.start_multiplayer()
       $Buttons.hide()
       $StatusLabel.text = "Connecting to GD-Sync servers..."

   func _on_quit_pressed():
       get_tree().quit()

   func on_connected():
       # Different behaviors based on which button was pressed
       if $JoinGameButton.pressed:
           get_tree().change_scene_to_file("res://scenes/ui/lobby_browser.tscn")
       else:
           # Go to lobby creation screen
           get_tree().change_scene_to_file("res://scenes/ui/create_lobby.tscn")

   func on_connection_failed(error):
       $Buttons.show()
       match error:
           ENUMS.CONNECTION_FAILED.INVALID_PUBLIC_KEY:
               $StatusLabel.text = "Invalid API keys. Check your GD-Sync configuration."
           ENUMS.CONNECTION_FAILED.TIMEOUT:
               $StatusLabel.text = "Connection timeout. Check your internet connection."
           _:
               $StatusLabel.text = "Connection failed. Unknown error."
   ```

3. Create a lobby creation UI (`create_lobby.tscn`):
   - Add input fields for lobby name and password
   - Add buttons to create or cancel

4. Lobby creation script (`create_lobby.gd`):
   ```gdscript
   extends Control

   func _ready():
       # Connect GD-Sync lobby signals
       GDSync.lobby_created.connect(on_lobby_created)
       GDSync.lobby_creation_failed.connect(on_lobby_creation_failed)

   func _on_create_button_pressed():
       var lobby_name = $LobbyNameInput.text
       var password = $PasswordInput.text
       
       if lobby_name.strip_edges().is_empty():
           $StatusLabel.text = "Please enter a lobby name"
           return
       
       # Create the lobby
       $CreateButton.disabled = true
       $StatusLabel.text = "Creating lobby..."
       
       # Set this to true if you want the lobby to be visible in the lobby browser
       var is_public = $PublicCheckbox.button_pressed
       
       GDSync.create_lobby(lobby_name, password, is_public)

   func on_lobby_created(lobby_name):
       # Set player data if needed
       GDSync.set_player_username($UsernameInput.text)
       
       # Change to the game scene
       get_tree().change_scene_to_file("res://scenes/main/game_world.tscn")

   func on_lobby_creation_failed(lobby_name, error):
       $CreateButton.disabled = false
       match error:
           ENUMS.LOBBY_CREATION_ERROR.ALREADY_EXISTS:
               $StatusLabel.text = "A lobby with this name already exists"
           ENUMS.LOBBY_CREATION_ERROR.INVALID_NAME:
               $StatusLabel.text = "Invalid lobby name"
           _:
               $StatusLabel.text = "Failed to create lobby"
   ```

5. Create a lobby browser UI (`lobby_browser.tscn`):
   - Add a list view (ItemList) to display available lobbies
   - Add buttons to refresh, join, and back

6. Lobby browser script (`lobby_browser.gd`):
   ```gdscript
   extends Control

   func _ready():
       # Connect GD-Sync lobby signals
       GDSync.lobbies_received.connect(on_lobbies_received)
       GDSync.lobby_joined.connect(on_lobby_joined)
       GDSync.lobby_join_failed.connect(on_lobby_join_failed)
       
       # Request lobby list on startup
       refresh_lobbies()

   func refresh_lobbies():
       $LobbyList.clear()
       $StatusLabel.text = "Fetching lobbies..."
       GDSync.get_public_lobbies()

   func on_lobbies_received(lobbies):
       $LobbyList.clear()
       $StatusLabel.text = ""
       
       if lobbies.size() == 0:
           $StatusLabel.text = "No public lobbies available"
           return
       
       for lobby in lobbies:
           var player_count = lobby.player_count
           var max_players = lobby.max_players
           var item_text = "%s (%d/%d players)" % [lobby.name, player_count, max_players]
           $LobbyList.add_item(item_text)
           # Store the lobby name as metadata
           $LobbyList.set_item_metadata($LobbyList.get_item_count() - 1, lobby.name)

   func _on_join_button_pressed():
       var selected_idx = $LobbyList.get_selected_items()
       if selected_idx.size() == 0:
           $StatusLabel.text = "Please select a lobby"
           return
       
       var lobby_name = $LobbyList.get_item_metadata(selected_idx[0])
       var password = $PasswordInput.text
       
       $JoinButton.disabled = true
       $StatusLabel.text = "Joining lobby..."
       
       GDSync.join_lobby(lobby_name, password)

   func on_lobby_joined(lobby_name):
       # Set player data if needed
       GDSync.set_player_username($UsernameInput.text)
       
       # Change to the game scene
       get_tree().change_scene_to_file("res://scenes/main/game_world.tscn")

   func on_lobby_join_failed(lobby_name, error):
       $JoinButton.disabled = false
       match error:
           ENUMS.LOBBY_JOIN_ERROR.DOES_NOT_EXIST:
               $StatusLabel.text = "Lobby does not exist"
           ENUMS.LOBBY_JOIN_ERROR.INCORRECT_PASSWORD:
               $StatusLabel.text = "Incorrect password"
           ENUMS.LOBBY_JOIN_ERROR.FULL:
               $StatusLabel.text = "Lobby is full"
           _:
               $StatusLabel.text = "Failed to join lobby"
   ```

## Step 6: Synchronizing Game State

1. Game world script (`game_world.gd`):
   ```gdscript
   extends Node2D

   var PLAYER_SCENE = preload("res://scenes/players/player.tscn")

   func _ready():
       # Connect GD-Sync signals
       GDSync.client_joined.connect(on_client_joined)
       GDSync.client_left.connect(on_client_left)
       GDSync.disconnected.connect(on_disconnected)
       
       # Spawn players for all clients already in the lobby
       for client_id in GDSync.lobby_get_all_clients():
           spawn_player(client_id)

   func on_client_joined(client_id):
       spawn_player(client_id)

   func on_client_left(client_id):
       # Remove the player when they leave
       var player_node = str(client_id)
       if has_node(player_node):
           get_node(player_node).queue_free()

   func on_disconnected():
       # Return to main menu if disconnected
       get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

   func spawn_player(client_id):
       var player = PLAYER_SCENE.instantiate()
       player.name = str(client_id)
       player.position = $SpawnPoint.position
       add_child(player)
       
       # Assign ownership to the client
       GDSync.set_gdsync_owner(player, client_id)
   ```

2. Synchronizing player properties:
   - Add a PropertySynchronizer node to your player scene
   - In the inspector, configure which properties to synchronize:
     - position
     - velocity
     - animation state
     - etc.
   - Make sure to configure the sync mode (e.g., continuous for position)

3. Example property synchronization in player.tscn:
   - Add a PropertySynchronizer node as a child of the player
   - In its Inspector properties, add:
     ```
     Property: position, Mode: Continuous
     Property: velocity, Mode: Continuous
     Property: flip_h, Mode: On Change (for the Sprite2D)
     ```

4. Add animations to your player:
   - Create animations for idle, run, jump
   - Add this to your player script:

   ```gdscript
   # Add this to your player.gd script
   var animation_state = "idle"
   
   func _physics_process(delta):
       # Existing movement code...
       
       # Update animation state
       if not is_on_floor():
           animation_state = "jump"
       elif abs(velocity.x) > 0:
           animation_state = "run"
       else:
           animation_state = "idle"
       
       # Update sprite direction
       if velocity.x < 0:
           $Sprite2D.flip_h = true
       elif velocity.x > 0:
           $Sprite2D.flip_h = false
           
       # Play animation
       $AnimationPlayer.play(animation_state)
   ```

## Step 7: Lobby System

1. Add lobby status display:
   - Create a UI that shows all connected players
   - Allow the host to kick players
   - Show player usernames

2. Lobby management script:
   ```gdscript
   extends Control

   func _ready():
       # Update the player list initially
       update_player_list()
       
       # Connect to player events
       GDSync.client_joined.connect(func(_id): update_player_list())
       GDSync.client_left.connect(func(_id): update_player_list())
       
       # Show host controls only for the host
       $HostControls.visible = GDSync.is_host()

   func update_player_list():
       $PlayerList.clear()
       var clients = GDSync.lobby_get_all_clients()
       
       for client_id in clients:
           var username = GDSync.get_player_username(client_id)
           var is_host_text = " (Host)" if GDSync.is_client_host(client_id) else ""
           var is_you_text = " (You)" if client_id == GDSync.get_client_id() else ""
           
           $PlayerList.add_item(username + is_host_text + is_you_text)
           $PlayerList.set_item_metadata($PlayerList.get_item_count() - 1, client_id)

   func _on_kick_button_pressed():
       if !GDSync.is_host():
           return
           
       var selected_idx = $PlayerList.get_selected_items()
       if selected_idx.size() == 0:
           return
           
       var client_id = $PlayerList.get_item_metadata(selected_idx[0])
       
       # Don't allow kicking yourself
       if client_id == GDSync.get_client_id():
           return
           
       GDSync.kick_client(client_id)
   ```

## Step 8: Testing and Deployment

1. Local testing:
   - Run multiple instances of Godot
   - Create a lobby in one instance
   - Join from the other instances
   - Test all multiplayer functionality

2. Performance optimization:
   - Use the PropertySynchronizer's "Delta Threshold" to reduce network traffic
   - Set appropriate sync update rates for different properties
   - Consider using the "Authoritative" mode for physics-based objects

3. Building for distribution:
   - Export your game for your target platforms
   - Make sure the GD-Sync addon is included in exports
   - Test the exported build to ensure multiplayer works correctly

## Common Issues and Solutions

1. **Connection Issues**
   - Make sure your API keys are correct
   - Check your internet connection
   - Verify the GD-Sync servers are online

2. **Synchronization Problems**
   - Ensure PropertySynchronizer nodes are set up correctly
   - Use appropriate sync modes for different properties
   - Use "Authoritative" mode for critical game elements

3. **Client Ownership Issues**
   - Always call `GDSync.set_gdsync_owner()` after spawning player-controlled objects
   - Make sure to use the correct client ID

4. **Performance Issues**
   - Use the "Delta Threshold" to reduce network traffic
   - Synchronize only necessary properties
   - Consider using the SynchronizedAnimationPlayer for animations

## Advanced Features

1. **Custom Game Modes**
   - Use lobby data to store game mode information
   - Example: 
     ```gdscript
     GDSync.set_lobby_data("game_mode", "capture_the_flag")
     var current_mode = GDSync.get_lobby_data("game_mode")
     ```

2. **Chat System**
   - Implement a basic chat using GDSync's remote procedure calls:
     ```gdscript
     # Sending a message
     GDSync.call_func_on_all("receive_chat_message", [GDSync.get_player_username(GDSync.get_client_id()), message_text])
     
     # Receiving a message
     func receive_chat_message(sender_name, message_text):
         $ChatHistory.text += sender_name + ": " + message_text + "\n"
     ```

3. **Game State Synchronization**
   - Track and synchronize game state using lobby data
     ```gdscript
     # Game started
     GDSync.set_lobby_data("game_state", "in_progress")
     
     # Game over
     GDSync.set_lobby_data("game_state", "game_over")
     
     # Monitor for changes
     GDSync.lobby_data_changed.connect(func(key, value): 
         if key == "game_state" and value == "game_over":
             show_game_over_screen()
     )
     ```

---

This README should provide you with a solid foundation for creating a 2D multiplayer game using GD-Sync. Remember to adapt these examples to your specific game design and mechanics. 