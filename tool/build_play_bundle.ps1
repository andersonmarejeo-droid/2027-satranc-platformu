[CmdletBinding()]
param(
    [string]$ApplicationId = 'com.zpgames.satrancplatformu',
    [string]$FlutterSdk = 'C:\flutter',
    [string]$JdkHome,
    [bool]$EnableServerAuthority = $false
)

$ErrorActionPreference = 'Stop'
$chessProjectRoot = Split-Path -Parent $PSScriptRoot
$chessPropertiesFile = Join-Path $chessProjectRoot 'android\key.properties'
if ($ApplicationId -notmatch '^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*){2,}$' -or $ApplicationId.StartsWith('com.example.')) {
    throw 'Play için geçerli, kalıcı bir paket adı gerekir.'
}
if (-not (Test-Path -LiteralPath $chessPropertiesFile -PathType Leaf)) {
    throw 'Play yükleme anahtarı hazır değil. Önce tool/create_upload_key.ps1 ile imzalama hazırlanmalı.'
}
$chessDart = Join-Path $FlutterSdk 'bin\cache\dart-sdk\bin\dart.exe'
$chessFlutterTools = Join-Path $FlutterSdk 'bin\cache\flutter_tools.snapshot'
if (-not (Test-Path -LiteralPath $chessDart) -or -not (Test-Path -LiteralPath $chessFlutterTools)) {
    throw 'Flutter araçları bulunamadı. -FlutterSdk ile mevcut Flutter SDK yolunu belirtin.'
}
. (Join-Path $PSScriptRoot 'chess_java.ps1')
$chessJdkHome = Get-ChessJavaHome -ProjectRoot $chessProjectRoot -JdkHome $JdkHome
$chessEnvironmentNames = @('ORG_GRADLE_PROJECT_chessStoreBuild', 'ORG_GRADLE_PROJECT_chessStoreApplicationId', 'APPDATA', 'LOCALAPPDATA', 'JAVA_HOME')
$chessPreviousEnvironment = @{}
foreach ($chessName in $chessEnvironmentNames) { $chessPreviousEnvironment[$chessName] = [Environment]::GetEnvironmentVariable($chessName, 'Process') }
Push-Location -LiteralPath $chessProjectRoot
try {
    $env:ORG_GRADLE_PROJECT_chessStoreBuild = 'true'
    $env:ORG_GRADLE_PROJECT_chessStoreApplicationId = $ApplicationId
    $env:JAVA_HOME = $chessJdkHome
    $chessToolState = Join-Path $env:TEMP 'CodexChessFlutterState'
    New-Item -ItemType Directory -Path $chessToolState -Force | Out-Null
    $env:APPDATA = $chessToolState
    $env:LOCALAPPDATA = $chessToolState
    # integration_test is a dev dependency. Flutter 3.47 can still place its
    # Android plugin in the release registrant, where the production app has
    # no corresponding Gradle module. Generate plugins first, then remove only
    # that dev-only registration before the release build.
    & $chessDart $chessFlutterTools --suppress-analytics pub get
    if ($LASTEXITCODE -ne 0) { throw 'Flutter paketleri çözülemedi.' }
    $chessRegistrant = Join-Path $chessProjectRoot 'android\app\src\main\java\io\flutter\plugins\GeneratedPluginRegistrant.java'
    if (Test-Path -LiteralPath $chessRegistrant -PathType Leaf) {
        $chessRegistrantText = Get-Content -Raw -LiteralPath $chessRegistrant
        $chessRegistrantText = [regex]::Replace(
            $chessRegistrantText,
            '(?s)\r?\n    try \{\r?\n      flutterEngine\.getPlugins\(\)\.add\(new dev\.flutter\.plugins\.integration_test\.IntegrationTestPlugin\(\)\);\r?\n    \} catch \(Exception e\) \{\r?\n      Log\.e\(TAG, "Error registering plugin integration_test, dev\.flutter\.plugins\.integration_test\.IntegrationTestPlugin", e\);\r?\n    \}',
            ''
        )
        Set-Content -LiteralPath $chessRegistrant -Value $chessRegistrantText -Encoding UTF8
    }
    $chessAuthorityDefine = 'CHESS_SERVER_AUTHORITY_ENABLED=' + $EnableServerAuthority.ToString().ToLowerInvariant()
    & $chessDart $chessFlutterTools --suppress-analytics build appbundle --release `
        --dart-define=CHESS_FIREBASE_ENABLED=true `
        --dart-define=CHESS_APP_CHECK_ENABLED=true `
        --dart-define=CHESS_TELEMETRY_ENABLED=true `
        ('--dart-define=' + $chessAuthorityDefine) `
        '--android-project-arg=chessStoreBuild=true' `
        ('--android-project-arg=chessStoreApplicationId=' + $ApplicationId)
    if ($LASTEXITCODE -ne 0) { throw 'Play paketi derlenemedi; yeni teslim dosyası oluşturulmadı.' }
    $chessSourceBundle = Join-Path $chessProjectRoot 'build\app\outputs\bundle\release\app-release.aab'
    if (-not (Test-Path -LiteralPath $chessSourceBundle -PathType Leaf)) { throw 'Başarılı derleme sonrasında AAB dosyası bulunamadı.' }
    $chessMergedManifest = Join-Path $chessProjectRoot 'build\app\intermediates\merged_manifest\release\processReleaseMainManifest\AndroidManifest.xml'
    [xml]$chessManifest = Get-Content -Raw -LiteralPath $chessMergedManifest
    if ($chessManifest.manifest.package -ne $ApplicationId) { throw 'Derlenen Android kimliği mağaza kimliğiyle uyuşmuyor; teslim dosyası üretilmedi.' }
    $chessCertificateText = & (Join-Path $chessJdkHome 'bin\keytool.exe') -printcert -jarfile $chessSourceBundle 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0 -or $chessCertificateText -match 'CN=Android Debug' -or $chessCertificateText -notmatch 'Satranc Platformu Upload') {
        throw 'App Bundle yükleme imzasını taşımıyor; teslim dosyası üretilmedi.'
    }
    $chessVersionLine = Get-Content -LiteralPath (Join-Path $chessProjectRoot 'pubspec.yaml') | Where-Object { $_ -match '^version:\s*(\S+)\s*$' }
    if ($chessVersionLine.Count -ne 1) { throw 'Teslim dosyası için sürüm belirlenemedi.' }
    $chessVersion = ($chessVersionLine -replace '^version:\s*', '').Trim()
    $chessReleases = Join-Path $chessProjectRoot 'releases'
    New-Item -ItemType Directory -Path $chessReleases -Force | Out-Null
    $chessDestination = Join-Path $chessReleases ('satranc-platformu-play-' + $chessVersion + '.aab')
    Copy-Item -LiteralPath $chessSourceBundle -Destination $chessDestination
    Write-Output ('Hazır Play paketi: ' + $chessDestination)
    Write-Output ('Paket kimliği: ' + $ApplicationId)
    Write-Output ('SHA-256: ' + (Get-FileHash -LiteralPath $chessDestination -Algorithm SHA256).Hash)
} finally {
    Pop-Location
    foreach ($chessName in $chessEnvironmentNames) { [Environment]::SetEnvironmentVariable($chessName, $chessPreviousEnvironment[$chessName], 'Process') }
}
