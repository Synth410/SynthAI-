#!/bin/bash
cd /home/diag/autodiag
. venv/bin/activate

# ВИПРАВЛЕНО: використовуємо python3 зі стабільної версії venv, не хардкодимо 3.14
python3 app.py &
sleep 3
firefox --kiosk http://localhost:5000
