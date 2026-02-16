#!/bin/bash
set -e

GREEN="\e[32;4m"  # зелёный + подчёркнутый
RESET="\e[0m"

SERVER_IP=$(hostname -I | awk '{print $1}')

# ---------------------- language ----------------------
clear
echo "Select language / Выберите язык:"
echo "1 - English"
echo "2 - Русский"
printf "> "
read -n1 LANG_CHOICE
echo
LANG_CHOICE=$(echo "$LANG_CHOICE" | tr -d '[:space:]')

if [ "$LANG_CHOICE" = "1" ]; then
    MSG_UPDATE="Updating packages and installing Docker..."
    MSG_DOCKER_START="Starting and enabling Docker..."
    MSG_PULL="Pulling nineseconds/mtg:2 image..."
    MSG_DOMAIN="Enter domain (example: www.example.com): "
    MSG_PORT="Enter port (default 443): "
    MSG_NO_DOMAIN="Domain not specified. Exiting."
    MSG_GEN_SECRET="Generating secret..."
    MSG_SECRET_ERROR="Secret generation failed."
    MSG_CONFIG="Creating config.toml..."
    MSG_RUN="Starting container..."
    MSG_ACCESS="Link:"
    MSG_DONE="Done."
    MSG_ALREADY_INST="MTG is already installed."
    MSG_OPTION="Choose:\n1 - Reinstall\n2 - Remove\n3 - Exit: "
    MSG_REMOVE_DONE="MTG removed successfully."
elif [ "$LANG_CHOICE" = "2" ]; then
    MSG_UPDATE="Обновление пакетов и установка Docker..."
    MSG_DOCKER_START="Запуск и добавление Docker в автозагрузку..."
    MSG_PULL="Загрузка образа nineseconds/mtg:2..."
    MSG_DOMAIN="Введите домен (пример: www.example.com): "
    MSG_PORT="Введите порт (по умолчанию 443): "
    MSG_NO_DOMAIN="Домен не указан. Завершение."
    MSG_GEN_SECRET="Генерация secret..."
    MSG_SECRET_ERROR="Ошибка генерации secret."
    MSG_CONFIG="Создание config.toml..."
    MSG_RUN="Запуск контейнера..."
    MSG_ACCESS="Ссылка:"
    MSG_DONE="Готово."
    MSG_ALREADY_INST="MTG уже установлен."
    MSG_OPTION="Выберите:\n1 - Переустановить\n2 - Удалить\n3 - Выход: "
    MSG_REMOVE_DONE="MTG успешно удалён."
else
    echo "Invalid selection / Неверный выбор."
    exit 1
fi

# ---------------------- check Docker ----------------------
if ! command -v docker >/dev/null 2>&1; then
    echo -e "${GREEN}$MSG_UPDATE${RESET}"
    sudo apt update
    sudo apt install -y docker.io
fi

echo -e "${GREEN}$MSG_DOCKER_START${RESET}"
sudo systemctl start docker
sudo systemctl enable docker

echo -e "${GREEN}$MSG_PULL${RESET}"
sudo docker pull nineseconds/mtg:2

# ---------------------- check container ----------------------
if sudo docker ps -a --format '{{.Names}}' | grep -q '^mtg-proxy$'; then
    clear
    echo -e "${GREEN}$MSG_ALREADY_INST${RESET}"
    echo

    printf "%b" "$MSG_OPTION"
    echo

    read -n1 -p "> " OPT
    echo
    OPT=$(echo "$OPT" | tr -d '[:space:]')

    case "$OPT" in
        1)
            if [ "$LANG_CHOICE" = "1" ]; then
                echo -e "${GREEN}Reinstalling...${RESET}"
            else
                echo -e "${GREEN}Переустановка...${RESET}"
            fi
            sudo docker stop mtg-proxy || true
            sudo docker rm mtg-proxy || true
            rm -f config.toml
            ;;
        2)
            sudo docker stop mtg-proxy || true
            sudo docker rm mtg-proxy || true
            rm -f config.toml
            echo -e "${GREEN}$MSG_REMOVE_DONE${RESET}"
            exit 0
            ;;
        *)
            if [ "$LANG_CHOICE" = "1" ]; then
                echo "Exiting..."
            else
                echo "Выход..."
            fi
            exit 0
            ;;
    esac
fi

# ---------------------- domain and port ----------------------
echo
read -p "$MSG_DOMAIN" DOMAIN
if [ -z "$DOMAIN" ]; then
    echo "$MSG_NO_DOMAIN"
    exit 1
fi

echo
read -p "$MSG_PORT" PORT
PORT=${PORT:-443}

# ---------------------- secret ----------------------
echo
echo -e "${GREEN}$MSG_GEN_SECRET${RESET}"
SECRET=$(sudo docker run --rm nineseconds/mtg:2 generate-secret --hex "$DOMAIN")

if [ -z "$SECRET" ]; then
    echo "$MSG_SECRET_ERROR"
    exit 1
fi

# ---------------------- create config.toml ----------------------
echo
echo -e "${GREEN}$MSG_CONFIG${RESET}"
cat > config.toml <<EOF
secret = "$SECRET"
bind-to = "0.0.0.0:$PORT"
EOF

# ---------------------- container ----------------------
PORT=${PORT:-443}

if [ "$PORT" -lt 1024 ]; then
    NET_BIND="--cap-add=NET_BIND_SERVICE"
else
    NET_BIND=""
fi

sudo docker run -d \
  $NET_BIND \
  -v "$PWD/config.toml:/config.toml" \
  -p "$PORT:$PORT" \
  --name mtg-proxy \
  --restart=unless-stopped \
  nineseconds/mtg:2

# ---------------------- tg://proxy link ----------------------
echo
echo -e "${GREEN}$MSG_ACCESS${RESET}"
echo "tg://proxy?server=$SERVER_IP&port=$PORT&secret=$SECRET"

echo
echo -e "${GREEN}$MSG_DONE${RESET}"
