extends Control
## Экран победы (ты выбрался из данжа).

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$VBox/Again.pressed.connect(_on_again)
	$VBox/Menu.pressed.connect(_on_menu)

func _on_again() -> void:
	GameManager.restart_level()

func _on_menu() -> void:
	GameManager.goto_main_menu()
