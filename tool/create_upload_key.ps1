[CmdletBinding()]
param(
    [string]$KeytoolPath,
    [switch]$Create
)

$ErrorActionPreference = 'Stop'
$chessProjectRoot = Split-Path -Parent $PSScriptRoot
$chessAndroidRoot = Join-Path $chessProjectRoot 'android'
$chessPrivateRoot = Join-Path $chessAndroidRoot 'private'
$chessKeyFile = Join-Path $chessPrivateRoot 'satranc-upload.p12'
$chessPropertiesFile = Join-Path $chessAndroidRoot 'key.properties'

if (-not $Create) {
    Write-Output 'Hazırlık: ZP GAMES için ayrı bir Play yükleme anahtarı üretilecek.'
    Write-Output ('Şifreli anahtar: ' + $chessKeyFile)
    Write-Output ('Yerel imzalama ayarı: ' + $chessPropertiesFile)
    Write-Output 'Henüz anahtar oluşturulmadı. Oluşturmak için -Create kullanılır.'
    return
}

if ((Test-Path -LiteralPath $chessKeyFile) -or (Test-Path -LiteralPath $chessPropertiesFile)) {
    throw 'Mevcut imzalama dosyası bulundu; yeni anahtar mevcut anahtarın üzerine yazılmaz.'
}
if ([string]::IsNullOrWhiteSpace($KeytoolPath)) {
    . (Join-Path $PSScriptRoot 'chess_java.ps1')
    $chessJdkHome = Get-ChessJavaHome -ProjectRoot $chessProjectRoot
    $KeytoolPath = Join-Path $chessJdkHome 'bin\keytool.exe'
}
if ([string]::IsNullOrWhiteSpace($KeytoolPath) -or -not (Test-Path -LiteralPath $KeytoolPath -PathType Leaf)) {
    throw 'Keytool bulunamadı. Android Studio JBR içindeki keytool.exe yolunu -KeytoolPath ile belirtin.'
}

$chessSecretBytes = New-Object byte[] 32
$chessRandom = [System.Security.Cryptography.RandomNumberGenerator]::Create()
try { $chessRandom.GetBytes($chessSecretBytes) } finally { $chessRandom.Dispose() }
$chessPassword = [Convert]::ToBase64String($chessSecretBytes)
$chessPreviousPassword = $env:CHESS_UPLOAD_KEY_PASSWORD
try {
    New-Item -ItemType Directory -Path $chessPrivateRoot -Force | Out-Null
    $env:CHESS_UPLOAD_KEY_PASSWORD = $chessPassword
    & $KeytoolPath -genkeypair -noprompt -storetype PKCS12 -keystore $chessKeyFile `
        -alias upload -keyalg RSA -keysize 3072 -validity 10000 `
        -dname 'CN=Satranc Platformu Upload, O=ZP GAMES, C=TR' `
        -storepass:env CHESS_UPLOAD_KEY_PASSWORD -keypass:env CHESS_UPLOAD_KEY_PASSWORD
    if ($LASTEXITCODE -ne 0) { throw 'Yükleme anahtarı üretilemedi; imzalama ayarı yazılmadı.' }
    $chessProperties = "storeFile=private/satranc-upload.p12`nstorePassword=$chessPassword`nkeyAlias=upload`nkeyPassword=$chessPassword`n"
    [System.IO.File]::WriteAllText($chessPropertiesFile, $chessProperties, (New-Object System.Text.UTF8Encoding($false)))
    & $KeytoolPath -list -v -keystore $chessKeyFile -alias upload -storepass:env CHESS_UPLOAD_KEY_PASSWORD |
        Select-String 'SHA1:|SHA256:'
    if ($LASTEXITCODE -ne 0) { throw 'Anahtar üretildi ancak sertifika parmak izi kontrol edilemedi.' }
    Write-Output 'Anahtar üretildi. Anahtar ve key.properties dosyalarının güvenli yedeğini saklayın; parolalar yazdırılmadı.'
} finally {
    $env:CHESS_UPLOAD_KEY_PASSWORD = $chessPreviousPassword
    $chessPassword = $null
    $chessProperties = $null
    [Array]::Clear($chessSecretBytes, 0, $chessSecretBytes.Length)
}
