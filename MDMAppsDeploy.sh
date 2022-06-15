#!/bin/bash

#
# Display a Dialog with a list of applications and indicate when they've been installed
# Useful when apps are deployed at random, without local logging, etc.
# Useful for Mosyle App Catalog deployments, VPP app deployments, etc.
#
# This script doesn't handle installing Dialog and etc. It's meant for you to
# iterate on. Check out MDMInstallAndDeploy.sh for a complete example.
# 
# Requires Dialog v1.9.1 or later https://github.com/bartreardon/Dialog/releases
#

# List of apps to process
# Provide the display name as you prefer and the path to the app/file. ex: "Google Chrome,/Applications/Google Chrome.app"
# Tip: Check for something like print drivers using the pkg receipt, ex: "Konica-Minolta drivers,/var/db/receipts/jp.konicaminolta.print.package.C759.plist"
apps=(
    "Google Chrome,/Applications/Google Chrome.app"
    "Google Drive,/Applications/Google Drive.app"
    "VLC,/Applications/VLC.app"
    "zoom.us,/Applications/zoom.us.app"
)

# Dialog display settings, change as desired
title="Installing Apps"
message="Please wait while we download and install apps"

# location of dialog and dialog command file
dialogApp="/usr/local/bin/dialog"
dialog_command_file="/var/tmp/dialog.log"

# check we are running as root
if [[ $(id -u) -ne 0 ]]; then
  echo "This script should be run as root"
  exit 1
fi

# *** functions

# execute a dialog command
function dialog_command(){
  echo "$1"
  echo "$1"  >> $dialog_command_file
}

function finalise(){
  dialog_command "progresstext: Install of applications complete"
  dialog_command "progress: complete"
  dialog_command "button1text: Done"
  dialog_command "button1: enable" 
  exit 0
}

function appCheck(){
dialog_command "listitem: $(echo "$app" | cut -d ',' -f1): wait"
while [ ! -e "$(echo "$app" | cut -d ',' -f2)" ]
do
    sleep 2
done
dialog_command "progresstext: Install of \"$(echo "$app" | cut -d ',' -f1)\" complete"
dialog_command "listitem: $(echo "$app" | cut -d ',' -f1): ✅"
progress_index=$(( progress_index + 1 ))
echo "at item number $progress_index"
}

# *** end functions

# set progress total to the number of apps in the list
progress_total=${#apps[@]}

# set icon based on whether computer is a desktop or laptop
hwType=$(/usr/sbin/system_profiler SPHardwareDataType | grep "Model Identifier" | grep "Book")  
if [ "$hwType" != "" ]; then
  icon="SF=laptopcomputer.and.arrow.down,weight=thin,colour1=#51a3ef,colour2=#5154ef"
  else
  icon="SF=desktopcomputer.and.arrow.down,weight=thin,colour1=#51a3ef,colour2=#5154ef"
fi

dialogCMD="$dialogApp -p --title \"$title\" \
--message \"$message\" \
--icon \"$icon\" \
--progress $progress_total \
--button1text \"Please Wait\" \
--button1disabled"

# create the list of apps
listitems=""
for app in "${apps[@]}"; do
  listitems="$listitems --listitem '$(echo "$app" | cut -d ',' -f1)'"
done

# final command to execute
dialogCMD="$dialogCMD $listitems"

echo "$dialogCMD"

# Launch dialog and run it in the background sleep for a second to let thing initialise
eval "$dialogCMD" &
sleep 2

progress_index=0

(for app in "${apps[@]}"; do
  step_progress=$(( 1 + progress_index ))
  dialog_command "progress: $step_progress"
  appCheck &
done

wait)

# all done. close off processing and enable the "Done" button
finalise
