#!/bin/bash

# Microsoft fwlink product ID, e.g. "525133" for Office Suite, found at the end of Microsoft's FW link
linkID="525133"
url="https://go.microsoft.com/fwlink/?linkid=$linkID"
# serializerURL="https://qwerty.domain.net/OfficeForMac/Microsoft_Office_LTSC_2021_VL_Serializer.pkg" # Replace with the URL to your serializer PKG, Comment line 6-8 if you're not serializing
# UNAME=abc # Replace with the username, if needed, to curl your PKG. Comment line 6-8 if you're not serializing
# PWORD=xyz # Replace with the password, if needed, to curl your PKG. Comment line 6-8 if you're not serializing
expectedTeamID="UBF8T346G9" # '/usr/sbin/spctl -a -vv -t install package.pkg' to get the expected Team ID
dialogApp="/usr/local/bin/dialog"
workDirectory=$( /usr/bin/basename "$0" )
tempDirectory=$( /usr/bin/mktemp -d "/private/tmp/$workDirectory.XXXXXX" )
dialog_command_file="$tempDirectory/dialog.log"

function dialog_command(){
	echo $1
	echo $1  >> $dialog_command_file
}

function finalize(){
	dialog_command "progresstext: Install of Microsoft Office complete"
	dialog_command "progress: complete"
	dialog_command "button1text: Done"
	dialog_command "button1: enable" 
	exit 0
}

function finalizeError(){
	dialog_command "progress: 0"
	dialog_command "button1text: Close"
	dialog_command "button1: enable" 
	exit 0
}

function dialogAppleScript(){
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
    # the above line *must* use tabs and not spaces. Ensure your text editor does not change them.
  fi
}

function dialogCheck(){
  # Get the URL of the latest PKG From the Dialog GitHub repo
  dialogURL=$(curl --silent --fail "https://api.github.com/repos/bartreardon/swiftDialog/releases/latest" | awk -F '"' "/browser_download_url/ && /pkg\"/ { print \$4; exit }")
  # Expected Team ID of the downloaded PKG
  dialogExpectedTeamID="PWA5E9TQ59"

  # Check for Dialog and install if not found
  if [ ! -e "/Library/Application Support/Dialog/Dialog.app" ]; then
    echo "Dialog not found. Installing..."
    # Create temporary working directory
    workDirectory=$( /usr/bin/basename "$0" )
    tempDirectory=$( /usr/bin/mktemp -d "/private/tmp/$workDirectory.XXXXXX" )
    # Download the installer package
    /usr/bin/curl --location --silent "$dialogURL" -o "$tempDirectory/Dialog.pkg"
    # Verify the download
    teamID=$(/usr/sbin/spctl -a -vv -t install "$tempDirectory/Dialog.pkg" 2>&1 | awk '/origin=/ {print $NF }' | tr -d '()')
    # Install the package if Team ID validates
    if [ "$dialogExpectedTeamID" = "$teamID" ] || [ "$dialogExpectedTeamID" = "" ]; then
      /usr/sbin/installer -pkg "$tempDirectory/Dialog.pkg" -target /
    else 
      dialogAppleScript
      exitCode=1
      exit $exitCode
    fi
    # Remove the temporary working directory when done
    /bin/rm -Rf "$tempDirectory"  
  else echo "Dialog already found. Proceeding..."
  fi
}

function serializeOffice(){
  # download the serializer package and capture the % percentage sign progress for Dialog display
  # We all know not to use cURL with a username and password in the script. Yada yada. Remove --user $UNAME:$PWORD if not required.
  /usr/bin/curl --user $UNAME:$PWORD -L "$serializerURL" -# -o "$tempDirectory/Microsoft_Office_LTSC_2021_VL_Serializer.pkg" 2>&1 | while IFS= read -r -n1 char; do
    [[ $char =~ [0-9] ]] && keep=1 ;
    [[ $char == % ]] && dialog_command "progresstext: Downloading Microsoft Office License ${progress}%" && progress="" && keep=0 ;
    [[ $keep == 1 ]] && progress="$progress$char" ;
  done

  # verify the serializer download
  teamID=$(/usr/sbin/spctl -a -vv -t install "$tempDirectory/Microsoft_Office_LTSC_2021_VL_Serializer.pkg" 2>&1 | awk '/origin=/ {print $NF }' | tr -d '()')
  echo "Team ID for downloaded package: $teamID"

  # install the serializer package if Team ID validates
  if [ "$expectedTeamID" = "$teamID" ] || [ "$expectedTeamID" = "" ]; then
    dialog_command "progresstext: Installing Microsoft Office License..."
    dialog_command "progress: 1"
    /usr/sbin/installer -pkg "$tempDirectory/Microsoft_Office_LTSC_2021_VL_Serializer.pkg" -target /
  else
    dialog_command "progresstext: Something went wrong. Please try again or contact IT. (Invalid License URL or License Team ID)"
    finalizeError
    exitCode=1
    exit $exitCode
  fi
}

