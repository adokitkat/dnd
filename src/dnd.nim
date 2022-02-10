import std/[os, parseopt, parsecfg, posix, strformat, strutils, terminal, unicode, uri]
import gintro/[gtk, gdk, glib, gobject, gio]

const
  NimblePkgVersion {.strdefine.} = "Unknown"
  Version = NimblePkgVersion
  MAX_SIZE = 1024

var # Program default settings
  app_name = getAppFilename().rsplit("/", maxsplit=1)[1]
  cfg_file = "dnd.cfg"
  cfg_path = os.getHomeDir() & ".config/dnd/"
  dnd_cfg = ""
  cfg_preset = "Default" # You can modify presets in dnd.cfg file
  w = 200 # app width
  h = 200 # app height
  decorated = true
  opacity = 1.0
  keep = false
  always_on_top = true
  center_mouse = false
  center_screen = true
  
  verbose = false
  print_path = true

var # Variables
  window: ApplicationWindow 
  vbox: Box
  input: seq[string]

  uri_collection: seq[cstring]
  uri_count = 0
  drag_all = false
  #iconTheme: gtk.IconTheme
  #thumb_size = 96

type # Custom types
  TargetType {.pure.} = enum
    Text = 1
    Uri = 2
  
  DraggableThing = ref object
    text: string
    uri: string
  
  ArgParseOutput = tuple
    keep, always_on_top, center_mouse, center_screen, decorated: bool
    opacity: float

proc addDndButton(box: var Box) # Forward declaration

proc isFileUri(uri: string): bool = uri.parseUri().scheme == "file"

proc buttonClicked(widget: gtk.Button; dd: DraggableThing) =
  when defined(posix):
    if posix.fork() == 0:
      discard posix.execlp("xdg-open", "xdg-open", dd.uri.cstring, nil)
  else:
    {.warning: "Click to open won't work in not POSIX enviroment".}

proc dragDataGet(widget: gtk.Button, context: gdk.DragContext, 
                data: gtk.SelectionData, info: int, time: int, dd: DraggableThing) =
  if info == TargetType.Uri.ord:
    var uris: seq[cstring]
    
    if drag_all:
      uri_collection[uri_count] = nil
      uris = uri_collection
    else:
      #uris.add dd.uri.cstring # TODO: a bug in gintro
      discard

    if verbose:
      if drag_all:
        stderr.write &"Sending all as URI\n"
      else:
        stderr.write &"Sending as URI: {dd.uri}\n"

    discard data.setUris(dd.uri.cstring) # TODO: a bug in gintro
    widget.signalStopEmissionByName("drag-data-get")
  
  elif info == TargetType.Text.ord:
    if verbose:
      stderr.write &"Sending as TEXT: {dd.text}\n"
    discard data.setText(dd.text.cstring, -1)
  
  else:
    stderr.write &"Error: bad target type {info}\n"

proc dragEnd(widget: Button; context: gdk.DragContext) =
  if verbose:
    let
      succeeded = context.dragDropSucceeded()
      action: DragAction = context.getSelectedAction()
    var action_str: string
    if DragFlag.copy in action:
      action_str = "COPY"
    elif DragFlag.move in action:
      action_str = "MOVE"
    elif DragFlag.link in action:
      action_str = "LINK"
    elif DragFlag.ask in action:
      action_str = "ASK"
    else:
      action_str = &"invalid {action}"
    echo &"Selected drop action: {action_str}; Succeeded: {succeeded}"

proc addButton(box: var gtk.Box, label: string; dragdata: DraggableThing; typee: int): gtk.Button =
  var button: gtk.Button = newButton(label)
  #if icons_only:
  #  button = gtk.newButton()
  #else:
  var target_list: gtk.TargetList = button.dragSourceGetTargetList()
  if target_list != nil:
    discard target_list.`ref`
  else:
    target_list = gtk.new_target_list(newSeq[TargetEntry]())

  if typee == TargetType.Uri.ord:
    target_list.addUriTargets(TargetType.Uri.ord)
  else:
    target_list.addTextTargets(TargetType.Text.ord)

  button.dragSourceSet({ModifierFlag.button1}, newSeq[TargetEntry](),
                      {DragFlag.copy})#, DragFlag.link, DragFlag.ask}) 
  button.dragSourceSetTargetList(target_list)

  button.connect("drag-data-get", dragDataGet, dragdata)
  button.connect("clicked", buttonClicked, dragdata)
  button.connect("drag-end", dragEnd)
  box.add(button)

  if drag_all:
    if uri_count < MAX_SIZE:
      uri_collection[uri_count] = dragdata.uri.cstring
    else:
      stderr.write &"Exceeded maximum number of files for drag_all ({MAX_SIZE})\n"
  
  uri_count.inc
  return button

