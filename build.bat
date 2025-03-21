@echo off
nimble build -d:release -d:ssl --gc:orc --opt:size --verbose
move pingh.exe bin\
