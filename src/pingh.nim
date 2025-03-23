#[
pingh: periodically return status of host as a HTTP response.
Michael Adams, unquietwiki.com, 2025.03.22.2
]#

# Libraries
import std/[asyncdispatch, httpclient, net, osproc, parseopt, strutils, uri]

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

# === Functions to check for running program/process ===
proc findProgram(): bool =
  # Windows
  when defined(windows):
    let winFound = osproc.execProcess("tasklist").find(program) != -1
    return winFound
  # Linux
  when defined(linux):
    let linFound = osproc.execProcess("ps -A").find(program) != -1
    return linFound
  return false

proc checkProgram(): bool =
  if (program.len > 0) and not findProgram():
    echo("Program ", program, " is not running.")
    return false
  if (program.len > 0) and findProgram():
    echo("Program ", program, " is running.")
  return true

# === Function to check if a TCP port is open ===
proc checkTCPPort(): bool =
  if port == 0:
    return true
  try:
    let sock = net.dial(server, Port(port))
    echo("Port ", port, " is open on ", server)
    sock.close()
  except:
    return false
  return true

# === Ping the target URL ===
proc pingURL() =
  let client: HttpClient = newHttpClient()
  let response: string = client.getContent(targetURL)
  echo("Pinged: ", $targetURL, " ; Response length: ", response.len)
  client.close()

# === Timer loop, written partly with Copilot ===
proc timerLoop*(interval: int = 1, callback: proc()) {.async.} =
    ## Executes a callback function on a timer loop
    ## interval: time in minutes (minimum 1 minute)
    ## callback: procedure to execute on each interval
    let actualInterval = max(1, interval) # Ensure minimum 1 minute
    while true:
        await sleepAsync(actualInterval * 60 * 1000)
        if checkProgram() and checkTCPPort():
          callback()

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
  echo("Other flags: --help (-h), --version (-v)")
  echo("==============================================================")

# === Parse command line ===
for kind, key, val in getopt():
  case kind
  of cmdLongOption, cmdShortOption:
    case key
    of "min", "m":
      let min = parseInt(val)
      if min > 0:
        minutes = min
      else:
        echo("Invalid interval: ", val)
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
      port = parseInt(val)
      if port < 1 or port > 65535:
        echo("Invalid port number: ", val)
        quit(1)
    of "help", "h":
      writeHelp()
      quit(0)
    of "version", "v":
      writeVersion()
      quit(0)
  of cmdArgument:
    try:
      targetURL = parseUri(key)
    except:
      echo("Invalid URL: ", key)
      quit(1)
  of cmdEnd:
    quit(0)

# === Main ===
proc main() {.async.} =
  if (minutes == 0) or (targetURL.hostname.len == 0):
    writeHelp()
    quit(1)
  if checkProgram() and checkTCPPort():
    pingURL()
    echo("Pinging ", $targetURL, " every ", $minutes, " minutes...")
  await timerLoop(minutes, pingURL)
waitfor main()
