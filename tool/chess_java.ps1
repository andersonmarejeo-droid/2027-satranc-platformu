function Get-ChessJavaHome {
    [CmdletBinding()]
    param([string]$ProjectRoot, [string]$JdkHome)

    if (-not [string]::IsNullOrWhiteSpace($JdkHome)) {
        if (-not (Test-Path -LiteralPath (Join-Path $JdkHome 'bin\java.exe') -PathType Leaf)) { throw 'Belirtilen Java konumunda java.exe bulunamadı.' }
        return $JdkHome
    }
    $chessPortableRoot = Join-Path $ProjectRoot '.tools\java21'
    if (Test-Path -LiteralPath $chessPortableRoot -PathType Container) {
        $chessPortableCandidates = @(Get-ChildItem -LiteralPath $chessPortableRoot -Directory -Filter 'jdk-21*' |
            Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'bin\java.exe') -PathType Leaf })
        if ($chessPortableCandidates.Count -eq 1) { return $chessPortableCandidates[0].FullName }
        if ($chessPortableCandidates.Count -gt 1) { throw 'Birden fazla proje JDK bulundu; -JdkHome ile birini açıkça seçin.' }
    }
    if ($env:JAVA_HOME -and (Test-Path -LiteralPath (Join-Path $env:JAVA_HOME 'bin\java.exe') -PathType Leaf)) { return $env:JAVA_HOME }
    throw 'Geçerli Java bulunamadı. Proje Java ortamını hazırlayın veya -JdkHome ile kurulu JDK yolunu belirtin.'
}
