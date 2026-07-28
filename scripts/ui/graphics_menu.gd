extends Control

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$VBox/Title.text = SettingsManager.t("graphics")
	$VBox/QualityLabel.text = SettingsManager.t("quality")
	$VBox/Low.text = SettingsManager.t("low")
	$VBox/Medium.text = SettingsManager.t("medium")
	$VBox/High.text = SettingsManager.t("high")
	$VBox/Ultra.text = SettingsManager.t("ultra")
	$VBox/Back.text = SettingsManager.t("back")
	# подсветка текущего пресета
	var cur := int(SettingsManager.get_value("graphics", "tier", 2))
	_highlight(cur)
	$VBox/Low.pressed.connect(func(): _apply(0))
	$VBox/Medium.pressed.connect(func(): _apply(1))
	$VBox/High.pressed.connect(func(): _apply(2))
	$VBox/Ultra.pressed.connect(func(): _apply(3))
	$VBox/Back.pressed.connect(_on_back)

func _apply(tier: int) -> void:
	GraphicsManager.apply_tier(tier)
	_highlight(tier)

func _highlight(tier: int) -> void:
	var btns := [$VBox/Low, $VBox/Medium, $VBox/High, $VBox/Ultra]
	for i in range(btns.size()):
		btns[i].modulate = Color(1, 1, 0.5) if i == tier else Color(1, 1, 1)

func _on_back() -> void:
	GameManager.goto_scene("res://scenes/ui/settings_menu.tscn")