# Begin

chmod 777 "$tempDirectory"

setupAssistantProcess=$(pgrep -l "Setup Assistant")
until [ "$setupAssistantProcess" = "" ]; do
  echo "$(date "+%a %h %d %H:%M:%S"): Setup Assistant Still Running. PID $setupAssistantProcess."
  sleep 1
  setupAssistantProcess=$(pgrep -l "Setup Assistant")
done
echo "$(date "+%a %h %d %H:%M:%S"): Out of Setup Assistant" 2>&1
echo "$(date "+%a %h %d %H:%M:%S"): Logged in user is $(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ { print $3 }')"

finderProcess=$(pgrep -l "Finder")
until [ "$finderProcess" != "" ]; do
  echo "$(date "+%a %h %d %H:%M:%S"): Finder process not found. Assuming device is at login screen. PID $finderProcess"
  sleep 1
  finderProcess=$(pgrep -l "Finder")
done

echo "$(date "+%a %h %d %H:%M:%S"): Finder is running"
echo "$(date "+%a %h %d %H:%M:%S"): Logged in user is $(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ { print $3 }')"

dialogCheck

# initial dialog starting arguments
message="Installing Microsoft Office"

# set icon based on whether computer is a desktop or laptop
hwType=$(/usr/sbin/system_profiler SPHardwareDataType | grep "Model Identifier" | grep "Book")	
if [ "$hwType" != "" ]; then
	icon="SF=laptopcomputer.and.arrow.down"
	else
	icon="SF=desktopcomputer.and.arrow.down"
fi

dialogCMD="$dialogApp --title none \
--message \"$message\" \
--alignment center \
--icon \"$icon\" \
--centericon \
--commandfile \"$dialog_command_file\" \
--ontop \
--moveable \
--small \
--progress 3 \
--button1text \"Please Wait\" \
--button1disabled"

echo $dialogCMD
# Launch dialog and run it in the background sleep for a second to let thing initialise
eval $dialogCMD &
sleep 2

# now start executing

dialog_command "progress: 0"
dialog_command "progresstext: Starting..."

if [ -z "$serializerURL" ]
then
  echo "Microsoft Serializer not specified. Continuing on."
else
  serializeOffice
fi

# download the installer package and capture the % percentage sign progress for Dialog display
dialog_command "progress: 1"
/usr/bin/curl --location "$url" -# -o "$tempDirectory/$linkID.pkg" 2>&1 | while IFS= read -r -n1 char; do
  [[ $char =~ [0-9] ]] && keep=1 ;
  [[ $char == % ]] && dialog_command "progresstext: Downloading Microsoft Office ${progress}%" && progress="" && keep=0 ;
  [[ $keep == 1 ]] && progress="$progress$char" ;
done

# verify the download
teamID=$(/usr/sbin/spctl -a -vv -t install "$tempDirectory/$linkID.pkg" 2>&1 | awk '/origin=/ {print $NF }' | tr -d '()')
echo "Team ID for downloaded package: $teamID"

# install the package if Team ID validates
if [ "$expectedTeamID" = "$teamID" ] || [ "$expectedTeamID" = "" ]; then
  dialog_command "progresstext: Installing Microsoft Office..."
	dialog_command "progress: 2"
  /usr/sbin/installer -pkg "$tempDirectory/$linkID.pkg" -target /
  dialog_command "icon: SF=checkmark.circle.fill,color1=green"
  finalize
  exitCode=0
else
  dialog_command "progresstext: Something went wrong. Please try again or contact IT. (Invalid app URL or app Team ID)"
  finalizeError
  exitCode=1
fi

# remove the temporary working directory when done
/bin/rm -Rf "$tempDirectory"

exit $exitCode
