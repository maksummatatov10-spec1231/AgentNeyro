extends Node
## SettingsManager — настройки + локализация (autoload).

const CONFIG_PATH := "user://config.cfg"
var config := ConfigFile.new()

var language: String = "ru"
var mouse_sensitivity: float = 0.0025

# Локализация (встроенная, без внешних файлов)
const TRANSLATIONS := {
	"ru": {
		"play": "Играть", "settings": "Настройки", "quit": "Выход",
		"graphics": "Графика", "controls": "Управление", "language": "Язык",
		"mouse_sens": "Чувствительность мыши", "back": "Назад",
		"low": "Низкое", "medium": "Среднее", "high": "Высокое", "ultra": "Ультра",
		"quality": "Качество", "restart": "Заново", "main_menu": "В главное меню",
		"you_escaped": "ТЫ СБЕЖАЛ!", "you_died": "ТЫ ПОГИБ",
		"friends_greet": "Друзья встретили тебя у выхода.",
		"dungeon_consumed": "Подземелье поглотило тебя.",
		"controls_hint": "WASD — движение • Мышь — обзор • Space — прыжок • Shift — бег",
		"combat_hint": "ЛКМ — меч • ПКМ — болт • Q — взрыв • H — хил • E — рывок • R — тяжёлый",
	},
	"en": {
		"play": "Play", "settings": "Settings", "quit": "Quit",
		"graphics": "Graphics", "controls": "Controls", "language": "Language",
		"mouse_sens": "Mouse Sensitivity", "back": "Back",
		"low": "Low", "medium": "Medium", "high": "High", "ultra": "Ultra",
		"quality": "Quality", "restart": "Restart", "main_menu": "Main Menu",
		"you_escaped": "YOU ESCAPED!", "you_died": "YOU DIED",
		"friends_greet": "Your friends greeted you at the exit.",
		"dungeon_consumed": "The dungeon consumed you.",
		"controls_hint": "WASD — move • Mouse — look • Space — jump • Shift — sprint",
		"combat_hint": "LMB — sword • RMB — bolt • Q — AoE • H — heal • E — dash • R — heavy",
	},
}

func _ready() -> void:
	var err := config.load(CONFIG_PATH)
	if err == OK:
		language = config.get_value("gameplay", "language", "ru")
		mouse_sensitivity = config.get_value("gameplay", "mouse_sensitivity", 0.0025)

func t(key: String) -> String:
	var lang := TRANSLATIONS.get(language, TRANSLATIONS["en"])
	return lang.get(key, key)

func set_language(lang: String) -> void:
	language = lang
	set_value("gameplay", "language", lang)
	save_settings()

func set_mouse_sensitivity(value: float) -> void:
	mouse_sensitivity = value
	set_value("gameplay", "mouse_sensitivity", value)
	save_settings()

func get_value(section: String, key: String, default: Variant) -> Variant:
	return config.get_value(section, key, default)

func set_value(section: String, key: String, value: Variant) -> void:
	config.set_value(section, key, value)

func save_settings() -> int:
	return config.save(CONFIG_PATH)
