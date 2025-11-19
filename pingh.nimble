import
  os

template thisModuleFile: string = instantiationInfo(fullPaths = true).filename

when system.fileExists(thisModuleFile.parentDir / "src/config.nim"):
  # In the git repository the Nimble sources are in a ``src`` directory.
  import src/config
else:
  # When the package is installed, the ``src`` directory disappears.
  import config


# Package

version       = pkgVersion
author        = pkgAuthor
description   = pkgDescription
license       = "MIT"
bin           = @["pingh"]
srcDir        = "src"
installExt    = @["nim"]

# Dependencies

requires "nim >= 2.2.0"

const compile = "nim c -d:release -d:ssl --mm:orc --opt:size"
const linux_x64 = "--cpu:amd64 --os:linux -o:pingh"
const linux_arm64 = "--cpu:arm64 --os:linux -o:pingh"
const windows_x64 = "--cpu:amd64 --os:windows -o:pingh.exe"
const macosx_x64 = "-o:pingh"
const program = "pingh"
const program_file = "src/pingh.nim"
const zip = "zip -X"

proc shell(command, args: string, dest = "") =
  exec command & " " & args & " " & dest

proc filename_for(os: string, arch: string): string =
  return "pingh" & "_v" & version & "_" & os & "_" & arch & ".zip"

task windows_x64_build, "Build pingh for Windows (x64)":
  shell compile, windows_x64, program_file

task linux_x64_build, "Build pingh for Linux (x64)":
  shell compile, linux_x64,  program_file

task linux_arm64_build, "Build pingh for Linux (arm64)":
  shell compile, linux_arm64,  program_file

task macosx_x64_build, "Build pingh for Mac OS X (x64)":
  shell compile, macosx_x64, program_file

# TODO: figure out proper "release" logic