proc addFileButton(box: var gtk.Box, file: gio.GFile): gtk.Button =
  let
    filename: string = file.get_path()
    uri: string = file.get_uri()
    dragdata: DraggableThing = DraggableThing()

  if not file.query_exists(nil):
    stderr.write &"The file {filename} does not exist.\n"
  else:
    dragdata.text = filename
    dragdata.uri = uri
    let button = box.addButton(filename, dragdata, TargetType.Uri.ord)
    result = button

proc addUriButton(box: var gtk.Box, uri: string): gtk.Button =
  let dragdata: DraggableThing = DraggableThing()
  dragdata.text = uri
  dragdata.uri = uri
  let button = box.addButton(uri, dragdata, TargetType.Uri.ord)
  result = button

proc makeButton(box: var gtk.Box, filename: string): gtk.Button =
  # decodeUrl ?
  let uri = filename.parseUri()
  var file: gio.GFile

  if uri.scheme == "":
    file = filename.newGFileForPath()
    result = box.addFileButton(file)

  elif uri.scheme == "file":
    file = filename.newGFileForUri()
    result = box.addFileButton(file)

  else:
    result = box.addUriButton(filename)

proc dragDataRecieved(widget: gtk.Button, context: gdk.DragContext; x, y: int; data: gtk.SelectionData; info, time: int) =
  let
    uris: seq[string] = data.getUris()
    text: string = data.getText()
  var file: GFile

  if uris.len == 0 and text.len == 0:
    context.drag_finish(false, false, time)

  if uris.len > 0:
    if verbose:
      stderr.write "Received URIs\n"

    vbox.remove(widget)
    for uri in uris:
      if uri.isFileUri():
        file = uri.cstring.newGFileForUri()
        if print_path:
          let filename: string  = file.getPath()
          echo filename
        else:
          echo uri
        if keep:
          discard vbox.addFileButton(file)
        else:
          echo uri
          if keep:
            discard vbox.addUriButton(uri)

    vbox.addDndButton()
    window.showAll()

  if text.len > 0:
    if verbose:
      stderr.write "Received Text\n"

    if keep:
      var text_uri = text.parseUri()
      if $text_uri.scheme != "":
        vbox.remove(widget)
        discard vbox.addUriButton($text_uri)
        vbox.addDndButton()
        window.showAll()

    echo text

  if verbose and uris.len == 0 and text.len == 0:
    stderr.write "Received nothing\n"

  context.drag_finish(true, false, time)

proc dragDrop(widget: gtk.Button; context: DragContext; x, y, time: int) : bool = 
  let
    target_list = dragDestGetTargetList(widget)
    list: seq[gdk.Atom] = gdk.listTargets(context)
  var success: bool = false

  for atom in list:
    if target_list.findTargetList(atom):
      widget.dragGetData(context, atom, time)
      success = true
  
  if not success:
    context.dragFinish(false, false, time)
  
  result = true

proc addDndButton(box: var gtk.Box) =
  var
    dnd_area = newButton("Drag and drop here")
    target_list = dnd_area.dragDestGetTargetList()
  
  box.packStart(dnd_area, true, true, 0)

  if target_list.isNil:
    target_list = newTargetList(newSeq[TargetEntry]())
  else:
    target_list = target_list.`ref`

  target_list.addTextTargets(TargetType.Text.ord)
  target_list.addUriTargets(TargetType.Uri.ord)
  dnd_area.dragDestSet(
    {DestFlag.motion, DestFlag.highlight},
    @[],
    {gdk.DragFlag.copy}
  )

  dnd_area.dragDestSetTargetList(targetlist)
  dnd_area.connect("drag-drop", dragDrop)
  dnd_area.connect("drag-data-received", dragDataRecieved)

proc quitAction(action: SimpleAction; v: Variant) = quit()

proc appActivate(app: Application) =
  window = newApplicationWindow(app)
  window.title = app_name.cstring
  window.defaultSize = (w, h)
  window.decorated = decorated
  window.resizable = true
  window.keepAbove = always_on_top
  if center_screen:
    window.position = WindowPosition.center
  if center_mouse:
    window.position = WindowPosition.mouse
  
  # Register key events
  let action = newSimpleAction("quit")
  discard action.connect("activate", quitAction)
  window.actionMap.addAction(action)
  app.setAccelsForAction("win.quit", "Q", "Escape")
  
  # Create  window content
  vbox = newBox(Orientation.vertical, 0)
  window.add(vbox)

  # Add piped files to input
  if not io.stdin.isatty():
    for line in io.stdin.lines:
      input.add line

  # Populate if input files, otherwise read 
  for arg in input:
    discard vbox.makeButton(arg)

  vbox.add_dnd_button() # Add drag and drop area
  window.showAll()
  if opacity < 1.0 :
    window.setAppPaintable(true)
    window.setOpacity(opacity)

