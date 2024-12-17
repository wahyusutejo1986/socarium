#!/bin/bash

# auto_install_all_packages.sh: Execute All SOC Packages Installation
# Author: Gamutech Services Indonesia

# Source installation scripts
source ./modules/prerequisites.sh
source ./modules/wazuh.sh
source ./modules/opencti.sh
source ./modules/misp.sh
source ./modules/dfir_iris.sh
source ./modules/shuffle.sh
source ./modules/yara_manual.sh

# Function: Run All Installations
auto_install_all() {
    echo "🚀 Installing all prerequisites and SOC packages..."

    install_prerequisites || { echo "❌ Failed at prerequisites installation."; exit 1; }
    install_wazuh || { echo "❌ Failed at Wazuh installation."; exit 1; }
    install_opencti || { echo "❌ Failed at OpenCTI installation."; exit 1; }
    install_misp || { echo "❌ Failed at MISP installation."; exit 1; }
    install_dfir_iris || { echo "❌ Failed at DFIR IRIS installation."; exit 1; }
    install_shuffle || { echo "❌ Failed at Shuffle installation."; exit 1; }
    install_yara_manual || { echo "⚠️ Follow YARA manual installation instructions."; }

    echo "✅ All SOC packages installed successfully!"
}

# Run the function
auto_install_all
