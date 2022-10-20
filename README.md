# dialog-scripts
Scripts I've written to use with the awesome swiftDialog app https://github.com/bartreardon/swiftDialog

Most scripts in this repo have comment code to describe their use. 

The most useful example is MDMAppsDeploy shown below.

## MDMAppsDeploy.sh
Display a Dialog with a list of applications and indicate when they've been installed. Useful when apps are deployed by something besides this script, or without local logging, etc. In particular, it's useful for Mosyle App Catalog deployments and VPP app deployments. This script doesn't handle installing Dialog and etc. It's meant for you to iterate on. Check out MDMInstallAndDeploy.sh in this repo for a complete, standalone, ready to use script.

![MDMAppsDeploy](https://user-images.githubusercontent.com/6863894/189948035-3f34c0d4-f551-4a7f-bffd-1ee5ab52ace1.png)

MDMAppsDeploy checks every two seconds that a file, like `/Applications/Google Chrome.app`, exists. Once it does, the list is updated and shows Google Chromea with a checkmark, indicating it's complete. This means you can have it check for anything, like a printer driver file path, to indicate the install is complete.

## MDMInstallandDeploy.sh
This is an all in one script showing how to use MDMAppsDeploy. The script will wait until the user is logged in, download and install swiftDialog, and then perform the rest of what MDMAppsDeploy does.

Requires swiftDialog 1.11.2 or later.
