#!/bin/bash

dialogPath="/usr/local/bin/dialog"
dialogTitle="SF Symbols Test"
dialogMessage="How does this icon look?"
dialogIcon="SF=laptopcomputer"
dialogOverlayIcon="SF=arrow.down.circle.fill,palette=white,black,none,bgcolor=none"

dialogOptions=(
--title "$dialogTitle"
--icon "$dialogIcon"
--overlayicon "$dialogOverlayIcon"
--moveable
--ontop
)

dialogContent=(
--message "$dialogMessage"
)

"$dialogPath" "${dialogOptions[@]}" "${dialogContent[@]}"
