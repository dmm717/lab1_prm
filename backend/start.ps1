$ErrorActionPreference = 'Stop'
$port = $env:PORT
if ([string]::IsNullOrWhiteSpace($port)) {
    $envFile = Join-Path $PSScriptRoot '.env'
    if (Test-Path $envFile) {
        $match = Get-Content $envFile | Select-String -Pattern '^\s*PORT\s*=\s*(\d+)\s*$' | Select-Object -First 1
        if ($match) { $port = $match.Matches[0].Groups[1].Value }
    }
}
if ([string]::IsNullOrWhiteSpace($port)) { $port = '8080' }
if ($port -notmatch '^\d+$') { throw 'PORT trong backend/.env phải là số.' }
Push-Location $PSScriptRoot
try {
    & dart_frog dev --port $port
} finally {
    Pop-Location
}
