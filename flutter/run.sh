#!/bin/bash
pip3 install -q -r automated-email-sender/requirements.txt
python3 automated-email-sender/mailer.py &
SERVER_PID=$!
trap "kill $SERVER_PID 2>/dev/null" EXIT
flutter run -d chrome
