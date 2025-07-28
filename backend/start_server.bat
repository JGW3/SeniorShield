@echo off
echo Installing Python dependencies...
pip install -r requirements.txt

echo Starting SeniorShield Backend Server...
echo The server will be available at http://localhost:8000
echo Press Ctrl+C to stop the server

python main.py