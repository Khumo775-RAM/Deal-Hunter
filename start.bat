@echo off
echo Starting DealHunter...

:: Start the backend in a new window
start "DealHunter Backend" cmd /k "cd /d "%~dp0backend" && call venv\Scripts\activate && uvicorn main:app --reload --host 0.0.0.0 --port 8000"

:: Give the backend a couple of seconds to start
timeout /t 3 /nobreak >nul

:: Start the Flutter frontend in a new window
start "DealHunter Frontend" cmd /k "cd /d "%~dp0deal_hunter" && flutter run"
:: flutter run -d DYN6R19510002550

echo Both windows launched. Close this window if you like.
