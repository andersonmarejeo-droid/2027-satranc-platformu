[CmdletBinding()]
param([string]$ApplicationId = 'com.zpgames.satrancplatformu')

$ErrorActionPreference = 'Stop'
$chessProjectRoot = Split-Path -Parent $PSScriptRoot
$chessKeyProperties = Join-Path $chessProjectRoot 'android\key.properties'
$chessFirebaseFile = Join-Path $chessProjectRoot 'android\app\google-services.json'
$chessResult = [ordered]@{
    applicationId = $ApplicationId
    permanentPackage = ($ApplicationId -match '^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*){2,}$' -and -not $ApplicationId.StartsWith('com.example.'))
    uploadSigningConfigured = $false
    uploadKeystoreExists = $false
    firebaseAndroidConfigPresent = (Test-Path -LiteralPath $chessFirebaseFile -PathType Leaf)
    firebasePackageMatches = $false
    firebaseCoreInstalled = $false
    firebaseInitializationPresent = $false
    recordedFirebaseVerification = $false
    recordedFirebaseChecks = 0
}
if (Test-Path -LiteralPath $chessKeyProperties -PathType Leaf) {
    # Read only the keystore path; never print password properties.
    $chessPropertyLines = @(Get-Content -LiteralPath $chessKeyProperties)
    $chessSigningFieldsPresent = $true
    foreach ($chessField in @('storeFile', 'storePassword', 'keyAlias', 'keyPassword')) {
        if (@($chessPropertyLines | Where-Object { $_ -match ('^' + $chessField + '\s*=\s*\S.*$') }).Count -ne 1) { $chessSigningFieldsPresent = $false }
    }
    $chessStoreLine = @($chessPropertyLines | Where-Object { $_ -match '^storeFile\s*=' })
    if ($chessStoreLine.Count -eq 1) {
        $chessStorePath = ($chessStoreLine[0] -replace '^storeFile\s*=\s*', '').Trim()
        if (-not [System.IO.Path]::IsPathRooted($chessStorePath)) { $chessStorePath = Join-Path (Join-Path $chessProjectRoot 'android') $chessStorePath }
        $chessResult.uploadSigningConfigured = $chessSigningFieldsPresent
        $chessResult.uploadKeystoreExists = Test-Path -LiteralPath $chessStorePath -PathType Leaf
    }
}
if ($chessResult.firebaseAndroidConfigPresent) {
    $chessFirebase = Get-Content -LiteralPath $chessFirebaseFile -Raw | ConvertFrom-Json
    $chessResult.firebasePackageMatches = @($chessFirebase.client | Where-Object { $_.client_info.android_client_info.package_name -eq $ApplicationId }).Count -gt 0
}
$chessPubspec = Get-Content -LiteralPath (Join-Path $chessProjectRoot 'pubspec.yaml') -Raw
$chessMain = Get-Content -LiteralPath (Join-Path $chessProjectRoot 'lib\main.dart') -Raw
$chessResult.firebaseCoreInstalled = $chessPubspec -match '(?m)^\s+firebase_core\s*:'
$chessResult.firebaseInitializationPresent = $chessMain -match 'Firebase\.initializeApp'
$chessProbeLog = Join-Path $chessProjectRoot 'releases\online-070-firebase-verification.log'
if (Test-Path -LiteralPath $chessProbeLog -PathType Leaf) {
    try {
        $chessProbe = Get-Content -LiteralPath $chessProbeLog -Raw | ConvertFrom-Json
        $chessResult.recordedFirebaseVerification = $chessProbe.status -eq 'passed'
        $chessResult.recordedFirebaseChecks = $chessProbe.checks
    } catch { }
}
$chessResult | ConvertTo-Json
Write-Output 'Yerel hazırlık ve saklanan test kaydı gösterilir; bu betik yeni canlı test yapmaz. Güncel yayın durumu store/release-status.json içindedir.'
