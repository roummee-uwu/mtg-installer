# 📌 MTG Installer (MTProto Proxy via Docker)
## Установка одной командой
🚀 Установка:
```bash
curl -L -o install_mtg.sh https://raw.githubusercontent.com/systeamotech/mtg-installer/main/install_mtg.sh && chmod +x install_mtg.sh && bash install_mtg.sh
```
⚙️ Что делает скрипт:
- устанавливает Docker (если отсутствует)
- скачивает образ nineseconds/mtg:2 (https://github.com/9seconds/mtg)
- генерирует secret с TLS-маскировкой
- создаёт config.toml
- запускает контейнер mtg-proxy
- выводит готовую ссылку для Telegram

📦 Зависимости:
- Docker
- Linux (Ubuntu/Debian)

📜 Лицензия:
- MIT
