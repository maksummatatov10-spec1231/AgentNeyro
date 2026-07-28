# 🎮 EMBERFALL — Dungeon Escape

3D action-FPS на **Godot 4.7.1**. Герой спавнится в подземелье, пробивается через орды
скелетов и ловушки (меч + магия: снаряды/луч/AoE), находит ключ, открывает гейт и выходит
наружу, где его встречают друзья. **Вид от первого лица, управление WASD**, большое меню
графики **Low → Ultra** («шедевральная» картинка на Ultra).

> Статус: **дизайн полностью продуман и задокументирован** → переход к производству.

---

## 📐 Дизайн-документация (`docs/design/`)
Полная документация на высшем уровне — читать по порядку:
- **[`00_GDD.md`](docs/design/00_GDD.md)** — мастер-дизайн (концепт, core loop, игрок, враги, ловушки, уровень, UI, звук)
- **[`01_COMBAT_AND_ABILITIES.md`](docs/design/01_COMBAT_AND_ABILITIES.md)** — бой: меч, магия (болт/луч/AoE/хил/дэш), реакции урона врага и игрока
- **[`02_GRAPHICS_TIERS.md`](docs/design/02_GRAPHICS_TIERS.md)** — меню графики Low→Ultra (~30 параметров)
- **[`03_TECHNICAL_ARCHITECTURE.md`](docs/design/03_TECHNICAL_ARCHITECTURE.md)** — автозагрузки, сцены, скрипты, потоки данных
- **[`04_ASSET_MAPPING.md`](docs/design/04_ASSET_MAPPING.md)** — маппинг ассет→роль (риги, текстуры, VFX)
- **[`05_CONTROLS.md`](docs/design/05_CONTROLS.md)** — управление

## 📚 Анализ ассетов (`docs/`)
- **[`ASSETS_MASTER_ANALYSIS.md`](docs/ASSETS_MASTER_ANALYSIS.md)** — мастер-паспорт всех 7 наборов (риги/текстуры/форматы)
- **[`VFX_ANALYSIS.md`](docs/VFX_ANALYSIS.md)** — 7 Godot-native VFX-паков
- **[`GODOT_2026_BRIEFING.md`](docs/GODOT_2026_BRIEFING.md)** — актуальное состояние Godot 4.7.1
- **[`GAME_IDEAS_50.md`](docs/GAME_IDEAS_50.md)** — 50 идей (выбрана № — Dungeon Escape)

## 🎯 Ключевое
- **Два рига:** KayKit Rig_Medium (23 кости, герои+скелеты) и Quaternius Mixamo (67 костей, UAL).
  В игре KayKit-персонажей анимируем родными Rig_Medium-анимациями.
- **Способности:** меч (лёгкое комбо + тяжёлый), магический болт (шары из VFX), луч, огненный AoE, исцеление, рывок.
- **Реакции урона:** враг — flash + Hit_A/B + HitFX + смерть Death_A/dissolve; игрок — vignette + тряска + искры.
- Все текстуры 1024² RGBA; окружение статичное; FBX-текстуры подключаем через общие материалы.

## 🛠️ Стек
Godot 4.7.1 · GDScript · Jolt physics (дефолт 4.7) · ufbx (FBX) + GLB · CC0/FREE ассеты.

---
*Документация готова. Далее — сборка игры и ZIP-архив рядом с README.*
