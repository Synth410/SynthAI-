#!/bin/bash
# SynthAI — Автоматичне встановлення v2.1

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

clear
echo -e "${BLUE}"
echo "  ███████╗██╗   ██╗███╗   ██╗████████╗██╗  ██╗ █████╗ ██╗"
echo "  ██╔════╝╚██╗ ██╔╝████╗  ██║╚══██╔══╝██║  ██║██╔══██╗██║"
echo "  ███████╗ ╚████╔╝ ██╔██╗ ██║   ██║   ███████║███████║██║"
echo "  ╚════██║  ╚██╔╝  ██║╚██╗██║   ██║   ██╔══██║██╔══██║██║"
echo "  ███████║   ██║   ██║ ╚████║   ██║   ██║  ██║██║  ██║██║"
echo "  ╚══════╝   ╚═╝   ╚═╝  ╚═══╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝"
echo -e "${NC}"
echo -e "${GREEN}  AI Діагностичний стенд — Встановлення v2.1${NC}"
echo "  ================================================"
echo ""

# Перевірка Ubuntu
echo -e "${CYAN}Перевірка системи...${NC}"
if ! grep -q "Ubuntu" /etc/os-release; then
    echo -e "${RED}Помилка: Підтримується тільки Ubuntu!${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Ubuntu виявлено${NC}"

# Перевірка інтернету
if ! ping -c 1 google.com &>/dev/null; then
    echo -e "${RED}Помилка: Немає підключення до інтернету!${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Інтернет доступний${NC}"

# ВИПРАВЛЕНО: Python 3.11 або 3.12 — стабільні версії замість 3.14
PYTHON_CMD=""
for v in python3.12 python3.11 python3; do
    if command -v "$v" &>/dev/null; then
        PYTHON_CMD="$v"
        break
    fi
done

if [ -z "$PYTHON_CMD" ]; then
    echo -e "${RED}Помилка: Python 3.11+ не знайдено!${NC}"
    echo "Встановіть: sudo apt install python3.12"
    exit 1
fi
PYTHON_VERSION=$($PYTHON_CMD --version 2>&1)
echo -e "${GREEN}✅ $PYTHON_VERSION знайдено ($PYTHON_CMD)${NC}"

echo ""
echo -e "${YELLOW}================================================${NC}"
echo -e "${YELLOW}  Налаштування SynthAI${NC}"
echo -e "${YELLOW}================================================${NC}"
echo ""

# Запит API ключів
echo -e "${CYAN}Крок 1: API ключі Gemini${NC}"
echo "Отримайте безкоштовний ключ на: https://aistudio.google.com"
echo ""
read -p "Введіть GEMINI_API_KEY (головний): " GEMINI_KEY
while [ -z "$GEMINI_KEY" ]; do
    echo -e "${RED}Ключ не може бути порожнім!${NC}"
    read -p "Введіть GEMINI_API_KEY: " GEMINI_KEY
done

read -p "Введіть GEMINI_RESEARCH_API_KEY (другий акаунт, або той самий): " GEMINI_RESEARCH_KEY
if [ -z "$GEMINI_RESEARCH_KEY" ]; then
    GEMINI_RESEARCH_KEY=$GEMINI_KEY
    echo "Використовується той самий ключ для дослідника."
fi

echo ""
echo -e "${CYAN}Крок 2: OBD адаптер${NC}"
echo "MAC адреса вашого Bluetooth OBD адаптера"
echo "Приклад: AA:BB:CC:11:22:33"
echo "(Знайдіть через: bluetoothctl scan on)"
echo ""
read -p "Введіть MAC адресу OBD адаптера: " OBD_MAC
while [ -z "$OBD_MAC" ]; do
    echo -e "${RED}MAC адреса не може бути порожньою!${NC}"
    read -p "Введіть MAC адресу: " OBD_MAC
done

echo ""
echo -e "${CYAN}Крок 3: Ім'я користувача${NC}"
CURRENT_USER=$(whoami)
read -p "Ім'я користувача Ubuntu [$CURRENT_USER]: " INPUT_USER
USER_NAME=${INPUT_USER:-$CURRENT_USER}
HOME_DIR="/home/$USER_NAME"
INSTALL_DIR="$HOME_DIR/autodiag"

echo ""
echo -e "${YELLOW}================================================${NC}"
echo -e "${YELLOW}  Підтвердження налаштувань${NC}"
echo -e "${YELLOW}================================================${NC}"
echo "  Користувач:    $USER_NAME"
echo "  Папка:         $INSTALL_DIR"
echo "  OBD MAC:       $OBD_MAC"
echo "  Python:        $PYTHON_CMD ($PYTHON_VERSION)"
echo "  Gemini ключ:   ${GEMINI_KEY:0:20}..."
echo ""
read -p "Продовжити встановлення? (y/n): " CONFIRM
if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    echo "Встановлення скасовано."
    exit 0
fi

echo ""
echo -e "${YELLOW}[1/9] Оновлення системи...${NC}"
sudo apt update -y 2>/dev/null
echo -e "${GREEN}✅ Система оновлена${NC}"

