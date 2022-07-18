#!/bin/bash

#
# Complete script meant for running via MDM on device enrollment. This will download
# and install Dialog on the fly before opening Dialog. Tested with Mosyle MDM.
# 
# The logging to /var/tmp/deploy.log is useful when getting started but
# arguably is not needed.
#
# The progress bar manipulation could use some improvement.
#
# Display a Dialog with a list of applications and indicate when they've been installed
# Useful when apps are deployed at random, perhaps without local logging.
# Applies to Mosyle App Catalog installs, VPP app installs, etc.
# 
# Requires Dialog v1.9.1 or later https://github.com/bartreardon/swiftDialog/
#

# *** definable variables

# List of apps/installs to process
# Provide the display name as you prefer and the path to the app/file. ex: "Google Chrome,/Applications/Google Chrome.app"
# A comma separates the display name from the path. Do not use commas in your display name text.
# Tip: Check for something like print drivers using the pkg receipt, like "Konica-Minolta drivers,/var/db/receipts/jp.konicaminolta.print.package.C759.plist"
apps=(
  "Google Chrome,/Applications/Google Chrome.app"
  "Google Drive,/Applications/Google Drive.app"
  "VLC,/Applications/VLC.app"
  "zoom.us,/Applications/zoom.us.app"
)

dialogURL=$(curl --silent --fail "https://api.github.com/repos/bartreardon/swiftDialog/releases/latest" | awk -F '"' "/browser_download_url/ && /pkg\"/ { print \$4; exit }")
# Expected Team ID of the downloaded PKG
dialogExpectedTeamID="PWA5E9TQ59"

# Dialog display settings, change as desired
title="Installing Apps"
message="Please wait while we download and install apps"

# location of dialog and dialog command file
dialogApp="/usr/local/bin/dialog"
dialog_command_file="/var/tmp/dialog.log"

# *** end definable variables

# *** functions

function dialog_command(){
  echo "$1"
  echo "$1"  >> $dialog_command_file
}

function finalise(){
  dialog_command "icon: SF=checkmark.circle.fill,color1=green"
  dialog_command "progresstext: Install of apps complete"
  dialog_command "progress: complete"
  dialog_command "button1text: Done"
  dialog_command "button1: enable" 
  exit 0
}

function appCheck(){
dialog_command "listitem: '$(echo "$app" | cut -d ',' -f1)': wait"
while [ ! -e "$(echo "$app" | cut -d ',' -f2)" ]
do
  sleep 2
done
dialog_command "progresstext: Install of \"$(echo "$app" | cut -d ',' -f1)\" complete"
dialog_command "listitem: $(echo "$app" | cut -d ',' -f1): ✅"
progress_index=$(( progress_index + 1 ))
echo "at item number $progress_index"
}

function dialogCheck(){
if [ ! -e "/Library/Application Support/Dialog/Dialog.app" ]; then
  echo "$(date "+%a %h %d %H:%M:%S"): Dialog not found. Installing." 2>&1 | tee -a /var/tmp/deploy.log
  # Create temporary working directory
  workDirectory=$( /usr/bin/basename "$0" )
  tempDirectory=$( /usr/bin/mktemp -d "/private/tmp/$workDirectory.XXXXXX" )
  echo "$(date "+%a %h %d %H:%M:%S"): Created working directory '$tempDirectory'" 2>&1 | tee -a /var/tmp/deploy.log
  # Download the installer package
  echo "$(date "+%a %h %d %H:%M:%S"): Downloading Dialog package" 2>&1 | tee -a /var/tmp/deploy.log
  /usr/bin/curl --location --silent "$dialogURL" -o "$tempDirectory/Dialog.pkg"
  # Verify the download
  teamID=$(/usr/sbin/spctl -a -vv -t install "$tempDirectory/Dialog.pkg" 2>&1 | awk '/origin=/ {print $NF }' | tr -d '()')
  echo "$(date "+%a %h %d %H:%M:%S"): Team ID for downloaded package: $teamID" 2>&1 | tee -a /var/tmp/deploy.log
  # Install the package if Team ID validates
  if [ "$dialogExpectedTeamID" = "$teamID" ] || [ "$dialogExpectedTeamID" = "" ]; then
    echo "$(date "+%a %h %d %H:%M:%S"): Package verified. Installing package Dialog.pkg" 2>&1 | tee -a /var/tmp/deploy.log
    /usr/sbin/installer -pkg "$tempDirectory/Dialog.pkg" -target /
    exitCode=0
  else 
    echo "$(date "+%a %h %d %H:%M:%S"): Package verification failed before package installation could start. Download link may be invalid. Aborting." 2>&1 | tee -a /var/tmp/deploy.log
    displayDialog
    exitCode=1
    exit $exitCode
  fi
  # Remove the temporary working directory when done
  echo "$(date "+%a %h %d %H:%M:%S"): Deleting working directory '$tempDirectory' and its contents" 2>&1 | tee -a /var/tmp/deploy.log
  /bin/rm -Rf "$tempDirectory"  
else echo "$(date "+%a %h %d %H:%M:%S"): Dialog already found. Proceeding..." 2>&1 | tee -a /var/tmp/deploy.log
fi
}

