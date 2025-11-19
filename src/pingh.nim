#[
pingh: periodically return status of host as a HTTP response.
Michael Adams, unquietwiki.com, 2025.11.18.1
]#

# Libraries
import std/[asyncdispatch, asyncnet, exitprocs, httpclient, net, os, osproc, parseopt, strutils, uri]

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
  httpClientLocal: AsyncHttpClient = nil

# === Functions to check for running program/process ===
proc findProgramAsync(): Future[bool] {.async.} =
  if program.len == 0:
    return true
  # Enhanced validation to prevent injection
  if program.contains({';', '&', '|', '`', '$', '(', ')', '<', '>', '"', '\'', '\\', '/', '*', '?'}):
    echo("Invalid characters in program name")
    return false
  # Windows
  if defined(windows):
    try:
      # Run in background to avoid blocking the async event loop
      let cmd = "tasklist /fi \"imagename eq " & program & "\" /fo csv /nh"
      let output = osproc.execProcess(cmd)
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

proc checkProgramAsync(): Future[bool] {.async.} =
  if program.len == 0:
    return true

  let running = await findProgramAsync()
  if not running:
    echo("Program ", program, " is not running.")
    return false

  if verbose:
    echo("Program ", program, " is running.")
  return true

# === Function to check if a TCP port is open ===
proc checkTCPPortAsync(): Future[bool] {.async.} =
  if port == 0:
    return true
  try:
    let sock = newAsyncSocket()
    # Set timeout of 5 seconds for connection attempt
    let connected = await sock.connect(server, Port(port)).withTimeout(5000)
    if connected:
      sock.close()
      if verbose:
        echo("Port ", port, " is open on ", server, ".")
      return true
    else:
      sock.close()
      echo("Port ", port, " connection timeout on ", server, ".")
      return false
  except TimeoutError:
    echo("Port ", port, " connection timeout on ", server, ".")
    return false
  except:
    echo("Port ", port, " is closed on ", server, ".")
    return false

# === Cleanup handler for graceful shutdown ===
proc cleanup() {.noconv.} =
  ## Cleanup handler called on program exit
  if not httpClientLocal.isNil:
    try:
      httpClientLocal.close()
      if verbose:
        echo("HTTP client closed.")
    except:
      discard
  if verbose:
    echo("Cleanup completed.")

# === Ping the target URL ===
proc pingURL(): Future[bool] {.async.} =
  try:
    if httpClientLocal.isNil:
      httpClientLocal = newAsyncHttpClient()
      httpClientLocal.timeout = 10000
    let response: string = await httpClientLocal.getContent($targetURL)
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
proc timerLoop*(interval: int = 1, callback: proc(): Future[void]) {.async.} =
    ## Executes a callback function on a timer loop
    ## interval: time in minutes (minimum 1 minute)
    ## callback: async procedure to execute on each interval
    let actualInterval = max(1, interval) # Ensure minimum 1 minute
    while true:
        await sleepAsync(actualInterval * 60 * 1000)
        await callback()

# === Function to call check functions (need for async timer) ===
proc runChecks(): Future[void] {.async.} =
  # Run all three checks in parallel for better performance
  let results = await all(checkProgramAsync(), checkTCPPortAsync(), pingURL())
  let programOk = results[0]
  let portOk = results[1]
  let urlOk = results[2]

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
  await runChecks()  # Initial check before starting the timer
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

addExitProc(cleanup) # Register cleanup handler

waitfor main()
