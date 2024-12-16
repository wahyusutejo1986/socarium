#!/bin/bash

install_prerequisites() {
    echo "🛠 Installing prerequisites..."
    sudo apt update -y || error_handler "System Update"
    sudo apt install -y git curl wget python3-pip || error_handler "Prerequisites Installation"
}

