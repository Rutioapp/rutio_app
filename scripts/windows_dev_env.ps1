$ErrorActionPreference = 'Stop'

$tempDir = 'D:\dev\temp'
$pubCacheDir = 'D:\dev\flutter_cache\pub-cache'
$gradleCacheDir = 'D:\dev\gradle_cache'

foreach ($path in @($tempDir, $pubCacheDir, $gradleCacheDir)) {
    if (-not (Test-Path -LiteralPath $path)) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
    }
}

$env:TEMP = $tempDir
$env:TMP = $tempDir
$env:PUB_CACHE = $pubCacheDir
$env:GRADLE_USER_HOME = $gradleCacheDir

Write-Host 'Current session environment variables:'
Write-Host "  TEMP=$env:TEMP"
Write-Host "  TMP=$env:TMP"
Write-Host "  PUB_CACHE=$env:PUB_CACHE"
Write-Host "  GRADLE_USER_HOME=$env:GRADLE_USER_HOME"
Write-Host ''
Write-Host 'Persist these for future terminals:'
Write-Host '  setx TEMP "D:\dev\temp"'
Write-Host '  setx TMP "D:\dev\temp"'
Write-Host '  setx PUB_CACHE "D:\dev\flutter_cache\pub-cache"'
Write-Host '  setx GRADLE_USER_HOME "D:\dev\gradle_cache"'
Write-Host ''
Write-Host 'Close and reopen PowerShell after running setx for the persistent values to apply.'
