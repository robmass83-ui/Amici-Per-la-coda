#Requires -Version 5.1
<#
.SYNOPSIS
  Un solo APK di rilascio: stesso versionCode su pubspec, GitHub Release e ADB.

.DESCRIPTION
  Un solo binario: stesso versionCode e stesso SHA-256 su pubspec, GitHub Latest e ADB.
  Se pubspec è già uguale a Latest, non si incrementa: si installa quella release.
  Altrimenti versionCode = max(pubspec, Latest) + 1 (versionName 1.0.x invariato).
  -Force: nuovo versionCode anche se pubspec = Latest (binario cambiato, es. R8).
  Tag: v{name}+{code}. Gli APK ABI condividono lo stesso intero.
  ADB parte solo dopo che GitHub ha gli stessi file. L'app confronta versionCode
  con /releases/latest; a parità non mostra "Nuova versione".
#>
param(
    [switch]$Force
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$RepoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $RepoRoot

$GhDir = 'C:\Program Files\GitHub CLI'
if (Test-Path -LiteralPath (Join-Path $GhDir 'gh.exe')) {
    $env:Path = "$GhDir;" + $env:Path
}

$Flutter = 'C:\Users\masal\flutter\bin\flutter.bat'
if (-not (Test-Path -LiteralPath $Flutter)) {
    $Flutter = 'flutter'
}
$Sdk = $env:ANDROID_SDK_ROOT
if ([string]::IsNullOrWhiteSpace($Sdk)) {
    $Sdk = $env:ANDROID_HOME
}
if ([string]::IsNullOrWhiteSpace($Sdk)) {
    $Sdk = Join-Path $env:LOCALAPPDATA 'Android\sdk'
}
$env:ANDROID_SDK_ROOT = $Sdk
$Adb = Join-Path $Sdk 'platform-tools\adb.exe'
if (-not (Test-Path -LiteralPath $Adb)) {
    $Adb = 'adb'
}

$PackageId = 'it.amiciperlacoda.amici_per_la_coda'
$LaunchComponent = "$PackageId/.MainActivity"
$ApkDir = Join-Path $RepoRoot 'build\app\outputs\flutter-apk'

function Get-PubspecVersion {
    $line = Select-String -Path (Join-Path $RepoRoot 'pubspec.yaml') -Pattern '^version:\s*(\S+)' |
        Select-Object -First 1
    if ($null -eq $line) {
        throw 'pubspec.yaml senza riga version:'
    }
    $raw = $line.Matches[0].Groups[1].Value.Trim()
    $name = $raw
    $code = 0
    $plus = $raw.IndexOf('+')
    if ($plus -ge 0) {
        $name = $raw.Substring(0, $plus)
        $parsed = 0
        if ([int]::TryParse($raw.Substring($plus + 1), [ref]$parsed)) {
            $code = $parsed
        }
    }
    return [pscustomobject]@{ Name = $name; Code = $code; Raw = $raw }
}

function Get-GithubLatestCode {
    $tag = ''
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $tag = (& gh release view --json tagName --jq .tagName 2>$null | Out-String).Trim()
        if ($LASTEXITCODE -ne 0) {
            return 0
        }
    } finally {
        $ErrorActionPreference = $prevEap
    }
    if ([string]::IsNullOrWhiteSpace($tag) -or $tag -eq 'null') {
        return 0
    }
    $raw = $tag.Trim()
    if ($raw.StartsWith('v') -or $raw.StartsWith('V')) {
        $raw = $raw.Substring(1)
    }
    $plus = $raw.LastIndexOf('+')
    if ($plus -lt 0) {
        return 0
    }
    $parsed = 0
    if ([int]::TryParse($raw.Substring($plus + 1), [ref]$parsed)) {
        return $parsed
    }
    return 0
}

function Set-PubspecVersion([string]$Name, [int]$Code) {
    $path = Join-Path $RepoRoot 'pubspec.yaml'
    $text = [System.IO.File]::ReadAllText($path)
    $updated = [regex]::Replace(
        $text,
        '(?m)^version:\s*\S+',
        "version: $Name+$Code",
        1
    )
    if ($updated -eq $text -and $text -notmatch "(?m)^version:\s*$([regex]::Escape("$Name+$Code"))") {
        throw "Non riesco ad aggiornare version in pubspec.yaml"
    }
    $utf8 = New-Object System.Text.UTF8Encoding $false
    $newLine = if ($text.Contains("`r`n")) { "`r`n" } else { "`n" }
    if ($newLine -eq "`n") {
        $updated = $updated.Replace("`r`n", "`n")
    }
    [System.IO.File]::WriteAllText($path, $updated, $utf8)
}

