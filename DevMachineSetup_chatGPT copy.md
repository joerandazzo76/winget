# Automated Windows Setup Script

This PowerShell script automates the installation and configuration of essential tools and applications on a Windows machine. It:

- Installs or updates WinGet (Windows Package Manager)
- Configures WinGet settings
- Installs a list of specified applications using WinGet
- Removes unwanted pre-installed applications
- Sets up Windows Subsystem for Linux (WSL)

## Table of Contents

- [Prerequisites](#prerequisites)
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Customization](#customization)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## Prerequisites

- **Operating System**: Windows 10 version 2004 or later
- **PowerShell**: Version 5.1 or higher (Built into Windows 10)
- **Administrator Privileges**: The script must be run with administrative rights

## Features

- **WinGet Installation**: Checks for the presence of WinGet and installs or updates it if necessary.
- **WinGet Configuration**: Enables experimental features, including access to Microsoft Store apps.
- **Application Installation**: Automates the installation of commonly used applications.
- **Application Removal**: Removes unwanted or pre-installed Windows applications.
- **WSL Setup**: Installs Windows Subsystem for Linux to allow running Linux distributions on Windows.

## Installation

1. **Download the Script**

   Save the script to your local machine with a `.ps1` extension, e.g., `SetupEnvironment.ps1`.

2. **Open PowerShell as Administrator**

   - Click on the **Start** menu.
   - Type `PowerShell`.
   - Right-click on **Windows PowerShell** and select **Run as administrator**.

3. **Set Execution Policy (Optional but Recommended)**

   To allow the script to run, you may need to set the execution policy:

   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

   > **Note**: The script sets the execution policy for the process scope, but setting it for the current user may prevent policy prompts.

## Usage

1. **Navigate to the Script Directory**

   Use `cd` to change to the directory where the script is saved:

   ```powershell
   cd C:\Path\To\Your\Script
   ```

2. **Execute the Script**

   ```powershell
   .\SetupEnvironment.ps1
   ```

3. **Monitor the Output**

   The script will display progress messages in the console. It may take several minutes to complete, depending on your internet connection and system performance.

4. **Restart Your Computer**

   After the script completes, it's recommended to restart your computer, especially if WSL was installed.

## Customization

### Adding Applications to Install

You can customize the list of applications to install by modifying the `$applicationsToInstall` array in the script:

```powershell
$applicationsToInstall = @(
    @{ name = "Microsoft.VisualStudioCode" },
    @{ name = "Git.Git" },
    # Add more applications here
)
```

- **Finding Application IDs**: Use the following command to search for applications:

  ```powershell
  winget search <application-name>
  ```

- **Adding Applications**: Add a new entry with the `name` key set to the application's ID.

### Removing Applications

Modify the `$applicationsToRemove` array to specify applications you want to remove:

```powershell
$applicationsToRemove = @(
    "*3DPrint*",
    "Microsoft.MixedReality.Portal"
    # Add more application patterns here
)
```

- Use wildcard patterns (`*`) to match application names.

### Adjusting WinGet Settings

To customize WinGet settings, modify the `$settingsContent` in the `Configure-WinGet` function:

```powershell
$settingsContent = @{
    experimentalFeatures = @{
        experimentalMSStore = $true
        # Enable other experimental features here
    }
} | ConvertTo-Json -Depth 3
```

## Troubleshooting

- **Script Not Running**

  - Ensure you are running PowerShell as an Administrator.
  - Check the execution policy with `Get-ExecutionPolicy` and set it to `RemoteSigned` if necessary.

- **WinGet Installation Fails**

  - Make sure you have an active internet connection.
  - Verify that your Windows version supports WinGet.

- **Application Installation Issues**

  - Some applications may fail to install if they require additional dependencies or user interaction.
  - Check the application ID and ensure it is correct.

- **WSL Installation Issues**

  - WSL requires Windows 10 version 2004 or later.
  - Ensure virtualization is enabled in your system's BIOS settings.

## Contributing

Contributions are welcome! If you have suggestions for improvements or encounter any issues, please create a pull request or submit an issue on the project's repository.

### Steps to Contribute

1. **Fork the Repository**

2. **Create a Feature Branch**

   ```bash
   git checkout -b feature/YourFeature
   ```

3. **Commit Your Changes**

   ```bash
   git commit -m "Add your message here"
   ```

4. **Push to Your Fork**

   ```bash
   git push origin feature/YourFeature
   ```

5. **Create a Pull Request**

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

*Disclaimer: This script is provided as-is without any warranty. Use at your own risk.*