#!/bin/bash
cd "$(dirname "$(readlink -f "$0")")"
. venv/bin/activate

# ВИПРАВЛЕНО: використовуємо python3 зі стабільної версії venv, не хардкодимо 3.14
python3 app.py &
sleep 3
firefox --kiosk http://localhost:5000
