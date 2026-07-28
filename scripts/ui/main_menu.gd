extends Control
## Главное меню. Этап 1: Играть / Настройки (заглушка) / Выход.

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$VBox/Play.pressed.connect(_on_play)
	$VBox/Settings.pressed.connect(_on_settings)
	$VBox/Quit.pressed.connect(_on_quit)
	GameManager.set_state(GameManager.GameState.MAIN_MENU)

func _on_play() -> void:
	GameManager.set_state(GameManager.GameState.LOADING)
	GameManager.goto_scene("res://scenes/levels/test_level.tscn")

func _on_settings() -> void:
	GameManager.goto_scene("res://scenes/ui/settings_menu.tscn")

func _on_quit() -> void:
	GameManager.quit_game()
