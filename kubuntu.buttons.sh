#!/bin/bash

writeconfig5 --file ~/.config/kwinrc --group ModifierOnlyShortcuts --key Meta "org.kde.lattedock,/Latte,org.kde.LatteDock,activateLauncherMenu"
qdbus org.kde.KWin /KWin reconfigure

[org.kde.kdecoration2]
BorderSize=Normal
ButtonsOnLeft=XIAS
ButtonsOnRight=H
CloseOnDoubleClickOnMenu=false
ShowToolTips=true
library=org.kde.breeze
theme=Breeze
