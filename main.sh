#!/bin/bash

# Main.sh: Socarium Interactive Menu with Whiptail
# Author: Gamutech Services Indonesia

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

# Function to check if directory exists
check_directory() {
    local DIR="/opt/socarium"
    if [ ! -d "$DIR" ]; then
        echo "Creating directory $DIR..."
        sudo mkdir -p $DIR || {
            echo "❌ Failed to create directory $DIR. Exiting."
            exit 1
        }
    fi
    echo "✅ Directory $DIR is ready."
}

# Function to check prerequisites
check_prerequisites() {
    MISSING=""
    for CMD in git curl wget docker docker-compose; do
        if ! command -v $CMD &> /dev/null; then
            MISSING+="$CMD\n"
        fi
    done

    if ! pip -V &> /dev/null; then
        MISSING+="pip\n"
    fi

    if [ "$MISSING" != "" ]; then
        whiptail --msgbox "Missing prerequisites:\n$MISSING\nPlease select '1. Install Prerequisites' to install them." 20 70
        return 1
    fi
    echo "✅ All prerequisites are installed."
}

# Function to check Docker
check_docker() {
    if ! command -v docker &> /dev/null || ! command -v docker-compose &> /dev/null; then
        whiptail --msgbox "Docker is not installed. Installing Docker..." 10 50
        source ./modules/prerequisites/docker.sh
    fi
    echo "✅ Docker is installed."
}

# Function to check the status of platforms
check_status() {
    while true; do
        MENU_OPTIONS=()
        PLATFORM_DETAILS=""

        # List of platforms to check
        declare -A PLATFORMS=(
            ["Wazuh"]="wazuh"
            ["DFIR IRIS"]="iriswebapp_nginx"
            ["Shuffle"]="shuffle-frontend"
            ["MISP"]="misp"
            ["OpenCTI"]="opencti"
        )

        for PLATFORM in "${!PLATFORMS[@]}"; do
            CONTAINER_NAME="${PLATFORMS[$PLATFORM]}"
            if sudo docker ps --format '{{.Names}}' | grep -q "$CONTAINER_NAME"; then
                MENU_OPTIONS+=("$PLATFORM" "✓ Installed")
            else
                MENU_OPTIONS+=("$PLATFORM" "× Not Installed")
            fi
        done

        # Display the menu
        CHOICE=$(whiptail --title "Platform Status" --menu "Select a platform to view details:" 20 70 10 "${MENU_OPTIONS[@]}" 3>&1 1>&2 2>&3)

        if [ $? -ne 0 ]; then
            # User pressed Cancel or Esc
            break
        fi

        # Gather detailed information for the selected platform
        SELECTED_CONTAINER="${PLATFORMS[$CHOICE]}"
        if sudo docker ps --format '{{.Names}}' | grep -q "$SELECTED_CONTAINER"; then
            IP=$(sudo docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$SELECTED_CONTAINER")
            PORTS=$(sudo docker ps --format '{{.Ports}}' --filter "name=$SELECTED_CONTAINER")
            PLATFORM_DETAILS="$CHOICE:\n  Status: Installed\n  IP Address: $IP\n  Ports: $PORTS"
        else
            PLATFORM_DETAILS="$CHOICE:\n  Status: Not Installed\n  No additional details available."
        fi

        # Display detailed information in a scrollable box
        whiptail --scrolltext --msgbox "$PLATFORM_DETAILS" 20 70
    done
}

# Interactive Menu with Welcome Banner
show_menu() {
    while true; do
        OPTION=$(whiptail --title "Socarium Installation Menu" --menu "\nPlease select an option:" 20 70 10 \
        "1" "Install Prerequisites" \
        "2" "Auto-Install All Packages" \
        "3" "Install Wazuh" \
        "4" "Install OpenCTI" \
        "5" "Install MISP" \
        "6" "Install DFIR IRIS" \
        "7" "Install Shuffle" \
        "8" "YARA Manual Installation Instructions" \
        "9" "Check Status" \
        "10" "Exit" 3>&1 1>&2 2>&3)

        # Check exit status of Whiptail
        STATUS=$?
        if [ $STATUS -ne 0 ]; then
            # Exit if Cancel or Esc is pressed
            whiptail --msgbox "Exiting Socarium Setup. Goodbye!" 10 50
            exit 0
        fi

        case $OPTION in
            1)
                    source ./modules/prerequisites/prerequisites.sh 
                    install_prerequisites 

                whiptail --msgbox "✅ Prerequisites installed successfully!" 10 50
                ;;
            2)
              
                    ./install_all.sh 
                   
                whiptail --msgbox "✅ All SOC packages installed successfully!" 10 50
                ;;
            3)
                    source ./modules/wazuh/wazuh.sh 
                    install_wazuh 
       
                whiptail --msgbox "✅ Wazuh installed successfully!" 10 50
                ;;
            4)
                    source ./modules/opencti/opencti.sh 
                    install_opencti 
                
                whiptail --msgbox "✅ OpenCTI installed successfully!" 10 50
                ;;
            5)
                
                    source ./modules/misp/misp.sh 
                    install_misp 
                   
                whiptail --msgbox "✅ MISP installed successfully!" 10 50
                ;;
            6)
                source ./modules/dfir_iris/dfir_iris.sh
                install_dfir_iris  # The function will handle the progress display

                whiptail --msgbox "✅ DFIR-IRIS installed successfully!" 10 50
                ;;
            7)
                
                    source ./modules/shuffle/shuffle.sh 
                    install_shuffle 
                   
                whiptail --msgbox "✅ Shuffle installed successfully!" 10 50
                ;;
            8)
                source ./modules/yara/yara_manual.sh 
                install_yara_manual 
                whiptail --msgbox "✅ Follow manual YARA installation instructions!" 10 50
                whiptail --msgbox "🚀 Use the following command on endpoints: sudo apt install -y yara" 10 50
                ;;
            9)
                check_status
                ;;
            10)
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
echo "✅ Whiptail is available."
echo "🔍 Checking System Overview..."
check_system
echo "🔍 Checking Directory..."
check_directory
echo "🔍 Checking Prerequisites..."
check_prerequisites
echo "🔍 Checking Docker..."
check_docker
echo "✅ All checks complete. Launching menu..."
show_menu
