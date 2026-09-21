param([ValidateSet('run','test','ui-test','match-test','match-ui-test','author-match','import','apk','editor','windows','web')][string]$Action = 'run')
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
$engine = Get-ChildItem -LiteralPath "$PSScriptRoot/.tools/godot" -Filter '*console.exe' -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
if (-not $engine) { $engine = $env:GODOT_BIN }
if (-not $engine -or -not (Test-Path -LiteralPath $engine)) { throw 'Install Godot 4.7.2 in .tools/godot or set GODOT_BIN to the executable.' }
switch ($Action) {
  'match-test' { & $engine --headless --path $PSScriptRoot --script res://tests/match.gd }
  'match-ui-test' { New-Item -ItemType Directory -Force artifacts | Out-Null; & $engine --path $PSScriptRoot --script res://tests/match_ui.gd }
  'author-match' { & $engine --headless --path $PSScriptRoot --script res://tests/author_match.gd }
  'web' {
    New-Item -ItemType Directory -Force web-site/dist | Out-Null
    & $engine --headless --path $PSScriptRoot --export-release Web web-site/dist/index.html
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    python tools_web.py
  }
  'run' { & $engine --path $PSScriptRoot }
  'editor' { & $engine --path $PSScriptRoot --editor }
  'import' { & $engine --headless --path $PSScriptRoot --editor --import }
  'test' { & $engine --headless --path $PSScriptRoot --script res://tests/run.gd }
  'ui-test' { New-Item -ItemType Directory -Force artifacts | Out-Null; & $engine --path $PSScriptRoot --script res://tests/ui.gd }
  'apk' {
    New-Item -ItemType Directory -Force artifacts | Out-Null
    $buildPath = $PSScriptRoot
    if ($PSScriptRoot -match '[^\x00-\x7F]') {
      $buildPath = Join-Path $env:USERPROFILE 'GardenOfLightBuild'
      if (Test-Path -LiteralPath $buildPath) {
        $link = Get-Item -LiteralPath $buildPath
        if ($link.LinkType -ne 'Junction' -or [string]$link.Target -ne $PSScriptRoot) { throw 'GardenOfLightBuild exists and points elsewhere. Use an ASCII project path for Android export.' }
      } else { New-Item -ItemType Junction -Path $buildPath -Target $PSScriptRoot | Out-Null }
    }
    $templateArgs = @()
    if (-not (Test-Path -LiteralPath "$PSScriptRoot/android/build/build.gradle")) { $templateArgs = @('--install-android-build-template') }
    & $engine --headless --path $buildPath @templateArgs --export-debug Android "$buildPath/artifacts/garden-of-light-prototype.apk"
  }
  'windows' { New-Item -ItemType Directory -Force artifacts | Out-Null; & $engine --headless --path $PSScriptRoot --export-release Windows artifacts/garden-of-light.exe }
}
exit $LASTEXITCODE
