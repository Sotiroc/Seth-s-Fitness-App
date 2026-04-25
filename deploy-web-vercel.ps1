param(
  [string]$ProjectName = 'seth-fitness-app',
  [string]$Scope = 'sethsotiralis-gmailcoms-projects',
  [switch]$SkipDeploy
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$buildOutput = Join-Path $repoRoot 'build\web'
$vercelConfigPath = Join-Path $buildOutput 'vercel.json'
$vercelConfig = @'
{
  "rewrites": [
    {
      "source": "/(.*)",
      "destination": "/index.html"
    }
  ]
}
'@

function Assert-CommandAvailable {
  param([string]$CommandName)

  if (-not (Get-Command $CommandName -ErrorAction SilentlyContinue)) {
    throw "Required command '$CommandName' was not found in PATH."
  }
}

Assert-CommandAvailable 'flutter'
Assert-CommandAvailable 'vercel'

Push-Location $repoRoot
try {
  Write-Host 'Building Flutter web release...'
  flutter build web --release

  if (-not (Test-Path $buildOutput)) {
    throw "Expected build output at '$buildOutput' was not created."
  }

  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($vercelConfigPath, $vercelConfig, $utf8NoBom)

  if ($SkipDeploy) {
    Write-Host 'Skipping Vercel link and deploy.'
    return
  }

  Push-Location $buildOutput
  try {
    Write-Host "Linking Vercel project '$ProjectName' in scope '$Scope'..."
    vercel link --yes --project $ProjectName --scope $Scope

    Write-Host 'Deploying production build to Vercel...'
    vercel deploy --prod --yes --scope $Scope
  }
  finally {
    Pop-Location
  }
}
finally {
  Pop-Location
}