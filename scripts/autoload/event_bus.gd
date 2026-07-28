extends Node
## EventBus — глобальная шина сигналов (autoload).
## Центральное место для игровых событий, чтобы системы общались без жёстких связей.

signal player_hurt(amount: float)
signal player_healed(amount: float)
signal player_died
signal player_mana_changed(value: float, max_value: float)
signal player_stamina_changed(value: float, max_value: float)
signal enemy_spawned(enemy: Node)
signal enemy_died(position: Vector3)
signal checkpoint_reached
signal level_loaded
signal game_state_changed(new_state: int)
