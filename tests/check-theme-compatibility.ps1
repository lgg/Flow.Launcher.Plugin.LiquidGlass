# Fail fast if generated XAML references Base.xaml resources missing in stable Flow Launcher.
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = Split-Path -Parent $PSScriptRoot
$themeWriter = Get-Content -LiteralPath (Join-Path $root 'ThemeWriter.cs') -Raw
$available = @(
    Get-Content -LiteralPath (Join-Path $PSScriptRoot 'flow-2.1.4-base-keys.txt') |
        Where-Object { $_ -and -not $_.StartsWith('#') }
)
$references = @(
    [regex]::Matches($themeWriter, 'StaticResource\s+(Base[A-Za-z0-9]+)') |
        ForEach-Object { $_.Groups[1].Value } |
        Sort-Object -Unique
)
$missing = @($references | Where-Object { $_ -notin $available })
if ($missing.Count -gt 0) {
    throw "ThemeWriter.cs references unavailable Flow Launcher 2.0.0-2.1.4 resources: $($missing -join ', ')"
}

# Keep the published plugin metadata consistent with the built DLL.
$plugin = Get-Content -LiteralPath (Join-Path $root 'plugin.json') -Raw | ConvertFrom-Json
[xml]$project = Get-Content -LiteralPath (Join-Path $root 'Flow.Launcher.Plugin.LiquidGlass.csproj') -Raw
if ($plugin.Version -ne $project.Project.PropertyGroup.Version) {
    throw "Plugin version $($plugin.Version) does not match project version $($project.Project.PropertyGroup.Version)"
}

Write-Host "Theme references OK: $($references.Count) base styles are present in stable Flow Launcher."
Write-Host "Version consistency OK: $($plugin.Version)."
