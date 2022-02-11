# dnd

![dnd logo](resources/dnd.png "dnd logo")

Bi-directional drag and drop source / target

- Run `dnd` without arguments and blank window with target area appears
- Run `dnd` with arguments, e.g. `dnd file1.txt file2.html`, `dnd *` or pipe into it like `find . -name "*.txt" | dnd file2.html` and window with both drag and drop source files & target area appears
- Configure default options (flags) in `dnd.cfg` file located in the same directory as the executable or `~/.config/dnd/dnd.cfg.` (after installation) so you dont have to type them every time
- Save different setting presets in `dnd.cfg` and switch between them by running the program like `dnd --preset=Alt`
- Run `dnd --help` to see all options or look at [usage](#Usage) below
- You can quit by hitting `Esc` or `Q` key also

## Requirements

- GTK+ 3 + dev packages
- [Nim compiler 1.6.4+](https://nim-lang.org/)
- [gintro](https://github.com/StefanSalewski/gintro/) (automatically downloaded)

## Getting Started

### Build

```sh
nimble build
```

or

```sh
make
```

### Installation / Uninstallation

```sh
make install
```

```sh
make uninstall
```

- `dnd` executable is installed to `~/.local/bin/dnd`
- `dnd.cfg` is installed to `~/.config/dnd/dnd.cfg`
- Desktop entry is installed to `~/.local/share/applications/dnd.desktop`
- Icon `dnd.xpm` is installed to `~/.local/share/icons/dnd.xpm`

### Usage

```man
dnd - bi-directional drag and drip source / target
Usage: dnd [options] [file...]
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

## TODO

- Drag all

## Thanks

Thanks to [mwh](https://github.com/mwh) and his [dragon](https://github.com/mwh/dragon) for inspiration and [Dr. Stefan Salewski](https://github.com/StefanSalewski) for help with GTK and [gintro](https://github.com/StefanSalewski/gintro/).

## License

GNU GPL version 3
