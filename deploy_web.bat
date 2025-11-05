@echo off
echo Building Flutter Web Application...
flutter build web --release

echo.
echo Build completed! Web files are in: build\web\
echo.
echo To deploy:
echo 1. Upload all files from build\web\ to your web server
echo 2. Or use Firebase Hosting: firebase deploy
echo 3. Or use GitHub Pages by copying files to docs folder
echo.
echo The app includes:
echo - HiveMap Editor (interactive alliance map editor)
echo - Resource Calculators (building, troop, gear calculations)
echo - Supabase integration for cloud save/sync
echo.
pause