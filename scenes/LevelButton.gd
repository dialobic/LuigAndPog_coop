extends Button

@export var level_name: String = ""

func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	if level_name != "":
		GameState.current_level = level_name
		
		CouchBridge.start_gameplay() # Chiamata all'SDK tramite l'Autoload
		
		get_tree().change_scene_to_file("res://scenes/GameScene.tscn")
