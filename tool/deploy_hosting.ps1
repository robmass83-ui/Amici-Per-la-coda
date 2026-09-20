$ErrorActionPreference = 'Stop'
if ($args.Count -gt 0) {
  Write-Error 'Nessun argomento extra. Questo script pubblica SOLO Hosting.'
  exit 2
}
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
flutter build web --release
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Set-Location (Join-Path $root 'backend')
npx --yes firebase-tools deploy --only hosting --project amici-per-la-coda
