import os
import platform
import subprocess
import shutil
import psutil
import requests
import logging
import json
from concurrent.futures import ThreadPoolExecutor

# Setup logging
logging.basicConfig(
    filename="setup_environment.log", 
    level=logging.DEBUG, 
    format="%(asctime)s [%(levelname)s] %(message)s", 
    filemode="w"
)

# Log function for convenience
def log(message, level=logging.INFO):
    logging.log(level, message)
    print(message)

# Function to check if dependencies are installed
def check_dependencies():
    try:
        import psutil
        import requests
    except ImportError as e:
        log(f"Missing required module: {e.name}. Please install it before running the script.", logging.ERROR)
        exit(1)

# Function to get system info
def system_info():
    system = platform.system().lower()
    arch = platform.machine()
    ram = psutil.virtual_memory().total // (1024 ** 3)
    log(f"System: {system.capitalize()}, Architecture: {arch}, RAM: {ram} GB", logging.INFO)

# Function to check system resources
def check_system_resources(min_disk_gb=10, min_ram_mb=1024):
    log("Checking system resources...", logging.INFO)
    
    # Check available disk space
    total, used, free = shutil.disk_usage("/")
    log(f"Disk Space: {free // (2**30)} GB available")

    # Check available RAM
    memory_info = psutil.virtual_memory()
    log(f"RAM: {memory_info.available // (2**20)} MB available")

    # Check network connectivity
    try:
        requests.get("https://www.google.com", timeout=5)
        log("Network: Connected")
    except requests.ConnectionError:
        log("Network: No connectivity", logging.ERROR)
        return False

    # Check if system meets requirements
    if free < min_disk_gb * (2**30) or memory_info.available < min_ram_mb * (2**20):
        log("Insufficient system resources, aborting.", logging.ERROR)
        return False
    return True

# Function to install a single package
def install_package(package_manager, package_name):
    try:
        log(f"Installing {package_name} with {package_manager}...", logging.INFO)
        if platform.system().lower() == "windows":
            subprocess.run([package_manager, "install", "--id", package_name, "-e", "--silent"], check=True)
        else:
            subprocess.run([package_manager, "install", package_name], check=True)
        log(f"{package_name} installed successfully", logging.INFO)
    except subprocess.CalledProcessError as e:
        log(f"Failed to install {package_name}: {e}", logging.ERROR)

# Install packages concurrently
def install_packages(packages):
    system = platform.system().lower()
    if system == "windows":
        package_manager = "winget"
    elif system == "linux":
        package_manager = "apt"
    elif system == "darwin":
        package_manager = "brew"
    else:
        log(f"Unsupported OS: {system}", logging.ERROR)
        return

    with ThreadPoolExecutor() as executor:
        for package in packages:
            executor.submit(install_package, package_manager, package)

# Function to remove packages
def remove_packages(packages):
    system = platform.system().lower()
    package_manager = {
        "windows": "winget",
        "linux": "apt",
        "darwin": "brew"
    }.get(system)

    if not package_manager:
        log(f"Unsupported OS: {system}", logging.ERROR)
        return
    
    for package in packages:
        log(f"Removing {package}...", logging.INFO)
        try:
            subprocess.run([package_manager, "uninstall", package], check=True)
            log(f"{package} removed successfully", logging.INFO)
        except subprocess.CalledProcessError as e:
            log(f"Failed to remove {package}: {e}", logging.ERROR)

# Function to set up WSL (Windows only)
def setup_wsl():
    if platform.system().lower() == "windows":
        try:
            log("Setting up Windows Subsystem for Linux (WSL)...", logging.INFO)
            subprocess.run(["wsl", "--install"], check=True)
            log("WSL installation initiated. A system restart may be required.", logging.INFO)
        except subprocess.CalledProcessError as e:
            log(f"Failed to install WSL: {e}", logging.ERROR)
    else:
        log("WSL is only supported on Windows.", logging.INFO)

# Load applications to install and remove from config file
def load_config():
    with open("config.json") as f:
        return json.load(f)

# Main function
def main(interactive=False, dry_run=True):
    check_dependencies()
    system_info()

    # Check system resources first
    if not check_system_resources():
        return

    # Load configuration
    config = load_config()
    applications_to_install = config.get("install", [])
    applications_to_remove = config.get("remove", [])

    # Dry run mode
    if dry_run:
        log(f"Dry run mode enabled. Applications to install: {applications_to_install}, to remove: {applications_to_remove}")
        return

    # Install and remove applications
    install_packages(applications_to_install)
    remove_packages(applications_to_remove)

    # Set up WSL (if on Windows)
    setup_wsl()

    log("Environment setup completed successfully", logging.INFO)

if __name__ == "__main__":
    main()