# If something goes wrong and Dialog isn't installed we want to notify the user using AppleScript and exit the script
 # Line 117 must use tabs, do not replace with spaces
function displayDialog(){
  message="A problem was encountered setting up this Mac. Please contact IT."
  currentUser=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ { print $3 }')
  if [[ "$currentUser" != "" ]]; then
    currentUserID=$(id -u "$currentUser")
    launchctl asuser "$currentUserID" /usr/bin/osascript <<-EndOfScript
      button returned of ¬
      (display dialog "$message" ¬
      buttons {"OK"} ¬
      default button "OK")
		EndOfScript
  fi
}

# *** end functions

# start 

setupAssistantProcess=$(pgrep -l "Setup Assistant")
until [ "$setupAssistantProcess" = "" ]; do
  echo "$(date "+%a %h %d %H:%M:%S"): Setup Assistant Still Running. PID $setupAssistantProcess." 2>&1 | tee -a /var/tmp/deploy.log
  sleep 1
  setupAssistantProcess=$(pgrep -l "Setup Assistant")
done
echo "$(date "+%a %h %d %H:%M:%S"): Out of Setup Assistant" 2>&1 | tee -a /var/tmp/deploy.log
echo "$(date "+%a %h %d %H:%M:%S"): Logged in user is $(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ { print $3 }')" 2>&1 | tee -a /var/tmp/deploy.log

finderProcess=$(pgrep -l "Finder")
until [ "$finderProcess" != "" ]; do
  echo "$(date "+%a %h %d %H:%M:%S"): Finder process not found. Assuming device is at login screen. PID $finderProcess" 2>&1 | tee -a /var/tmp/deploy.log
  sleep 1
  finderProcess=$(pgrep -l "Finder")
done
echo "$(date "+%a %h %d %H:%M:%S"): Finder is running" 2>&1 | tee -a /var/tmp/deploy.log
echo "$(date "+%a %h %d %H:%M:%S"): Logged in user is $(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ { print $3 }')" 2>&1 | tee -a /var/tmp/deploy.log

dialogCheck

# set progress total to the number of apps in the list
progress_total=${#apps[@]}

# set icon based on whether computer is a desktop or laptop
hwType=$(/usr/sbin/system_profiler SPHardwareDataType | grep "Model Identifier" | grep "Book")	
if [ "$hwType" != "" ]; then
	icon="SF=laptopcomputer.and.arrow.down,weight=thin,colour1=#51a3ef,colour2=#5154ef"
	else
	icon="SF=desktopcomputer.and.arrow.down,weight=thin,colour1=#51a3ef,colour2=#5154ef"
fi

echo "$(date "+%a %h %d %H:%M:%S"): Logged in user is $(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ { print $3 }')" 2>&1 | tee -a /var/tmp/deploy.log

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
echo "$(date "+%a %h %d %H:%M:%S"): About to launch Dialog." 2>&1 | tee -a /var/tmp/deploy.log
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

echo "$(date "+%a %h %d %H:%M:%S"): Finalizing." 2>&1 | tee -a /var/tmp/deploy.log
finalise
echo "$(date "+%a %h %d %H:%M:%S"): Done." 2>&1 | tee -a /var/tmp/deploy.log
