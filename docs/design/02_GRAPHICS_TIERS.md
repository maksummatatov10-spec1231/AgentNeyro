# 🖼️ Настройки графики — пресеты Low → Ultra (EMBERFALL)

> Самое большое меню в игре (~30 параметров). Пресеты применяются в реальном времени
> через `GraphicsManager` (WorldEnvironment + ProjectSettings + Viewport).
> Цель: **Ultra = шедевральная картка**, Low = 60 FPS на слабом железе.

---

## 1. Пресеты (один клик)

| Параметр | 🟢 Low | 🟡 Medium | 🟠 High | 🔴 **Ultra** |
|---|---|---|---|---|
| Render Scale | 0.75× | 0.85× | 1.0× | **1.25× (SS)** |
| MSAA | Off | 2× | 4× | **4× + FXAA** |
| TAA | Off | Off | On | **On** |
| Тени (Directional) | 1024 | 2048 | 4096 | **8192** |
| Shadow Atlas | 1024 | 2048 | 4096 | **8192** |
| Soft Shadows | Off | Low | Medium | **Ultra (PCSS-like)** |
| Точечные тени | Off | Half | All | **All + High** |
| **SDFGI** (Global Illum) | Off | Off | On | **On + High rays** |
| VoxelGI | — | — | — | (опц. для комнат) |
| **SSAO** | Off | Low | Medium | **High + Half-size off** |
| SSIL | Off | Off | Low | **Medium** |
| **SSR** | Off | Off | Low | **High** |
| **Объёмный туман** | Off | On(low) | On | **On + High length** |
| Fog (дымка) | Light | Med | High | **High + glow falloff** |
| **Glow/Bloom** | Off | Low | Med | **High + ACES-ish** |
| Глубина резкости (DoF) | Off | Off | On | **On + Bokeh high** |
| Motion Blur | Off | Off | Low | **Medium** |
| **Tonemap** | Filmic | Filmic | ACES | **AgX** |
| HDR-вывод (4.7!) | Off | Off | On | **On (full HDR)** |
| Brightness/Contrast | 0 дефолт | дефолт | дефолт | настр. |
| Текстуры (limits) | Half | Full | Full | **Full + mips all** |
| Anisotropic | 1× | 4× | 8× | **16×** |
| Макс. источники света | 8 | 16 | 32 | **64 + AreaLight3D** |
| Reflections (Atlas) | Off | 128 | 256 | **512 + SSR** |
| Decals | Off | On | On | **On** |
| Particles (3D) cap | Low | Med | High | **Max** |
| VSync | Adaptive | On | On | **On (mailbox)** |
| Ограничение FPS | 60 | 60/120 | 144 | **Unlimited** |
| Occlusion Culling | On | On | On | **On (BVH)** |

---

## 2. Описание «Ultra = шедевр» 🔴

На Ultra картинка превращается в кинематограф:
- **AgX-тонмаппинг + HDR** — глубокие цвета, ровные яркие источники (факелы, магия).
- **SDFGI** — глобальное освещение: свет факелов мягко ложится на стены/пол, цветное bleeding.
- **Объёмный туман + god-rays** — лучи света сквозь проёмы, пылинки в воздухе, глубина.
- **Плотный Bloom/Glow** — магия и факелы «светятся», мягкие ореолы.
- **Высокие тени (8K) + soft shadows** — мягкие контактные тени, реалистичный penumbra.
- **SSAO + SSR + SSIL** — контактные тени в углах, отражения на мокром камне, вторичное освещение.
- **DoF (bokeh)** — лёгкий фокус на прицеле, размытие фона в коридорах.
- **AreaLight3D (новинка 4.7)** — мягкий прямоугольный свет из окон/проёмов.
- **MSAA 4× + TAA + supersampling 1.25×** — идеально чистые контуры, никакого «желе».
- Тонны точечных огней (факелы/свечи) + частицы искр/дыма.

---

## 3. Структура меню «Графика» (UI)

```
ГРАФИКА
├─ Пресет качества:   [Low] [Medium] [High] [Ultra] [Custom]
├─ Разрешение окна:   (системный список) ▼
├─ Режим окна:        Оконный / Безрамочный / Полноэкранный
├─ Вертик. синхр.:    Off / On / Адаптивная / Mailbox
├─ Лимит FPS:         30/60/120/144/Без
├─ ─────────────────── Качество рендера ───────────────────
├─ Масштаб рендера:   [—————●——] 0.5× – 1.5×
├─ Сглаживание:       MSAA [Off/2×/4×/8×]  □ FXAA  □ TAA
├─ Тени:              [Off/Low/Med/High/Ultra]
│   ├─ Разрешение направленного света
│   └─ Мягкие тени, точечные тени
├─ Глоб. освещение:   [Off/SDFGI/VoxelGI] + качество
├─ SSAO / SSIL:       □ Вкл + качество
├─ Отражения (SSR):   □ Вкл + качество
├─ Туман:             □ Объёмный  □ Дымка   (ползунки плотности/дальности)
├─ Постобработка:     □ Glow  □ DoF  □ Motion Blur  (интенсивности)
├─ Тонмаппинг:        [Linear/Reinhard/Filmic/ACES/AgX]
├─ HDR-вывод:         □ Вкл (4.7)
├─ Яркость/Контраст/Насыщенность:  ползунки
├─ Текстуры:          [Half/Full] + анизотропия [1–16×]
├─ Ограничения:       макс. источники света, частицы, decals
└─ [Применить]  [По умолчанию]  [Назад]
```

Каждый пункт имеет **tooltip-описание** и влияние на FPS. Изменение пресета = предустановка
всех параметров; ручная правка переключает пресет на **Custom**.

---

## 4. Реализация (`GraphicsManager`, autoload)

- Хранит настройки в `config.cfg` (`SettingsManager`).
- Применяет к: `Environment` (tonemap, glow, fog, volumetric, dof, ssao, ssr, ssil, sdfgi, adjustment),
  `ProjectSettings` (`rendering/anti_aliasing/*`, `rendering/reflections/*`, тени, текстуры),
  `get_viewport().msaa_3d`, `world_3d.environment`, `DisplayServer` (vsync, окно).
- HDR: `DisplayServer.window_set_flag(HDR)` / `rendering/output/hdr` (4.7 API).
- Переключение безопасно: applying в `_process`-throttled, без перезагрузки сцены.

> Детали API и точные пути ProjectSettings — в `03_TECHNICAL_ARCHITECTURE.md`.
