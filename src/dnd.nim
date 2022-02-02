import std/[bitops, os, parseopt, parsecfg, strformat, strutils, unicode]
import std/posix
import gintro/[gtk, gdk, gdkpixbuf, glib, gobject, gio]

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

  vbox: Box

var
  input : seq[string]

type
  DraggableThing = ref object
    text: string
    uri: string

# // MODE_ALL
const MAX_SIZE = 100

var
  uri_collection: seq[cstring]
  uri_count = 0
  drag_all = false
  #iconTheme: gtk.IconTheme
  #thumb_size = 96

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

proc drag_drop(widget: Button, context: DragContext, x: int, y: int, time: int) : bool = 
  var
    target_list = dragDestGetTargetList(widget)
    #list = gdk_drag_context_list_targets(context.addr)#listTargets(context)

  #if list.isNil == false:

  # ... TODO

  return true

proc button_clicked(widget: Button; dd: Draggable_thing) =
  if posix.fork() == 0:
    discard posix.execlp("xdg-open", "xdg-open", dd.uri.cstring, nil)

proc drag_data_get(widget: Button; context: gdk.DragContext; data: gtk.SelectionData;  info: int; time: int; dd: Draggable_thing) =
  if info == TargetType.Uri.ord:
    var uris: seq[cstring]
    var single_uri_data: array[2, cstring] = [dd.uri.cstring, ""]
    echo dd.uri
    if drag_all:
      uri_collection[uri_count] = ""
      uris = uri_collection
    else:
      uris = @single_uri_data
    #if verbose:
    if drag_all:
     stderr.write("Sending all as URI\n")
    else:
      stderr.write("Sending as URI: $1\n" % [dd.uri])
    discard gtk.set_uris(data, uris)
    gobject.signal_stop_emission_by_name(widget, "drag-data-get")
  elif info == TargetType.Text.ord:
    #if verbose:
    #  write(stderr, "Sending as TEXT: $1\n" % [dd.text])
    discard gtk.set_text(data, dd.text.cstring, -1)
  else:
    write(stderr, "Error: bad target type $1\n" % [$info])

proc drag_end(widget: Button; context: gdk.DragContext) =
  #if verbose:
    let succeeded = gdk.drag_drop_succeeded(context)
    let action: gdk.DragAction = gdk.get_selected_action(context)
    var action_str: string
    case action
    of gdk.DragAction.copy: # GDK_ACTION_COPY:
      action_str = "COPY"
    of DragAction.move: #GDK_ACTION_MOVE:
      action_str = "MOVE"
    of DragAction.link: #GDK_ACTION_LINK:
      action_str = "LINK"
    of DragAction.ask: #GDK_ACTION_ASK:
      action_str = "ASK"
    else:
      #action_str = malloc(sizeof(char) * 20);
      #snprintf(action_str, 20, "invalid (%d)", action);
      action_str = "invalid ($1)" % [$action]
    stderr.write("Selected drop action: $1; Succeeded: $2\n" % [$action_str, $succeeded])
    #if (action_str[0] == 'i')
    #  free(action_str);
  #if and_exit:
  #  gtk.main_quit()

proc add_button(label: string; dragdata: Draggable_thing; typee: int): gtk.Button =
  var button: gtk.Button
  #if icons_only:
  #  button = gtk.newButton()
  #else:
  button = gtk.newButton(label)
  var targetlist: gtk.TargetList = gtk.drag_source_get_target_list(button)
  if targetlist != nil:
    discard # gtk_target_list_ref(targetlist);
  else:
    targetlist = gtk.new_target_list(newSeq[TargetEntry]());
  if typee == TargetType.Uri.ord:
    gtk.add_uri_targets(targetlist, TargetType.Uri.ord)
  else:
    gtk.add_text_targets(targetlist, TargetType.Text.ord)
  #gtk.drag_source_set(button, {ModifierFlag.button1}, newSeq[TargetEntry](), {gdk.DragAction.copy, link, ask}) # bug in gintro!
  gtk.drag_source_set(button, {ModifierFlag.button1}, newSeq[TargetEntry](), cast[DragAction](bitor(gdk.DragAction.copy.ord, gdk.DragAction.link.ord, gdk.DragAction.ask.ord)))
  gtk.drag_source_set_target_list(button, targetlist)
  button.connect("drag-data-get", drag_data_get, dragdata)
  button.connect("clicked", button_clicked, dragdata)
  button.connect("drag-end", drag_end)#, dragdata)
  vbox.add(button)
  if drag_all:
    if uri_count < MAX_SIZE:
      uri_collection[uri_count] = dragdata.uri.cstring
    else:
      stderr.write("Exceeded maximum number of files for drag_all ($1)\n" % [$MAX_SIZE])
  uri_count += 1
  return button;

proc add_file_button(file: gio.GFile) =
  let filename: string = gio.get_path(file)
  if not gio.query_exists(file, nil):
    stderr.write("The file `$1' does not exist.\n" % [filename])
    quit(1)
  let uri: string = gio.get_uri(file)
  let dragdata: Draggable_thing = Draggable_thing() # malloc(sizeof(struct draggable_thing));
  dragdata.text = filename
  dragdata.uri = uri
  let button: gtk.Button = add_button(filename, dragdata, TargetType.Uri.ord)

proc add_filename_button(filename: string) =
  let file: gio.GFile = new_gfile_for_path(filename)
  add_file_button(file)

proc add_uri_button(uri: string) =
  let dragdata: Draggable_thing = Draggable_thing() # malloc(sizeof(struct draggable_thing));
  dragdata.text = uri
  dragdata.uri = uri
  let button: gtk.Button = add_button(uri, dragdata, TargetType.Uri.ord)

proc is_uri(uri: string): bool =
  for i in uri.low .. uri.high:
  # for (int i=0; uri[i]; i++)
    if uri[i] == '/':
      return false;
    elif uri[i] == ':' and i > 0:
      return true
    elif (not(uri[i] >= 'a' and uri[i] <= 'z')) or
      (uri[i] >= 'A' and uri[i] <= 'Z') or
      (uri[i] >= '0' and uri[i] <= '9' and i > 0) or
      (i > 0 and (uri[i] == '+' or uri[i] == '.' or uri[i] == '-')): # // RFC3986 URI scheme syntax
        return false
  return false

proc is_file_uri(uri: string): bool = uri.startsWith("file:")

proc make_btn(filename: string) =

  if not is_uri(filename):
    add_filename_button(filename)

  elif is_file_uri(filename):
    let file: gio.GFile = gio.new_gfile_for_uri(filename)
    add_file_button(file)

  else:
    add_uri_button(filename)

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
  dnd_area.connect("drag-drop", drag_drop)
  #dnd_area.connect("drag-data-recieved", drag-data-recieved)

proc appActivate(app: Application) =
  let window = newApplicationWindow(app)
  window.title = app_name.cstring
  window.defaultSize = (w, h)
  window.resizable = true
  window.keepAbove = always_on_top
  if center_screen:
    window.position = WindowPosition.center

  vbox = newBox(Orientation.vertical, 0)
  window.add(vbox)

  vbox.add_dnd_button()

  for arg in input:
    make_btn(arg)
  
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