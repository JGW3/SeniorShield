@echo off
echo ================================
echo SeniorShield FREE AI Server
echo ================================
echo.

echo Installing dependencies...
pip install -r requirements.txt

echo.
echo Starting server with FREE local AI...
echo Note: First run will download AI model (~500MB)
echo This may take a few minutes, please wait...
echo.
echo The server will be available at http://localhost:8000
echo Press Ctrl+C to stop the server
echo.

python main.py