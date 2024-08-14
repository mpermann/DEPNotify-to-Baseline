#!/bin/zsh --no-rcs
set -x

# Name: Branding-Customizations.sh
# Version: 1.0
# Created: 08-05-2024 by Michael Permann
# Updated: 
# This Baseline customizations script is meant to download and install a branding and
# customizations package from an https location so the proper images and icons are in
# place before the Register Your Mac screens are presented to the end user. Inspiration
# and code came from the following script:
# Second Son Consulting - Baseline
# https://github.com/SecondSonConsulting/Baseline

logFile="/var/log/Baseline.log"
# Name of your Baseline branding and customizations package
customizationsPkgName="Baseline-Branding-Customizations.pkg"
# Path to the Registration.sh script to determine the customizations package was installed
customizationsPath="/usr/local/Baseline/Scripts/Registration.sh"
# URL to the public https host
hostUrl="https://myawsbucket.s3.amazonaws.com/"
# URL to the public https hosting your customizations package
customizationsPkgUrl="${hostUrl}${customizationsPkgName}"

# Publish a message to the Baseline log
function log_message(){
    echo "$(date): $*" | tee >( cat >> "$logFile" ) 
}

# Only delete something if the variable has a value!
function rm_if_exists(){
    if [ -n "${1}" ] && [ -e "${1}" ];then
        /bin/rm -rf "${1}"
    fi
}

# Download and install customizations package
function install_customizations(){
    # Check for the Registration.sh script and install the branding and customizations 
    # package if not found. We'll try 10 times before exiting the script with a fail.
    customizationsInstallAttempts=0
    while [ ! -e "$customizationsPath" ] && [ "$customizationsInstallAttempts" -lt 10 ]; do
        log_message "$customizationsPath not found. Installing."
        # Create temporary working directory
        tempDirectory=$( /usr/bin/mktemp -d "/private/tmp/customizations.XXXXXX" )
        # Download the installer package
        /usr/bin/curl --location --silent "$customizationsPkgUrl" -o "$tempDirectory/$customizationsPkgName"
        /usr/sbin/installer -pkg "$tempDirectory/$customizationsPkgName" -target /  > /dev/null 2>&1
        customizationsInstallExitCode=$?
        if [ ! -e "$customizationsPath" ]; then
            log_message "$customizationsPkgName installation failed."
            sleep 5
            customizationsInstallAttempts=$((customizationsInstallAttempts+1))
        fi
        # Remove the temporary working directory when done
        rm_if_exists "$tempDirectory"
    done
}

install_customizations