function Find-Aapt {
    $buildTools = Join-Path $Sdk 'build-tools'
    if (-not (Test-Path -LiteralPath $buildTools)) {
        throw "SDK Android non trovato: $Sdk"
    }
    $aapt = Get-ChildItem -Path $buildTools -Filter aapt.exe -Recurse -ErrorAction SilentlyContinue |
        Sort-Object { $_.Directory.Name } -Descending |
        Select-Object -First 1
    if ($null -eq $aapt) {
        throw "aapt.exe non trovato in $buildTools"
    }
    return $aapt.FullName
}

function Get-ApkVersionCode([string]$Aapt, [string]$Apk) {
    $dump = & $Aapt dump badging $Apk | Out-String
    $match = [regex]::Match($dump, "versionCode='(\d+)'")
    if (-not $match.Success) {
        throw "versionCode illeggibile in $Apk"
    }
    return [int]$match.Groups[1].Value
}

function Get-ConnectedSerials {
    $lines = & $Adb devices
    $serials = @()
    foreach ($line in $lines) {
        if ($line -match '^(\S+)\s+device$') {
            $serials += $Matches[1]
        }
    }
    return $serials
}

function Get-DeviceAbi([string]$Serial) {
    $abi = (& $Adb -s $Serial shell getprop ro.product.cpu.abi | Out-String).Trim()
    if ([string]::IsNullOrWhiteSpace($abi)) {
        return 'arm64-v8a'
    }
    return $abi
}

function Find-ApkForAbi([string]$Abi, [string[]]$Apks) {
    $needle = $Abi.ToLowerInvariant()
    foreach ($apk in $Apks) {
        if ((Split-Path -Leaf $apk).ToLowerInvariant().Contains($needle)) {
            return $apk
        }
    }
    return $null
}

function Get-ReleaseApkPaths([string]$Directory) {
    if (-not (Test-Path -LiteralPath $Directory)) {
        return @()
    }
    return @(Get-ChildItem -Path $Directory -Filter 'app-*-release.apk' -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match '^app-(arm64-v8a|armeabi-v7a|x86_64)-release\.apk$' } |
        ForEach-Object { $_.FullName })
}

