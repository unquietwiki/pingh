#[
pingh: periodically return status of host as a HTTP response.
Michael Adams, unquietwiki.com, 2025.06.02.2
]#

# Libraries
import std/[asyncdispatch, httpclient, net, os, osproc, parseopt, strutils, times, uri]

# Config import (it's just variables)
include config

# Constants
const
  name = pkgTitle
  version = pkgVersion
  description = pkgDescription
  author = pkgAuthor

# Variables (modified by the command line options)
var
  minutes: int = 0
  targetURL: Uri
  program: string = ""
  port: int = 0
  server: string = "localhost"
  verbose: bool = false

# === Functions to check for running program/process ===
proc findProgram(): bool =
  if program.len == 0:
    return true
  # Enhanced validation to prevent injection
  if program.contains({';', '&', '|', '`', '$', '(', ')', '<', '>', '"', '\'', '\\', '/', '*', '?'}):
    echo("Invalid characters in program name")
    return false
  # Windows
  if defined(windows):
    try:
      let output = osproc.execProcess("tasklist /fo csv /nh")
      for line in output.splitLines():
        if line.len > 0:
          let fields = line.split(',')
          if fields.len > 0:
            let processName = fields[0].strip(chars = {'"'})
            if processName.toLowerAscii() == program.toLowerAscii():
              return true
      return false
    except:
      echo("Error checking for program: ", getCurrentExceptionMsg())
      return false
  # Unix-like systems
  elif defined(linux) or defined(macosx):
    try:
      # Use execCmd instead of execCmdEx to avoid shell execution
      let exitCode = osproc.execCmd("pgrep -x " & program.quoteShell() & " > /dev/null 2>&1")
      return exitCode == 0
    except:
      echo("Error checking for program: ", getCurrentExceptionMsg())
      return false
  else:
    echo("Unsupported operating system for program check.")
    return false

proc checkProgram(): bool =
  if (program.len > 0) and not findProgram():
    echo("Program ", program, " is not running.")
    return false
  if (program.len > 0) and findProgram():
    if verbose:
      echo("Program ", program, " is running.")
  return true

# === Function to check if a TCP port is open ===
proc checkTCPPort(): bool =
  if port == 0:
    return true
  try:
    let sock = net.dial(server, Port(port))
    sock.close()
    if verbose:
      echo("Port ", port, " is open on ", server, ".")
    return true
  except:
    echo("Port ", port, " is closed on ", server, ".")
    return false

# === Ping the target URL ===
proc pingURL(): bool =
  try:
    let client = newHttpClient(timeout = 10000)
    let response: string = client.getContent(targetURL)
    client.close()
    if verbose:
      echo("Pinged: ", $targetURL, " ; Response length: ", response.len)
    return true
  except HttpRequestError:
    echo("HTTP error pinging: ", $targetURL, " ; Error: ", getCurrentExceptionMsg())
    return false
  except TimeoutError:
    echo("Timeout pinging: ", $targetURL)
    return false
  except:
    echo("Failed to ping: ", $targetURL, " ; Error: ", getCurrentExceptionMsg())
    return false

# === Timer loop, written partly with Copilot ===
proc timerLoop*(interval: int = 1, callback: proc()) {.async.} =
    ## Executes a callback function on a timer loop
    ## interval: time in minutes (minimum 1 minute)
    ## callback: procedure to execute on each interval
    let actualInterval = max(1, interval) # Ensure minimum 1 minute
    while true:
        await sleepAsync(actualInterval * 60 * 1000)
        callback()

# === Function to call check functions (need for async timer) ===
proc runChecks() =
  let programOk = checkProgram()
  let portOk = checkTCPPort()
  let urlOk = pingURL()  
  if not programOk or not portOk or not urlOk:
    var failedChecks: seq[string] = @[]
    if not programOk: failedChecks.add("program")
    if not portOk: failedChecks.add("port")
    if not urlOk: failedChecks.add("URL")
    echo("Failed checks: ", failedChecks.join(", "))
    quit(1)

# === Functions to display command line information ===
proc writeVersion() =
  echo("==============================================================")
  echo(name & " " & version)
  echo(description)
  echo("Maintainer(s): " & author)
  echo("==============================================================")

proc writeHelp() =
  writeVersion()
  echo("Usage: -m:<minutes> \"<URL>\"")
  echo("       -m:<minutes> -p:<program> \"<URL>\"")
  echo("       -m:<minutes> -t:<port> \"<URL>\"")
  echo("       -m:<minutes> -s:\"localhost\" -t:<port> \"<URL>\"")
  echo("Other flags: --debug (-d), --help (-h), --version (-v)")
  echo("==============================================================")

# === Parse command line ===
for kind, key, val in getopt():
  case kind
  of cmdLongOption, cmdShortOption:
    case key
    of "min", "m":
      try:
        let min = parseInt(val)
        if min > 0:
          minutes = min
        else:
          echo("Invalid interval: ", val)
          quit(1)
      except ValueError:
        echo("Must enter a numerical value for minutes: ", val)
        quit(1)
    of "program", "p":
      program = val
      if program.len == 0:
        echo("Invalid program name: ", val)
        quit(1)
    of "server", "s":
      server = val
      if server.len == 0:
        echo("Invalid server name: ", val)
        quit(1)
    of "tcpport", "t":
      try:
        port = parseInt(val)
        if port < 1 or port > 65535:
          echo("Port number needs to be between 1-65535: ", val)
          quit(1)
      except ValueError:
        echo("Invalid port number: ", val)
        quit(1)
    of "debug", "d":
      verbose = true
    of "help", "h":
      writeHelp()
      quit(0)
    of "version", "v":
      writeVersion()
      quit(0)
  of cmdArgument:
    try:
      targetURL = parseUri(key)
      if targetURL.scheme notin ["http", "https"]:
        echo("Invalid URL scheme: ", targetURL.scheme)
        quit(1)
    except:
      echo("Invalid URL: ", key)
      quit(1)
  of cmdEnd:
    break

# === Main loop ===
proc main() {.async.} =
  if verbose:
    echo("Begin pingh main loop")
  echo("Pinging ", $targetURL, " every ", $minutes, " minutes...")
  runChecks()  # Initial check before starting the timer
  await timerLoop(minutes, runChecks) # Loop every 'minutes' minutes

# === Start the program ===
if (minutes == 0) or (targetURL.hostname.len == 0):
  writeHelp()
  quit(1)
if verbose:
  writeVersion()
  echo("Starting pingh with the following parameters:")
  echo("Minutes: ", minutes)
  echo("Target URL: ", $targetURL)
  echo("Program: ", program)
  echo("Port: ", port)
  echo("Server: ", server)
waitfor main()
