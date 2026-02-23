#!/bin/bash
# ===========================================
# 🔹 SSH → Telegram Notify Installer 2.0
# ===========================================

set -e

# Цветной вывод
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
RESET="\e[0m"

echo -e "${GREEN}===========================================${RESET}"
echo -e "${GREEN} SSH → Telegram Notify Installer 2.0 ${RESET}"
echo -e "${GREEN}===========================================${RESET}"

# Проверка root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}❌ Запусти скрипт от root (sudo).${RESET}"
  exit 1
fi

# Проверка curl
if ! command -v curl &> /dev/null; then
  echo -e "${YELLOW}📦 Устанавливаю curl...${RESET}"
  apt update
  apt install -y curl
fi

# Получение токена и chat_id
echo
read -p "Введите Telegram Bot Token: " TOKEN

if [ -z "$TOKEN" ]; then
  echo -e "${RED}❌ TOKEN обязателен.${RESET}"
  exit 1
fi

# Автоматическое получение chat_id через API
echo -e "${YELLOW}🔎 Получаем chat_id через Telegram API...${RESET}"
UPDATE=$(curl -s "https://api.telegram.org/bot$TOKEN/getUpdates")

if [[ $UPDATE == *"error"* ]]; then
  echo -e "${RED}❌ Неверный TOKEN или бот ещё не активирован.${RESET}"
  exit 1
fi

echo "Напишите что-нибудь вашему боту в Telegram, чтобы получить chat_id."
read -p "Нажмите Enter, когда написали: " dummy

UPDATE=$(curl -s "https://api.telegram.org/bot$TOKEN/getUpdates")
CHAT_ID=$(echo "$UPDATE" | grep -o '"id":[0-9]\+' | head -1 | grep -o '[0-9]\+')

if [ -z "$CHAT_ID" ]; then
  echo -e "${RED}❌ Не удалось получить chat_id. Проверьте, написали ли вы боту.${RESET}"
  exit 1
fi

echo -e "${GREEN}✅ Chat ID получен: $CHAT_ID${RESET}"

# Создание скрипта уведомления
SCRIPT_PATH="/usr/local/bin/ssh_notify.sh"
echo -e "${YELLOW}⚙️ Создаю скрипт уведомления...${RESET}"

cat > $SCRIPT_PATH <<EOF
#!/bin/bash
TOKEN="$TOKEN"
CHAT_ID="$CHAT_ID"

IP=\$PAM_RHOST
USER=\$PAM_USER
DATE=\$(date "+%Y-%m-%d %H:%M:%S")
SERVER=\$(hostname)

MESSAGE="🔐 SSH login
User: \$USER
IP: \$IP
Server: \$SERVER
Time: \$DATE"

curl -s -X POST https://api.telegram.org/bot\$TOKEN/sendMessage \\
-d chat_id=\$CHAT_ID \\
-d text="\$MESSAGE" > /dev/null 2>&1
EOF

chmod +x $SCRIPT_PATH

# Подключение PAM
echo -e "${YELLOW}🔧 Подключаю PAM...${RESET}"
if ! grep -q "ssh_notify.sh" /etc/pam.d/sshd; then
  echo "session optional pam_exec.so $SCRIPT_PATH" >> /etc/pam.d/sshd
fi

# Перезапуск SSH
echo -e "${YELLOW}🔄 Перезапуск SSH...${RESET}"
if systemctl is-active ssh &> /dev/null; then
  systemctl restart ssh
elif systemctl is-active sshd &> /dev/null; then
  systemctl restart sshd
else
  echo -e "${RED}❌ Не удалось перезапустить SSH. Проверьте службу.${RESET}"
fi

# Тестовое уведомление
echo -e "${YELLOW}📨 Отправка тестового уведомления...${RESET}"
TEST_MSG="✅ Тестовое уведомление: скрипт успешно установлен на $(hostname)"
curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" -d chat_id="$CHAT_ID" -d text="$TEST_MSG" > /dev/null 2>&1

echo -e "${GREEN}===========================================${RESET}"
echo -e "${GREEN}✅ Установка завершена!${RESET}"
echo -e "${GREEN}Теперь при входе по SSH придёт уведомление.${RESET}"
echo -e "${GREEN}===========================================${RESET}"
