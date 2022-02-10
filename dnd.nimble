# Package

version       = "0.4.0"
author        = "Adam Múdry"
description   = "Drag and drop source / target"
license       = "MIT"
srcDir        = "src"
bin           = @["dnd"]


# Dependencies

requires "nim >= 1.6.2"
requires "gintro#head"

import os, strformat
task prepareInstall, "Installing...":
  let desktop_entry = &"""[Desktop Entry]
Name=dnd
Exec={getHomeDir()}.local/bin/dnd
Icon={getHomeDir()}/.local/share/icons/dnd.xpm
Terminal=false
Type=Application"""
  "dnd.desktop".writeFile(desktop_entry)