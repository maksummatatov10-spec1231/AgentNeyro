extends Node
## GraphicsManager — применение пресетов графики (autoload).

enum Tier { LOW, MEDIUM, HIGH, ULTRA }

func _ready() -> void:
	# Применяем сохранённый пресет при старте
	var saved := int(SettingsManager.get_value("graphics", "tier", Tier.HIGH))
	apply_tier(saved)

## Применить пресет: ProjectSettings (немедленно) + сохранить для уровня
func apply_tier(tier: int) -> void:
	SettingsManager.set_value("graphics", "tier", tier)
	SettingsManager.save_settings()
	match tier:
		Tier.LOW:
			ProjectSettings.set_setting("rendering/anti_aliasing/quality/msaa_3d", 0)
		Tier.MEDIUM:
			ProjectSettings.set_setting("rendering/anti_aliasing/quality/msaa_3d", 2)
		Tier.HIGH:
			ProjectSettings.set_setting("rendering/anti_aliasing/quality/msaa_3d", 4)
		Tier.ULTRA:
			ProjectSettings.set_setting("rendering/anti_aliasing/quality/msaa_3d", 4)
	apply_env_to_scene(tier)

## Найти WorldEnvironment в текущей сцене и применить настройки качества
func apply_env_to_scene(tier: int = -1) -> void:
	if tier < 0:
		tier = int(SettingsManager.get_value("graphics", "tier", Tier.HIGH))
	var we := _find_world_env()
	if we == null or we.environment == null:
		return
	var env: Environment = we.environment
	match tier:
		Tier.LOW:
			env.glow_enabled = false
			env.ssao_enabled = false
			env.ssr_enabled = false
			env.fog_enabled = true
			env.volumetric_fog_enabled = false
			env.tonemap_mode = 0  # Linear
			env.glow_intensity = 0.0
		Tier.MEDIUM:
			env.glow_enabled = true
			env.ssao_enabled = false
			env.ssr_enabled = false
			env.fog_enabled = true
			env.volumetric_fog_enabled = true
			env.tonemap_mode = 2  # Filmic
			env.glow_intensity = 0.6
		Tier.HIGH:
			env.glow_enabled = true
			env.ssao_enabled = true
			env.ssr_enabled = false
			env.fog_enabled = true
			env.volumetric_fog_enabled = true
			env.tonemap_mode = 2  # Filmic
			env.glow_intensity = 0.8
		Tier.ULTRA:
			env.glow_enabled = true
			env.ssao_enabled = true
			env.ssr_enabled = true
			env.fog_enabled = true
			env.volumetric_fog_enabled = true
			env.tonemap_mode = 4  # AgX
			env.glow_intensity = 1.2

func _find_world_env() -> WorldEnvironment:
	var root = get_tree().current_scene
	if root == null:
		return null
	for c in root.get_children():
		if c is WorldEnvironment:
			return c
	return null
