#!/bin/zsh --no-rcs
# shellcheck shell=bash
# set -x

# Name: Registration.sh
# Version: 1.0
# Created: 08-05-2024 by Michael Permann
# Updated: 
# This Baseline registration script is meant to display an End User License Agreement
# and Register Your Mac screens before the Baseline device provisioning workflow kicks
# off. If power isn't detected, the script will pause and notify the user to connect to
# power before proceeding. Inspiration and code came from the following scripts:
# Jamf Software - DEPNotify-Starter 
# https://github.com/jamf/DEPNotify-Starter/
# HCS Technology - How to Configure Baseline for Jamf Pro 
# https://hcsonline.com/support/white-papers/how-to-configure-baseline-for-jamf-pro

# Registration options (departmentList and buildingList must exactly match their respective lists in Jamf Pro)
# Lists are comma separated, with no spaces after commas
departmentList="Communications,Finance,Human Resources,Information Technology,Marketing,Operations,Sales,Test"
buildingList="Burlington,Grimes,Las Vegas,Tipton"
setUpByList="End User,Maxwell Permann,Michael Permann,Morris Permann,Other Technician"
deployedList="Summer 2024,Fall 2024,Winter 2024,Spring 2025,Summer 2025,Fall 2025,Winter 2025"

# Path to binaries
dialogPath="/usr/local/bin/dialog"
jamfPath="/usr/local/bin/jamf"
plistBuddyPath="/usr/libexec/PlistBuddy"

# Temporary Dialog Command files
powerCheckCommandFile=$(mktemp /var/tmp/powercheck.XXXXXX)
registrationCommandFile=$(mktemp /var/tmp/registration.XXXXXX)

# Provision report plist location
provisionReport="/Users/Shared/BaselineConfigData.plist"

# Variables
currentUser=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }')
provisionDate=$(date)
serialNum=$(ioreg -l | awk '/IOPlatformSerialNumber/ {print $4}' | sed 's/"//g')
uuid=$(ioreg -rd1 -c IOPlatformExpertDevice | awk -F'"' '/IOPlatformUUID/{print $(NF-1)}')
# Optimal bannerImage logo size is 700 x 150 pixels
bannerImage="/usr/local/Baseline/Icons/BannerImage.png" 
# Optimal logo size is 1024 x 1024 pixels
logo="/usr/local/Baseline/Icons/Logo.png"

# Function to display a dialog asking to plug into power
function display_power_dialog() {
    # Display the dialog alert
    "$dialogPath" command display alert \
    --title "Power Check" \
    --message "Power is required to continue setting up your Mac. Please connect your charger." \
    --messagealignment "center" \
    --icon "SF=powerplug" \
    --overlayicon caution \
    --button1disabled \
    --quitkey ] \
    --commandfile "$powerCheckCommandFile" \
    --centericon \
    --width 400 \
    --blurscreen \
    &
}

# Execute a dialog command
function dialog_command(){
    /bin/echo "$@"  >> "$registrationCommandFile"
    sleep .1
}

# Check if the device is on battery
powerSource=$(pmset -g ps | head -1)
# If we're on battery...
if [[ "$powerSource" == "Now drawing from 'Battery Power'" ]]; then
    # Display a dialog about it
    display_power_dialog
    # Loop endlessly until the device gets connected to power.
    while [[ "$(pmset -g ps | head -1)" == "Now drawing from 'Battery Power'" ]]; do
        echo "$(date): Device is on battery power"
        sleep 3
    done
    # Device is now connected to power, close the dialog and continue
    echo "$(date): Device is now connected to a power source."
    echo "quit:" >> "$powerCheckCommandFile"
fi

# End User License Agreement dialog shown to users and requiring their agreement
dialogEulaResponse=$(\
"$dialogPath" \
    --bannerimage "$bannerImage" \
    --title "End User License Agreement" \
    --message "$(cat /Users/Shared/eula.md)" \
    --checkbox "I Agree",enableButton1 \
    --button1disabled \
    --width 700 --height 600 \
    --commandfile "$registrationCommandFile" \
    --blurscreen
)

