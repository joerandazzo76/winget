# SetupEnvironment.Tests.ps1

# Import the module or script containing the functions
. "$PSScriptRoot\SetupEnvironment.ps1"

# Import Pester module
Import-Module Pester

Describe "Install-WinGet" {
    Mock -CommandName Get-AppxPackage -MockWith {
        @{
            Name = 'Microsoft.DesktopAppInstaller'
            Version = '1.0.0.0'
        }
    }

    Mock -CommandName Invoke-WebRequest
    Mock -CommandName Add-AppxPackage
    Mock -CommandName Remove-Item

    It "Should install WinGet when not installed" {
        # Arrange
        Mock -CommandName Get-AppxPackage -MockWith { return $null }

        # Act
        Install-WinGet -TempDirectory "C:\Temp\WinGetTest"

        # Assert
        Assert-MockCalled Invoke-WebRequest -Exactly 3 -Scope It
        Assert-MockCalled Add-AppxPackage -Exactly 2 -Scope It
        Assert-MockCalled Remove-Item -Exactly 1 -Scope It
    }

    It "Should not install WinGet when already up-to-date" {
        # Arrange
        Mock -CommandName Get-AppxPackage -MockWith {
            @{
                Name = 'Microsoft.DesktopAppInstaller'
                Version = '1.10.0.0'
            }
        }

        # Act
        Install-WinGet

        # Assert
        Assert-MockNotCalled Invoke-WebRequest -Scope It
        Assert-MockNotCalled Add-AppxPackage -Scope It
        Assert-MockNotCalled Remove-Item -Scope It
    }
}

Describe "Configure-WinGet" {
    Mock -CommandName New-Item
    Mock -CommandName Out-File

    It "Should create settings directory if it doesn't exist" {
        # Arrange
        Mock -CommandName Test-Path -MockWith { $false }

        # Act
        Configure-WinGet -SettingsPath "C:\Temp\Settings\settings.json"

        # Assert
        Assert-MockCalled New-Item -ParameterFilter { $_.Path -eq "C:\Temp\Settings" } -Exactly 1 -Scope It
        Assert-MockCalled Out-File -ParameterFilter { $_.FilePath -eq "C:\Temp\Settings\settings.json" } -Exactly 1 -Scope It
    }

    It "Should not create settings directory if it exists" {
        # Arrange
        Mock -CommandName Test-Path -MockWith { $true }

        # Act
        Configure-WinGet -SettingsPath "C:\Temp\Settings\settings.json"

        # Assert
        Assert-MockNotCalled New-Item -Scope It
        Assert-MockCalled Out-File -ParameterFilter { $_.FilePath -eq "C:\Temp\Settings\settings.json" } -Exactly 1 -Scope It
    }
}

Describe "Install-Applications" {
    Mock -CommandName winget

    It "Should install applications not already installed" {
        # Arrange
        $applications = @(
            @{ name = "Test.App1" },
            @{ name = "Test.App2" }
        )
        Mock -CommandName winget -ParameterFilter { $args[0] -eq 'list' } -MockWith { return @() }

        # Act
        Install-Applications -Applications $applications -WingetCommand 'winget'

        # Assert
        Assert-MockCalled winget -ParameterFilter { $args[0] -eq 'install' } -Times 2 -Scope It
    }

    It "Should skip applications that are already installed" {
        # Arrange
        $applications = @(
            @{ name = "Test.App1" },
            @{ name = "Test.App2" }
        )
        Mock -CommandName winget -ParameterFilter { $args[0] -eq 'list' } -MockWith { return 'Test.App1' }

        # Act
        Install-Applications -Applications $applications -WingetCommand 'winget'

        # Assert
        Assert-MockCalled winget -ParameterFilter { $args[0] -eq 'install' } -Times 1 -Scope It
    }
}

Describe "Remove-Applications" {
    Mock -CommandName Get-AppxPackage
    Mock -CommandName Remove-AppxPackage

    It "Should remove specified applications" {
        # Arrange
        $applicationsToRemove = @("Test.App*")
        Mock -CommandName Get-AppxPackage -MockWith {
            @(
                @{
                    Name = 'Test.App1'
                    PackageFullName = 'Test.App1_1.0.0.0_neutral__xyz'
                },
                @{
                    Name = 'Test.App2'
                    PackageFullName = 'Test.App2_1.0.0.0_neutral__xyz'
                }
            )
        }

        # Act
        Remove-Applications -ApplicationsToRemove $applicationsToRemove

        # Assert
        Assert-MockCalled Remove-AppxPackage -Times 2 -Scope It
    }

    It "Should not remove applications if none match" {
        # Arrange
        $applicationsToRemove = @("Non.Existent.App")
        Mock -CommandName Get-AppxPackage -MockWith { @() }

        # Act
        Remove-Applications -ApplicationsToRemove $applicationsToRemove

        # Assert
        Assert-MockNotCalled Remove-AppxPackage -Scope It
    }
}

Describe "Setup-WSL" {
    Mock -CommandName wsl

    It "Should install WSL on supported Windows versions" {
        # Arrange
        $windowsVersion = 2004

        # Act
        Setup-WSL -WindowsVersion $windowsVersion

        # Assert
        Assert-MockCalled wsl -ParameterFilter { $args[0] -eq '--install' } -Exactly 1 -Scope It
    }

    It "Should not install WSL on unsupported Windows versions" {
        # Arrange
        $windowsVersion = 1909

        # Act
        Setup-WSL -WindowsVersion $windowsVersion

        # Assert
        Assert-MockNotCalled wsl -Scope It
    }
}
