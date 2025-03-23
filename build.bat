@echo off
nimble build -d:release -d:ssl --mm:orc --opt:size --verbose
move pingh.exe bin\
