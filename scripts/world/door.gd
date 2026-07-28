extends Node3D
## Дверь (Этап 4.2). Открывается (уезжает вверх), когда игрок близко; закрывается, когда ушёл.

@export var open_range: float = 4.5
@onready var _panel: StaticBody3D = $Panel
var _closed_y: float = 0.0
var _open: bool = false
var _player: Node = null

func _ready() -> void:
	if _panel:
		_closed_y = _panel.position.y
	_player = get_tree().get_first_node_in_group("player")

func _physics_process(_delta: float) -> void:
	if _panel == null:
		return
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
		return
	var d: float = global_position.distance_to(_player.global_position)
	var should := d < open_range
	if should != _open:
		_open = should
		var target_y: float = _closed_y + (3.4 if _open else 0.0)
		var tw := create_tween()
		tw.tween_property(_panel, "position:y", target_y, 0.45).set_ease(Tween.EASE_IN_OUT)
