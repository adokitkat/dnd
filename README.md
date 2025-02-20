# dnd

![dnd logo](resources/dnd.png "dnd logo")

Bi-directional drag and drop source / target

Key features:

- Run `dnd` without arguments and blank window with target area appears
- Run `dnd` with arguments, e.g. `dnd file1.txt file2.html`, `dnd *` or pipe into it like `find . -name "*.txt" | dnd file2.html` and window with both drag and drop source files & target area appears
- Configure default options (flags) in `dnd.cfg` file located in the same directory as the executable or `~/.config/dnd/dnd.cfg.` (after installation) so you dont have to type them every time
- Save different setting presets in `dnd.cfg` and switch between them by running the program like `dnd --preset=Alt`
- Run `dnd --help` to see all options or look at [usage](#Usage) below
- You can quit by hitting `Esc` or `Q` key also

## Requirements

- GTK+ 3

### Build Requirements

- GTK+ 3 dev packages
- [Nim compiler 1.6.12](https://nim-lang.org/) - e.g. use `choosenim 1.6.12` (compilation with newer versions unfortunately fails due to isuue in gintro and/or Nim compiler itself)
- [gintro](https://github.com/StefanSalewski/gintro/) (automatically downloaded via nimble)

## Getting Started

You can install it via 2 methods:

- Manual (Makefile) - Nim not required (when not building)
- Nim's package manager `nimble`

### Manual (Makefile)

Download [the latest release](https://github.com/adokitkat/dnd/releases) and unpack it to a folder (`tar -zxf FILENAME`)

To install:

```sh
make install
```

To uninstall:

```sh
make uninstall
```

- `dnd` executable is installed to `~/.local/bin/dnd`
- `dnd.cfg` is installed to `~/.config/dnd/dnd.cfg`
- Desktop entry is installed to `~/.local/share/applications/dnd.desktop`
- Icon `dnd.xpm` is installed to `~/.local/share/icons/dnd.xpm`

### Nimble

```sh
nimble install dnd
```

- `dnd` symlink is installed to `~/.nimble/bin/dnd` and executable to `~/.nimble/pkgs/dnd-VERSION/dnd`
- `dnd.cfg` is installed to `~/.nimble/pkgs/dnd-VERSION/dnd.cfg`
- Desktop entry is installed to `~/.local/share/applications/dnd.desktop` - `nimble uninstall dnd` cannot remove it automatically?
- Icon `dnd.xpm` is installed to `~/.nimble/pkgs/dnd-VERSION/resources/dnd.xpm`

## Usage

```man
dnd - bi-directional drag and drip source / target
Usage: dnd [options] [file...]
  -a,       --all=true           Drag all files at once
  -k,       --keep=true          Keep dropped files in for a drag out
  -t,       --top=true           Keep the program window always on top
  -c,       --center-mouse=true  Center the program on the mouse
  -C,       --center-screen=true Center the program in the middle of the screen
  -f=NAME,  --cfg=NAME           Load a different config file
  -p=NAME,  --preset=NAME        Load different preset from config file
  -d,       --decorated=true     Let the program window be decorated by the window manager
  -o=FLOAT, --opacity=FLOAT      Change the program window opacity
  -v,       --version            Show version info
  -h,       --help               Show this message

Presets in current loaded dnd.cfg file:
  [Default]
  w = 200 # Width
  h = 200 # Height
  keep = false
  always_on_top = true
  center_mouse = false
  center_screen = true
  decorated = true
  opacity = 1.0
```

## Examples

- `dnd` - shows a blank `dnd` window with drag-and-drop area, drag media into it and an URL/URI address is printed to `stdout`
- `dnd *` - shows a drag area for every file in the folder and drop area at the bottom
- `dnd .` - shows a drag area for the current folder and drop area at the bottom
- `dnd file1 file2` - shows a drag area for `file1`, `file2` and drop area at the bottom
- `find . -name "*.txt" | dnd file2.html` - shows a drag area for `file.html`, every file output by the pipe (every `txt` file in current folder and subfolders) and drop area at the bottom
- `dnd | while read url; do wget "$url"; done` - drag media from browser (a picture) into `dnd` drop area, it captures the URL address and uses `wget` to download the media to current folder (also in `examples/dnd_wget.sh`) 

## Thanks

Thanks to [mwh](https://github.com/mwh) and his [dragon](https://github.com/mwh/dragon) for inspiration and [Dr. Stefan Salewski](https://github.com/StefanSalewski) for help with GTK and [gintro](https://github.com/StefanSalewski/gintro/).

## License

GNU GPL version 3