function Get-ApkSha256([string]$Path) {
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Get-GithubAssetDigestMap([string]$Tag) {
    $json = & gh release view $Tag --json assets | ConvertFrom-Json
    $map = @{}
    foreach ($asset in @($json.assets)) {
        $assetName = [string]$asset.name
        if ($assetName -notlike '*.apk') {
            continue
        }
        $digest = [string]$asset.digest
        if ($digest.StartsWith('sha256:')) {
            $digest = $digest.Substring(7)
        }
        $map[$assetName] = $digest.ToLowerInvariant()
    }
    return $map
}

function Assert-ApkVersionCodes([string[]]$Apks, [int]$Code) {
    $aapt = Find-Aapt
    foreach ($apk in $Apks) {
        $apkCode = Get-ApkVersionCode -Aapt $aapt -Apk $apk
        if ($apkCode -ne $Code) {
            throw "$(Split-Path -Leaf $apk) ha versionCode $apkCode, atteso $Code."
        }
        Write-Host "OK $(Split-Path -Leaf $apk) versionCode=$apkCode"
    }
}

function Assert-ApksMatchGithub([string]$Tag, [string[]]$Apks) {
    $remote = Get-GithubAssetDigestMap $Tag
    if ($remote.Count -lt 1) {
        throw "Release GitHub $Tag senza APK."
    }
    foreach ($apk in $Apks) {
        $fileName = Split-Path -Leaf $apk
        $localHash = Get-ApkSha256 $apk
        if (-not $remote.ContainsKey($fileName)) {
            throw "GitHub $Tag non contiene $fileName. ADB non installa un APK assente su GitHub."
        }
        $remoteHash = [string]$remote[$fileName]
        if ([string]::IsNullOrWhiteSpace($remoteHash)) {
            throw "GitHub ${Tag}: digest mancante per $fileName."
        }
        if ($remoteHash -ne $localHash) {
            throw "$fileName sul PC ($localHash) diverso da GitHub ($remoteHash). Stesso numero, file diverso: fermo."
        }
        Write-Host "OK stesso file $fileName"
    }
}

function Get-ApksFromGithubRelease([string]$Tag, [int]$Code) {
    $dest = Join-Path $env:TEMP "amici-apk-github-$Code"
    if (Test-Path -LiteralPath $dest) {
        Remove-Item -LiteralPath $dest -Recurse -Force
    }
    New-Item -ItemType Directory -Path $dest | Out-Null
    Write-Host "Scarico APK di GitHub $Tag (stessi file della Latest)..."
    & gh release download $Tag --pattern 'app-*-release.apk' --dir $dest --clobber
    if ($LASTEXITCODE -ne 0) {
        throw "Download GitHub $Tag fallito."
    }
    $downloaded = @(Get-ReleaseApkPaths $dest)
    if ($downloaded.Count -lt 2) {
        throw "Download GitHub ${Tag}: APK insufficienti."
    }
    Assert-ApkVersionCodes $downloaded $Code
    Assert-ApksMatchGithub $Tag $downloaded
    return $downloaded
}

function Stop-StaleReleaseRuns([string]$KeepTag) {
    $ids = @()
    foreach ($status in @('queued', 'in_progress', 'waiting', 'requested', 'pending')) {
        $raw = & gh run list --workflow 'release-apk.yml' --status $status --json databaseId |
            ConvertFrom-Json
        foreach ($run in @($raw)) {
            $id = [string]$run.databaseId
            if ($id) { $ids += $id }
        }
    }
    $ids = $ids | Select-Object -Unique
    foreach ($id in $ids) {
        Write-Host "Annullo GitHub Action ${id}: non deve ripubblicare main sopra $KeepTag."
        & gh run cancel $id | Out-Null
    }
    return @($ids).Count
}

Write-Host '=== Amici per la Coda: un solo APK (GitHub = PC = ADB) ==='

$ghOk = $false
$prevEap = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
try {
    & gh auth status 2>$null | Out-Null
    $ghOk = ($LASTEXITCODE -eq 0)
} finally {
    $ErrorActionPreference = $prevEap
}
if (-not $ghOk) {
    throw 'gh non autenticato. Esegui gh auth login, poi ritenta.'
}

$pub = Get-PubspecVersion
$prevCode = Get-GithubLatestCode
$name = $pub.Name
$apks = @()

if (-not $Force -and $pub.Code -gt 0 -and $pub.Code -eq $prevCode) {
    $code = $pub.Code
    $tag = "v$name+$code"
    $version = "$name+$code"
    Write-Host "PC e GitHub gia allineati su $version. Non creo un altro versionCode."
    $local = @(Get-ReleaseApkPaths $ApkDir)
    $useLocal = $false
    if ($local.Count -ge 2) {
        try {
            Assert-ApkVersionCodes $local $code
            Assert-ApksMatchGithub $tag $local
            $useLocal = $true
        } catch {
            Write-Host $_.Exception.Message
            Write-Host 'APK locali diversi da GitHub: installo i file di GitHub.'
        }
    }
    if ($useLocal) {
        $apks = $local
    } else {
        $apks = @(Get-ApksFromGithubRelease -Tag $tag -Code $code)
    }
} else {
    $max = $pub.Code
    if ($prevCode -gt $max) {
        $max = $prevCode
    }
    $code = $max + 1
    $tag = "v$name+$code"
    $version = "$name+$code"

    if ($Force -and $pub.Code -eq $prevCode) {
        Write-Host "Force: pubspec e GitHub erano $name+$($pub.Code). Nuovo versionCode $code (binario nuovo)."
    }

    Write-Host "pubspec=$($pub.Raw) github_code=$prevCode -> $version  tag=$tag"
    Set-PubspecVersion -Name $name -Code $code

    Write-Host 'Build APK release (split per ABI, stesso versionCode)...'
    cmd /c "`"$Flutter`" pub get"
    if ($LASTEXITCODE -ne 0) {
        throw 'flutter pub get fallito'
    }
    cmd /c "`"$Flutter`" build apk --release --split-per-abi --build-name=$name --build-number=$code -Pforce-version-code-ignoring-abi=true"
    if ($LASTEXITCODE -ne 0) {
        throw 'flutter build apk fallito'
    }

    $apks = @(Get-ReleaseApkPaths $ApkDir)
    if ($apks.Count -lt 2) {
        throw "Servono gli APK ABI in $ApkDir (trovati: $($apks.Count))"
    }
    Assert-ApkVersionCodes $apks $code

    $notes = @"
Build di test $version.
Stesso versionCode e stesso SHA-256 su GitHub e sul telefono (ADB). Android installa solo un codice strettamente maggiore; a parita l'app non mostra "Nuova versione".
"@
    $noteFile = Join-Path $env:TEMP "amici-release-$code.md"
    [System.IO.File]::WriteAllText($noteFile, $notes)

    Write-Host "Pubblico GitHub Release $tag..."
    $ghArgs = @('release', 'create', $tag, '--title', "Amici per la Coda $version", '--notes-file', $noteFile, '--latest')
    $ghArgs += $apks
    & gh @ghArgs
    if ($LASTEXITCODE -ne 0) {
        throw "gh release create $tag fallito. Non installo via ADB un binario non pubblicato."
    }

    $prevCancel = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $deadline = [datetime]::UtcNow.AddSeconds(45)
        do {
            Stop-StaleReleaseRuns -KeepTag $tag | Out-Null
            Start-Sleep -Seconds 5
        } while ([datetime]::UtcNow -lt $deadline)
        $latestNow = (& gh release view --json tagName --jq .tagName 2>$null | Out-String).Trim()
        if ($latestNow -ne $tag) {
            throw "Latest GitHub e' $latestNow, atteso ${tag}. CI ha sovrascritto la build locale."
        }
        Write-Host "Latest GitHub confermato: $tag"
    } finally {
        $ErrorActionPreference = $prevCancel
    }

    Assert-ApksMatchGithub $tag $apks
}

