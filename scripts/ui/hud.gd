extends CanvasLayer
## HUD: полосы HP/MP/STA, статус кулдаунов, прицел, легенда управления.

@onready var hp_bar: ProgressBar = $BarsPanel/Bars/HP
@onready var mp_bar: ProgressBar = $BarsPanel/Bars/Mana
@onready var st_bar: ProgressBar = $BarsPanel/Bars/Stamina
@onready var cd_label: Label = $CooldownLabel

var player: Node = null

func _ready() -> void:
	EventBus.player_hp_changed.connect(_on_hp)
	EventBus.player_mana_changed.connect(_on_mana)
	EventBus.player_stamina_changed.connect(_on_stamina)

func _process(_delta: float) -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("player")
		return
	var aoe := "✓" if player._cd_aoe <= 0.0 else "%.1fs" % player._cd_aoe
	var heal := "✓" if player._cd_heal <= 0.0 else "%.1fs" % player._cd_heal
	var dash := "✓" if player._cd_dash <= 0.0 else "%.1fs" % player._cd_dash
	cd_label.text = "AoE (Q): %s     Исцеление (H): %s     Рывок (E): %s" % [aoe, heal, dash]

func _on_hp(c: float, m: float) -> void:
	hp_bar.value = (c / m) * 100.0

func _on_mana(c: float, m: float) -> void:
	mp_bar.value = (c / m) * 100.0

func _on_stamina(c: float, m: float) -> void:
	st_bar.value = (c / m) * 100.0
