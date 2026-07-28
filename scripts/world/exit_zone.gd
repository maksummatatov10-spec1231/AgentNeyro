extends Area3D
## Зона выхода (Этап 4). Игрок касается → победа.

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		GameManager.win_game()
