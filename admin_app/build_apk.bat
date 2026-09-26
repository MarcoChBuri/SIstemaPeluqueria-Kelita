@echo off
echo ========================================================
echo   Compilando APK de Peluqueria Raquel Admin (Flutter)
echo ========================================================
echo.

cd /d "%~dp0"

echo [1/2] Limpiando y obteniendo dependencias...
call C:\src\flutter\bin\flutter.bat pub get

echo.
echo [2/2] Generando APK en modo Release...
call C:\src\flutter\bin\flutter.bat build apk --release

echo.
echo ========================================================
echo   APK generado exitosamente en:
echo   admin_app\build\app\outputs\flutter-apk\app-release.apk
echo ========================================================
pause
