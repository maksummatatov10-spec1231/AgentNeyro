extends Node
## EventBus — глобальная шина сигналов (autoload).
## Сигналы эмитятся из других систем, поэтому локальное предупреждение
## UNUSED_SIGNAL глушим аннотацией @warning_ignore.

# Игрок
@warning_ignore("unused_signal")
signal player_hp_changed(current: float, maximum: float)
@warning_ignore("unused_signal")
signal player_mana_changed(current: float, maximum: float)
@warning_ignore("unused_signal")
signal player_stamina_changed(current: float, maximum: float)
@warning_ignore("unused_signal")
signal player_hurt(amount: float)
@warning_ignore("unused_signal")
signal player_healed(amount: float)
@warning_ignore("unused_signal")
signal player_died

# Способности
@warning_ignore("unused_signal")
signal ability_cast(ability_name: String)

# Враги / бой
@warning_ignore("unused_signal")
signal enemy_spawned(enemy: Node)
@warning_ignore("unused_signal")
signal enemy_died(position: Vector3)

# Уровень / поток
@warning_ignore("unused_signal")
signal checkpoint_reached
@warning_ignore("unused_signal")
signal level_loaded
@warning_ignore("unused_signal")
signal game_state_changed(new_state: int)