echo -e "${YELLOW}[2/9] Встановлення системних пакетів...${NC}"
# ВИПРАВЛЕНО: прибрано mono-complete (500 МБ непотрібного пакету)
sudo apt install -y \
    bluetooth bluez bluez-tools \
    pipewire pipewire-pulse wireplumber \
    libspa-0.2-bluetooth \
    alsa-utils \
    portaudio19-dev libportaudio2 \
    ffmpeg \
    xorg xinit openbox \
    firefox \
    git curl wget 2>/dev/null
echo -e "${GREEN}✅ Пакети встановлено${NC}"

echo -e "${YELLOW}[3/9] Налаштування Bluetooth...${NC}"
sudo systemctl enable bluetooth
sudo systemctl start bluetooth

echo "options btusb enable_autosuspend=n" | sudo tee /etc/modprobe.d/btusb.conf > /dev/null
echo "options bluetooth disable_ertm=1" | sudo tee /etc/modprobe.d/bluetooth.conf > /dev/null

sudo bash -c 'cat > /etc/bluetooth/main.conf << EOF
[Policy]
AutoEnable=true

[General]
FastConnectable=true
ControllerMode=bredr
EOF'
echo -e "${GREEN}✅ Bluetooth налаштовано${NC}"

echo -e "${YELLOW}[4/9] Встановлення Python залежностей...${NC}"
cd "$INSTALL_DIR"
$PYTHON_CMD -m venv venv
source venv/bin/activate

pip install --upgrade pip --quiet
pip install \
    flask \
    google-genai \
    python-dotenv \
    obd \
    pyserial \
    faster-whisper \
    edge-tts \
    pygame \
    pyaudio \
    numpy \
    SpeechRecognition \
    ollama --quiet
echo -e "${GREEN}✅ Python залежності встановлено${NC}"

echo -e "${YELLOW}[5/9] Встановлення Ollama...${NC}"
curl -fsSL https://ollama.com/install.sh | sh 2>/dev/null
sleep 3
ollama pull gemma3:12b
echo -e "${GREEN}✅ Ollama і модель встановлено${NC}"

echo -e "${YELLOW}[6/9] Запис налаштувань...${NC}"
# ВИПРАВЛЕНО: OBD_MAC також записується в .env, а не тільки в код
cat > "$INSTALL_DIR/.env" << EOF
GEMINI_API_KEY=$GEMINI_KEY
GEMINI_RESEARCH_API_KEY=$GEMINI_RESEARCH_KEY
OBD_MAC=$OBD_MAC
EOF
echo -e "${GREEN}✅ Налаштування записано у .env${NC}"

echo -e "${YELLOW}[7/9] Налаштування автозапуску...${NC}"
sudo bash -c "cat > /etc/rc.local << EOF
#!/bin/bash
sleep 15
rmmod btusb 2>/dev/null
sleep 3
modprobe btusb
sleep 8
hciconfig hci0 up
sleep 3
bluetoothctl power on
sleep 2
bluetoothctl connect $OBD_MAC
sleep 5
rfcomm connect 0 $OBD_MAC 1 &
sleep 8
chmod 666 /dev/rfcomm0 2>/dev/null
exit 0
EOF"
sudo chmod +x /etc/rc.local
sudo systemctl enable rc-local

mkdir -p "$HOME_DIR/.config/openbox"
cat > "$HOME_DIR/.config/openbox/autostart" << EOF
pulseaudio --start &
setxkbmap -layout us,ua &
sleep 5
cd $INSTALL_DIR && source venv/bin/activate && $PYTHON_CMD app.py &
sleep 3
firefox --kiosk http://localhost:5000 &
EOF

cat >> "$HOME_DIR/.bash_profile" << EOF
if [ -z "\$DISPLAY" ] && [ "\$(tty)" = "/dev/tty1" ]; then
    startx openbox-session
fi
EOF
echo -e "${GREEN}✅ Автозапуск налаштовано${NC}"

echo -e "${YELLOW}[8/9] Налаштування sudoers...${NC}"
echo "$USER_NAME ALL=(ALL) NOPASSWD: /usr/bin/rfcomm, /bin/chmod, /sbin/hciconfig, /sbin/modprobe, /sbin/rmmod, /usr/bin/fuser" | sudo tee /etc/sudoers.d/synthai > /dev/null
sudo chmod 440 /etc/sudoers.d/synthai
echo -e "${GREEN}✅ Sudoers налаштовано${NC}"

echo -e "${YELLOW}[9/9] Налаштування автологіну...${NC}"
sudo mkdir -p /etc/systemd/system/getty@tty1.service.d
sudo bash -c "cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $USER_NAME --noclear %I \$TERM
EOF"
sudo systemctl daemon-reload
echo -e "${GREEN}✅ Автологін налаштовано${NC}"

echo ""
echo -e "${GREEN}"
echo "  ================================================"
echo "  🎉 SynthAI успішно встановлено!"
echo "  ================================================"
echo ""
echo "  Після перезавантаження система автоматично:"
echo "  • Підключиться до OBD адаптера ($OBD_MAC)"
echo "  • Запустить IRIS діагностичний стенд"
echo "  • Відкриє інтерфейс в браузері"
echo ""
echo "  Для ручного запуску:"
echo "  cd $INSTALL_DIR"
echo "  source venv/bin/activate"
echo "  $PYTHON_CMD app.py"
echo ""
echo -e "${NC}"

read -p "Перезавантажити зараз? (y/n): " REBOOT
if [ "$REBOOT" = "y" ] || [ "$REBOOT" = "Y" ]; then
    sudo reboot
fi
