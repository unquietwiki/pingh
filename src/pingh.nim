#[
pingh: periodically return status of host as a HTTP response.
Michael Adams, unquietwiki.com, 2025-03-21
]#

# Libraries
import std/[asyncdispatch, httpclient, parseopt, strutils, times, uri]

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
  minutes: int
  targetURL: Uri

# === Timer loop, written partly with Copilot ===
proc timerLoop*(interval: int = 1, callback: proc()) {.async.} =
    ## Executes a callback function on a timer loop
    ## interval: time in minutes (minimum 1 minute)
    ## callback: procedure to execute on each interval
    let actualInterval = max(1, interval) # Ensure minimum 1 minute
    while true:
        await sleepAsync(actualInterval * 60 * 1000)
        callback()

# === Ping the target URL ===
proc pingURL() =
  let client: HttpClient = newHttpClient()
  let response: string = client.getContent(targetURL)
  echo("Pinged: ", $targetURL, " ; Response length: ", response.len)
  client.close()

# === Functions to display command line information ===
proc writeVersion() =
  echo("==============================================================")
  echo(name & " " & version)
  echo(description)
  echo("Maintainer(s): " & author)
  echo("==============================================================")

proc writeHelp() =
  writeVersion()
  echo("Usage: -m:<minutes> <URL>")
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
    of "help", "h":
      writeHelp()
      quit(0)
    of "version", "v":
      writeVersion()
      quit(0)
  of cmdArgument:
    targetURL = parseUri(key)
  of cmdEnd:
    quit(0)

# === Main ===
proc main() {.async.} =
  echo("Pinging ", $targetURL, " every ", $minutes, " minutes...")
  pingURL()
  await timerLoop(minutes, pingURL)

waitfor main()
