extends Node
## EventBus — глобальная шина сигналов (autoload).

# Игрок
signal player_hp_changed(current: float, maximum: float)
signal player_mana_changed(current: float, maximum: float)
signal player_stamina_changed(current: float, maximum: float)
signal player_hurt(amount: float)
signal player_healed(amount: float)
signal player_died

# Способности
signal ability_cast(ability_name: String)

# Враги / бой
signal enemy_spawned(enemy: Node)
signal enemy_died(position: Vector3)

# Уровень / поток
signal checkpoint_reached
signal level_loaded
signal game_state_changed(new_state: int)
