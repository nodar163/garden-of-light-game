# Источники ресурсов

- `assets/icon.svg`, отрисовка в `scripts/board.gd` и оформление интерфейса созданы для этого проекта; сторонние картинки не использованы.
- `assets/ambience.wav` и `assets/chime.wav` синтезированы кодом `tools_build_assets.py`; сторонние записи и семплы не использованы.
- `assets/nature.wav`, `swap.wav`, `bloom.wav`, `power.wav`, `win.wav` синтезированы оригинальным `tools_nature_audio.py`; полевые записи и сторонние семплы не используются.
- `flowers-atlas.png` и `obstacles-atlas.png` созданы встроенным imagegen для проекта, без входных изображений или графики Royal Match. Описание промптов и применения: `PREMIUM-FIELD.md`.
- `garden-music.wav` синтезирован оригинальным `tools_garden_music.py`, без сторонних записей и семплов.
- Эффекты «Цветочного каскада» созданы в `scripts/match_board.gd`. Источники изучения механики перечислены в `FLOWER-CASCADE.md` и `PREMIUM-FIELD.md`.
- Шрифт — встроенный шрифт Godot. Его уведомления вместе с лицензиями движка доступны в игре: Настройки → Лицензии.
- Godot Engine: MIT; полный текст и notices компонентов выводятся через `Engine.get_license_text()`, `Engine.get_copyright_info()` и `Engine.get_license_info()`.
- Инструменты `.tools` не входят в игровой контент. Их лицензии поставляются с самими инструментами.

Коммерческий релиз потребует сохранения этих уведомлений и дополнительной проверки лицензий, если появятся новые ресурсы.

- assets/garden-world.png, jack.png и garden-decor.png созданы встроенным imagegen для проекта. Описание изображений: JACK-GARDEN.md. soft-turn.wav синтезирован tools_garden_music.py без сторонних записей.
