#!/bin/bash

dialogApp="/usr/local/bin/dialog"

title="SF Symbols Test"
message="How does this icon look?"

dialogCMD="$dialogApp -p --title \"$title\" \
--icon SF=laptopcomputer \
--overlayicon SF=arrow.down.circle.fill,palette=white,black,none,bgcolor=none \
--message \"$message\" \
--moveable"

eval "$dialogCMD"