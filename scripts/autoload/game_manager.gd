extends Node
## GameManager — управление потоком игры и регистрация ввода.
## (autoload) Ввод задаётся в коде, чтобы project.godot оставался чистым и портируемым.

enum GameState { BOOT, MAIN_MENU, LOADING, PLAYING, PAUSED, WIN, LOSE }

var state: int = GameState.BOOT

# Клавиши по умолчанию (physical_keycode — не зависит от раскладки клавиатуры).
const ACTIONS := {
	"move_forward": [KEY_W],
	"move_back": [KEY_S],
	"move_left": [KEY_A],
	"move_right": [KEY_D],
	"jump": [KEY_SPACE],
	"sprint": [KEY_SHIFT],
	"crouch": [KEY_CTRL],
	"interact": [KEY_E],
	"pause": [KEY_ESCAPE],
	"attack_light": [-1],   # мышь: добавим программно
	"cast_bolt": [-2],
}

func _ready() -> void:
	_ensure_input_actions()

func _ensure_input_actions() -> void:
	for action in ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for ev in InputMap.action_get_events(action):
			InputMap.action_erase_event(action, ev)
		for keycode in ACTIONS[action]:
			if keycode > 0:
				var k := InputEventKey.new()
				k.physical_keycode = keycode
				InputMap.action_add_event(action, k)
	# Кнопки мыши
	_add_mouse_action("attack_light", MOUSE_BUTTON_LEFT)
	_add_mouse_action("cast_bolt", MOUSE_BUTTON_RIGHT)

func _add_mouse_action(action: String, button_index: int) -> void:
	var m := InputEventMouseButton.new()
	m.button_index = button_index
	InputMap.action_add_event(action, m)

func set_state(new_state: int) -> void:
	state = new_state
	EventBus.game_state_changed.emit(new_state)

func goto_scene(path: String) -> void:
	get_tree().change_scene_to_file(path)

func goto_main_menu() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func quit_game() -> void:
	get_tree().quit()
