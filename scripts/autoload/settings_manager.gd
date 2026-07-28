extends Node
## SettingsManager — загрузка/сохранение настроек в user://config.cfg (autoload).
## Этап 1: базовый каркас. Полные секции графики/звука добавляются позже.

const CONFIG_PATH := "user://config.cfg"

var config := ConfigFile.new()

func _ready() -> void:
	var err := config.load(CONFIG_PATH)
	if err != OK and err != ERR_FILE_NOT_FOUND:
		push_warning("SettingsManager: не удалось загрузить конфиг (%d)" % err)

func get_value(section: String, key: String, default: Variant) -> Variant:
	return config.get_value(section, key, default)

func set_value(section: String, key: String, value: Variant) -> void:
	config.set_value(section, key, value)

func save_settings() -> int:
	return config.save(CONFIG_PATH)
