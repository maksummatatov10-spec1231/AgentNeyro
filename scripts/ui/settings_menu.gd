extends Control

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$VBox/Title.text = SettingsManager.t("settings")
	$VBox/SensLabel.text = SettingsManager.t("mouse_sens")
	$VBox/LangLabel.text = SettingsManager.t("language")
	$VBox/LangRow/LangEN.text = "English"
	$VBox/LangRow/LangRU.text = "Русский"
	$VBox/ControlsBtn.text = SettingsManager.t("controls")
	$VBox/GraphicsBtn.text = SettingsManager.t("graphics")
	$VBox/Back.text = SettingsManager.t("back")
	$VBox/SensSlider.value = SettingsManager.mouse_sensitivity * 10000.0
	# подсветка текущего языка
	_update_lang_highlight()
	# соединения
	$VBox/SensSlider.value_changed.connect(_on_sens_changed)
	$VBox/LangRow/LangEN.pressed.connect(func(): SettingsManager.set_language("en"); _refresh())
	$VBox/LangRow/LangRU.pressed.connect(func(): SettingsManager.set_language("ru"); _refresh())
	$VBox/GraphicsBtn.pressed.connect(_on_graphics)
	$VBox/Back.pressed.connect(_on_back)

func _refresh() -> void:
	_ready()

func _update_lang_highlight() -> void:
	$VBox/LangRow/LangEN.modulate = Color(1, 1, 0.5) if SettingsManager.language == "en" else Color(1, 1, 1)
	$VBox/LangRow/LangRU.modulate = Color(1, 1, 0.5) if SettingsManager.language == "ru" else Color(1, 1, 1)

func _on_sens_changed(value: float) -> void:
	SettingsManager.set_mouse_sensitivity(value / 10000.0)

func _on_graphics() -> void:
	GameManager.goto_scene("res://scenes/ui/graphics_menu.tscn")

func _on_back() -> void:
	GameManager.goto_main_menu()
