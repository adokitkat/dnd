# Package

version       = "0.6.0"
author        = "Adam Múdry"
description   = "Drag and drop source / target"
license       = "GPL-3.0-only"
bin           = @["dnd"]
installDirs   = @["resources", "examples"]
installFiles  = @["dnd.cfg", "README.md"]


# Dependencies

requires "nim >= 1.6.2"
requires "gintro#head"

import os, strformat
before build:
  writeFile("dnd.nims", "--define:InstallTypeDefine:nimble")

after build:
  rmFile "dnd.nims"

after install:
  var desktop_entry = &"""
[Desktop Entry]
Name=dnd
Exec={os.getHomeDir()}.nimble/bin/dnd
Icon={os.getHomeDir()}.nimble/pkgs/dnd-{version}/resources/dnd.xpm
Terminal=false
Type=Application"""
  writeFile(&"{os.getHomeDir()}.local/share/applications/dnd.desktop", desktop_entry)

before uninstall:
  rmFile &"{os.getHomeDir()}.local/share/applications/dnd.desktop" #TODO: doesn't work?