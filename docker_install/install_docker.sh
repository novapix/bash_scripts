#!/bin/bash

function checkOS() {
    if [[ -e /etc/debian_version ]]; then
        OS="debian"
        source /etc/os-release
        if [[ $ID == "debian"]]; then
            if [[ $VERSION_ID -lt 9]]; then
                echo "Debian Version not supported"
                exit 1
            fi 
        elif [[ $ID == "ubuntu"]]
            OS="ubuntu"
            # Get the Major version which is the first field
            MAJOR_VERSION=$(echo "$VERSION_ID" | cut -d '.' -f1)
            if [[ MAJOR_VERSION -lt 18]]; then
                echo "ubuntu version not supported"
                exit 1
            fi
        fi
    elif [[ -e /etc/arch-release ]]; then
		OS="arch"
	else
		echo "Unsupported OS.Script only supports Debian, Ubuntu and Archlinux"
		exit 1
	fi              

}

function startCheck() {
    if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root."
    exit 1
    fi

    echo "Running as root!"

	checkOS
}

function updateSystem(){
    if [[ $OS =~ (debian|ubuntu) ]]; then
        echo "debian/ubuntu system detected. updating system"
        (apt update && apt upgrade -y) > ~/docker-install.log 2>&1 
    elif [[ $OS == "arch"]]
        echo "Arch Based System Detectec"
    fi
}