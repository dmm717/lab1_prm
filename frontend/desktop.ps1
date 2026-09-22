param(
    [ValidateSet('run', 'build')]
    [string]$Mode = 'run'
)
$ErrorActionPreference = 'Stop'
$port = $env:PORT
if ([string]::IsNullOrWhiteSpace($port)) {
    $envFile = Join-Path $PSScriptRoot '..\backend\.env'
    if (Test-Path $envFile) {
        $match = Get-Content $envFile | Select-String -Pattern '^\s*PORT\s*=\s*(\d+)\s*$' | Select-Object -First 1
        if ($match) { $port = $match.Matches[0].Groups[1].Value }
    }
}
if ([string]::IsNullOrWhiteSpace($port)) { $port = '8080' }
if ($port -notmatch '^\d+$') { throw 'PORT trong backend/.env phải là số.' }
$backendDefine = "--dart-define=BACKEND_URL=http://localhost:$port"
Push-Location $PSScriptRoot
try {
    if ($Mode -eq 'build') {
        & flutter build windows --release $backendDefine
    } else {
        & flutter run -d windows $backendDefine
    }
} finally {
    Pop-Location
}
