param([string]$FlutterPath = 'flutter')

$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$appRoot = Join-Path $projectRoot 'app'
$resolvedFlutter = (Get-Command $FlutterPath -ErrorAction Stop).Source
$dartPath = Join-Path (Split-Path $resolvedFlutter) 'cache\dart-sdk\bin\dart.exe'
if (-not (Test-Path -LiteralPath $dartPath)) { throw 'Pass the installed Flutter bin/flutter.bat path.' }
if (-not $env:JAVA_HOME) { $env:JAVA_HOME = Join-Path $env:ProgramFiles 'Android\Android Studio\jbr' }
if (-not $env:ANDROID_HOME) { $env:ANDROID_HOME = Join-Path $env:LOCALAPPDATA 'Android\Sdk' }
$env:ANDROID_SDK_ROOT = $env:ANDROID_HOME
$env:Path = "$env:JAVA_HOME\bin;" + $env:Path
New-Item -ItemType Directory -Force (Join-Path $appRoot 'build') | Out-Null
$logFile = Join-Path $appRoot 'build\verification.log'

Push-Location $appRoot
try {
    & {
        Write-Output 'Formatting Flutter source and tests.'
        & $dartPath format lib test
        if ($LASTEXITCODE -ne 0) { throw 'Formatting failed.' }
        Write-Output 'Checking Flutter source.'
        & $resolvedFlutter analyze --no-pub
        if ($LASTEXITCODE -ne 0) { throw 'Static checks failed.' }
        Write-Output 'Running Flutter tests.'
        & $resolvedFlutter test --no-pub --reporter expanded
        if ($LASTEXITCODE -ne 0) { throw 'Flutter tests failed.' }
        Write-Output 'Building Android debug APK.'
        & $resolvedFlutter build apk --debug --no-pub
        if ($LASTEXITCODE -ne 0) { throw 'Android build failed.' }
        Write-Output 'Verification and Android build passed.'
    } 2>&1 | Tee-Object -FilePath $logFile
} finally {
    Pop-Location
}
