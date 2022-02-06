# dnd
Bi-directional drag and drop source / target 

WIP

## TODO

- Fix drag and drop from `dnd` to destination. Does not work for some reason. Crashes `Nautilus` file explorer, `Chrome` does not react in nay way. `GtkDragAction` copy should be sent.
- Implement `--center` option


## Requirements

 - GTK+ 3/4 (dev packages also)
 - [Nim compiler 1.6.2+](https://nim-lang.org/)
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

### Usage
```
dnd - bi-directional drag and drip source / target
Usage: dnd [options] [file...]
  -k, --keep           Keep dropped files in for a drag out
  -t, --top            Keep the program window always on top
  -c, --center         Open the program window in the middle of the parent window
  -C, --center-screen  Open program the window in the middle of the screen
  -p, --preset=NAME    Load different preset from config file
```

## Thanks

Thanks to [mwh](https://github.com/mwh) and his [dragon](https://github.com/mwh/dragon) for inspiration and [Dr. Stefan Salewski](https://github.com/StefanSalewski) for help with GTK and [gintro](https://github.com/StefanSalewski/gintro/).

## License

GNU GPL version 3