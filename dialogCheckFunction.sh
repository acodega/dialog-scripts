# this function is Bash compatible, insert the function in your script and then place dialogCheck where you want it to be executed

function dialogCheck(){
  # Get the URL of the latest PKG From the Dialog GitHub repo
  dialogURL=$(curl --silent --fail "https://api.github.com/repos/bartreardon/Dialog/releases/latest" | awk -F '"' "/browser_download_url/ && /pkg\"/ { print \$4; exit }")
  # Expected Team ID of the downloaded PKG
  expectedDialogTeamID="PWA5E9TQ59"

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
    if [ "$expectedDialogTeamID" = "$teamID" ] || [ "$expectedDialogTeamID" = "" ]; then
      /usr/sbin/installer -pkg "$tempDirectory/Dialog.pkg" -target /
    else
      # displayAppleScript # uncomment this if you're using my displayAppleScript function
      # echo "Dialog Team ID verification failed."
      # exit 1 # uncomment this if want script to bail if Dialog install fails
    fi
    # Remove the temporary working directory when done
    /bin/rm -Rf "$tempDirectory"  
  else echo "Dialog found. Proceeding..."
  fi
}
