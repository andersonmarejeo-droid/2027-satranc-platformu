param([ValidateRange(1024, 65535)][int]$Port = 8347)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$webRoot = Join-Path $projectRoot 'build\web'
if (-not (Test-Path -LiteralPath (Join-Path $webRoot 'index.html'))) {
    throw 'Önce proje klasöründe flutter build web --release --no-web-resources-cdn çalıştırın.'
}

$pythonExe = Join-Path $env:USERPROFILE '.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
if (-not (Test-Path -LiteralPath $pythonExe)) {
    $pythonCommand = Get-Command python.exe -ErrorAction Stop
    $pythonExe = $pythonCommand.Source
}

$portProbe = [Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback, $Port)
try { $portProbe.Start() } finally { $portProbe.Stop() }
$logRoot = Join-Path $projectRoot '.dart_tool'
$serverProcess = Start-Process -FilePath $pythonExe -ArgumentList @(
    '-m', 'http.server', $Port, '--bind', '127.0.0.1', '--directory', ('"' + $webRoot + '"')
) -WindowStyle Hidden -RedirectStandardOutput (Join-Path $logRoot 'preview.log') -RedirectStandardError (Join-Path $logRoot 'preview-errors.log') -PassThru
[pscustomobject]@{ProcessId=$serverProcess.Id; Port=$Port; Url="http://127.0.0.1:$Port"} |
    ConvertTo-Json | Set-Content -LiteralPath (Join-Path $logRoot 'preview-server.json') -Encoding utf8
Write-Output "Önizleme hazır: http://127.0.0.1:$Port"
Write-Output "Kapatmak için: Stop-Process -Id $($serverProcess.Id)"
