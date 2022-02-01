import std/[bitops, os, parseopt, parsecfg, strformat, strutils, unicode]
import gintro/[gtk, gdk, glib, gobject, gio]

const
  NimblePkgVersion {.strdefine.} = "Unknown"
  Version = NimblePkgVersion

var # Program defaults
  app_name = getAppFilename().rsplit("/", maxsplit=1)[1]
  cfg_file = "dnd.cfg"
  cfg_preset = "Default" # You can modify presets in dnd.cfg file
  w = 200 # app width
  h = 200 # app height
  keep = true
  always_on_top = true
  center = true
  center_screen = false

var
  input : seq[string]

type
  TargetType {.pure.} = enum
    Text, Uri
  
  ArgParseOutput = tuple
    keep, always_on_top, center, center_screen: bool

proc arg_parse() : ArgParseOutput =

  proc writeHelp() = 
    echo fmt"{app_name} - drag and drip source / target"
    echo fmt"Usage: {app_name} [options] [file...]"
    let help = block:
      [
        "-k, --keep\t\tKeep dropped files in for a drag out",
        "-t, --top\t\tKeep the program window always on top",
        "-c, --center\t\tOpen the program window in the middle of the parent window",
        "-C, --center-screen\tOpen program the window in the middle of the screen",
        "-p, --preset=NAME\tLoad different preset from config file"
      ]
    for line in help:
      echo "  " & line

  var
    k = keep
    t = always_on_top
    c = center
    C = center_screen

  for kind, key, val in commandLineParams().getopt():
    case kind
    of cmdEnd: break
    of cmdArgument: input.add key
    of cmdLongOption, cmdShortOption:
      case key
      of "preset", "p":
        if val != "":
          cfg_preset = val
      of "keep", "k":
        k = true
      of "top", "t":
        t = true
      of "center", "c": 
        c = true
      of "center-screen", "C":
        C = true
      of "help", "h": 
        writeHelp()
        quit 0
      of "version", "v": 
        echo &"{app_name} {Version}"
        quit 0

  result = (k, t, c, C)

proc dragDrop(widget: Widget, context: DragContext, x: int, y: int, time: int) : bool = 
  var
    target_list = dragDestGetTargetList(widget)
    #list = gdk_drag_context_list_targets(context.addr)#listTargets(context)

  #if list.isNil == false:

  return true
#proc dragDataRecieved() = discard

proc add_dnd_button(box: var Box) =
  var dnd_area = newButton("Drag and drop here")
  box.packStart(dnd_area, true, true, 0)
  var target_list = dnd_area.dragDestGetTargetList()
  if target_list.isNil:
    target_list = newTargetList(@[])
  else:
    discard target_list.`ref`
  target_list.addTextTargets(TargetType.Text.ord)
  target_list.addUriTargets(TargetType.Uri.ord)
  dnd_area.dragDestSet(
    bitor(DestDefaults.motion.ord, DestDefaults.highlight.ord).DestDefaults,
    @[],
    gdk.DragAction.copy
  )
  dnd_area.dragDestSetTargetList(targetlist)
  #dnd_area.connect("drag-drop", dragDrop)
  #dnd_area.connect("drag-data-recieved", dragDataRecieved)

proc appActivate(app: Application) =
  let window = newApplicationWindow(app)
  window.title = app_name.cstring
  window.defaultSize = (w, h)
  window.resizable = true
  window.keepAbove = always_on_top
  if center_screen:
    window.position = WindowPosition.center

  var vbox = newBox(Orientation.vertical, 0)
  window.add(vbox)

  vbox.add_dnd_button()


  
  showAll(window)

proc main() =
  let args = arg_parse()

  if cfg_file.fileExists:
    var cfg = cfg_file.loadConfig
    try: w = cfg.getSectionValue(&"{cfg_preset}", "w").parseInt
    except: discard
    try: h = cfg.getSectionValue(&"{cfg_preset}", "h").parseInt
    except: discard
    try: keep = cfg.getSectionValue(&"{cfg_preset}", "keep").toLower.parseBool
    except: discard
    try: always_on_top = cfg.getSectionValue(&"{cfg_preset}", "always_on_top").toLower.parseBool
    except: discard
    try: center = cfg.getSectionValue(&"{cfg_preset}", "center").toLower.parseBool
    except: discard
    try: center_screen = cfg.getSectionValue(&"{cfg_preset}", "center_screen").toLower.parseBool
    except: discard
  
  # Flags override the preset
  keep = args.keep
  always_on_top = args.always_on_top
  center = args.center
  center_screen = args.center_screen

  let app = newApplication("org.gtk.example")
  app.connect("activate", appActivate)
  discard app.run()

when isMainModule:
  main()