proc parseCfg() =
  for kind, key, val in commandLineParams().getopt():
    case kind
    of cmdEnd: break
    of cmdArgument: discard
    of cmdLongOption, cmdShortOption:
      case key
      of "cfg", "f":
        if val != "": cfg_file = val
      of "preset", "p":
        if val != "": cfg_preset = val

  dnd_cfg = cfg_file
  if not dnd_cfg.fileExists: # If no config in current dir
    dnd_cfg = cfg_path & cfg_file # Set path to cfg installation folder

  if dnd_cfg.fileExists: # If config exist try to load it
    var cfg = dnd_cfg.loadConfig()
    try: w = cfg.getSectionValue(&"{cfg_preset}", "w").parseInt
    except: discard
    try: h = cfg.getSectionValue(&"{cfg_preset}", "h").parseInt
    except: discard
    try: keep = cfg.getSectionValue(&"{cfg_preset}", "keep").toLower.parseBool
    except: discard
    try: always_on_top = cfg.getSectionValue(&"{cfg_preset}", "always_on_top").toLower.parseBool
    except: discard
    try: center_mouse = cfg.getSectionValue(&"{cfg_preset}", "center_mouse").toLower.parseBool
    except: discard
    try: center_screen = cfg.getSectionValue(&"{cfg_preset}", "center_screen").toLower.parseBool
    except: discard
    try: decorated = cfg.getSectionValue(&"{cfg_preset}", "decorated").toLower.parseBool
    except: discard
    try: opacity = cfg.getSectionValue(&"{cfg_preset}", "opacity").toLower.parseFloat
    except: discard

proc argParse() : ArgParseOutput =
  proc writeHelp() = 
    echo &"{app_name} - bi-directional drag and drip source / target"
    echo &"Usage: {app_name} [options] [file...]"
    let help = block:
      [
        "-k, --keep\t\tKeep dropped files in for a drag out",
        "-t, --top\t\tKeep the program window always on top",
        "-c, --center-mouse\tCenter the program on the mouse",
        "-C, --center-screen\tCenter the program in the middle of the screen",
        "-f, --cfg=NAME\tLoad a different config file",
        "-p, --preset=NAME\tLoad a different preset from the config file",
        "-d, --decorated\tLet the program window be decorated by the window manager",
        "-o, --opacity=FLOAT\tChange the program window opacity",
        "-v, --version\t\tShow version info",
        "-h, --help\t\tShow this message"
      ]
    for line in help:
      echo "  " & line
    if dnd_cfg.fileExists:
      echo ""
      echo &"Presets in current loaded dnd.cfg file ({dnd_cfg}):"
      for line in dnd_cfg.lines:
        echo "  " & line

  var
    k = keep
    t = always_on_top
    c = center_mouse
    C = center_screen
    d = decorated
    o = opacity

  for kind, key, val in commandLineParams().getopt():
    case kind
    of cmdEnd: break
    of cmdArgument: input.add key
    of cmdLongOption, cmdShortOption:
      case key
      of "keep", "k":
        if val != "": 
          try: k = val.toLower.parseBool
          except: discard
        else:
          k = true
      of "top", "t":
        if val != "": 
          try: t = val.toLower.parseBool
          except: discard
        else:
          t = true
      of "center_mouse", "c": 
        if val != "": 
          try: c = val.toLower.parseBool
          except: discard
        else:
          c = true
      of "center-screen", "C":
        if val != "": 
          try: C = val.toLower.parseBool
          except: discard
        else:
          C = true
      of "decorated", "d":
        if val != "": 
          try: d = val.toLower.parseBool
          except: discard
        else:
          d = true
      of "opacity", "o":
        if val != "": 
          try: o = val.parseFloat
          except: discard
      of "help", "h": 
        writeHelp()
        quit 0
      of "version", "v": 
        echo &"{app_name} {Version}"
        quit 0

  result = (k, t, c, C, d, o)

proc main() =
  parseCfg() # Parse config file
  let args = argParse() # Parse arguments (flags)
  # Flags override the preset
  keep = args.keep
  always_on_top = args.always_on_top
  center_mouse = args.center_mouse
  center_screen = args.center_screen
  decorated = args.decorated
  opacity = args.opacity
  # Run the GUI
  let app = newApplication("org.gtk.example")
  app.connect("activate", appActivate)
  discard app.run()

when isMainModule:
  main()