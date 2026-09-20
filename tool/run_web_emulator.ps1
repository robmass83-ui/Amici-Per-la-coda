$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$env:FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080'
$env:FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9099'

function Test-TcpOpen {
  param(
    [string]$TargetHost,
    [int]$Port,
    [int]$TimeoutMs = 400
  )
  $client = [System.Net.Sockets.TcpClient]::new()
  try {
    $iar = $client.BeginConnect($TargetHost, $Port, $null, $null)
    if (-not $iar.AsyncWaitHandle.WaitOne($TimeoutMs, $false)) {
      return $false
    }
    $client.EndConnect($iar)
    return $client.Connected
  } catch {
    return $false
  } finally {
    $client.Dispose()
  }
}

Start-Process -WorkingDirectory (Join-Path $root 'backend') npx -ArgumentList '--yes','firebase-tools','emulators:start','--only','auth,firestore,hosting','--project','amici-per-la-coda'

$deadline = (Get-Date).AddSeconds(60)
$ready = $false
while ((Get-Date) -lt $deadline) {
  if ((Test-TcpOpen -TargetHost '127.0.0.1' -Port 8080) -or (Test-TcpOpen -TargetHost '127.0.0.1' -Port 9099)) {
    $ready = $true
    break
  }
  Start-Sleep -Milliseconds 500
}
if (-not $ready) {
  Write-Error 'Emulatori Firebase non pronti entro 60s (127.0.0.1:8080 / 9099). Flutter non viene avviato.'
  exit 1
}

Set-Location $root
flutter run -d chrome --dart-define=AMICI_USE_EMULATOR=true
