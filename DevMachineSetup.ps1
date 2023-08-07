#Install WinGet
#Based on this gist: https://gist.github.com/crutkas/6c2096eae387e544bd05cde246f23901
$hasPackageManager = Get-AppPackage -name 'Microsoft.DesktopAppInstaller'
if (!$hasPackageManager -or [version]$hasPackageManager.Version -lt [version]"1.10.0.0") {
    "Installing winget Dependencies"
    Add-AppxPackage -Path 'https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx'

    $releases_url = 'https://api.github.com/repos/microsoft/winget-cli/releases/latest'

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $releases = Invoke-RestMethod -uri $releases_url
    $latestRelease = $releases.assets | Where { $_.browser_download_url.EndsWith('msixbundle') } | Select -First 1

    "Installing winget from $($latestRelease.browser_download_url)"
    Add-AppxPackage -Path $latestRelease.browser_download_url
}
else {
    "winget already installed"
}

#Configure WinGet
Write-Output "Configuring winget"

#winget config path from: https://github.com/microsoft/winget-cli/blob/master/doc/Settings.md#file-location
$settingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState\settings.json";
$settingsJson = 
@"
    {
        // For documentation on these settings, see: https://aka.ms/winget-settings
        "experimentalFeatures": {
          "experimentalMSStore": true,
        }
    }
"@;
$settingsJson | Out-File $settingsPath -Encoding utf8

#Install New apps
Write-Output "Installing Apps"
$apps = @(
    @{name = "Microsoft.VisualStudioCode" }, 
    @{name = "Git.Git" }, 
    @{name = "Docker.DockerDesktop" },
    @{name = "GitHub.cli" },
    @{name = "GitHub.GitHubDesktop" },
    @{name = "JanDeDobbeleer.OhMyPosh" },
    @{name = "Python.Python.3.10" },
    @{name = "Node.js" },
    @{name = "WhatsApp.WhatsApp" },
    @{name = "SublimeHQ.SublimeText.4" },
    @{name = "DisplayLink.GraphicsDriver" },
    @{name = "Google.Chrome" }
);
Foreach ($app in $apps) {
    $listApp = winget list --exact -q $app.name --accept-source-agreements 
    if (![String]::Join("", $listApp).Contains($app.name)) {
        Write-host "Installing:" $app.name
        if ($app.source -ne $null) {
            winget install --exact --silent $app.name --source $app.source --accept-package-agreements
        }
        else {
            winget install --exact --silent $app.name --accept-package-agreements
        }
    }
    else {
        Write-host "Skipping Install of " $app.name
    }
}

#Remove Apps
Write-Output "Removing Apps"

$apps = "*3DPrint*", "Microsoft.MixedReality.Portal"
Foreach ($app in $apps)
{
  Write-host "Uninstalling:" $app
  Get-AppxPackage -allusers $app | Remove-AppxPackage
}

#Setup WSL
wsl --install