$latestNow = (& gh release view --json tagName --jq .tagName 2>$null | Out-String).Trim()
if ($latestNow -ne $tag) {
    throw "Latest GitHub e' $latestNow, atteso ${tag}. Non installo via ADB un'altra versione."
}

$serials = @()
try {
    $serials = @(Get-ConnectedSerials)
} catch {
    Write-Host "ADB non disponibile: $($_.Exception.Message). GitHub $version invariato."
    Write-Host "FATTO $version  (solo GitHub, stesso SHA-256 del PC)"
    exit 0
}
if ($serials.Count -eq 0) {
    Write-Host 'Nessun telefono in adb devices: niente sideload. Il telefono prende GitHub Latest in-app, stesso APK.'
    Write-Host "FATTO $version  (solo GitHub, stesso SHA-256 del PC)"
    exit 0
}

foreach ($serial in $serials) {
    $abi = Get-DeviceAbi -Serial $serial
    $apk = Find-ApkForAbi -Abi $abi -Apks $apks
    if ($null -eq $apk) {
        Write-Host "DISPOSITIVO $serial ABI ${abi}: nessun APK corrispondente, salto ADB."
        continue
    }
    Write-Host "ADB $serial ($abi) <- $(Split-Path -Leaf $apk) $version (stesso file GitHub)"
    try {
        & $Adb -s $serial install -r $apk
        if ($LASTEXITCODE -ne 0) {
            Write-Host "ADB install fallita su $serial. Il telefono usera l'aggiornamento in-app (stesso APK GitHub)."
            continue
        }
        & $Adb -s $serial shell am start -n $LaunchComponent | Out-Null
        $pkg = (& $Adb -s $serial shell dumpsys package $PackageId | Out-String)
        $installed = [regex]::Match($pkg, "versionCode=(\d+)")
        if ($installed.Success -and [int]$installed.Groups[1].Value -ne $code) {
            throw "Telefono $serial ha versionCode $($installed.Groups[1].Value), GitHub e' $code."
        }
    } catch {
        Write-Host "ADB install fallita su ${serial}: $($_.Exception.Message). Aggiornamento in-app."
    }
}

Write-Host "FATTO $version  (GitHub + ADB, stesso SHA-256). Il telefono collegato e gia a ${code}: niente foglio aggiornamento."
exit 0
