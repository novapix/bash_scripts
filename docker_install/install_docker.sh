#!/bin/bash

ISACTIVE=$( (sudo systemctl is-active docker ) 2>&1 )

OS=""
ERRORMSG="Something went wrong. Please check docker-install.log"

function checkOS() {
    if [[ -e /etc/debian_version ]]; then
        OS="debian"
        source /etc/os-release
        if [[ $ID == "debian" ]]; then
            if [[ $VERSION_ID -lt 9 ]]; then
                echo "Debian Version not supported"
                exit 1
            fi 
        elif [[ $ID == "ubuntu" ]]; then
            OS="ubuntu"
            # Get the Major version which is the first field
            MAJOR_VERSION=$(echo "$VERSION_ID" | cut -d '.' -f1)
            if [[ $MAJOR_VERSION -lt 18 ]]; then
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

function updateSystem(){
    if [[ "$OS" =~ (debian|ubuntu) ]]; then
        echo "debian/ubuntu system detected. updating system"
        if ( apt update && apt upgrade -y ) >> ~/docker-install.log 2>&1; then
            echo "Update Complete"
        else
            echo "$ERRORMSG"
            exit 1
        fi

    elif [[ "$OS" == "arch" ]]; then
        echo "Arch Based System Detected"        
        if (pacman -Syu --noconfirm) >> ~/docker-install.log 2>&1; then
            echo "Update Complete" 
        else
            echo "$ERRORMSG"
            exit 1
        fi
    fi
}

function installPrerequisites(){
    echo "Installing Prerequisite Packages..."
    if [[ "$OS" =~ (debian|ubuntu) ]]; then
        if ( apt install curl wget git -y) >> ~/docker-install.log 2>&1; then
            echo "Installed packages"
        else
            echo "$ERRORMSG"
            exit 1
        fi
    elif [[ "$OS" == "arch" ]]; then
        if (pacman -Sy git curl wget --noconfirm) >> ~/docker-install.log 2>&1; then
            echo "Update Complete" 
        else
            echo "$ERRORMSG"
            exit 1
        fi
    fi
}

function installDocker(){
    if [[ "$ISACTIVE" != "active" ]]; then
        echo " Installing Docker Community Edition "
        sleep 2s
        if [[ "$OS" =~ (debian|ubuntu) ]]; then
            if (curl -fsSL https://get.docker.com | sh)>> ~/docker-install.log 2>&1; then
                DOCKERV=$(docker -v)
                echo "Installed $DOCKERV "
                systemctl start docker
            else
                echo "$ERRORMSG"
            fi
        elif [[ "$OS" == "arch" ]]; then
            if (pacman -Sy docker --noconfirm)>> ~/docker-install.log 2>&1; then
                DOCKERV=$(docker -v)
                echo "Installed $DOCKERV "
                systemctl start docker
            else
                echo "$ERRORMSG"
            fi
        fi
    else
        echo "Docker Seems to be already running.... Skipping"
    fi
}

function installCompose(){
    if command -v docker-compose &> /dev/null; then
        echo "docker-compose is already installed..."
    else
        echo "docker-compose is not installed. Installing Docker Compose."
        VERSION=$(curl --silent https://api.github.com/repos/docker/compose/releases/latest | grep -Po '"tag_name": "\K[^"]+')
        ARCH=$(uname -m)
        URL="https://github.com/docker/compose/releases/download/$VERSION/docker-compose-linux-$ARCH"
        if (curl -SL "$URL" -o /usr/local/bin/docker-compose)>> ~/docker-install.log 2>&1; then
                chmod +x /usr/local/bin/docker-compose
                echo "Installed $VERSION "
        else
                echo "$ERRORMSG"
        fi

    fi
}


function startCheck() {
    if [ "$EUID" -ne 0 ]; then
        echo "This script must be run as root."
        exit 1
    fi

    echo "Running as root!"

	checkOS
    updateSystem
    installPrerequisites
    installDocker
    installCompose
}
