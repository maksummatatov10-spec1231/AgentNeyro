extends Node
## GraphicsManager — применение пресетов графики (autoload).
## Этап 1: безопасный стаб + разумные дефолты. Полные пресеты Low→Ultra — позже.

enum Tier { LOW, MEDIUM, HIGH, ULTRA, CUSTOM }

func _ready() -> void:
	# Базовый комфортный набор на старте.
	apply_tier(Tier.MEDIUM)

## Применить пресет к Environment/ProjectSettings/Viewport (заглушка этапа 1).
func apply_tier(tier: int) -> void:
	match tier:
		Tier.LOW:
			ProjectSettings.set_setting("rendering/anti_aliasing/quality/msaa_3d", 0)
		_:
			ProjectSettings.set_setting("rendering/anti_aliasing/quality/msaa_3d", 2)