# Process and store EulaResponse
eulaSelection=$(echo "$dialogEulaResponse" | grep -v 'index :' | grep "I Agree" | awk -F ": " '{print $NF}' | sed 's/"//g')

# Registration dialog requesting information from user
dialogRegistrationResponse=$(\
"$dialogPath" \
    --bannerimage "$bannerImage" \
    --title "Register Your Mac" \
    --message "" \
    --quitkey ] \
    --textfield "Asset Tag",prompt="54321",regex="^\d{5}$",regexerror="Asset Tag # must be a five digit number" \
    --textfield "Computer Name",required,prompt="Maxwell Permann 54321" \
    --selecttitle "Department",required --selectvalues "$departmentList" \
    --selecttitle "Building",required --selectvalues "$buildingList" \
    --selecttitle "Set Up By",required --selectvalues "$setUpByList" \
    --selecttitle "Deployed",required --selectvalues "$deployedList" \
    --width 700 --height 500 \
    --commandfile "$registrationCommandFile" \
    --blurscreen
)

# Process and store RegistrationResponse
assetTag=$(echo "$dialogRegistrationResponse" | grep "Asset Tag" | awk -F ": " '{print $NF}' )
computerName=$(echo "$dialogRegistrationResponse" | grep "Computer Name" | awk -F ": " '{print $NF}' )
buildingSelection=$(echo "$dialogRegistrationResponse" | grep -v 'index :' | grep "Building" | awk -F ": " '{print $NF}' | sed 's/"//g')
departmentSelection=$(echo "$dialogRegistrationResponse" | grep -v 'index :' | grep "Department" | awk -F ": " '{print $NF}' | sed 's/"//g')
setUpBySelection=$(echo "$dialogRegistrationResponse" | grep -v 'index :' | grep "Set Up By" | awk -F ": " '{print $NF}' | sed 's/"//g')
deployedSelection=$(echo "$dialogRegistrationResponse" | grep -v 'index :' | grep "Deployed" | awk -F ": " '{print $NF}' | sed 's/"//g')

# Updating Management System dialog to inform the user of progress 
"$dialogPath" \
    --title "Updating Management System" \
    --icon "$logo" \
    --message "This may take a few minutes to complete. Please be patient." \
    --mini \
    --button1disabled \
    --progress \
    --quitkey ] \
    --width 500 --height 200 \
    --commandfile "$registrationCommandFile" \
    --blurscreen \
    &

# Updating computer name in Jamf Pro
"$jamfPath" setComputerName -name "$computerName"
# Updating tag number in Jamf Pro
"$jamfPath" recon -assetTag "$assetTag"
# Updating building assignment in Jamf Pro
"$jamfPath" recon -building "$buildingSelection"
# Updating department assignment in Jamf Pro
"$jamfPath" recon -department "$departmentSelection"

# Write information to provisioning report and update inventory
"$plistBuddyPath" -c "Add :'Asset Tag #' string $assetTag" "$provisionReport"
"$plistBuddyPath" -c "Add :'Computer Serial #' string $serialNum" "$provisionReport"
"$plistBuddyPath" -c "Add :'Device UUID' string $uuid" "$provisionReport"
"$plistBuddyPath" -c "Add :'Building' string $buildingSelection" "$provisionReport"
"$plistBuddyPath" -c "Add :'Department' string $departmentSelection" "$provisionReport"
"$plistBuddyPath" -c "Add :'Set Up By' string $setUpBySelection" "$provisionReport"
"$plistBuddyPath" -c "Add :'Provision Timeframe' string $deployedSelection" "$provisionReport"
"$plistBuddyPath" -c "Add :'Provision Date' string $provisionDate" "$provisionReport"
"$plistBuddyPath" -c "Add :'Username' string $currentUser" "$provisionReport"
"$plistBuddyPath" -c "Add :'EULA Response' string $eulaSelection" "$provisionReport"
"$jamfPath" recon
dialog_command "progress: complete"
dialog_command "progresstext: Finished with Registration"
sleep 3
dialog_command "quit: "

/bin/rm -rf "$powerCheckCommandFile" > /dev/null 2>&1
/bin/rm -rf "$registrationCommandFile" > /dev/null 2>&1
exit 0