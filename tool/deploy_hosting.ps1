$ErrorActionPreference = 'Stop'
if ($args.Count -gt 0) {
  Write-Error 'Nessun argomento extra. Questo script pubblica SOLO Hosting.'
  exit 2
}
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
flutter build web --release
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$sourceConfig = Join-Path $root 'backend\firebase.json'
$hostingConfig = Join-Path $root '.firebase-hosting.generated.json'

try {
  $config = Get-Content $sourceConfig -Raw | ConvertFrom-Json
  $config.hosting.public = 'build/web'
  [pscustomobject]@{ hosting = $config.hosting } |
    ConvertTo-Json -Depth 20 |
    Set-Content $hostingConfig -Encoding UTF8

  npx --yes firebase-tools deploy --only hosting --project amici-per-la-coda --config $hostingConfig
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
finally {
  Remove-Item $hostingConfig -Force -ErrorAction SilentlyContinue
}
