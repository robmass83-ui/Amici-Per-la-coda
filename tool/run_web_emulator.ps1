$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$env:FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080'
$env:FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9099'
Start-Process -WorkingDirectory (Join-Path $root 'backend') npx -ArgumentList '--yes','firebase-tools','emulators:start','--only','auth,firestore,hosting','--project','demo-amici-web'
Start-Sleep -Seconds 8
Set-Location $root
flutter run -d chrome --dart-define=AMICI_USE_EMULATOR=true
