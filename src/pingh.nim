#[
pingh: periodically return status of host as a HTTP response.
Michael Adams, unquietwiki.com, 2025-03-20
]#

# Libraries
import std/[os, parseopt, strformat, strutils]

# Config import (it's just variables)
include config

# Tiffany import
include tiffany

# Constants
const
  name = pkgTitle
  version = pkgVersion
  description = pkgDescription
  author = pkgAuthor

# Variables (modified by the command line options)
var
  exts: seq[string]

# === Functions to display command line information ===
proc writeVersion() =
  echo("==============================================================")
  echo(name & " " & version)
  echo(description)
  echo("Maintainer(s): " & author)
  echo("==============================================================")

proc writeHelp() =
  writeVersion()
  echo("Usage: TBD")
  echo("Other flags: --help (-h), --version (-v)")
  echo("==============================================================")

# === Parse command line ===
for kind, key, val in getopt():
  case kind
  of cmdLongOption, cmdShortOption:
    case key
    of "help", "h":
      writeHelp()
      quit(0)
    of "version", "v":
      writeVersion()
      quit(0)
  of cmdArgument:
    exts.add(key)
  of cmdEnd:
    quit(0)
