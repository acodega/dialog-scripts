#!/bin/bash
dialogApp="/usr/local/bin/dialog"

title="Name This Mac"
message="Enter the preferred computer name below"

hwType=$(/usr/sbin/system_profiler SPHardwareDataType | grep "Model Identifier" | grep "Book")  
if [ "$hwType" != "" ]; then
  icon="SF=laptopcomputer.and.arrow.down,weight=thin,colour1=#51a3ef,colour2=#5154ef"
  else
  icon="SF=desktopcomputer.and.arrow.down,weight=thin,colour1=#51a3ef,colour2=#5154ef"
fi

dialogCMD="$dialogApp -p --title \"$title\" \
--icon \"$icon\" \
--message \"$message\" \
--small \
--textfield \"Computer Name\""

computerName=$(eval "$dialogCMD" | awk -F " : " '{print $NF}')

scutil --set HostName "$computerName"
scutil --set LocalHostName "$computerName"
scutil --set ComputerName "$computerName"
