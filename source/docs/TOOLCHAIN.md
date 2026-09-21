# Зафиксированные инструменты

- Godot **4.7.2.stable.official.ed1daf0bf**, standard, Windows x86_64.
- Export templates **4.7.2.stable**, из официальной загрузки Godot.
- Renderer: GL Compatibility; Android ETC2/ASTC import включён.
- GDScript, без внешних игровых библиотек.
- Microsoft OpenJDK **17.0.20.1+1** в `.tools/java`.
- Android SDK в `.tools/android-sdk`; platform **35**, build-tools **35.0.1**. Дополнительные зависимости Gradle берутся из закреплённого шаблона Godot.
- Фактическая Gradle-сборка также установила compile SDK **36**, build-tools **36.1.0**; Gradle wrapper **8.11.1**. Min SDK 26 и target SDK 35 подтверждены в итоговом APK.
- Android: min SDK **26**, target SDK **35** для прототипа. Требования публикации проверяются отдельно перед релизом.
- Python 3.14.1 использован только для создания локальных исходных ресурсов.

Официальные источники: https://godotengine.org/download/windows/ и https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html

Godot работает в self-contained режиме (`.tools/godot/_sc_`); настройки SDK и шаблоны хранятся внутри `.tools/godot/editor_data`, не меняя конфигурацию других установок Godot.

Для инструментов Android создан junction `C:/Users/User/GardenOfLightBuild` → исходная папка проекта. В настройках SDK/JDK используется этот путь латиницей, поскольку aapt2 неверно интерпретировал кириллицу в исходном пути. Файлы не переносились.

Новый Android CLI заменяет sdkmanager; в текущем комплекте совместимая обёртка sdkmanager неправильно передала имена пакетов с `;`. Установка выполнена через `android.exe --no-metrics --sdk=... sdk install ...` с сохранением полных имён пакетов.
