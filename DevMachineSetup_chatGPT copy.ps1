<#
.SYNOPSIS
    Automates the installation and configuration of WinGet, installs specified applications, removes unwanted applications, and sets up WSL on Windows.

.DESCRIPTION
    This script checks for the presence of WinGet and installs it if necessary.
    It configures WinGet settings, installs a list of applications, removes unwanted applications,
    and sets up Windows Subsystem for Linux (WSL).

.NOTES
    Author: [Your Name]
    Date: [Today's Date]
    Version: 1.0
#>

# Requires RunAs Administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole('Administrator')) {
    Write-Warning "This script must be run as an Administrator."
    exit 1
}

# Set Execution Policy for the session
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force

# Import necessary modules
Import-Module PackageManagement
Import-Module Appx

# Function to install WinGet
function Install-WinGet {
    Write-Output "Checking for WinGet installation..."

    $packageManager = Get-AppxPackage -Name 'Microsoft.DesktopAppInstaller' -ErrorAction SilentlyContinue
    if (-not $packageManager -or [Version]$packageManager.Version -lt [Version]"1.10.0.0") {
        Write-Output "WinGet not found or outdated. Installing WinGet..."
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

        $tempDir = Join-Path $env:TEMP "WinGetInstall"
        if (-not (Test-Path $tempDir)) {
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        }

        # Download dependencies
        $vcLibsUrl = 'https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx'
        $vcLibsPath = Join-Path $tempDir "Microsoft.VCLibs.x64.14.00.Desktop.appx"
        Invoke-WebRequest -Uri $vcLibsUrl -OutFile $vcLibsPath -UseBasicParsing

        try {
            Add-AppxPackage -Path $vcLibsPath -ErrorAction Stop
            Write-Output "Microsoft VCLibs installed successfully."
        } catch {
            Write-Error "Failed to install Microsoft VCLibs: $_"
            exit 1
        }

        # Get the latest WinGet release
        $releasesUrl = 'https://api.github.com/repos/microsoft/winget-cli/releases/latest'
        $latestRelease = Invoke-RestMethod -Uri $releasesUrl
        $wingetAsset = $latestRelease.assets | Where-Object { $_.name -like '*msixbundle' } | Select-Object -First 1

        if ($wingetAsset) {
            $wingetPackagePath = Join-Path $tempDir $wingetAsset.name
            Invoke-WebRequest -Uri $wingetAsset.browser_download_url -OutFile $wingetPackagePath -UseBasicParsing

            try {
                Add-AppxPackage -Path $wingetPackagePath -ErrorAction Stop
                Write-Output "WinGet installed successfully."
            } catch {
                Write-Error "Failed to install WinGet: $_"
                exit 1
            }
        } else {
            Write-Error "Unable to find the latest WinGet package."
            exit 1
        }

        # Clean up temporary files
        Remove-Item -Path $tempDir -Recurse -Force
    } else {
        Write-Output "WinGet is already installed and up-to-date."
    }
}

# Function to configure WinGet settings
function Set-WinGet {
    Write-Output "Setting WinGet settings..."

    $settingsPath = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState\settings.json'
    $settingsDir = Split-Path $settingsPath

    if (-not (Test-Path $settingsDir)) {
        New-Item -ItemType Directory -Path $settingsDir -Force | Out-Null
    }

    $settingsContent = @{
        experimentalFeatures = @{
            experimentalMSStore = $true
        }
    } | ConvertTo-Json -Depth 3

    try {
        $settingsContent | Out-File -FilePath $settingsPath -Encoding utf8 -Force
        Write-Output "WinGet settings configured successfully."
    } catch {
        Write-Error "Failed to configure WinGet settings: $_"
    }
}

# Function to install applications using WinGet
function Install-Applications {
    param (
        [Parameter(Mandatory = $true)]
        [Array]$Applications
    )

    Write-Output "Installing applications..."

    foreach ($app in $Applications) {
        Write-Output "Processing application: $($app.name)"

        $appInstalled = winget list --id $app.name --exact --accept-source-agreements | Select-Object -Skip 2
        if (-not $appInstalled) {
            Write-Output "Installing $($app.name)..."

            $installArgs = @(
                "install"
                "--id", $app.name
                "--exact"
                "--silent"
                "--accept-package-agreements"
                "--accept-source-agreements"
            )

            if ($app.additionalArgs) {
                $installArgs += $app.additionalArgs
            }

            try {
                winget @installArgs -ErrorAction Stop
                Write-Output "$($app.name) installed successfully."
            } catch {
                Write-Error "Failed to install $($app.name): $_"
            }
        } else {
            Write-Output "$($app.name) is already installed."
        }
    }
}

# Function to remove unwanted applications
function Remove-Applications {
    param (
        [Parameter(Mandatory = $true)]
        [Array]$ApplicationsToRemove
    )

    Write-Output "Removing unwanted applications..."

    foreach ($appPattern in $ApplicationsToRemove) {
        Write-Output "Processing application pattern: $appPattern"

        $packages = Get-AppxPackage -AllUsers -Name $appPattern

        if ($packages) {
            foreach ($package in $packages) {
                Write-Output "Uninstalling $($package.Name)..."

                try {
                    Remove-AppxPackage -Package $package.PackageFullName -AllUsers -ErrorAction Stop
                    Write-Output "$($package.Name) uninstalled successfully."
                } catch {
                    Write-Error "Failed to uninstall $($package.Name): $_"
                }
            }
        } else {
            Write-Output "No packages found matching pattern: $appPattern"
        }
    }
}

# Function to set up Windows Subsystem for Linux (WSL)
function Install-WSL {
    Write-Output "Installing Windows Subsystem for Linux (WSL)..."

    $windowsVersion = [int](Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name ReleaseId).ReleaseId

    if ($windowsVersion -ge 2004) {
        try {
            wsl --install
            Write-Output "WSL installation initiated. A system restart may be required."
        } catch {
            Write-Error "Failed to initiate WSL installation: $_"
        }
    } else {
        Write-Warning "WSL installation requires Windows 10 version 2004 or later."
    }
}

# Main script execution
function Main {
    Install-WinGet
    Set-WinGet

    $applicationsToInstall = @(
        @{ name = "Microsoft.VisualStudioCode" },
        @{ name = "Git.Git" },
        @{ name = "Docker.DockerDesktop" },
        @{ name = "GitHub.cli" },
        @{ name = "GitHub.GitHubDesktop" },
        @{ name = "JanDeDobbeleer.OhMyPosh" },
        @{ name = "Python.Python.3.10" },
        @{ name = "OpenJS.NodeJS.LTS" },
        @{ name = "WhatsApp.WhatsApp" },
        @{ name = "SublimeHQ.SublimeText.4" },
        @{ name = "DisplayLink.GraphicsDriver" },
        @{ name = "Google.Chrome" }
    )

    Install-Applications -Applications $applicationsToInstall

    $applicationsToRemove = @(
        "*3DPrint*",
        "Microsoft.MixedReality.Portal"
    )

    Remove-Applications -ApplicationsToRemove $applicationsToRemove

    Install-WSL

    Write-Output "Script execution completed."
}

# Start the main function
Main
