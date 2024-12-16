#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status.
trap cleanup ERR  # Trap errors and perform cleanup.

# Base setup
BASE_DIR="modules"
LOG_FILE="/var/log/socarium_setup.log"
exec > >(tee -a "$LOG_FILE") 2>&1  # Redirect output to log file.

# Welcome Banner
welcome_banner() {
    echo "==============================================================="
    echo "                     Welcome to Socarium                      "
    echo "==============================================================="
    echo "Socarium is a modular SOC management package designed for     "
    echo "simplified deployment, management, and testing of SOC tools. "
    echo "This package includes: Wazuh, IRIS, Shuffle, MISP, and OpenCTI."
    echo "---------------------------------------------------------------"
    echo "Recommended OS: Ubuntu Server 22.04 LTS                      "
    echo "This package has been tested and verified to work optimally   "
    echo "on Ubuntu Server 22.04 LTS.                                  "
    echo "---------------------------------------------------------------"
    echo "Author:                                                       "
    echo "This SOC package was created through a collaboration between  "
    echo "JICA and idCARE UI to promote cybersecurity excellence.       "
    echo "==============================================================="
}

# Check Requirements
check_requirements() {
    echo "🛠 Checking system requirements..."
    local requirements_met=true
    local checklist=""

    # OS Check
    os_version=$(lsb_release -d | awk -F'\t' '{print $2}')
    if [[ "$os_version" != *"Ubuntu 22.04"* ]]; then
        checklist+="[✘] OS: Not Ubuntu 22.04 LTS (Detected: $os_version)\n"
        echo "⚠️ Socarium has not been tested on $os_version. Proceeding with caution."
    else
        checklist+="[✔] OS: Ubuntu 22.04 LTS (Detected: $os_version)\n"
    fi

    # Check required packages
    REQUIRED_PACKAGES=("docker" "docker-compose" "git" "curl" "wget")
    for package in "${REQUIRED_PACKAGES[@]}"; do
        if command -v $package &> /dev/null; then
            checklist+="[✔] $package: Installed\n"
        else
            checklist+="[✘] $package: Not Installed\n"
            requirements_met=false
        fi
    done

    # Display checklist
    echo -e "========================================="
    echo -e "         System Requirements Checklist"
    echo -e "========================================="
    echo -e "$checklist"
    echo -e "========================================="

    # Handle unmet requirements
    if [ "$requirements_met" = false ]; then
        echo "⚠️ Some requirements are not met. Installing pre-requisites..."
        install_prerequisites
    else
        echo "✅ All system requirements are met. Proceeding with installation."
    fi
}

# Check for Existing Directories and Handle User Confirmation
check_and_update_or_install() {
    # Define the directories to check
    DIRECTORIES=(        
        "/opt/socarium/iris_web"
        "/opt/socarium/misp"
        "/opt/socarium/wazuh-docker"
        "/opt/socarium/opencti"
        "/opt/socarium/shuffle"
    )

    for DIR in "${DIRECTORIES[@]}"; do
        if [ -d "$DIR" ]; then
            echo "⚠️ Directory $DIR already exists."
            echo "Updating $DIR with the latest changes..."
            (cd "$DIR" && git pull)
            echo "✅ $DIR updated."
        else
            echo "✅ Directory $DIR does not exist. Creating it..."
            mkdir -p "$DIR"
            echo "Running installation for $DIR..."
            # Call the appropriate installation function based on the directory
            case "$DIR" in
                "/opt/socarium/iris_web")
                    install_dfir_iris
                    ;;
                "/opt/socarium/misp")
                    install_misp
                    ;;
                "/opt/socarium/wazuh-docker")
                    install_wazuh
                    ;;
                "/opt/socarium/opencti")
                    install_opencti
                    ;;
                "/opt/socarium/shuffle")
                    install_shuffle
                    ;;
            esac
        fi
    done

    echo "✅ All directories are ready for installation."
}

# Dynamically load all platform-specific installation scripts
for module in $BASE_DIR/*/*.sh; do
    source "$module"
done

# Display Welcome Banner
welcome_banner

# Check System Requirements
check_requirements

# Check for Existing Directories
check_and_remove_existing

# Menu-driven selection
while true; do
    echo "================================="
    echo "SOC Tools Installation Menu"
    echo "================================="
    echo "1. Install Prerequisites"
    echo "2. Install All (Automated, Excluding YARA)"
    echo "3. Install Wazuh"
    echo "4. Install OpenCTI"
    echo "5. Install MISP"
    echo "6. Install DFIR IRIS"
    echo "7. Install Shuffle (Last)"
    echo "8. YARA Manual Step (Instructions)"
    echo "9. Exit"
    echo "================================="
    read -p "Choose an option [1-9]: " choice
    case $choice in
        1) install_prerequisites ;;
        2)
            echo "🚀 Installing all components in the correct order..."
            install_prerequisites
            install_wazuh
            install_opencti
            install_misp
            install_dfir_iris
            install_shuffle
            echo "✅ All components installed successfully!"
            ;;
        3) install_wazuh ;;
        4) install_opencti ;;
        5) install_misp ;;
        6) install_dfir_iris ;;
        7) install_shuffle ;;
        8) install_yara_manual ;;
        9) echo "Exiting..."; break ;;
        *) echo "Invalid option, please choose again." ;;
    esac
done

echo "✅ Installation menu completed!"
