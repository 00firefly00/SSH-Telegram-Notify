#!/bin/bash

echo "[*] Removing SSH Telegram notification..."

# Удаляем сам скрипт
rm -f /usr/local/bin/TGNotify.sh
rm -f /usr/local/bin/ssh_notify.sh
rm -f /root/TGNotify.sh
rm -f /root/ssh_notify.sh

# Удаляем из PAM
if [ -f /etc/pam.d/sshd ]; then
    sed -i '/TGNotify.sh/d' /etc/pam.d/sshd
    sed -i '/ssh_notify.sh/d' /etc/pam.d/sshd
fi

# Удаляем из bash/profile
sed -i '/TGNotify.sh/d' /etc/profile 2>/dev/null
sed -i '/ssh_notify.sh/d' /etc/profile 2>/dev/null
sed -i '/TGNotify.sh/d' /etc/bash.bashrc 2>/dev/null
sed -i '/ssh_notify.sh/d' /etc/bash.bashrc 2>/dev/null
sed -i '/TGNotify.sh/d' /root/.bashrc 2>/dev/null
sed -i '/ssh_notify.sh/d' /root/.bashrc 2>/dev/null

# Перезапуск SSH
systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null

echo "[✓] SSH Telegram notification successfully removed."
