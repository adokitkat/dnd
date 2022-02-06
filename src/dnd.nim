import std/[os, parseopt, parsecfg, posix, strformat, strutils, unicode, uri]
import gintro/[gtk, gdk, gdkpixbuf, glib, gobject, gio]

const
  NimblePkgVersion {.strdefine.} = "Unknown"
  Version = NimblePkgVersion
  MAX_SIZE = 1024

var # Program default settings
  app_name = getAppFilename().rsplit("/", maxsplit=1)[1]
  cfg_file = "dnd.cfg"
  cfg_preset = "Default" # You can modify presets in dnd.cfg file
  w = 200 # app width
  h = 200 # app height
  keep = false
  always_on_top = true
  center = false
  center_screen = true
  
  verbose = true
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
    keep, always_on_top, center, center_screen: bool

proc addDndButton(box: var Box)

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
    var
      uris: seq[cstring]
      #single_uri_data: array[2, cstring] = [dd.uri.cstring, nil]
    
    if drag_all:
      uri_collection[uri_count] = nil
      uris = uri_collection
    else:
      uris.add dd.uri.cstring
      uris.add nil

    if verbose:
      if drag_all:
        stderr.write &"Sending all as URI\n"
      else:
        stderr.write &"Sending as URI: {dd.uri}\n"

    discard data.setUris(uris)
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
    case cast[DragFlag](action)
    of DragFlag.copy:
      action_str = "COPY"
    of DragFlag.move:
      action_str = "MOVE"
    of DragFlag.link:
      action_str = "LINK"
    of DragFlag.ask:
      action_str = "ASK"
    else:
      action_str = "invalid action"
    echo &"Selected drop action: {action_str}; Succeeded: {succeeded}"
  #if and_exit:
  #  gtk.main_quit()

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
                      {DragFlag.copy, DragFlag.link, DragFlag.ask}) 
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

# proc addTextButton()

proc makeButton(box: var gtk.Box, filename: string): gtk.Button =
  # decodeUrl ?
  let uri = filename.parseUri()
  var file: gio.GFile

  if uri.scheme == "":
    file = new_gfile_for_path(filename)
    result = box.add_file_button(file)

  elif uri.scheme == "file":
    file = gio.new_gfile_for_uri(filename)
    result = box.add_file_button(file)

  else:
    result = box.add_uri_button(filename)

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

    for uri in uris:
      if uri.isFileUri():

        file = gio.new_gfile_for_uri(uri.cstring)
        
        if print_path:
          let filename: string  = gio.get_path(file)
          echo filename
        else:
          echo uri
        
        if keep:
          vbox.remove(widget)
          discard vbox.add_file_button(file)
          vbox.add_dnd_button()
          window.show_all()
        else:
          echo uri
          #if keep:
          vbox.remove(widget)
          discard vbox.addUriButton(uri)
          vbox.add_dnd_button()
          window.show_all()


  if text.len > 0:
    if verbose:
      stderr.write "Received Text\n"

    if keep:
      var text_uri = text.parseUri()
      if $text_uri.scheme != "":
        vbox.remove(widget)
        discard vbox.addUriButton($text_uri)
        vbox.add_dnd_button()
        window.show_all()

    echo text

  if verbose and uris.len == 0 and text.len == 0:
    stderr.write "Received nothing\n"

  # TODO: keep files from args 
  context.drag_finish(true, false, time)
  #if and_exit:
  #  gtk.main_quit()

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

proc appActivate(app: Application) =
  window = newApplicationWindow(app)
  window.title = app_name.cstring
  window.defaultSize = (w, h)
  window.resizable = true
  window.keepAbove = always_on_top
  if center_screen:
    window.position = WindowPosition.center
  # Create  window content
  vbox = newBox(Orientation.vertical, 0)
  window.add(vbox)
  # Populate if input files
  for arg in input:
    discard vbox.makeButton(arg)
  vbox.add_dnd_button() # Add drag and drop area
  window.showAll()

proc parseCfg() =
  if cfg_file.fileExists:
    var cfg = cfg_file.loadConfig()
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

proc argParse() : ArgParseOutput =
  proc writeHelp() = 
    echo &"{app_name} - bi-directional drag and drip source / target"
    echo &"Usage: {app_name} [options] [file...]"
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

proc main() =
  let args = argParse() # Parse arguments (flags)
  parseCfg() # Parse config file
  # Flags override the preset
  keep = args.keep
  always_on_top = args.always_on_top
  center = args.center
  center_screen = args.center_screen
  # Run the GUI
  let app = newApplication("org.gtk.example")
  app.connect("activate", appActivate)
  discard app.run()

when isMainModule:
  main()