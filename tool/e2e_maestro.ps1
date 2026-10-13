<#
.SYNOPSIS
  Corre los flujos Maestro (.maestro/) contra el backend e2e local y genera el informe QA.

.DESCRIPTION
  1. Verifica que el backend e2e responda en /swagger-json (NO lo levanta: `pnpm e2e:serve` en el repo Backend).
  2. Compila el APK debug con dart_defines.e2e.json.
  3. Instala el APK en el dispositivo/emulador conectado (adb).
  4. maestro test .maestro --format junit --output build/qa/maestro.xml
  5. dart run tool/qa_report.dart build/qa/maestro.xml flujo  -> test/qa/informes/AAAA-MM-DD_flujo_<rama>.md

  Requisitos: Flutter, JDK 17, adb, Maestro en el PATH (ver test/qa/README.md), un emulador o
  dispositivo visible en `adb devices`, y dart_defines.e2e.json (copia de dart_defines.e2e.example.json).

.PARAMETER Backend
  Base del backend e2e vista DESDE LA PC (default http://localhost:3100/tekoapp-backend/api).

.PARAMETER Reverse
  Hace `adb reverse tcp:3100 tcp:3100` (dispositivo fisico con API_BASE_URL=http://localhost:3100/...).

.PARAMETER SkipBuild
  Reusa el APK ya compilado en build/app/outputs/flutter-apk/app-debug.apk.
#>
[CmdletBinding()]
param(
  [string]$Backend = 'http://localhost:3100/tekoapp-backend/api',
  [switch]$Reverse,
  [switch]$SkipBuild
)

$ErrorActionPreference = 'Stop'
Set-Location (Split-Path -Parent $PSScriptRoot)

function Fail([string]$msg) { Write-Error $msg; exit 1 }

# 0. Prerrequisitos
foreach ($cmd in 'flutter', 'adb', 'maestro', 'dart') {
  if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) { Fail "Falta '$cmd' en el PATH." }
}
if (-not (Test-Path 'dart_defines.e2e.json')) {
  Fail 'Falta dart_defines.e2e.json (copiar de dart_defines.e2e.example.json).'
}
$devices = (adb devices | Select-String -Pattern "`tdevice$").Count
if ($devices -lt 1) { Fail "No hay dispositivo/emulador en 'adb devices'. Sin dispositivo no hay ejecucion ni informe de Maestro." }

# 1. Backend e2e vivo
$swagger = "$Backend/swagger-json"
try {
  $r = Invoke-WebRequest -Uri $swagger -UseBasicParsing -TimeoutSec 10
  if ($r.StatusCode -ne 200) { Fail "Backend respondio $($r.StatusCode) en $swagger" }
  Write-Host "[e2e] backend OK: $swagger"
} catch {
  Fail "Backend e2e no responde en $swagger. Levantarlo en el repo Backend: pnpm e2e:up; pnpm e2e:seed; pnpm e2e:serve"
}

# 2. Build debug
$apk = 'build/app/outputs/flutter-apk/app-debug.apk'
if (-not $SkipBuild) {
  flutter build apk --debug --dart-define-from-file=dart_defines.e2e.json
  if ($LASTEXITCODE -ne 0) { Fail 'flutter build apk fallo.' }
}
if (-not (Test-Path $apk)) { Fail "No existe $apk" }

# 3. Instalar
if ($Reverse) { adb reverse tcp:3100 tcp:3100 }
adb install -r $apk
if ($LASTEXITCODE -ne 0) { Fail 'adb install fallo.' }

# 4. Maestro (continueOnFailure en .maestro/config.yaml: corre todos los flujos aunque alguno falle)
New-Item -ItemType Directory -Force build/qa, build/qa/maestro | Out-Null
maestro test .maestro --format junit --output build/qa/maestro.xml
$maestroExit = $LASTEXITCODE

# 5. Informe (solo si hubo ejecucion real y produjo el XML)
if (Test-Path build/qa/maestro.xml) {
  $env:QA_COMMAND = 'pwsh tool/e2e_maestro.ps1'
  dart run tool/qa_report.dart build/qa/maestro.xml flujo
} else {
  Write-Warning 'Maestro no genero build/qa/maestro.xml: no se escribe informe.'
}
exit $maestroExit
