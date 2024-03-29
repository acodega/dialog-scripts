# this function is Bash compatible, insert the function in your script and then place dialogAppleScript where you want it to be executed
# this is meant to be used when you need to show an error to the user and swiftDialog is not installed

dialogAppleScript(){
  message="A problem was encountered setting up this Mac. Please contact IT."
  currentUser=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ { print $3 }')
  if [[ "$currentUser" != "" ]]; then
    currentUserID=$(id -u "$currentUser")
    launchctl asuser "$currentUserID" /usr/bin/osascript <<-EndOfScript
      button returned of ¬
      (display dialog "$message" ¬
      buttons {"OK"} ¬
      default button "OK")
		EndOfScript # this line *must* use tabs and not spaces. Ensure your text editor does not change them.
  fi
}
