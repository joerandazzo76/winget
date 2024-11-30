# Ensure the script is run as Administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole] "Administrator")) {
    Write-Warning "You do not have Administrator rights to run this script. Please re-run this script as an Administrator."
    exit 1
}

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force

# Install WinGet
Write-Output "Checking for WinGet installation..."
$hasPackageManager = Get-AppxPackage -Name 'Microsoft.DesktopAppInstaller' -ErrorAction SilentlyContinue
if (!$hasPackageManager -or [version]$hasPackageManager.Version -lt [version]"1.10.0.0") {
    Write-Output "Installing WinGet dependencies..."
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    $tempDir = "$env:TEMP\winget_install"
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

    $vcLibsUrl = 'https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx'
    $vcLibsPath = "$tempDir\Microsoft.VCLibs.x64.14.00.Desktop.appx"
    Invoke-WebRequest -Uri $vcLibsUrl -OutFile $vcLibsPath

    try {
        Add-AppxPackage -Path $vcLibsPath -ErrorAction Stop
    } catch {
        Write-Error "Failed to install VCLibs: $_"
        exit 1
    }

    $releasesUrl = 'https://api.github.com/repos/microsoft/winget-cli/releases/latest'
    $releases = Invoke-RestMethod -Uri $releasesUrl
    $latestRelease = $releases.assets | Where-Object { $_.browser_download_url -match 'msixbundle$' } | Select-Object -First 1

    if ($latestRelease) {
        $wingetPackagePath = "$tempDir\WinGet.msixbundle"
        Invoke-WebRequest -Uri $latestRelease.browser_download_url -OutFile $wingetPackagePath

        try {
            Add-AppxPackage -Path $wingetPackagePath -ErrorAction Stop
            Write-Output "WinGet installed successfully."
        } catch {
            Write-Error "Failed to install WinGet: $_"
            exit 1
        }
    } else {
        Write-Error "Could not find the latest WinGet release."
        exit 1
    }
} else {
    Write-Output "WinGet is already installed."
}

# Configure WinGet
Write-Output "Configuring WinGet..."
$settingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState\settings.json"
$settingsDir = Split-Path $settingsPath
if (!(Test-Path $settingsDir)) {
    New-Item -ItemType Directory -Path $settingsDir -Force | Out-Null
}

$settingsJson = @'
{
    "experimentalFeatures": {
        "experimentalMSStore": true
    }
}
'@
$settingsJson | Out-File $settingsPath -Encoding utf8

# Install New Apps
Write-Output "Installing Apps..."
$apps = @(
    @{name = "Microsoft.VisualStudioCode"},
    @{name = "Git.Git"},
    @{name = "Docker.DockerDesktop"},
    @{name = "GitHub.cli"},
    @{name = "GitHub.GitHubDesktop"},
    @{name = "JanDeDobbeleer.OhMyPosh"},
    @{name = "Python.Python.3.10"},
    @{name = "OpenJS.NodeJS.LTS"},
    @{name = "WhatsApp.WhatsApp"},
    @{name = "SublimeHQ.SublimeText.4"},
    @{name = "DisplayLink.GraphicsDriver"},
    @{name = "Google.Chrome"}
)

foreach ($app in $apps) {
    Write-Output "Processing $($app.name)..."
    $appInstalled = winget list --id $app.name --exact --accept-source-agreements | Select-Object -Skip 2
    if (-not $appInstalled) {
        Write-Output "Installing $($app.name)..."
        try {
            winget install --id $app.name --exact --silent --accept-package-agreements --accept-source-agreements -ErrorAction Stop
            Write-Output "$($app.name) installed successfully."
        } catch {
            Write-Error "Failed to install $($app.name): $_"
        }
    } else {
        Write-Output "$($app.name) is already installed."
    }
}

# Remove Apps
Write-Output "Removing Apps..."
$appsToRemove = "*3DPrint*", "Microsoft.MixedReality.Portal"
foreach ($app in $appsToRemove) {
    Write-Output "Uninstalling $app..."
    $packages = Get-AppxPackage -AllUsers -Name $app
    if ($packages) {
        foreach ($package in $packages) {
            try {
                Remove-AppxPackage -Package $package.PackageFullName -AllUsers -ErrorAction Stop
                Write-Output "Uninstalled $($package.Name)."
            } catch {
                Write-Error "Failed to uninstall $($package.Name): $_"
            }
        }
    } else {
        Write-Output "No packages found matching $app."
    }
}

# Setup WSL
Write-Output "Setting up WSL..."
$windowsVersion = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').ReleaseId
if ($windowsVersion -ge 2004) {
    try {
        wsl --install
        Write-Output "WSL installation initiated. A restart may be required."
    } catch {
        Write-Error "Failed to initiate WSL installation: $_"
    }
} else {
    Write-Warning "WSL installation requires Windows 10 version 2004 or later."
}
