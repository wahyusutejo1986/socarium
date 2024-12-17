#!/bin/bash

# Main.sh: Socarium Interactive Menu with Whiptail
# Author: Gamutech Services Indonesia

# Load installation scripts
source ./auto_install_all_packages.sh
source ./modules/prerequisites.sh
source ./modules/wazuh.sh
source ./modules/opencti.sh
source ./modules/misp.sh
source ./modules/dfir_iris.sh
source ./modules/shuffle.sh
source ./modules/yara_manual.sh

# Function to check and install Whiptail
check_whiptail() {
    if ! command -v whiptail &> /dev/null; then
        echo "⚠️ Whiptail is not installed. Installing Whiptail..."
        sudo apt update -y && sudo apt install -y whiptail || {
            echo "❌ Failed to install Whiptail. Please check your system and try again."
            exit 1
        }
        echo "✅ Whiptail installed successfully!"
    fi
}

# Interactive Menu
show_menu() {
    while true; do
        OPTION=$(whiptail --title "Socarium Installation Menu" --menu "Choose an option:" 20 60 10 \
        "1" "Install Prerequisites" \
        "2" "Auto-Install All Packages" \
        "3" "Install Wazuh" \
        "4" "Install OpenCTI" \
        "5" "Install MISP" \
        "6" "Install DFIR IRIS" \
        "7" "Install Shuffle" \
        "8" "YARA Manual Installation Instructions" \
        "9" "Exit" 3>&1 1>&2 2>&3)
        
        case $OPTION in
            1)
                install_prerequisites
                whiptail --msgbox "✅ Prerequisites installed successfully!" 10 50
                ;;
            2)
                ./auto_install_all_packages.sh
                whiptail --msgbox "✅ All SOC packages installed successfully!" 10 50
                ;;
            3)
                install_wazuh
                whiptail --msgbox "✅ Wazuh installed successfully!" 10 50
                ;;
            4)
                install_opencti
                whiptail --msgbox "✅ OpenCTI installed successfully!" 10 50
                ;;
            5)
                install_misp
                whiptail --msgbox "✅ MISP installed successfully!" 10 50
                ;;
            6)
                install_dfir_iris
                whiptail --msgbox "✅ DFIR IRIS installed successfully!" 10 50
                ;;
            7)
                install_shuffle
                whiptail --msgbox "✅ Shuffle installed successfully!" 10 50
                ;;
            8)
                install_yara_manual
                whiptail --msgbox "✅ Follow manual YARA installation instructions!" 10 50
                ;;
            9)
                whiptail --msgbox "Exiting Socarium Setup. Goodbye!" 10 50
                exit 0
                ;;
            *)
                whiptail --msgbox "❌ Invalid option. Please try again." 10 50
                ;;
        esac
    done
}

# Main Execution
echo "🔍 Checking for Whiptail..."
check_whiptail
echo "✅ Whiptail is available. Launching menu..."
show_menu
